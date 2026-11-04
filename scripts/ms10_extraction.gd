extends Node3D
## MS-10: standalone Double-Deck Lockdown extraction encounter.

signal phase_changed(next_phase: int)
signal core_picked_up()
signal wave_activated(deck: String)
signal wave_waived(deck: String)
signal extraction_completed()

enum Phase { RETRIEVE, UPPER_WARNING, UPPER_FIGHT, LOWER_WARNING, LOWER_FIGHT, EXTRACT_READY, VICTORY, DEFEAT, RESTARTING }

const CYAN: Color = Color(0.35, 0.98, 0.90)
const AMBER: Color = Color(1.0, 0.67, 0.29)
const WARNING_SECONDS: float = 1.7
const RETRY_INTERVAL: float = 0.25
const WAIVER_SECONDS: float = 8.0
const INTERACTION_REACH: float = 3.0
const INTERACTION_HEIGHT: float = 1.3
const LOWER_FLOOR_Y: float = 0.0
const UPPER_FLOOR_Y: float = 2.9
const LOWER_GUARD_Y: float = 1.03
const UPPER_GUARD_Y: float = 3.93
const MIN_PLAYER_SEPARATION: float = 5.0
const MIN_DEVICE_SEPARATION: float = 2.5
const MIN_GUARD_SEPARATION: float = 2.0

@onready var player: CharacterBody3D = $Player
@onready var ability: Node = $Player/ShiftAbility
@onready var combat_hud: Node = $Player/CombatHUD
@onready var core_body: StaticBody3D = $ExperimentalCore
@onready var core_marker: Marker3D = $ExperimentalCore/InteractionPoint
@onready var core_mesh: MeshInstance3D = $ExperimentalCore/CoreCrystal
@onready var core_status: Label3D = $ExperimentalCore/Status
@onready var core_light: OmniLight3D = $ExperimentalCore/Light
@onready var gate_body: StaticBody3D = $ExtractionGate
@onready var gate_marker: Marker3D = $ExtractionGate/InteractionPoint
@onready var gate_beacon: MeshInstance3D = $ExtractionGate/Beacon
@onready var gate_status: Label3D = $ExtractionGate/Status
@onready var gate_light: OmniLight3D = $ExtractionGate/Light
@onready var objective_label: Label = $ExtractionHUD/Objective
@onready var hint_label: Label = $ExtractionHUD/Hint
@onready var clock_label: Label = $ExtractionHUD/Clock
@onready var feedback_label: Label = $ExtractionHUD/Feedback
@onready var outcome: CanvasLayer = $Outcome
@onready var outcome_title: Label = $Outcome/Card/Title
@onready var outcome_details: Label = $Outcome/Card/Details
@onready var replay_button: Button = $Outcome/Card/ReplayButton

var phase: Phase = Phase.RETRIEVE
var elapsed_seconds: float = 0.0
var shift_count: int = 0
var core_collected: bool = false
var extraction_done: bool = false
var upper_resolved: bool = false
var lower_resolved: bool = false
var warning_remaining: float = 0.0
var retry_remaining: float = 0.0
var retry_elapsed: float = 0.0
var waived_waves: Array[String] = []

var _guards: Array[Node] = []
var _upper: Array[Node] = []
var _lower: Array[Node] = []
var _activated: Array[Node] = []
var _defeated: Array[Node] = []
var _feedback_remaining: float = 0.0


func _ready() -> void:
    _build_arena()
    player.managed_restart = true
    combat_hud.call("set_mission_managed", true)
    for guard_path: NodePath in [NodePath("GuardUpperWest"), NodePath("GuardUpperEast")]:
        var guard: Node = get_node(guard_path)
        _upper.append(guard)
        _register_guard(guard)
    for guard_path: NodePath in [NodePath("GuardLowerMid"), NodePath("GuardLowerExit")]:
        var guard: Node = get_node(guard_path)
        _lower.append(guard)
        _register_guard(guard)
    player.died.connect(_on_player_died)
    ability.connect("shifted", _on_shifted)
    ability.connect("placement_rejected", _on_shift_rejected)
    ability.connect("shift_rejected", _on_shift_rejected)
    replay_button.pressed.connect(request_replay)
    outcome.visible = false
    feedback_label.text = ""
    _configure_shift_hud()
    _set_gate_visual(false)
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
    guard.call("set_combat_enabled", false)


