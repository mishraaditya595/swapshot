extends Node3D
## MS-04: safe SHIFT placement plus deterministic anchor, cooldown and echo lifecycle.

signal anchor_placed(surface_point: Vector3)
signal anchor_expired(surface_point: Vector3)
signal shifted(from_position: Vector3, to_position: Vector3)
signal placement_rejected(reason: String)
signal shift_rejected(reason: String)
signal state_changed(new_state: int)
signal timers_updated(anchor_seconds: float, cooldown_seconds: float)
signal cooldown_started(duration: float)
signal cooldown_finished()
signal echo_spawned(echo: Node3D, world_position: Vector3)
signal echo_ended(world_position: Vector3)

enum State { READY, ANCHOR_ACTIVE, COOLDOWN, DISABLED }

const ECHO_SCENE: PackedScene = preload("res://scenes/abilities/shift_echo.tscn")

@export_range(1.0, 40.0, 0.5) var max_range_meters: float = 18.0
@export_range(0.0, 75.0, 1.0) var max_slope_degrees: float = 40.0
@export_range(0.5, 8.0, 0.5) var max_height_difference: float = 4.0
@export_range(0.1, 30.0, 0.1) var anchor_lifetime_seconds: float = 8.0
@export_range(0.1, 15.0, 0.1) var cooldown_seconds: float = 4.0
@export_range(0.1, 5.0, 0.1) var echo_lifetime_seconds: float = 1.5

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var camera: Camera3D = get_node("../CameraPivot/CameraBoom/Camera3D") as Camera3D
@onready var body_collider: CollisionShape3D = get_node("../CollisionShape3D") as CollisionShape3D
@onready var preview_mesh: MeshInstance3D = $Preview
@onready var anchor_mesh: MeshInstance3D = $Anchor
@onready var status_label: Label = $ShiftHUD/Status
@onready var timer_label: Label = $ShiftHUD/Timer
@onready var cue_player: AudioStreamPlayer = $CuePlayer

var state: State = State.READY
var anchor_active: bool = false
var anchor_point: Vector3 = Vector3.ZERO
var anchor_remaining_seconds: float = 0.0
var cooldown_remaining_seconds: float = 0.0
var echo_remaining_seconds: float = 0.0
var echo_instance: Node3D
var owner_alive: bool = true

var _clearance_shape: CapsuleShape3D
var _valid_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D
var _echo_material: StandardMaterial3D
var _deploy_cue: AudioStreamWAV
var _shift_cue: AudioStreamWAV


func _ready() -> void:
    var capsule: CapsuleShape3D = body_collider.shape as CapsuleShape3D
    if capsule == null:
        push_error("SHIFT requires the player's CapsuleShape3D")
        set_physics_process(false)
        return
    _clearance_shape = CapsuleShape3D.new()
    _clearance_shape.radius = capsule.radius + 0.035
    _clearance_shape.height = capsule.height + 0.08
    _valid_material = _indicator_material(Color(0.32, 0.96, 0.90, 0.8))
    _invalid_material = _indicator_material(Color(1.0, 0.43, 0.24, 0.8))
    # Anchors and ghosts never inherit the moving player's transform.
    preview_mesh.top_level = true
    anchor_mesh.top_level = true
    anchor_mesh.material_override = _valid_material
    preview_mesh.visible = false
    anchor_mesh.visible = false
    cue_player.volume_db = -16.0
    _deploy_cue = _make_cue(440.0)
    _shift_cue = _make_cue(760.0)
    _say("SHIFT  |  Aim at floor, Q deploy")
    _update_timer_label()


func _indicator_material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = Color(color.r, color.g, color.b)
    material.emission_energy_multiplier = 0.6
    return material


