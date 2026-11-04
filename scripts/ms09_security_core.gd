extends Node3D
## MS-09: standalone Security Core, safe two-stage fight and terminal shutdown.

signal phase_changed(next_phase: int)
signal upper_security_activated()
signal terminal_unlocked()
signal terminal_disabled()

enum Phase { ACTIVE, VICTORY, DEFEAT, RESTARTING }

const CYAN: Color = Color(0.35, 0.97, 0.90)
const AMBER: Color = Color(1.0, 0.68, 0.32)
const UPPER_DELAY: float = 2.0
const TERMINAL_REACH: float = 3.0
const MIN_SPAWN_DISTANCE: float = 4.0
const UPPER_FLOOR_Y: float = 2.9
const UPPER_GUARD_Y: float = 3.93

@onready var player: CharacterBody3D = $Player
@onready var ability: Node = $Player/ShiftAbility
@onready var combat_hud: Node = $Player/CombatHUD
@onready var terminal: StaticBody3D = $Terminal
@onready var terminal_marker: Marker3D = $Terminal/InteractionPoint
@onready var terminal_mesh: MeshInstance3D = $Terminal/Mesh
@onready var terminal_beacon: MeshInstance3D = $Terminal/Beacon
@onready var terminal_status: Label3D = $Terminal/Status
@onready var terminal_light: OmniLight3D = $Terminal/Light
@onready var objective_label: Label = $CoreHUD/Objective
@onready var hint_label: Label = $CoreHUD/Hint
@onready var clock_label: Label = $CoreHUD/Clock
@onready var feedback_label: Label = $CoreHUD/Feedback
@onready var outcome: CanvasLayer = $Outcome
@onready var outcome_title: Label = $Outcome/Card/Title
@onready var outcome_details: Label = $Outcome/Card/Details
@onready var replay_button: Button = $Outcome/Card/ReplayButton

var phase: Phase = Phase.ACTIVE
var elapsed_seconds: float = 0.0
var shift_count: int = 0
var upper_pending: bool = false
var upper_active: bool = false
var upper_countdown: float = 0.0
var is_terminal_unlocked: bool = false
var is_terminal_disabled: bool = false

var _guards: Array[Node] = []
var _lower: Array[Node] = []
var _upper: Array[Node] = []
var _defeated: Array[Node] = []
var _feedback_remaining: float = 0.0


func _ready() -> void:
    _build_arena()
    player.managed_restart = true
    combat_hud.call("set_mission_managed", true)
    for path: NodePath in [NodePath("GuardLowerWest"), NodePath("GuardLowerEast")]:
        var guard: Node = get_node(path)
        _lower.append(guard)
        _register_guard(guard)
    for path: NodePath in [NodePath("GuardUpperEast"), NodePath("GuardUpperWest")]:
        var guard: Node = get_node(path)
        _upper.append(guard)
        _register_guard(guard)
        guard.call("set_combat_enabled", false)
    player.died.connect(_on_player_died)
    ability.connect("shifted", _on_shifted)
    ability.connect("placement_rejected", _on_shift_rejected)
    ability.connect("shift_rejected", _on_shift_rejected)
    replay_button.pressed.connect(request_replay)
    outcome.visible = false
    _configure_shift_hud()
    _set_terminal_visual(AMBER, "CORE CONTROL\nLOCKED")
    _update_objective()
    _update_clock()
    _refresh_threat()


func _register_guard(guard: Node) -> void:
    _guards.append(guard)
    guard.connect("destroyed", _on_guard_destroyed.bind(guard))
    guard.connect("state_changed", _on_guard_state_changed)
    guard.connect("windup_started", _on_guard_windup)
    guard.connect("echo_distracted", _on_guard_echo)
    guard.connect("echo_released", _refresh_threat)


func _process(delta: float) -> void:
    if phase != Phase.ACTIVE:
        return
    elapsed_seconds += delta
    _update_clock()
    if _feedback_remaining > 0.0:
        _feedback_remaining = maxf(0.0, _feedback_remaining - delta)
        if _feedback_remaining <= 0.0:
            feedback_label.text = ""