func _process(delta: float) -> void:
    if phase == Phase.VICTORY or phase == Phase.DEFEAT or phase == Phase.RESTARTING:
        return
    elapsed_seconds += delta
    _update_clock()
    if _feedback_remaining > 0.0:
        _feedback_remaining = maxf(0.0, _feedback_remaining - delta)
        if _feedback_remaining == 0.0:
            feedback_label.text = ""


func _physics_process(delta: float) -> void:
    if get_tree().paused or delta <= 0.0:
        return
    if phase != Phase.UPPER_WARNING and phase != Phase.LOWER_WARNING:
        return
    if warning_remaining > 0.0:
        warning_remaining = maxf(0.0, warning_remaining - delta)
        return
    retry_elapsed += delta
    retry_remaining = maxf(0.0, retry_remaining - delta)
    if retry_remaining > 0.0:
        return
    retry_remaining = RETRY_INTERVAL
    var upper_wave: bool = phase == Phase.UPPER_WARNING
    var deck: String = "UPPER" if upper_wave else "LOWER"
    if _activate_wave(_upper if upper_wave else _lower, upper_wave):
        _enter_phase(Phase.UPPER_FIGHT if upper_wave else Phase.LOWER_FIGHT)
        wave_activated.emit(deck)
        _show_feedback("HELIX %s SECURITY DEPLOYED" % deck)
    elif retry_elapsed >= WAIVER_SECONDS:
        waived_waves.append(deck)
        wave_waived.emit(deck)
        _show_feedback("%s DEPLOYMENT BLOCKED / RESPONSE BYPASSED" % deck)
        _resolve_wave(upper_wave)
    else:
        hint_label.text = "HELIX ENTRY BLOCKED / CLEAR THE LANDING AREA"
        _refresh_threat()


func _on_shifted(_from: Vector3, _to: Vector3) -> void:
    if phase < Phase.VICTORY:
        shift_count += 1
        _update_clock()


func _on_shift_rejected(reason: String) -> void:
    if phase < Phase.VICTORY:
        _show_feedback("SHIFT BLOCKED / " + reason)


func _enter_phase(next_phase: Phase) -> void:
    if phase == Phase.VICTORY or phase == Phase.DEFEAT or phase == Phase.RESTARTING:
        return
    phase = next_phase
    phase_changed.emit(int(phase))
    _update_objective()
    _refresh_threat()


func _start_warning(upper_wave: bool) -> void:
    warning_remaining = WARNING_SECONDS
    retry_elapsed = 0.0
    retry_remaining = 0.0
    _enter_phase(Phase.UPPER_WARNING if upper_wave else Phase.LOWER_WARNING)
    _show_feedback("HELIX LOCKDOWN / %s RESPONSE INCOMING" % ("UPPER" if upper_wave else "LOWER"))


func try_collect_core() -> bool:
    if phase != Phase.RETRIEVE or not bool(player.get("is_alive")) or core_collected:
        return false
    if not _can_interact(core_marker, core_body, UPPER_FLOOR_Y):
        return false
    core_collected = true
    core_mesh.visible = false
    core_light.visible = false
    core_status.text = "CORE SECURED"
    core_status.modulate = CYAN
    core_picked_up.emit()
    _start_warning(true)
    return true