func _unhandled_input(event: InputEvent) -> void:
    if get_tree().paused or not owner_alive or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        return
    if event is InputEventKey and (event.echo or event.is_action_pressed("release_mouse")):
        return
    if event.is_action_pressed("deploy_anchor"):
        try_deploy()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("shift_teleport"):
        try_shift()
        get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
    _advance_lifecycle(delta)
    # Only the prospective marker follows the reticle. An armed anchor stays put.
    if not owner_alive or get_tree().paused or (
        Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
        or anchor_active or cooldown_remaining_seconds > 0.0
    ):
        preview_mesh.visible = false
        return
    var hit: Dictionary = _aim_surface()
    preview_mesh.visible = not hit.is_empty()
    if hit.is_empty():
        return
    var point: Vector3 = hit["position"]
    var normal: Vector3 = hit["normal"]
    preview_mesh.global_position = point + Vector3.UP * 0.035
    preview_mesh.material_override = (
        _valid_material if _validate_landing(point, normal).is_empty()
        else _invalid_material
    )


# Uses physics delta rather than wall-clock time, so pause freezes every timer.
# Kept callable for exact-boundary tests without sleeping for eight seconds.
func _advance_lifecycle(delta: float) -> void:
    if delta <= 0.0 or get_tree().paused or not owner_alive:
        return
    if anchor_active:
        anchor_remaining_seconds = maxf(0.0, anchor_remaining_seconds - delta)
        if anchor_remaining_seconds <= 0.0:
            _expire_anchor()
    if cooldown_remaining_seconds > 0.0:
        cooldown_remaining_seconds = maxf(0.0, cooldown_remaining_seconds - delta)
        if cooldown_remaining_seconds <= 0.0:
            _set_state(State.READY)
            cooldown_finished.emit()
            _say("SHIFT READY  |  Q to deploy")
    if echo_instance != null:
        echo_remaining_seconds = maxf(0.0, echo_remaining_seconds - delta)
        if echo_remaining_seconds <= 0.0:
            _remove_echo()
        else:
            var ratio: float = echo_remaining_seconds / echo_lifetime_seconds
            var tint: Color = _echo_material.albedo_color
            tint.a = 0.60 * ratio
            _echo_material.albedo_color = tint
            echo_instance.scale = Vector3.ONE * (
                1.0 + 0.035 * sin(echo_remaining_seconds * 18.0)
            )
    _update_timer_label()


func _set_state(new_state: State) -> void:
    if state != new_state:
        state = new_state
        state_changed.emit(state)


func _update_timer_label() -> void:
    if not owner_alive:
        timer_label.text = "DEVICE OFFLINE"
    elif anchor_active:
        timer_label.text = "ANCHOR  %.1f s" % anchor_remaining_seconds
    elif cooldown_remaining_seconds > 0.0:
        timer_label.text = "COOLDOWN  %.1f s" % cooldown_remaining_seconds
    else:
        timer_label.text = "SHIFT READY"
    timers_updated.emit(anchor_remaining_seconds, cooldown_remaining_seconds)


func _clear_anchor() -> void:
    anchor_active = false
    anchor_point = Vector3.ZERO
    anchor_remaining_seconds = 0.0
    anchor_mesh.visible = false


func _expire_anchor() -> void:
    var expired_point: Vector3 = anchor_point
    _clear_anchor()
    _set_state(State.READY)
    anchor_expired.emit(expired_point)
    _say("ANCHOR EXPIRED  |  Press Q to replace")


func _remove_echo() -> void:
    if echo_instance == null:
        return
    if is_instance_valid(echo_instance):
        # A top-level echo's local position is world-space, even after detaching.
        # global_position is unavailable during scene teardown (_exit_tree).
        echo_ended.emit(echo_instance.position)
        echo_instance.queue_free()
    echo_instance = null
    echo_remaining_seconds = 0.0
    _echo_material = null
    if owner_alive and is_inside_tree():
        _say("ECHO ENDED  |  SHIFT RECHARGING" if cooldown_remaining_seconds > 0.0 else "SHIFT READY  |  Q to deploy")


func _spawn_echo(world_pose: Transform3D) -> void:
    _remove_echo()
    var ghost: Node3D = ECHO_SCENE.instantiate() as Node3D
    add_child(ghost)
    ghost.top_level = true
    ghost.global_transform = world_pose
    _echo_material = _indicator_material(Color(0.30, 0.95, 0.94, 0.60))
    (ghost.get_node("Body") as MeshInstance3D).material_override = _echo_material
    (ghost.get_node("Visor") as MeshInstance3D).material_override = _echo_material
    (ghost.get_node("Beacon") as MeshInstance3D).material_override = _echo_material
    (ghost.get_node("BaseGlow") as MeshInstance3D).material_override = _echo_material
    echo_instance = ghost
    echo_remaining_seconds = echo_lifetime_seconds
    echo_spawned.emit(ghost, ghost.global_position)


