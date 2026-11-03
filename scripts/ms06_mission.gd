extends Node3D
## One encounter authority. Reserve guards are collision-free until safe activation.

signal phase_changed(next_phase: int)
signal wave_started(wave_number: int)

enum Phase { ACTIVE, VICTORY, DEFEAT, RESTARTING }

const WARNING: Color = Color(1.0, 0.74, 0.39)
const CYAN: Color = Color(0.40, 1.0, 0.90)
const REINFORCEMENT_DELAY: float = 4.0
const MIN_SPAWN_DISTANCE: float = 4.0
# Positions share the existing arena's floor/landing. Fallbacks avoid a player
# standing at a primary entry point; a clearance query also checks cover.
const SPAWN_SITES: Array[Vector3] = [
    Vector3(-11.2, 1.03, -10.8),
    Vector3(0.0, 1.03, -12.8),
    Vector3(10.8, 2.48, -11.0),
    Vector3(-11.6, 1.03, 8.3),
    Vector3(11.6, 1.03, 8.4),
    Vector3(-11.6, 1.03, -0.8),
    Vector3(11.7, 1.03, 0.5),
    Vector3(0.0, 1.03, 13.0)
]

@onready var player: CharacterBody3D = $Firefight/Arena/Player
@onready var ability: Node = $Firefight/Arena/Player/ShiftAbility
@onready var combat_hud: Node = $Firefight/Arena/Player/CombatHUD
@onready var objective: Label = $Firefight/EncounterHUD/HelixHint
@onready var wave_banner: Label = $MissionHUD/WaveBanner
@onready var wave_backdrop: ColorRect = $MissionHUD/WaveBannerBackdrop
@onready var elapsed_label: Label = $MissionHUD/Elapsed
@onready var outcome: CanvasLayer = $Outcome
@onready var outcome_title: Label = $Outcome/Card/Title
@onready var outcome_details: Label = $Outcome/Card/Details
@onready var replay_button: Button = $Outcome/Card/ReplayButton

var phase: Phase = Phase.ACTIVE
var current_wave: int = 1
var elapsed_seconds: float = 0.0
var shift_count: int = 0
var reinforcements_inbound: bool = false
var reinforcement_remaining: float = 0.0
var _banner_remaining: float = 0.0
var _guards: Array[Node] = []
var _initial_guards: Array[Node] = []
var _reserve_guards: Array[Node] = []


func _ready() -> void:
    # The MS-05 scene is still independent for existing regression tests.
    player.managed_restart = true
    combat_hud.call("set_mission_managed", true)
    ($Firefight/Arena/Instructions/ControlHints as Label).add_theme_font_size_override("font_size", 22)
    $Firefight/Arena/Instructions/ControlHints.text = (
        "SWAPSHOT  /  OPERATION ZERO HOUR\n"
        + "WASD MOVE  |  LMB FIRE  |  RMB AIM  |  R RELOAD  |  Q ANCHOR  |  SHIFT TELEPORT  |  ESC RELEASE"
    )
    for path: NodePath in [
        NodePath("Firefight/HelixTrooper"),
        NodePath("FlankGuard"),
        NodePath("UpperGuard")
    ]:
        var guard: Node = get_node(path)
        _initial_guards.append(guard)
        _register_guard(guard)
    for path: NodePath in [
        NodePath("ReinforcementWest"),
        NodePath("ReinforcementNorth"),
        NodePath("ReinforcementHigh")
    ]:
        var guard: Node = get_node(path)
        _reserve_guards.append(guard)
        _register_guard(guard)
        guard.call("set_combat_enabled", false)
    player.died.connect(_on_player_died)
    ability.connect("shifted", _on_shifted)
    replay_button.pressed.connect(request_replay)
    outcome.visible = false
    _show_banner("WAVE 1 / HELIX PATROL", 3.0)
    _update_objective()
    _refresh_threat()
    _update_time()


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
    _update_time()
    if _banner_remaining > 0.0 and not reinforcements_inbound:
        _banner_remaining = maxf(0.0, _banner_remaining - delta)
        if _banner_remaining <= 0.0:
            wave_banner.visible = false
            wave_backdrop.visible = false


func _physics_process(delta: float) -> void:
    _advance_waves(delta)


