extends Node3D
## MS-08 Loading Dock: contextual training, two-guard encounter, and gated exit.

signal training_changed(next_step: int)
signal gate_unlocked()
signal phase_changed(next_phase: int)

enum Step { MOVE, RIFLE, ANCHOR, SHIFT, COMBAT, EXIT }
enum Phase { ACTIVE, VICTORY, DEFEAT, RESTARTING }

const CYAN: Color = Color(0.40, 1.0, 0.90)
const AMBER: Color = Color(1.0, 0.74, 0.39)
const EXIT_DISTANCE: float = 3.6

@onready var player: CharacterBody3D = $Player
@onready var ability: Node = $Player/ShiftAbility
@onready var weapon: Node = $Player/VisualRoot/WeaponPivot/VX7
@onready var combat_hud: Node = $Player/CombatHUD
@onready var practice_target: StaticBody3D = $PracticeTarget
@onready var route_zone: Area3D = $RouteZone
@onready var exit_point: Marker3D = $ExitPoint
@onready var exit_beacon: MeshInstance3D = $GateBeacon
@onready var hint: Label = $DockHUD/Hint
@onready var objective: Label = $DockHUD/Objective
@onready var clock: Label = $DockHUD/Clock
@onready var feedback: Label = $DockHUD/Feedback
@onready var outcome: CanvasLayer = $Outcome
@onready var outcome_title: Label = $Outcome/Card/Title
@onready var outcome_details: Label = $Outcome/Card/Details
@onready var replay_button: Button = $Outcome/Card/ReplayButton

var phase: Phase = Phase.ACTIVE
var step: Step = Step.MOVE
var elapsed_seconds: float = 0.0
var shift_count: int = 0
var is_gate_unlocked: bool = false
var _route_seen: bool = false
var _target_hit: bool = false
var _anchor_seen: bool = false
var _shift_seen: bool = false
var _guards: Array[Node] = []
var _defeated: Array[Node] = []
var _feedback_remaining: float = 0.0


func _ready() -> void:
    player.managed_restart = true
    combat_hud.call("set_mission_managed", true)
    for path: NodePath in [NodePath("GuardWest"), NodePath("GuardEast")]:
        var guard: Node = get_node(path)
        _guards.append(guard)
        guard.connect("destroyed", _on_guard_destroyed.bind(guard))
        guard.connect("state_changed", _on_guard_state_changed)
        guard.connect("windup_started", _on_guard_windup)
        guard.connect("echo_distracted", _on_echo_distracted)
        guard.connect("echo_released", _refresh_threat)
    practice_target.connect("damaged", _on_target_damaged)
    route_zone.body_entered.connect(_on_route_entered)
    ability.connect("anchor_placed", _on_anchor_placed)
    ability.connect("shifted", _on_shifted)
    ability.connect("placement_rejected", _on_anchor_rejected)
    ability.connect("shift_rejected", _on_shift_rejected)
    player.died.connect(_on_player_died)
    replay_button.pressed.connect(request_replay)
    outcome.visible = false
    feedback.text = ""
    _set_gate_color(AMBER)
    _set_hint()
    _update_objective()
    _update_clock()
    _refresh_threat()


func _process(delta: float) -> void:
    if phase != Phase.ACTIVE:
        return
    elapsed_seconds += delta
    _update_clock()
    if _feedback_remaining > 0.0:
        _feedback_remaining = maxf(0.0, _feedback_remaining - delta)
        if _feedback_remaining == 0.0:
            feedback.text = ""


func _on_route_entered(body: Node3D) -> void:
    if body != player or phase != Phase.ACTIVE:
        return
    _route_seen = true
    _advance_training()


func _on_target_damaged(_health: float) -> void:
    if phase != Phase.ACTIVE:
        return
    _target_hit = true
    _advance_training()


func _on_anchor_placed(_point: Vector3) -> void:
    if phase != Phase.ACTIVE:
        return
    _anchor_seen = true
    _advance_training()