func _can_interact(marker: Marker3D, body: StaticBody3D, floor_y: float) -> bool:
    var point: Vector3 = marker.global_position
    var expected_player_y: float = floor_y + 1.03
    if absf(player.global_position.y - expected_player_y) > 0.7:
        _show_feedback("REACH THE %s DECK" % ("UPPER" if floor_y > 1.0 else "LOWER"))
        return false
    if absf(player.global_position.y - point.y) > INTERACTION_HEIGHT:
        _show_feedback("WRONG DECK / USE THE ACCESS RAMP")
        return false
    if player.global_position.distance_to(point) > INTERACTION_REACH:
        _show_feedback("MOVE CLOSER TO THE OBJECTIVE")
        return false
    var ray := PhysicsRayQueryParameters3D.create(
        player.global_position + Vector3.UP * 0.35, point, 1, [player.get_rid()]
    )
    ray.hit_from_inside = true
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
    if not hit.is_empty() and hit.get("collider") != body:
        _show_feedback("INTERACTION BLOCKED / FIND A CLEAR ANGLE")
        return false
    return true


func _activate_wave(group: Array[Node], upper_wave: bool) -> bool:
    if phase != Phase.UPPER_WARNING and phase != Phase.LOWER_WARNING:
        return false
    var floor_y: float = UPPER_FLOOR_Y if upper_wave else LOWER_FLOOR_Y
    var guard_y: float = UPPER_GUARD_Y if upper_wave else LOWER_GUARD_Y
    var pads: Array = []
    if upper_wave:
        pads = [
            [Vector3(-9.0, guard_y, -12.0), Vector3(-11.1, guard_y, -15.7), Vector3(-9.4, guard_y, -17.0)],
            [Vector3(9.0, guard_y, -12.0), Vector3(11.1, guard_y, -15.7), Vector3(9.4, guard_y, -17.0)]
        ]
    else:
        pads = [
            [Vector3(2.0, guard_y, 7.0), Vector3(-3.0, guard_y, 5.5), Vector3(1.0, guard_y, 12.0)],
            [Vector3(10.0, guard_y, 11.5), Vector3(11.5, guard_y, 7.0), Vector3(8.0, guard_y, 15.0)]
        ]
    var selected: Array[Vector3] = []
    for index: int in range(group.size()):
        var placed: bool = false
        for candidate_variant in pads[index]:
            var candidate: Vector3 = candidate_variant as Vector3
            if _safe_spawn(group[index] as StaticBody3D, candidate, selected, floor_y):
                selected.append(candidate)
                placed = true
                break
        if not placed:
            return false

    # Commit both placements only after the complete pair is safe.
    for index: int in range(group.size()):
        var guard: StaticBody3D = group[index] as StaticBody3D
        guard.global_position = selected[index]
        var face_point: Vector3 = (
            Vector3(0.0, guard_y, -11.0) if upper_wave
            else Vector3(9.0, guard_y, 16.0)
        )
        var facing: Vector3 = face_point - guard.global_position
        if facing.length_squared() > 0.001:
            var visual: Node3D = guard.get_node("VisualRoot") as Node3D
            visual.rotation.y = atan2(-facing.x, -facing.z)
        guard.reset_physics_interpolation()
        _activated.append(guard)
        guard.call("set_combat_enabled", true)
    return true


func _safe_spawn(guard: StaticBody3D, point: Vector3,
        selected: Array[Vector3], floor_y: float) -> bool:
    var site: Vector2 = Vector2(point.x, point.z)
    if site.distance_to(Vector2(player.global_position.x, player.global_position.z)) < MIN_PLAYER_SEPARATION:
        return false
    if bool(ability.get("anchor_active")):
        var anchor: Vector3 = ability.get("anchor_point") as Vector3
        if site.distance_to(Vector2(anchor.x, anchor.z)) < MIN_DEVICE_SEPARATION:
            return false
    var echo: Node3D = ability.get("echo_instance") as Node3D
    if is_instance_valid(echo):
        if site.distance_to(Vector2(echo.global_position.x, echo.global_position.z)) < MIN_DEVICE_SEPARATION:
            return false
    for another: Vector3 in selected:
        if site.distance_to(Vector2(another.x, another.z)) < MIN_GUARD_SEPARATION:
            return false
    var shape: CollisionShape3D = guard.get_node("CollisionShape3D") as CollisionShape3D
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = shape.shape
    query.transform = Transform3D(Basis.IDENTITY, point)
    query.collision_mask = 3
    query.exclude = [guard.get_rid()]
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    if not space.intersect_shape(query, 16).is_empty():
        return false
    var support := PhysicsRayQueryParameters3D.create(
        point + Vector3.UP * 0.15, point - Vector3.UP * 1.5, 1, [guard.get_rid()]
    )
    var hit: Dictionary = space.intersect_ray(support)
    if hit.is_empty() or (hit["normal"] as Vector3).dot(Vector3.UP) < 0.87:
        return false
    return absf((hit["position"] as Vector3).y - floor_y) <= 0.15