# Callable with physics delta for deterministic tests and pause regression.
func _advance_waves(delta: float) -> void:
    if phase != Phase.ACTIVE or not reinforcements_inbound or delta <= 0.0 or get_tree().paused:
        return
    reinforcement_remaining = maxf(0.0, reinforcement_remaining - delta)
    if reinforcement_remaining > 0.0:
        wave_banner.text = "REINFORCEMENTS INBOUND  /  %d s" % int(ceilf(reinforcement_remaining))
        return
    if _activate_reinforcements():
        reinforcements_inbound = false
        current_wave = 2
        wave_started.emit(current_wave)
        _show_banner("WAVE 2 / HELIX RESPONSE TEAM", 4.0)
        _update_objective()
        _refresh_threat()
    else:
        # Every guard must have a clear floor and capsule. If the player
        # occupies an entry point, retry next physics tick, never spawn on top.
        wave_banner.text = "REINFORCEMENTS / ENTRY ZONE BLOCKED"


func _show_banner(message: String, seconds: float) -> void:
    wave_banner.text = message
    wave_banner.visible = true
    wave_backdrop.visible = true
    _banner_remaining = seconds


func _activate_reinforcements() -> bool:
    var positions: Array[Vector3] = []
    for index in range(_reserve_guards.size()):
        var spawn: Vector3 = _find_spawn(_reserve_guards[index] as StaticBody3D, index, positions)
        if not spawn.is_finite():
            return false
        positions.append(spawn)
    for index in range(_reserve_guards.size()):
        var guard: StaticBody3D = _reserve_guards[index] as StaticBody3D
        guard.global_position = positions[index]
        guard.reset_physics_interpolation()
        guard.call("set_combat_enabled", true)
    return true


func _find_spawn(guard: StaticBody3D, slot: int, chosen: Array[Vector3]) -> Vector3:
    var collision: CollisionShape3D = guard.get_node("CollisionShape3D") as CollisionShape3D
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    for attempt in range(SPAWN_SITES.size()):
        var point: Vector3 = SPAWN_SITES[(slot + attempt) % SPAWN_SITES.size()]
        if point.distance_to(player.global_position) < MIN_SPAWN_DISTANCE:
            continue
        if bool(ability.get("anchor_active")) and point.distance_to(
            ability.get("anchor_point") as Vector3
        ) < 2.5:
            continue
        var near_existing: bool = false
        for already: Vector3 in chosen:
            if already.distance_to(point) < 2.0:
                near_existing = true
                break
        if near_existing:
            continue
        var overlap := PhysicsShapeQueryParameters3D.new()
        overlap.shape = collision.shape
        overlap.transform = Transform3D(Basis.IDENTITY, point)
        overlap.collision_mask = 3 # Arena and player, never through either.
        overlap.exclude = [guard.get_rid()]
        if not space.intersect_shape(overlap, 8).is_empty():
            continue
        var support_query := PhysicsRayQueryParameters3D.create(
            point + Vector3.UP * 0.2, point - Vector3.UP * 1.5, 1, [guard.get_rid()]
        )
        var support: Dictionary = space.intersect_ray(support_query)
        if support.is_empty() or (support["normal"] as Vector3).dot(Vector3.UP) < 0.87:
            continue
        if absf(float((support["position"] as Vector3).y) - (point.y - 1.03)) > 0.27:
            continue
        return point
    return Vector3.INF


func _update_time() -> void:
    elapsed_label.text = "MISSION  " + _format_time() + "   |   SHIFTS  %d" % shift_count


func _format_time() -> String:
    return "%02d:%02d" % [int(elapsed_seconds / 60.0), int(elapsed_seconds) % 60]


func _remaining_guards() -> int:
    var remaining: int = 0
    for guard: Node in _guards:
        if is_instance_valid(guard) and int(guard.get("state")) != 3:
            remaining += 1
    return remaining


func _initial_remaining() -> int:
    var remaining: int = 0
    for guard: Node in _initial_guards:
        if is_instance_valid(guard) and int(guard.get("state")) != 3:
            remaining += 1
    return remaining


func _update_objective() -> void:
    objective.text = (
        "OBJECTIVE / CLEAR HELIX SECURITY   %d / %d    |    WAVE %d / 2"
        % [_guards.size() - _remaining_guards(), _guards.size(), current_wave]
    )
    objective.add_theme_color_override("font_color", WARNING)