func _on_shifted(_from: Vector3, _to: Vector3) -> void:
    if phase != Phase.ACTIVE:
        return
    shift_count += 1
    _shift_seen = true
    _update_clock()
    _advance_training()


func _on_anchor_rejected(reason: String) -> void:
    if phase == Phase.ACTIVE and step == Step.ANCHOR:
        _show_feedback("ANCHOR NOT SET  /  " + reason)


func _on_shift_rejected(reason: String) -> void:
    if phase == Phase.ACTIVE and step == Step.SHIFT:
        _show_feedback("SHIFT BLOCKED  /  " + reason)


func _advance_training() -> void:
    if phase != Phase.ACTIVE or is_gate_unlocked:
        return
    var next: Step = step
    # Save early player actions so an unprompted anchor or target hit does not
    # force the player to repeat an already completed exercise.
    if next == Step.MOVE and _route_seen:
        next = Step.RIFLE
    if next == Step.RIFLE and _target_hit:
        next = Step.ANCHOR
    if next == Step.ANCHOR and _anchor_seen:
        next = Step.SHIFT
    if next == Step.SHIFT and _shift_seen:
        next = Step.COMBAT
    if next != step:
        step = next
        training_changed.emit(int(step))
        _set_hint()
        if step == Step.COMBAT:
            _show_feedback("GOOD FLANK  /  THE ECHO DRAWS GUARD ATTENTION")


func _set_hint() -> void:
    if phase != Phase.ACTIVE:
        return
    match step:
        Step.MOVE:
            hint.text = "01  /  WASD MOVE TO THE CYAN COVER MARKER"
        Step.RIFLE:
            hint.text = "02  /  MOUSE LOOK  |  RMB AIM  |  LMB HIT ORANGE TARGET  |  R RELOAD"
        Step.ANCHOR:
            hint.text = "03  /  AIM AT CLEAR FLOOR  |  Q PLACE ANCHOR (CYAN = SAFE)"
        Step.SHIFT:
            hint.text = "04  /  LEFT SHIFT TELEPORT TO ANCHOR  |  LEAVE AN ECHO"
        Step.COMBAT:
            hint.text = "05  /  CLEAR BOTH GUARDS  |  SHIFT BEHIND CARGO TO FLANK"
        Step.EXIT:
            hint.text = "06  /  FOLLOW CYAN LIGHT TO SECURITY CORE GATE  |  E INTERACT"


func _show_feedback(message: String) -> void:
    feedback.text = message
    _feedback_remaining = 2.6


func _remaining_guards() -> int:
    return _guards.size() - _defeated.size()


func _on_guard_destroyed(guard: Node) -> void:
    if phase != Phase.ACTIVE or not _guards.has(guard) or _defeated.has(guard):
        return
    _defeated.append(guard)
    _update_objective()
    if _remaining_guards() == 0:
        _unlock_gate()
    else:
        _show_feedback("HELIX GUARD DOWN  /  %d REMAINING" % _remaining_guards())
    _refresh_threat()


func _unlock_gate() -> void:
    if is_gate_unlocked or phase != Phase.ACTIVE or not bool(player.get("is_alive")):
        return
    is_gate_unlocked = true
    step = Step.EXIT
    training_changed.emit(int(step))
    _set_gate_color(CYAN)
    _set_hint()
    _update_objective()
    _show_feedback("DOCK SECURED  /  EXIT UNLOCKED")
    gate_unlocked.emit()


func _set_gate_color(tint: Color) -> void:
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = tint
    material.emission_enabled = true
    material.emission = tint
    material.emission_energy_multiplier = 1.4
    exit_beacon.material_override = material


func _update_objective() -> void:
    if is_gate_unlocked:
        objective.text = "OBJECTIVE  /  REACH THE LIT GATE AND PRESS E"
        objective.add_theme_color_override("font_color", CYAN)
    else:
        objective.text = "OBJECTIVE  /  CLEAR DOCK SECURITY   %d / 2" % _defeated.size()
        objective.add_theme_color_override("font_color", AMBER)