func _on_guard_destroyed(guard: Node) -> void:
    if phase != Phase.UPPER_FIGHT and phase != Phase.LOWER_FIGHT:
        return
    if not _activated.has(guard) or _defeated.has(guard):
        return
    _defeated.append(guard)
    var upper_wave: bool = phase == Phase.UPPER_FIGHT
    var group: Array[Node] = _upper if upper_wave else _lower
    var remaining: int = 0
    for active_guard: Node in group:
        if _activated.has(active_guard) and not _defeated.has(active_guard):
            remaining += 1
    if remaining == 0:
        _resolve_wave(upper_wave)
    else:
        _show_feedback("HELIX TROOPER DOWN / %d ACTIVE REMAINING" % remaining)
        _update_objective()
        _refresh_threat()


func _resolve_wave(upper_wave: bool) -> void:
    if upper_wave:
        if upper_resolved:
            return
        upper_resolved = true
        _start_warning(false)
    else:
        if lower_resolved:
            return
        lower_resolved = true
        if upper_resolved and core_collected and not _has_live_guards():
            _enter_phase(Phase.EXTRACT_READY)
            _set_gate_visual(true)
            _show_feedback("EXTRACTION READY / FOLLOW THE CYAN GATE")


func _has_live_guards() -> bool:
    for guard: Node in _activated:
        if not _defeated.has(guard) and int(guard.get("state")) != 3:
            return true
    return false


func try_extract() -> bool:
    if phase == Phase.RETRIEVE:
        _show_feedback("EXTRACTION LOCKED / RETRIEVE THE CORE")
        return false
    if phase != Phase.EXTRACT_READY or not core_collected or not upper_resolved or not lower_resolved:
        if phase < Phase.VICTORY:
            _show_feedback("EXTRACTION LOCKED / CLEAR HELIX RESPONSE")
        return false
    if extraction_done or not bool(player.get("is_alive")) or _has_live_guards():
        return false
    if not _can_interact(gate_marker, gate_body, LOWER_FLOOR_Y):
        return false
    extraction_done = true
    extraction_completed.emit()
    _finish(Phase.VICTORY)
    return true


func _set_gate_visual(unlocked: bool) -> void:
    var tint: Color = CYAN if unlocked else AMBER
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = tint
    material.emission_enabled = true
    material.emission = tint
    material.emission_energy_multiplier = 1.3
    gate_beacon.material_override = material
    gate_light.light_color = tint
    gate_status.modulate = tint
    gate_status.text = "EXTRACTION READY\nPRESS E" if unlocked else "EXTRACTION LOCKED"


func _on_player_died() -> void:
    if phase < Phase.VICTORY:
        _finish(Phase.DEFEAT)


