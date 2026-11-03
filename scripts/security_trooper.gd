extends StaticBody3D
## MS-05: one stationary Helix guard with deterministic combat and SHIFT distraction.

signal state_changed(next_state: int)
signal damaged(remaining_health: float)
signal destroyed()
signal shot_fired(hit_player: bool)
signal windup_started()
signal echo_distracted(world_position: Vector3)

enum State { IDLE, ALERT, ATTACK, DEAD }

@export_range(1.0, 500.0, 1.0) var max_health: float = 100.0
@export_range(1.0, 60.0, 0.5) var detection_range: float = 12.5
@export_range(30.0, 360.0, 1.0) var field_of_view_degrees: float = 145.0
@export_range(1.0, 50.0, 0.5) var attack_range: float = 22.0
@export_range(1.0, 50.0, 0.5) var echo_notice_range: float = 20.0
@export_range(0.05, 3.0, 0.05) var alert_seconds: float = 0.35
@export_range(0.05, 3.0, 0.05) var windup_seconds: float = 0.55
@export_range(0.2, 5.0, 0.05) var fire_interval_seconds: float = 1.35
@export_range(0.0, 50.0, 1.0) var shot_damage: float = 12.0
@export_range(1.0, 30.0, 0.5) var turn_speed: float = 9.0

const SIGHT_MASK: int = 3 # World (1) and player (2).
const WORLD_MASK: int = 1

@onready var visual_root: Node3D = $VisualRoot
@onready var eye: Marker3D = $VisualRoot/Eye
@onready var muzzle: Marker3D = $VisualRoot/Muzzle
@onready var visor: MeshInstance3D = $VisualRoot/Visor
@onready var alert_lamp: MeshInstance3D = $VisualRoot/AlertLamp
@onready var warning_flash: MeshInstance3D = $VisualRoot/WarningFlash
@onready var muzzle_flash: MeshInstance3D = $VisualRoot/MuzzleFlash
@onready var distraction_beacon: MeshInstance3D = $VisualRoot/DistractionBeacon
@onready var lock_cue: AudioStreamPlayer3D = $LockCue
@onready var shot_cue: AudioStreamPlayer3D = $ShotCue

var state: State = State.IDLE
var health: float = 100.0
var player: CharacterBody3D = null
var _shift_ability: Node = null
var _echo: Node3D = null
var _echo_position: Vector3 = Vector3.ZERO
var _alert_remaining: float = 0.0
var _windup_remaining: float = 0.0
var _cooldown_remaining: float = 0.0
var _flash_remaining: float = 0.0
var _hit_remaining: float = 0.0
var _lost_sight_remaining: float = 0.0
var _normal_visor_material: Material
var _hit_material: StandardMaterial3D


func _ready() -> void:
    health = max_health
    _normal_visor_material = visor.get_active_material(0)
    _hit_material = _glow_material(Color(1.0, 0.97, 0.83))
    alert_lamp.material_override = _glow_material(Color(1.0, 0.65, 0.22))
    warning_flash.material_override = _glow_material(Color(1.0, 0.31, 0.09))
    muzzle_flash.material_override = _glow_material(Color(1.0, 0.95, 0.56))
    distraction_beacon.material_override = _glow_material(Color(0.21, 0.98, 0.95))
    lock_cue.stream = _make_cue(570.0, 0.14)
    shot_cue.stream = _make_cue(125.0, 0.18)
    lock_cue.volume_db = -8.0
    shot_cue.volume_db = -6.0
    alert_lamp.visible = false
    warning_flash.visible = false
    muzzle_flash.visible = false
    distraction_beacon.visible = false
    var candidate: Node = get_tree().get_first_node_in_group("player")
    if candidate is CharacterBody3D:
        bind_player(candidate as CharacterBody3D)