func _update_clock() -> void:
    clock.text = "LOADING DOCK  %02d:%02d   |   SHIFTS  %d" % [
        int(elapsed_seconds / 60.0), int(elapsed_seconds) % 60, shift_count
    ]


func _on_guard_state_changed(_state: int) -> void:
    _refresh_threat()


func _on_guard_windup() -> void:
    if phase == Phase.ACTIVE:
        combat_hud.call("set_encounter_threat", "HELIX / SHOT INCOMING!", Color(1.0, 0.46, 0.25))


func _on_echo_distracted(_at: Vector3) -> void:
    if phase == Phase.ACTIVE:
        combat_hud.call("set_encounter_threat", "HELIX / ECHO DISTRACTION", CYAN)


func _refresh_threat() -> void:
    if phase != Phase.ACTIVE:
        return
    var alerted: bool = false
    var distracted: bool = false
    var attacking: bool = false
    for guard: Node in _guards:
        if _defeated.has(guard):
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
    elif is_gate_unlocked:
        combat_hud.call("set_encounter_threat", "HELIX / DOCK CLEAR", CYAN)
    else:
        combat_hud.call("set_encounter_threat", "HELIX / PATROL AHEAD", AMBER)


func try_exit() -> bool:
    if phase != Phase.ACTIVE or not bool(player.get("is_alive")):
        return false
    if not is_gate_unlocked:
        _show_feedback("GATE LOCKED  /  DEFEAT BOTH HELIX GUARDS")
        return false
    if player.global_position.distance_to(exit_point.global_position) > EXIT_DISTANCE:
        _show_feedback("MOVE CLOSER TO THE LIT GATE")
        return false
    _finish(Phase.VICTORY)
    return true


func _on_player_died() -> void:
    if phase == Phase.ACTIVE:
        _finish(Phase.DEFEAT)


func _finish(result: Phase) -> void:
    if phase != Phase.ACTIVE:
        return
    phase = result
    phase_changed.emit(int(phase))
    player.set_combat_enabled(false)
    for guard: Node in _guards:
        if is_instance_valid(guard) and int(guard.get("state")) != 3:
            guard.call("set_combat_enabled", false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    outcome.visible = true
    if result == Phase.VICTORY:
        outcome_title.text = "LOADING DOCK SECURED"
        outcome_title.add_theme_color_override("font_color", CYAN)
        objective.text = "SECTION COMPLETE  /  SECURITY CORE NEXT"
        combat_hud.call("set_encounter_threat", "HELIX / SECTOR SECURED", CYAN)
    else:
        outcome_title.text = "OPERATIVE DOWN"
        outcome_title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.31))
        objective.text = "MISSION FAILED  /  RETRY LOADING DOCK"
        combat_hud.call("set_encounter_threat", "HELIX / RETRY AVAILABLE", AMBER)
    hint.text = ""
    feedback.text = ""
    outcome_details.text = (
        "GUARDS  %d / 2    |    TIME  %02d:%02d    |    SHIFTS  %d\n"
        + ("SECURITY CORE IS NEXT. NO ZONE LOAD IN THIS PREVIEW." if result == Phase.VICTORY
           else "RETURN TO THE LOADING DOCK ENTRANCE.")
        + "\n\nPRESS ENTER OR CLICK TO REPLAY"
    ) % [_defeated.size(), int(elapsed_seconds / 60.0), int(elapsed_seconds) % 60, shift_count]


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if phase == Phase.ACTIVE and event.is_action_pressed("interact"):
        try_exit()
        get_viewport().set_input_as_handled()
    elif (phase == Phase.VICTORY or phase == Phase.DEFEAT) and (
        event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER
    ):
        request_replay()
        get_viewport().set_input_as_handled()


func request_replay() -> void:
    if phase != Phase.VICTORY and phase != Phase.DEFEAT:
        return
    phase = Phase.RESTARTING
    phase_changed.emit(int(phase))
    replay_button.disabled = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_tree().call_deferred("reload_current_scene")