func _finish(result: Phase) -> void:
    if phase >= Phase.VICTORY:
        return
    phase = result
    warning_remaining = 0.0
    retry_remaining = 0.0
    phase_changed.emit(int(phase))
    player.set_combat_enabled(false)
    for guard: Node in _guards:
        if int(guard.get("state")) != 3:
            guard.call("set_combat_enabled", false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    outcome.visible = true
    replay_button.disabled = false
    feedback_label.text = ""
    if result == Phase.VICTORY:
        outcome_title.text = "CORE EXTRACTED"
        outcome_title.add_theme_color_override("font_color", CYAN)
        objective_label.text = "OPERATION COMPLETE / VEX IS CLEAR"
        combat_hud.call("set_encounter_threat", "HELIX / EXTRACTION COMPLETE", CYAN)
    else:
        outcome_title.text = "OPERATIVE DOWN"
        outcome_title.add_theme_color_override("font_color", Color(1.0, 0.43, 0.30))
        objective_label.text = "MISSION FAILED / RESTART EXTRACTION"
        combat_hud.call("set_encounter_threat", "HELIX / RETRY AVAILABLE", AMBER)
    hint_label.text = ""
    var waiver_note: String = "DEPLOYMENT BLOCKED / " + ", ".join(waived_waves) if not waived_waves.is_empty() else "ALL DEPLOYED UNITS ACCOUNTED FOR"
    outcome_details.text = (
        "ENEMIES DEFEATED  %d / 4   |   TIME  %02d:%02d   |   SHIFTS  %d\n"
        + waiver_note + "\n"
        + ("HELIX CORE EXTRACTED. VEX IS CLEAR." if result == Phase.VICTORY
           else "RETURN TO THE EXTRACTION ENTRANCE.")
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
    if phase < Phase.VICTORY and event.is_action_pressed("interact"):
        var at_gate: bool = player.global_position.distance_to(gate_marker.global_position) < 4.5
        if at_gate:
            try_extract()
        elif phase == Phase.RETRIEVE:
            try_collect_core()
        else:
            _show_feedback("REACH EXTRACTION / CORE IS SECURED")
        get_viewport().set_input_as_handled()
    elif (phase == Phase.VICTORY or phase == Phase.DEFEAT) and (
        event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER
    ):
        request_replay()
        get_viewport().set_input_as_handled()


func _update_objective() -> void:
    match phase:
        Phase.RETRIEVE:
            objective_label.text = "OBJECTIVE / REACH UPPER GANTRY AND TAKE THE CORE"
            hint_label.text = "WEST ACCESS RAMP / Q ANCHOR / SHIFT TO FLANK / E TAKE CORE"
        Phase.UPPER_WARNING:
            objective_label.text = "OBJECTIVE / CORE SECURED / UPPER LOCKDOWN"
            hint_label.text = "SECURITY RESPONSE INCOMING / TAKE COVER"
        Phase.UPPER_FIGHT:
            objective_label.text = "OBJECTIVE / CLEAR UPPER SECURITY   %d / 2" % _wave_kills(_upper)
            hint_label.text = "USE UPPER COVER / SHIFT TO THE EAST OVERLOOK"
        Phase.LOWER_WARNING:
            objective_label.text = "OBJECTIVE / DESCEND TO EXTRACTION / LOWER LOCKDOWN"
            hint_label.text = "SECURITY RESPONSE INCOMING / RAMP OR DOWNWARD SHIFT"
        Phase.LOWER_FIGHT:
            objective_label.text = "OBJECTIVE / CLEAR LOWER SECURITY   %d / 2" % _wave_kills(_lower)
            hint_label.text = "DROP TO THE BAY / FLANK THE SHUTTLE GUARDS"
        Phase.EXTRACT_READY:
            objective_label.text = "OBJECTIVE / EXTRACTION READY / REACH CYAN GATE"
            hint_label.text = "LOWER SOUTHEAST GATE / PRESS E TO EXTRACT"
    objective_label.add_theme_color_override("font_color", CYAN if phase == Phase.EXTRACT_READY else AMBER)


func _wave_kills(group: Array[Node]) -> int:
    var total: int = 0
    for guard: Node in group:
        if _defeated.has(guard):
            total += 1
    return total


func _update_clock() -> void:
    clock_label.text = "EXTRACTION  %02d:%02d   |   SHIFTS  %d" % [
        int(elapsed_seconds / 60.0), int(elapsed_seconds) % 60, shift_count
    ]


func _show_feedback(message: String) -> void:
    feedback_label.text = message
    _feedback_remaining = 2.6


func _on_guard_state_changed(_next: int) -> void:
    _refresh_threat()


func _on_guard_windup() -> void:
    if phase < Phase.VICTORY:
        combat_hud.call("set_encounter_threat", "HELIX / SHOT INCOMING!", Color(1.0, 0.46, 0.25))


func _on_guard_echo(_at: Vector3) -> void:
    if phase < Phase.VICTORY:
        combat_hud.call("set_encounter_threat", "HELIX / ECHO DISTRACTION", CYAN)


func _refresh_threat() -> void:
    if phase >= Phase.VICTORY:
        return
    if phase == Phase.UPPER_WARNING or phase == Phase.LOWER_WARNING:
        combat_hud.call("set_encounter_threat", "HELIX / RESPONSE PENDING", AMBER)
        return
    var attacking: bool = false
    var alerted: bool = false
    var distracted: bool = false
    for guard: Node in _activated:
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
    elif phase == Phase.EXTRACT_READY:
        combat_hud.call("set_encounter_threat", "HELIX / EXTRACTION READY", CYAN)
    elif phase == Phase.RETRIEVE:
        combat_hud.call("set_encounter_threat", "HELIX / CORE SIGNAL DETECTED", CYAN)
    else:
        combat_hud.call("set_encounter_threat", "HELIX / SECURITY ACTIVE", AMBER)


func _configure_shift_hud() -> void:
    var hud: CanvasLayer = ability.get_node("ShiftHUD") as CanvasLayer
    var status: Label = hud.get_node("Status") as Label
    var timer: Label = hud.get_node("Timer") as Label
    var backdrop := ColorRect.new()
    backdrop.name = "ExtractionShiftBackdrop"
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


func _build_arena() -> void:
    var geometry := Node3D.new()
    geometry.name = "WorldGeometry"
    add_child(geometry)
    var floor_mat: StandardMaterial3D = _material(Color(0.12, 0.18, 0.24))
    var steel_mat: StandardMaterial3D = _material(Color(0.24, 0.33, 0.40))
    var cover_mat: StandardMaterial3D = _material(Color(0.35, 0.41, 0.46))
    var walk_mat: StandardMaterial3D = _material(Color(0.20, 0.39, 0.44))
    var rail_mat: StandardMaterial3D = _material(Color(0.45, 0.55, 0.60))
    _box(geometry, "Floor", Vector3(0, -0.30, 0), Vector3(34, 0.6, 40), floor_mat)
    _box(geometry, "NorthWall", Vector3(0, 3, -20), Vector3(34, 6, 0.7), steel_mat)
    _box(geometry, "SouthWall", Vector3(0, 3, 20), Vector3(34, 6, 0.7), steel_mat)
    _box(geometry, "WestWall", Vector3(-17, 3, 0), Vector3(0.7, 6, 40), steel_mat)
    _box(geometry, "EastWall", Vector3(17, 3, 0), Vector3(0.7, 6, 40), steel_mat)
    # One full ramp supports a walking return. Upper platforms overlap cleanly.
    _box(geometry, "WestRamp", Vector3(-11.0, 1.30, 3.4),
        Vector3(4.6, 0.32, 14), walk_mat, 0.211)
    _box(geometry, "WestLanding", Vector3(-11.0, 2.70, -6.8),
        Vector3(7.5, 0.4, 7.3), walk_mat)
    _box(geometry, "NorthGantry", Vector3(0, 2.70, -12.0),
        Vector3(27.0, 0.4, 5.0), walk_mat)
    _box(geometry, "WestGantry", Vector3(-10.3, 2.70, -15.0),
        Vector3(7.5, 0.4, 6.4), walk_mat)
    _box(geometry, "EastOverlook", Vector3(10.3, 2.70, -15.0),
        Vector3(7.5, 0.4, 6.4), walk_mat)
    # The middle front railing has deliberate openings for descending SHIFTS.
    for section: Array in [[-11.2, 4.0], [-4.6, 3.2], [4.6, 3.2], [11.2, 4.0]]:
        _box(geometry, "GantryRail" + str(section[0]),
            Vector3(float(section[0]), 3.23, -9.4),
            Vector3(float(section[1]), 0.65, 0.18), rail_mat)
    _box(geometry, "NorthRail", Vector3(0, 3.42, -18.3),
        Vector3(27, 1.0, 0.18), rail_mat)
    _box(geometry, "WestRail", Vector3(-14.1, 3.42, -15.1),
        Vector3(0.18, 1.0, 6.5), rail_mat)
    _box(geometry, "EastRail", Vector3(14.1, 3.42, -15.1),
        Vector3(0.18, 1.0, 6.5), rail_mat)
    for side_x: float in [-13.45, -8.55]:
        _box(geometry, "RampRail" + str(side_x), Vector3(side_x, 1.75, 3.4),
            Vector3(0.16, 0.66, 12.9), rail_mat, 0.211)

    for cover: Array in [
        ["LowerWestCover", Vector3(-5.7, 0.9, 5.5)],
        ["LowerMidCover", Vector3(-1.0, 0.9, 0.3)],
        ["LowerEastCover", Vector3(5.4, 0.9, 8.2)],
        ["ShuttleCover", Vector3(7.1, 0.9, 14.8)]
    ]:
        _box(geometry, cover[0] as String, cover[1] as Vector3,
            Vector3(2.6, 1.8, 2.4), cover_mat)
    _box(geometry, "UpperWestCover", Vector3(-5.0, 3.65, -15.7),
        Vector3(1.8, 1.5, 1.4), cover_mat)
    _box(geometry, "UpperEastCover", Vector3(5.0, 3.65, -15.7),
        Vector3(1.8, 1.5, 1.4), cover_mat)

    for guide: Array in [
        ["WestRampApproach", Vector3(-11.0, 0.03, 11.5), Vector3(2.8, 0.03, 2.0)],
        ["UpperWestPad", Vector3(-11.0, 2.92, -7.0), Vector3(2.3, 0.03, 2.0)],
        ["GantryCrossPad", Vector3(2.0, 2.92, -12.0), Vector3(2.0, 0.03, 1.5)],
        ["EastOverlookPad", Vector3(10.0, 2.92, -15.0), Vector3(2.0, 0.03, 1.6)],
        ["LowerDropPad", Vector3(0.0, 0.03, -6.7), Vector3(2.4, 0.03, 1.7)],
        ["LowerFlankPad", Vector3(2.5, 0.03, 14.0), Vector3(2.0, 0.03, 1.8)]
    ]:
        _guide(geometry, guide[0] as String, guide[1] as Vector3, guide[2] as Vector3)


func _material(tint: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.85
    return material


func _box(parent: Node3D, name: String, location: Vector3, size: Vector3,
        material: StandardMaterial3D, angle: float = 0.0) -> void:
    var solid := StaticBody3D.new()
    solid.name = name
    solid.collision_layer = 1
    solid.collision_mask = 1
    solid.position = location
    solid.rotation.x = angle
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    solid.add_child(collision)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    box.material = material
    mesh.mesh = box
    solid.add_child(mesh)
    parent.add_child(solid)


func _guide(parent: Node3D, name: String, location: Vector3, size: Vector3) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = name
    mesh.position = location
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var shape := BoxMesh.new()
    shape.size = size
    var glow := StandardMaterial3D.new()
    glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    glow.albedo_color = Color(0.16, 0.75, 0.78, 0.65)
    glow.emission_enabled = true
    glow.emission = Color(0.10, 0.54, 0.62)
    glow.emission_energy_multiplier = 0.6
    shape.material = glow
    mesh.mesh = shape
    parent.add_child(mesh)