func _glow_material(tint: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    result.albedo_color = tint
    result.emission_enabled = true
    result.emission = tint
    result.emission_energy_multiplier = 1.2
    return result


# Generate two short warning and firing cues once per guard.
func _make_cue(frequency_hz: float, duration: float) -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = 22050
    var samples: int = int(float(stream.mix_rate) * duration)
    var bytes := PackedByteArray()
    bytes.resize(samples * 2)
    for index in range(samples):
        var fraction: float = float(index) / float(samples)
        var time: float = float(index) / float(stream.mix_rate)
        var envelope: float = (1.0 - fraction) * (1.0 - fraction)
        var value: int = int(sin(TAU * frequency_hz * time) * envelope * 6200.0) & 0xFFFF
        bytes[index * 2] = value & 0xFF
        bytes[index * 2 + 1] = (value >> 8) & 0xFF
    stream.data = bytes
    return stream


# The scene can be reused in other arenas; binding is idempotent.
func bind_player(target: CharacterBody3D) -> void:
    _disconnect_shift()
    player = target
    if player == null or not is_instance_valid(player):
        return
    _shift_ability = player.get_node_or_null("ShiftAbility")
    if _shift_ability != null:
        if not _shift_ability.is_connected("echo_spawned", _on_echo_spawned):
            _shift_ability.connect("echo_spawned", _on_echo_spawned)
        if not _shift_ability.is_connected("echo_ended", _on_echo_ended):
            _shift_ability.connect("echo_ended", _on_echo_ended)


func _disconnect_shift() -> void:
    if is_instance_valid(_shift_ability):
        if _shift_ability.is_connected("echo_spawned", _on_echo_spawned):
            _shift_ability.disconnect("echo_spawned", _on_echo_spawned)
        if _shift_ability.is_connected("echo_ended", _on_echo_ended):
            _shift_ability.disconnect("echo_ended", _on_echo_ended)
    _shift_ability = null
    _echo = null


func _exit_tree() -> void:
    _disconnect_shift()


func _physics_process(delta: float) -> void:
    advance_ai(delta)


# Physics-time progression is callable by headless tests without wall-clock sleeps.
func advance_ai(delta: float) -> void:
    if delta <= 0.0 or state == State.DEAD or get_tree().paused:
        return
    _cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
    _flash_remaining = maxf(0.0, _flash_remaining - delta)
    muzzle_flash.visible = _flash_remaining > 0.0
    if _windup_remaining > 0.0:
        var pulse: float = 3.1 + 0.75 * sin(_windup_remaining * 25.0)
        warning_flash.scale = Vector3.ONE * pulse
    _hit_remaining = maxf(0.0, _hit_remaining - delta)
    if _hit_remaining <= 0.0:
        visor.material_override = null

    if _echo != null:
        if not is_instance_valid(_echo) or _echo.is_queued_for_deletion():
            _clear_echo()
        else:
            _set_state(State.ALERT)
            _turn_toward(_echo_position, delta)
            distraction_beacon.visible = true
            alert_lamp.visible = false
            return

    if not _player_is_alive():
        _set_state(State.IDLE)
        return

    var spotted: bool = _can_see_player()
    if state == State.IDLE:
        if spotted and _within_fov(_player_aim_point()):
            _enter_alert()
    elif state == State.ALERT:
        _turn_toward(_player_aim_point(), delta)
        if spotted:
            _lost_sight_remaining = 0.6
            _alert_remaining = maxf(0.0, _alert_remaining - delta)
            if _alert_remaining <= 0.0:
                _set_state(State.ATTACK)
        else:
            _lost_sight_remaining -= delta
            if _lost_sight_remaining <= 0.0:
                _set_state(State.IDLE)
    elif state == State.ATTACK:
        _turn_toward(_player_aim_point(), delta)
        if not spotted or eye.global_position.distance_to(_player_aim_point()) > attack_range:
            _enter_alert()
            return
        if _windup_remaining > 0.0:
            _windup_remaining = maxf(0.0, _windup_remaining - delta)
            if _windup_remaining <= 0.0:
                warning_flash.visible = false
                _fire()
        elif _cooldown_remaining <= 0.0:
            _windup_remaining = windup_seconds
            warning_flash.visible = true
            windup_started.emit()
            lock_cue.play()


func _player_is_alive() -> bool:
    return (is_instance_valid(player) and not player.is_queued_for_deletion()
        and player.is_inside_tree() and bool(player.get("is_alive")))


func _player_aim_point() -> Vector3:
    return player.global_position + Vector3.UP * 0.3


func _trace(from: Vector3, to: Vector3, mask: int) -> Dictionary:
    var query := PhysicsRayQueryParameters3D.create(
        from, to, mask, [get_rid()]
    )
    query.hit_from_inside = true
    return get_world_3d().direct_space_state.intersect_ray(query)


func _can_see_player() -> bool:
    if not _player_is_alive():
        return false
    var point: Vector3 = _player_aim_point()
    if eye.global_position.distance_to(point) > detection_range:
        return false
    return _trace(eye.global_position, point, SIGHT_MASK).get("collider") == player


func _within_fov(point: Vector3) -> bool:
    var direction: Vector3 = point - eye.global_position
    direction.y = 0.0
    if direction.length_squared() < 0.001:
        return true
    var forward: Vector3 = -visual_root.global_basis.z
    forward.y = 0.0
    return forward.normalized().dot(direction.normalized()) >= cos(
        deg_to_rad(field_of_view_degrees) * 0.5
    )


func _turn_toward(point: Vector3, delta: float) -> void:
    var direction: Vector3 = point - global_position
    direction.y = 0.0
    if direction.length_squared() < 0.001:
        return
    var target_yaw: float = atan2(-direction.x, -direction.z)
    visual_root.rotation.y = lerp_angle(
        visual_root.rotation.y, target_yaw, minf(1.0, turn_speed * delta)
    )


func _set_state(next: State) -> void:
    if state == next:
        return
    state = next
    alert_lamp.visible = (state == State.ALERT or state == State.ATTACK) and _echo == null
    if state != State.ATTACK:
        _cancel_windup()
    state_changed.emit(int(state))


func _enter_alert() -> void:
    _alert_remaining = alert_seconds
    _lost_sight_remaining = 0.6
    _set_state(State.ALERT)


func _cancel_windup() -> void:
    _windup_remaining = 0.0
    warning_flash.visible = false


func _fire() -> void:
    if state != State.ATTACK or not _player_is_alive():
        return
    var point: Vector3 = _player_aim_point()
    if muzzle.global_position.distance_to(point) > attack_range:
        _enter_alert()
        return
    # The same weapon ray must be unobstructed at discharge time.
    var hit: Dictionary = _trace(muzzle.global_position, point, SIGHT_MASK)
    if hit.get("collider") != player:
        _enter_alert()
        return
    _cooldown_remaining = fire_interval_seconds
    _flash_remaining = 0.12
    muzzle_flash.visible = true
    shot_cue.play()
    player.call("apply_damage", shot_damage)
    shot_fired.emit(true)
    if not _player_is_alive():
        _set_state(State.IDLE)


func _on_echo_spawned(ghost: Node3D, at: Vector3) -> void:
    if state == State.DEAD or not is_instance_valid(ghost):
        return
    if eye.global_position.distance_to(at + Vector3.UP * 0.3) > echo_notice_range:
        return
    # Holograms have no collider. Test only world occlusion.
    if not _trace(eye.global_position, at + Vector3.UP * 0.3, WORLD_MASK).is_empty():
        return
    _echo = ghost
    _echo_position = at
    _enter_alert()
    distraction_beacon.visible = true
    alert_lamp.visible = false
    echo_distracted.emit(at)


func _on_echo_ended(_at: Vector3) -> void:
    _clear_echo()


func _clear_echo() -> void:
    _echo = null
    distraction_beacon.visible = false
    if state != State.DEAD:
        _enter_alert()


func apply_damage(amount: float) -> void:
    if state == State.DEAD or amount <= 0.0:
        return
    health = maxf(0.0, health - amount)
    damaged.emit(health)
    if health <= 0.0:
        _echo = null
        _set_state(State.DEAD)
        collision_layer = 0
        collision_mask = 0
        _flash_remaining = 0.0
        muzzle_flash.visible = false
        alert_lamp.visible = false
        distraction_beacon.visible = false
        lock_cue.stop()
        # Sink the toppled mesh so it rests on the floor instead of hovering.
        var collapse: Tween = create_tween().set_parallel(true)
        collapse.tween_property(visual_root, "rotation:z", deg_to_rad(88.0), 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        collapse.tween_property(visual_root, "position:y", -0.61, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        set_physics_process(false)
        _disconnect_shift()
        destroyed.emit()
    else:
        visor.material_override = _hit_material
        _hit_remaining = 0.14
        if _player_is_alive() and _echo == null:
            _enter_alert()