func _physics_process(delta: float) -> void:
    if phase != Phase.ACTIVE or not upper_pending or delta <= 0.0 or get_tree().paused:
        return
    upper_countdown = maxf(0.0, upper_countdown - delta)
    if upper_countdown > 0.0:
        return
    if _activate_upper():
        upper_pending = false
        upper_active = true
        upper_security_activated.emit()
        hint_label.text = "REACH UPPER SECURITY  /  USE BOTH RAMPS OR SHIFT TO FLANK"
        _show_feedback("UPPER SECURITY ONLINE  /  WATCH THE CATWALK")
    else:
        hint_label.text = "UPPER SECURITY ENTRY BLOCKED  /  MOVE AWAY FROM LANDING"
    _update_objective()
    _refresh_threat()


func _on_shifted(_from: Vector3, _to: Vector3) -> void:
    if phase == Phase.ACTIVE:
        shift_count += 1
        _update_clock()


func _on_shift_rejected(reason: String) -> void:
    if phase == Phase.ACTIVE:
        _show_feedback("SHIFT BLOCKED  /  " + reason)


func _on_guard_destroyed(guard: Node) -> void:
    if phase != Phase.ACTIVE or not _guards.has(guard) or _defeated.has(guard):
        return
    _defeated.append(guard)
    if _defeated.size() == _guards.size():
        _unlock_terminal()
    elif not upper_active and not upper_pending and _lower_cleared():
        upper_pending = true
        upper_countdown = UPPER_DELAY
        hint_label.text = "LOWER SECURITY CLEARED  /  PREPARE FOR UPPER RESPONSE"
        _show_feedback("HELIX / UPPER SECURITY ACTIVATING")
    else:
        _show_feedback("HELIX TROOPER DOWN  /  %d REMAIN" % (_guards.size() - _defeated.size()))
    _update_objective()
    _refresh_threat()


func _lower_cleared() -> bool:
    for guard: Node in _lower:
        if not _defeated.has(guard):
            return false
    return true


# All candidates are on the same tested upper floor. Choosing both atomically
# prevents an incomplete or occupied wave from appearing in the player.
func _activate_upper() -> bool:
    var east_options: Array[Vector3] = [
        Vector3(8.5, UPPER_GUARD_Y, -12.0),
        Vector3(11.5, UPPER_GUARD_Y, -8.0),
        Vector3(10.0, UPPER_GUARD_Y, -6.0)
    ]
    var west_options: Array[Vector3] = [
        Vector3(-8.5, UPPER_GUARD_Y, -12.0),
        Vector3(-11.5, UPPER_GUARD_Y, -8.0),
        Vector3(-11.2, UPPER_GUARD_Y, -14.7)
    ]
    var chosen: Array[Vector3] = []
    for index: int in range(_upper.size()):
        var options: Array[Vector3] = east_options if index == 0 else west_options
        var found: bool = false
        for point: Vector3 in options:
            if _safe_upper_spawn(_upper[index] as StaticBody3D, point, chosen):
                chosen.append(point)
                found = true
                break
        if not found:
            return false
    for index: int in range(_upper.size()):
        var guard: StaticBody3D = _upper[index] as StaticBody3D
        guard.global_position = chosen[index]
        guard.reset_physics_interpolation()
        guard.call("set_combat_enabled", true)
    return true


