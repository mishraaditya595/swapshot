extends Node3D
## MS-06 encounter authority: objective, result, and whole-scene replay.

signal phase_changed(next_phase: int)

enum Phase { ACTIVE, VICTORY, DEFEAT, RESTARTING }

const WARNING: Color = Color(1.0, 0.74, 0.39)
const CYAN: Color = Color(0.40, 1.0, 0.90)

@onready var player: CharacterBody3D = $Firefight/Arena/Player
@onready var ability: Node = $Firefight/Arena/Player/ShiftAbility
@onready var weapon: Node = $Firefight/Arena/Player/VisualRoot/WeaponPivot/VX7
@onready var combat_hud: Node = $Firefight/Arena/Player/CombatHUD
@onready var objective: Label = $Firefight/EncounterHUD/HelixHint
@onready var elapsed_label: Label = $MissionHUD/Elapsed
@onready var outcome: CanvasLayer = $Outcome
@onready var outcome_title: Label = $Outcome/Card/Title
@onready var outcome_details: Label = $Outcome/Card/Details
@onready var replay_button: Button = $Outcome/Card/ReplayButton

var phase: Phase = Phase.ACTIVE
var elapsed_seconds: float = 0.0
var shift_count: int = 0
var _guards: Array[Node] = []


func _ready() -> void:
    # The previous encounter still exists for MS-05 regression tests.
    # This scene alone owns objective changes and keyboard replay.
    player.managed_restart = true
    combat_hud.call("set_mission_managed", true)
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
        _guards.append(guard)
        guard.connect("destroyed", _on_guard_destroyed.bind(guard))
        guard.connect("state_changed", _on_guard_state_changed)
        guard.connect("windup_started", _on_guard_windup)
        guard.connect("echo_distracted", _on_guard_echo)
        guard.connect("echo_released", _refresh_threat)
    player.died.connect(_on_player_died)
    ability.connect("shifted", _on_shifted)
    replay_button.pressed.connect(request_replay)
    outcome.visible = false
    _update_objective()
    _refresh_threat()
    _update_time()


func _process(delta: float) -> void:
    if phase == Phase.ACTIVE:
        elapsed_seconds += delta
        _update_time()


func _update_time() -> void:
    elapsed_label.text = "MISSION TIME  " + _format_time() + "  |  SHIFT FLANKS  %d" % shift_count


func _format_time() -> String:
    return "%02d:%02d" % [int(elapsed_seconds / 60.0), int(elapsed_seconds) % 60]


func _remaining_guards() -> int:
    var remaining: int = 0
    for guard: Node in _guards:
        if is_instance_valid(guard) and int(guard.get("state")) != 3:
            remaining += 1
    return remaining


func _update_objective() -> void:
    var cleared: int = _guards.size() - _remaining_guards()
    objective.text = "OBJECTIVE  /  CLEAR HELIX SECURITY    %d / %d" % [cleared, _guards.size()]
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
    else:
        _refresh_threat()


func _on_guard_state_changed(_next: int) -> void:
    _refresh_threat()


func _on_guard_windup() -> void:
    if phase == Phase.ACTIVE:
        combat_hud.call("set_encounter_threat", "HELIX  /  INCOMING SHOT!", Color(1.0, 0.46, 0.25))


func _on_guard_echo(_at: Vector3) -> void:
    if phase == Phase.ACTIVE:
        combat_hud.call("set_encounter_threat", "HELIX  /  ECHO DISTRACTION", CYAN)


func _refresh_threat() -> void:
    if phase != Phase.ACTIVE:
        return
    var attacking: bool = false
    var alerted: bool = false
    var searching: bool = false
    var distracted: bool = false
    for guard: Node in _guards:
        if not is_instance_valid(guard) or int(guard.get("state")) == 3:
            continue
        if guard.get("_echo") != null:
            distracted = true
        match int(guard.get("state")):
            2: attacking = true
            1: alerted = true
            4: searching = true
    if attacking:
        combat_hud.call("set_encounter_threat", "HELIX  /  UNDER FIRE!", WARNING)
    elif distracted:
        combat_hud.call("set_encounter_threat", "HELIX  /  ECHO DISTRACTION", CYAN)
    elif alerted:
        combat_hud.call("set_encounter_threat", "HELIX  /  CONTACT", WARNING)
    elif searching:
        combat_hud.call("set_encounter_threat", "HELIX  /  SEARCHING", WARNING)
    else:
        combat_hud.call("set_encounter_threat", "HELIX  /  CLEAR FOR NOW", Color(0.70, 0.86, 0.90))


func _on_player_died() -> void:
    if phase == Phase.ACTIVE:
        _finish(Phase.DEFEAT)


func _finish(result: Phase) -> void:
    if phase != Phase.ACTIVE:
        return
    phase = result
    phase_changed.emit(int(phase))
    player.set_combat_enabled(false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    outcome.visible = true
    if result == Phase.VICTORY:
        objective.text = "MISSION COMPLETE  /  HELIX SECURITY NEUTRALIZED"
        objective.add_theme_color_override("font_color", CYAN)
        outcome_title.text = "SECTOR SECURED"
        outcome_title.add_theme_color_override("font_color", CYAN)
        combat_hud.call("set_encounter_threat", "HELIX  /  ALL HOSTILES DOWN", CYAN)
    else:
        objective.text = "MISSION FAILED  /  OPERATIVE DOWN"
        objective.add_theme_color_override("font_color", Color(1.0, 0.46, 0.31))
        outcome_title.text = "OPERATIVE DOWN"
        outcome_title.add_theme_color_override("font_color", Color(1.0, 0.46, 0.31))
        combat_hud.call("set_encounter_threat", "HELIX  /  RETRY AVAILABLE", WARNING)
    outcome_details.text = (
        "GUARDS NEUTRALIZED  %d / %d\nTIME  %s    |    SHIFTS  %d\n\nPRESS ENTER OR CLICK BELOW TO REPLAY"
        % [_guards.size() - _remaining_guards(), _guards.size(), _format_time(), shift_count]
    )
    replay_button.text = "REPLAY ENCOUNTER  [ENTER]"


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
    # Reload the complete encounter so no guard, weapon, echo, or timer survives.
    get_tree().call_deferred("reload_current_scene")