# MS-06 health/restart can call this hook; no health system is added in MS-04.
func set_owner_alive(alive: bool) -> void:
    if alive:
        reset_lifecycle()
        return
    owner_alive = false
    _clear_anchor()
    _remove_echo()
    cooldown_remaining_seconds = 0.0
    preview_mesh.visible = false
    _set_state(State.DISABLED)
    _say("SHIFT OFFLINE")
    _update_timer_label()


func reset_lifecycle() -> void:
    _clear_anchor()
    _remove_echo()
    cooldown_remaining_seconds = 0.0
    owner_alive = true
    preview_mesh.visible = false
    _set_state(State.READY)
    _say("SHIFT READY  |  Aim at floor, Q deploy")
    _update_timer_label()


func _exit_tree() -> void:
    # Stop any in-flight cue before releasing the audio stream on scene unload.
    if is_instance_valid(cue_player):
        cue_player.stop()
        cue_player.stream = null
    _remove_echo()


func _ray(from: Vector3, to: Vector3, mask: int = 3) -> Dictionary:
    var query := PhysicsRayQueryParameters3D.create(
        from, to, mask, [player.get_rid()]
    )
    query.hit_from_inside = true
    return get_world_3d().direct_space_state.intersect_ray(query)


func _aim_surface() -> Dictionary:
    var origin: Vector3 = camera.global_position
    var reach: float = max_range_meters + origin.distance_to(player.global_position) + 1.0
    return _ray(origin, origin - camera.global_basis.z * reach)


func _arrival_origin(surface_point: Vector3) -> Vector3:
    var capsule: CapsuleShape3D = body_collider.shape as CapsuleShape3D
    return surface_point + Vector3.UP * (capsule.height * 0.5 + 0.08)


func _validate_landing(point: Vector3, normal: Vector3) -> String:
    if _clearance_shape == null:
        return "No player collision capsule"
    if player.global_position.distance_to(point) > max_range_meters:
        return "Out of range (18 m)"
    if absf(point.y - player.global_position.y) > max_height_difference:
        return "Landing too far above or below"
    var min_up: float = cos(deg_to_rad(max_slope_degrees))
    if normal.dot(Vector3.UP) < min_up:
        return "Surface is too steep"
    var eye: Vector3 = player.global_position + Vector3.UP * 0.52
    var sight_target: Vector3 = point + Vector3.UP * 0.16
    if not _ray(eye, sight_target).is_empty():
        return "Landing blocked from player"

    var shape_query := PhysicsShapeQueryParameters3D.new()
    shape_query.shape = _clearance_shape
    shape_query.transform = Transform3D(Basis.IDENTITY, _arrival_origin(point))
    shape_query.collision_mask = 0xFFFFFFFF
    shape_query.exclude = [player.get_rid()]
    if not get_world_3d().direct_space_state.intersect_shape(shape_query, 16).is_empty():
        return "Player capsule would overlap an obstacle"

    var inset: float = _clearance_shape.radius * 0.85
    var offsets: Array[Vector3] = [
        Vector3.ZERO, Vector3(inset, 0.0, 0.0),
        Vector3(-inset, 0.0, 0.0), Vector3(0.0, 0.0, inset),
        Vector3(0.0, 0.0, -inset)
    ]
    for offset: Vector3 in offsets:
        var support: Dictionary = _ray(
            point + offset + Vector3.UP * 0.34,
            point + offset - Vector3.UP * 0.26,
            1
        )
        if support.is_empty():
            return "No safe floor beneath landing"
        var floor_point: Vector3 = support["position"]
        var floor_normal: Vector3 = support["normal"]
        if absf(floor_point.y - point.y) > 0.14 or floor_normal.dot(Vector3.UP) < min_up:
            return "Floor edge, step or steep surface"
    return ""