func _on_shifted(_from: Vector3, _to: Vector3) -> void:
    if phase == Phase.ACTIVE:
        shift_count += 1
        _update_time()


func _on_guard_destroyed(guard: Node) -> void:
    if phase != Phase.ACTIVE or not _guards.has(guard):
        return
    _update_objective()
    if _remaining_guards() == 0 and bool(player.get("is_alive")):
        _finish(Phase.VICTORY)
    elif current_wave == 1 and not reinforcements_inbound and _initial_remaining() == 0:
        reinforcements_inbound = true
        reinforcement_remaining = REINFORCEMENT_DELAY
        _show_banner("REINFORCEMENTS INBOUND / 4 s", REINFORCEMENT_DELAY)
        _refresh_threat()
    else:
        _refresh_threat()


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
    if reinforcements_inbound:
        combat_hud.call("set_encounter_threat", "HELIX / RESPONSE INBOUND", WARNING)
        return
    var attacking: bool = false
    var alerted: bool = false
    var searching: bool = false
    var distracted: bool = false
    for guard: Node in _guards:
        if not is_instance_valid(guard) or int(guard.get("state")) == 3:
            continue
        if not bool(guard.get("combat_enabled")):
            continue
        if guard.get("_echo") != null:
            distracted = true
        match int(guard.get("state")):
            2: attacking = true
            1: alerted = true
            4: searching = true
    if attacking:
        combat_hud.call("set_encounter_threat", "HELIX / UNDER FIRE!", WARNING)
    elif distracted:
        combat_hud.call("set_encounter_threat", "HELIX / ECHO DISTRACTION", CYAN)
    elif alerted:
        combat_hud.call("set_encounter_threat", "HELIX / CONTACT", WARNING)
    elif searching:
        combat_hud.call("set_encounter_threat", "HELIX / SEARCHING", WARNING)
    else:
        combat_hud.call("set_encounter_threat", "HELIX / CLEAR FOR NOW", Color(0.70, 0.86, 0.90))


func _on_player_died() -> void:
    if phase == Phase.ACTIVE:
        _finish(Phase.DEFEAT)


func _finish(result: Phase) -> void:
    if phase != Phase.ACTIVE:
        return
    phase = result
    reinforcements_inbound = false
    reinforcement_remaining = 0.0
    wave_banner.visible = false
    wave_backdrop.visible = false
    phase_changed.emit(int(phase))
    player.set_combat_enabled(false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    outcome.visible = true
    if result == Phase.VICTORY:
        objective.text = "MISSION COMPLETE / HELIX SECURITY NEUTRALIZED"
        objective.add_theme_color_override("font_color", CYAN)
        outcome_title.text = "SECTOR SECURED"
        outcome_title.add_theme_color_override("font_color", CYAN)
        combat_hud.call("set_encounter_threat", "HELIX / ALL HOSTILES DOWN", CYAN)
    else:
        objective.text = "MISSION FAILED / OPERATIVE DOWN"
        objective.add_theme_color_override("font_color", Color(1.0, 0.46, 0.31))
        outcome_title.text = "OPERATIVE DOWN"
        outcome_title.add_theme_color_override("font_color", Color(1.0, 0.46, 0.31))
        combat_hud.call("set_encounter_threat", "HELIX / RETRY AVAILABLE", WARNING)
    outcome_details.text = (
        "GUARDS NEUTRALIZED  %d / %d\nTIME  %s   |   SHIFTS  %d\n\nPRESS ENTER OR CLICK BELOW TO REPLAY"
        % [_guards.size() - _remaining_guards(), _guards.size(), _format_time(), shift_count]
    )
    replay_button.text = "REPLAY ENCOUNTER [ENTER]"


func _unhandled_input(event: InputEvent) -> void:
    if phase != Phase.VICTORY and phase != Phase.DEFEAT:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            request_replay()
            get_viewport().set_input_as_handled()


func request_replay() -> void:
    if phase != Phase.VICTORY and phase != Phase.DEFEAT:
        return
    phase = Phase.RESTARTING
    phase_changed.emit(int(phase))
    replay_button.disabled = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    # Reload the whole encounter; no guard, echo or timer survives.
    get_tree().call_deferred("reload_current_scene")