func _safe_upper_spawn(guard: StaticBody3D, point: Vector3, chosen: Array[Vector3]) -> bool:
    # Horizontal separation matters when the player is standing directly
    # underneath the catwalk, not just the 3-D distance between capsules.
    var player_flat: Vector2 = Vector2(player.global_position.x, player.global_position.z)
    var site_flat: Vector2 = Vector2(point.x, point.z)
    if player_flat.distance_to(site_flat) < MIN_SPAWN_DISTANCE:
        return false
    var echo: Node3D = ability.get("echo_instance") as Node3D
    if is_instance_valid(echo):
        var echo_flat: Vector2 = Vector2(echo.global_position.x, echo.global_position.z)
        if echo_flat.distance_to(site_flat) < 2.5:
            return false
    if bool(ability.get("anchor_active")):
        var anchor: Vector3 = ability.get("anchor_point") as Vector3
        if Vector2(anchor.x, anchor.z).distance_to(site_flat) < 2.5:
            return false
    for other: Vector3 in chosen:
        if other.distance_to(point) < 2.0:
            return false
    var shape_node: CollisionShape3D = guard.get_node("CollisionShape3D") as CollisionShape3D
    var overlap := PhysicsShapeQueryParameters3D.new()
    overlap.shape = shape_node.shape
    overlap.transform = Transform3D(Basis.IDENTITY, point)
    overlap.collision_mask = 3
    overlap.exclude = [guard.get_rid()]
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    if not space.intersect_shape(overlap, 12).is_empty():
        return false
    var support_query := PhysicsRayQueryParameters3D.create(
        point + Vector3.UP * 0.15, point - Vector3.UP * 1.5, 1, [guard.get_rid()]
    )
    var floor_hit: Dictionary = space.intersect_ray(support_query)
    if floor_hit.is_empty():
        return false
    if (floor_hit["normal"] as Vector3).dot(Vector3.UP) < 0.87:
        return false
    return absf((floor_hit["position"] as Vector3).y - UPPER_FLOOR_Y) <= 0.15


func _unlock_terminal() -> void:
    if is_terminal_unlocked or phase != Phase.ACTIVE or not bool(player.get("is_alive")):
        return
    is_terminal_unlocked = true
    _set_terminal_visual(CYAN, "CORE CONTROL\nPRESS E TO DISABLE")
    hint_label.text = "REACH THE WEST TERMINAL  /  E DISABLE SECURITY CORE"
    _show_feedback("HELIX SECURITY CLEARED  /  TERMINAL UNLOCKED")
    terminal_unlocked.emit()


func _set_terminal_visual(color: Color, message: String) -> void:
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 1.1
    terminal_beacon.material_override = material
    terminal_light.light_color = color
    terminal_status.modulate = color
    terminal_status.text = message


func try_shutdown() -> bool:
    if phase != Phase.ACTIVE or not bool(player.get("is_alive")):
        return false
    if not is_terminal_unlocked:
        _show_feedback("TERMINAL LOCKED  /  CLEAR ALL FOUR TROOPERS")
        return false
    var console_point: Vector3 = terminal_marker.global_position
    if absf(player.global_position.y - console_point.y) > 1.3:
        _show_feedback("REACH THE UPPER TERMINAL DECK")
        return false
    if player.global_position.distance_to(console_point) > TERMINAL_REACH:
        _show_feedback("MOVE CLOSER TO THE CONTROL TERMINAL")
        return false
    var from: Vector3 = player.global_position + Vector3.UP * 0.35
    var query := PhysicsRayQueryParameters3D.create(
        from, console_point, 1, [player.get_rid()]
    )
    query.hit_from_inside = true
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty() and hit.get("collider") != terminal:
        _show_feedback("CONTROL TERMINAL BLOCKED  /  FIND A CLEAR ANGLE")
        return false
    is_terminal_disabled = true
    _set_terminal_visual(Color(0.18, 0.42, 0.47), "CORE CONTROL\nOFFLINE")
    terminal_disabled.emit()
    _finish(Phase.VICTORY)
    return true


func _on_player_died() -> void:
    if phase == Phase.ACTIVE:
        _finish(Phase.DEFEAT)