func _try_place_at(point: Vector3, normal: Vector3) -> bool:
    if not owner_alive or get_tree().paused:
        placement_rejected.emit("Device unavailable")
        return false
    if cooldown_remaining_seconds > 0.0:
        placement_rejected.emit("SHIFT recharging")
        _say("SHIFT RECHARGING  |  %.1f s" % cooldown_remaining_seconds)
        return false
    if anchor_active:
        placement_rejected.emit("Anchor already armed")
        _say("SHIFT  |  Anchor armed; press Left Shift")
        return false
    var problem: String = _validate_landing(point, normal)
    if not problem.is_empty():
        placement_rejected.emit(problem)
        _say("SHIFT BLOCKED  |  " + problem)
        return false
    anchor_point = point
    anchor_active = true
    anchor_remaining_seconds = anchor_lifetime_seconds
    anchor_mesh.global_position = point + Vector3.UP * 0.045
    anchor_mesh.visible = true
    preview_mesh.visible = false
    _set_state(State.ANCHOR_ACTIVE)
    anchor_placed.emit(point)
    _play_cue(440.0)
    _say("ANCHOR SET  |  Left Shift to teleport")
    _update_timer_label()
    return true


func try_deploy() -> bool:
    if not owner_alive or get_tree().paused or cooldown_remaining_seconds > 0.0 or anchor_active:
        return _try_place_at(anchor_point, Vector3.UP)
    var hit: Dictionary = _aim_surface()
    if hit.is_empty():
        placement_rejected.emit("No surface under crosshair")
        _say("SHIFT BLOCKED  |  Aim at a floor")
        return false
    return _try_place_at(hit["position"], hit["normal"])


func try_shift() -> bool:
    if not owner_alive or get_tree().paused:
        shift_rejected.emit("Device unavailable")
        return false
    if cooldown_remaining_seconds > 0.0:
        shift_rejected.emit("SHIFT recharging")
        _say("SHIFT RECHARGING  |  %.1f s" % cooldown_remaining_seconds)
        return false
    if not anchor_active:
        shift_rejected.emit("No anchor")
        _say("SHIFT  |  Deploy with Q first")
        return false
    if anchor_remaining_seconds <= 0.0:
        _expire_anchor()
        shift_rejected.emit("Anchor expired")
        _update_timer_label()
        return false
    # MS-03 safety is mandatory even if the target was safe at placement.
    var problem: String = _validate_landing(anchor_point, Vector3.UP)
    if not problem.is_empty():
        shift_rejected.emit(problem)
        _say("SHIFT BLOCKED  |  " + problem)
        return false

    var previous: Vector3 = player.global_position
    var echo_pose: Transform3D = player.get_node("VisualRoot").global_transform
    var destination: Vector3 = _arrival_origin(anchor_point)
    player.global_position = destination
    player.velocity = Vector3.ZERO
    player.reset_physics_interpolation()
    _clear_anchor()
    cooldown_remaining_seconds = cooldown_seconds
    _set_state(State.COOLDOWN)
    shifted.emit(previous, destination)
    cooldown_started.emit(cooldown_seconds)
    _spawn_echo(echo_pose)
    _play_cue(760.0)
    _say("SHIFT COMPLETE  |  Echo active")
    _update_timer_label()
    return true


func _play_cue(frequency_hz: float) -> void:
    # Reuse the two short streams instead of reallocating while the player spams Q.
    cue_player.stop()
    cue_player.stream = _deploy_cue if frequency_hz < 600.0 else _shift_cue
    cue_player.play()


func _make_cue(frequency_hz: float) -> AudioStreamWAV:
    # Tiny generated pulse: no external audio dependency or Web asset download.
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = 22050
    var samples: int = 2646
    var bytes := PackedByteArray()
    bytes.resize(samples * 2)
    for index in range(samples):
        var fraction: float = float(index) / float(samples)
        var t: float = float(index) / float(wav.mix_rate)
        var envelope: float = (1.0 - fraction) * (1.0 - fraction)
        var sample: int = int(sin(t * TAU * frequency_hz) * envelope * 4700.0) & 0xFFFF
        bytes[index * 2] = sample & 0xFF
        bytes[index * 2 + 1] = (sample >> 8) & 0xFF
    wav.data = bytes
    return wav


func _say(message: String) -> void:
    status_label.text = message