func _finish(result: Phase) -> void:
    if phase != Phase.ACTIVE:
        return
    phase = result
    upper_pending = false
    upper_countdown = 0.0
    phase_changed.emit(int(phase))
    player.set_combat_enabled(false)
    for guard: Node in _guards:
        if is_instance_valid(guard) and int(guard.get("state")) != 3:
            guard.call("set_combat_enabled", false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    outcome.visible = true
    feedback_label.text = ""
    if result == Phase.VICTORY:
        outcome_title.text = "SECURITY CORE OFFLINE"
        outcome_title.add_theme_color_override("font_color", CYAN)
        objective_label.text = "SECTION COMPLETE  /  SECURITY SYSTEM DISABLED"
        combat_hud.call("set_encounter_threat", "HELIX / SECURITY DISABLED", CYAN)
    else:
        outcome_title.text = "OPERATIVE DOWN"
        outcome_title.add_theme_color_override("font_color", Color(1.0, 0.43, 0.30))
        objective_label.text = "MISSION FAILED  /  RESTART SECURITY CORE"
        combat_hud.call("set_encounter_threat", "HELIX / RETRY AVAILABLE", AMBER)
    hint_label.text = ""
    outcome_details.text = (
        "TROOPERS  %d / 4    |    TIME  %02d:%02d    |    SHIFTS  %d\n"
        + ("SECURITY CORE DISABLED. EXTRACTION FOLLOWS IN MS-10." if result == Phase.VICTORY
           else "RETURN TO THE SECURITY CORE ENTRANCE.")
        + "\n\nPRESS ENTER OR CLICK TO REPLAY"
    ) % [_defeated.size(), int(elapsed_seconds / 60.0), int(elapsed_seconds) % 60, shift_count]


func request_replay() -> void:
    if phase != Phase.VICTORY and phase != Phase.DEFEAT:
        return
    phase = Phase.RESTARTING
    phase_changed.emit(int(phase))
    replay_button.disabled = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_tree().call_deferred("reload_current_scene")


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if phase == Phase.ACTIVE and event.is_action_pressed("interact"):
        try_shutdown()
        get_viewport().set_input_as_handled()
    elif (phase == Phase.VICTORY or phase == Phase.DEFEAT) and (
        event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER
    ):
        request_replay()
        get_viewport().set_input_as_handled()


func _update_clock() -> void:
    clock_label.text = "SECURITY CORE  %02d:%02d   |   SHIFTS  %d" % [
        int(elapsed_seconds / 60.0), int(elapsed_seconds) % 60, shift_count
    ]


func _update_objective() -> void:
    if is_terminal_unlocked:
        objective_label.text = "OBJECTIVE  /  REACH UPPER TERMINAL AND PRESS E"
        objective_label.add_theme_color_override("font_color", CYAN)
    elif upper_active or upper_pending:
        objective_label.text = "OBJECTIVE  /  CLEAR UPPER SECURITY   %d / 4" % _defeated.size()
        objective_label.add_theme_color_override("font_color", AMBER)
    else:
        objective_label.text = "OBJECTIVE  /  CLEAR LOWER SECURITY   %d / 2" % _defeated.size()
        objective_label.add_theme_color_override("font_color", AMBER)
        hint_label.text = "USE CRATES AS COVER  /  RAMPS LEAD TO UPPER CATWALKS"


func _show_feedback(message: String) -> void:
    feedback_label.text = message
    _feedback_remaining = 2.6


func _on_guard_state_changed(_next: int) -> void:
    _refresh_threat()


func _on_guard_windup() -> void:
    if phase == Phase.ACTIVE:
        combat_hud.call("set_encounter_threat", "HELIX / SHOT INCOMING!", Color(1.0, 0.46, 0.25))


func _on_guard_echo(_at: Vector3) -> void:
    if phase == Phase.ACTIVE:
        combat_hud.call("set_encounter_threat", "HELIX / ECHO DISTRACTION", CYAN)


func _refresh_threat() -> void:
    if phase != Phase.ACTIVE:
        return
    if upper_pending:
        combat_hud.call("set_encounter_threat", "HELIX / UPPER RESPONSE", AMBER)
        return
    var attacking: bool = false
    var alerted: bool = false
    var distracted: bool = false
    for guard: Node in _guards:
        if _defeated.has(guard) or not bool(guard.get("combat_enabled")):
            continue
        if guard.get("_echo") != null:
            distracted = true
        match int(guard.get("state")):
            2: attacking = true
            1: alerted = true
    if distracted:
        combat_hud.call("set_encounter_threat", "HELIX / ECHO DISTRACTION", CYAN)
    elif attacking:
        combat_hud.call("set_encounter_threat", "HELIX / UNDER FIRE!", AMBER)
    elif alerted:
        combat_hud.call("set_encounter_threat", "HELIX / CONTACT", AMBER)
    elif is_terminal_unlocked:
        combat_hud.call("set_encounter_threat", "HELIX / TERMINAL READY", CYAN)
    else:
        combat_hud.call("set_encounter_threat", "HELIX / TROOPERS ACTIVE", AMBER)


func _configure_shift_hud() -> void:
    var hud: CanvasLayer = ability.get_node("ShiftHUD") as CanvasLayer
    var status: Label = hud.get_node("Status") as Label
    var timer: Label = hud.get_node("Timer") as Label
    var backdrop := ColorRect.new()
    backdrop.name = "CoreShiftBackdrop"
    backdrop.color = Color(0.02, 0.06, 0.10, 0.78)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(backdrop)
    hud.move_child(backdrop, 0)
    backdrop.anchor_top = 1.0
    backdrop.anchor_bottom = 1.0
    backdrop.offset_left = 10.0
    backdrop.offset_right = 675.0
    backdrop.offset_top = -145.0
    backdrop.offset_bottom = -18.0
    for label: Label in [status, timer]:
        label.anchor_top = 1.0
        label.anchor_bottom = 1.0
        label.offset_left = 18.0
        label.offset_right = 660.0
        label.add_theme_font_size_override("font_size", 22)
    status.offset_top = -132.0
    status.offset_bottom = -87.0
    timer.offset_top = -81.0
    timer.offset_bottom = -35.0


# Geometry is generated once from deterministic box definitions. Every solid
# piece owns a StaticBody3D with matching collision. Thin route decals have
# no collider and do not interfere with SHIFT floor raycasts.
func _build_arena() -> void:
    var geometry := Node3D.new()
    geometry.name = "WorldGeometry"
    add_child(geometry)
    var floor_mat: StandardMaterial3D = _material(Color(0.14, 0.20, 0.25))
    var steel_mat: StandardMaterial3D = _material(Color(0.26, 0.34, 0.41))
    var cover_mat: StandardMaterial3D = _material(Color(0.38, 0.43, 0.47))
    var walk_mat: StandardMaterial3D = _material(Color(0.22, 0.41, 0.46))
    var rail_mat: StandardMaterial3D = _material(Color(0.48, 0.57, 0.61))
    _box(geometry, "Floor", Vector3(0, -0.30, 0), Vector3(34, 0.6, 42), floor_mat)
    _box(geometry, "NorthWall", Vector3(0, 3, -21), Vector3(34, 6, 0.7), steel_mat)
    _box(geometry, "SouthWall", Vector3(0, 3, 21), Vector3(34, 6, 0.7), steel_mat)
    _box(geometry, "WestWall", Vector3(-17, 3, 0), Vector3(0.7, 6, 42), steel_mat)
    _box(geometry, "EastWall", Vector3(17, 3, 0), Vector3(0.7, 6, 42), steel_mat)

    # The ramp rises continuously from the floor and overlaps its landing.
    # Positive X rotation puts its north end above its south end.
    for side: String in ["East", "West"]:
        var x: float = 10.4 if side == "East" else -10.4
        _box(geometry, side + "Ramp", Vector3(x, 1.30, 3.4),
            Vector3(4.6, 0.32, 14.0), walk_mat, 0.211)
        _box(geometry, side + "Landing", Vector3(x, 2.70, -6.8),
            Vector3(7.5, 0.4, 7.3), walk_mat)
    _box(geometry, "NorthWalk", Vector3(0, 2.70, -12.0),
        Vector3(27.0, 0.4, 5.0), walk_mat)
    _box(geometry, "WestTerminalDeck", Vector3(-10.4, 2.70, -15.0),
        Vector3(7.5, 0.4, 6.5), walk_mat)
    _box(geometry, "EastOverlook", Vector3(10.4, 2.70, -15.0),
        Vector3(7.5, 0.4, 6.5), walk_mat)

    # The front rail is interrupted for visible, usable SHIFT angles.
    for pair: Array in [[-11.3, 4.5], [-3.7, 3.0], [4.0, 4.0], [11.3, 4.5]]:
        _box(geometry, "FrontRail" + str(pair[0]), Vector3(float(pair[0]), 3.23, -9.4),
            Vector3(float(pair[1]), 0.65, 0.18), rail_mat)
    _box(geometry, "BackRail", Vector3(0, 3.42, -14.55),
        Vector3(27, 1.0, 0.18), rail_mat)
    _box(geometry, "WestDeckRail", Vector3(-14.15, 3.42, -15.1),
        Vector3(0.18, 1.0, 6.5), rail_mat)
    _box(geometry, "EastDeckRail", Vector3(14.15, 3.42, -15.1),
        Vector3(0.18, 1.0, 6.5), rail_mat)
    # Mark both outer ramp edges without closing off the top connection.
    for side_x: float in [-12.83, -7.97, 7.97, 12.83]:
        _box(geometry, "RampGuard" + str(side_x), Vector3(side_x, 1.75, 3.4),
            Vector3(0.16, 0.66, 13.0), rail_mat, 0.211)

    for name: String in ["CentralCrate", "WestCover", "EastCover", "NorthCover"]:
        var pos: Vector3 = Vector3.ZERO
        match name:
            "CentralCrate": pos = Vector3(-1.9, 0.9, 7.2)
            "WestCover": pos = Vector3(-5.8, 0.9, 1.0)
            "EastCover": pos = Vector3(4.0, 0.9, 1.4)
            "NorthCover": pos = Vector3(0.8, 0.9, -5.3)
        _box(geometry, name, pos, Vector3(2.7, 1.8, 2.6), cover_mat)
    _box(geometry, "UpperCoverEast", Vector3(6.0, 3.65, -12.0),
        Vector3(1.7, 1.5, 1.4), cover_mat)
    _box(geometry, "UpperCoverWest", Vector3(-5.8, 3.65, -12.0),
        Vector3(1.7, 1.5, 1.4), cover_mat)
    # Decorative frame stays clear of the active shooting and camera lanes.
    _box(geometry, "CoreHousing", Vector3(0, 0.95, -17.8),
        Vector3(4.0, 1.9, 1.8), steel_mat)
    for guide: Array in [
        ["LowerFlank", Vector3(-3.2, 0.03, 10.8), Vector3(2.8, 0.03, 1.8)],
        ["EastLandingPad", Vector3(10.4, 2.92, -6.5), Vector3(2.4, 0.03, 2.0)],
        ["WestLandingPad", Vector3(-10.4, 2.92, -6.5), Vector3(2.4, 0.03, 2.0)],
        ["UpperFlank", Vector3(0.0, 2.92, -12), Vector3(2.0, 0.03, 1.6)],
        ["TerminalGuide", Vector3(-10.4, 2.92, -16.4), Vector3(2.0, 0.03, 1.1)]
    ]:
        _guide(geometry, guide[0] as String, guide[1] as Vector3, guide[2] as Vector3)


func _material(tint: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.85
    return material


func _box(parent: Node3D, name: String, position: Vector3, size: Vector3,
        material: StandardMaterial3D, angle: float = 0.0) -> void:
    var body := StaticBody3D.new()
    body.name = name
    body.collision_layer = 1
    body.collision_mask = 1
    body.position = position
    body.rotation.x = angle
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    var mesh := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = size
    box_mesh.material = material
    mesh.mesh = box_mesh
    body.add_child(mesh)
    parent.add_child(body)


func _guide(parent: Node3D, name: String, position: Vector3, size: Vector3) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = name
    mesh.position = position
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var box := BoxMesh.new()
    box.size = size
    var glow := StandardMaterial3D.new()
    glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    glow.albedo_color = Color(0.16, 0.75, 0.78, 0.65)
    glow.emission_enabled = true
    glow.emission = Color(0.10, 0.54, 0.62)
    glow.emission_energy_multiplier = 0.6
    box.material = glow
    mesh.mesh = box
    parent.add_child(mesh)
