extends SceneTree
## MS-08: new-player training, real SHIFT safety, gate progression, and both replay paths.

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        printerr("MS-08 FAIL: " + message)


func _frames(count: int) -> void:
    for _frame in range(count):
        await physics_frame


func _blocker(parent: Node3D, at: Vector3) -> StaticBody3D:
    var solid := StaticBody3D.new()
    solid.collision_layer = 1
    solid.position = at
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(1.4, 2.2, 1.4)
    collision.shape = box
    solid.add_child(collision)
    parent.add_child(solid)
    return solid


func _run() -> void:
    var scene: PackedScene = load("res://scenes/levels/loading_dock.tscn")
    _check(scene != null, "Loading Dock scene resource loads")
    if scene == null:
        quit(1)
        return
    var main: PackedScene = load("res://scenes/main.tscn")
    _check(main != null, "Main scene loads")
    if main != null:
        var startup: Node = main.instantiate()
        _check(startup.has_node("LoadingDock/Player"),
            "Main starts at the Loading Dock, not the prior firefight")
        startup.free()
    var dock: Node3D = scene.instantiate()
    root.add_child(dock)
    current_scene = dock
    await _frames(8)

    var player: CharacterBody3D = dock.get_node("Player")
    var ability: Node = player.get_node("ShiftAbility")
    var weapon: Node = player.get_node("VisualRoot/WeaponPivot/VX7")
    var target: StaticBody3D = dock.get_node("PracticeTarget")
    var first: Node = dock.get_node("GuardWest")
    var second: Node = dock.get_node("GuardEast")
    var objective: Label = dock.get_node("DockHUD/Objective")
    var hint: Label = dock.get_node("DockHUD/Hint")
    var feedback: Label = dock.get_node("DockHUD/Feedback")
    var clock: Label = dock.get_node("DockHUD/Clock")
    var status: Label = ability.get_node("ShiftHUD/Status")
    var timer: Label = ability.get_node("ShiftHUD/Timer")
    var gate_sign: Label3D = dock.get_node("GateStatus")
    var outcome: CanvasLayer = dock.get_node("Outcome")
    _check(bool(player.get("managed_restart")), "Mission owns retry and replay")
    _check(int(dock.get("phase")) == 0 and int(dock.get("step")) == 0,
        "Opening starts at movement tutorial")
    _check(hint.text.contains("WASD") and objective.text.contains("0 / 2"),
        "Onboarding and live objective are both readable")
    _check(not bool(dock.get("is_gate_unlocked")) and not outcome.visible,
        "Exit is locked and result is hidden on fresh run")
    _check(int(dock.call("_remaining_guards")) == 2,
        "Two guard actors make up the opening fight")
    _check(is_equal_approx(float(player.get("health")), 100.0)
        and int(weapon.get("ammo")) == 24,
        "Full armor and magazine at start")
    _check(not bool(dock.call("try_exit")), "Exit cannot complete before both guards die")
    _check(feedback.text.contains("LOCKED"), "Locked gate explains missing objective")
    _check(gate_sign.text.contains("LOCKED"),
        "Gate signage starts amber and explicitly locked")
    _check(dock.has_node("RangeStatus") and dock.has_node("PracticeFrameTop")
        and dock.has_node("PracticeFrameLeft") and dock.has_node("PracticeFrameRight"),
        "The orange practice target has a distinct visible frame and range label")
    _check(ability.get_node("ShiftHUD/DockShiftBackdrop") is ColorRect,
        "Dock-specific SHIFT status has a solid readable background")
    for label: Label in [status, timer]:
        _check(is_equal_approx(label.anchor_top, 1.0)
            and is_equal_approx(label.anchor_bottom, 1.0),
            "SHIFT status and timer are anchored to the viewport bottom")
        for panel: Label in [objective, hint, clock]:
            _check(not label.get_global_rect().intersects(panel.get_global_rect()),
                "SHIFT HUD must not overlap dock objective, tutorial or clock")
    _check(not status.get_global_rect().intersects(timer.get_global_rect()),
        "SHIFT status and timer stay on independent lines")
    var original_viewport_size: Vector2i = root.size
    root.size = Vector2i(960, 540)
    await _frames(3)
    var ammo_label: Label = player.get_node("CombatHUD/Ammo")
    for label: Label in [status, timer]:
        for panel: Label in [objective, hint, clock, ammo_label]:
            _check(not label.get_global_rect().intersects(panel.get_global_rect()),
                "SHIFT HUD must remain separate at a 960 by 540 browser viewport")
    root.size = original_viewport_size
    await _frames(3)

    player.set_physics_process(false)
    for guard: Node in [first, second]:
        guard.set_physics_process(false)
    player.global_position = Vector3(0.0, 1.1, 12.0)
    await _frames(4)
    _check(int(dock.get("step")) == 1 and hint.text.contains("RMB AIM")
        and hint.text.contains("TARGET OR GUARD"),
        "Physical route trigger accepts a target or guard for rifle training")
    target.call("apply_damage", 20.0)
    _check(int(dock.get("step")) == 2 and hint.text.contains("Q PLACE"),
        "A registered target hit reveals the anchor instruction")

    var landing := Vector3(0.0, 0.0, 10.0)
    _check(bool(ability.call("_try_place_at", landing, Vector3.UP)),
        "Clear supported dock floor accepts anchor")
    _check(int(dock.get("step")) == 3 and hint.text.contains("LEFT SHIFT"),
        "Real anchor placement signal reveals SHIFT instruction")
    var origin: Vector3 = player.global_position
    var old_yaw: float = (player.get_node("CameraPivot") as Node3D).rotation.y
    var blocker: StaticBody3D = _blocker(dock, landing + Vector3.UP)
    await _frames(3)
    _check(not bool(ability.call("try_shift")), "Occupied landing rejects SHIFT")
    _check(player.global_position.distance_to(origin) < 0.05,
        "Rejected SHIFT never displaces the player")
    _check(bool(ability.get("anchor_active"))
        and is_zero_approx(float(ability.get("cooldown_remaining_seconds"))),
        "Rejected SHIFT does not consume anchor or cooldown")
    _check(int(dock.get("step")) == 3 and int(dock.get("shift_count")) == 0,
        "Rejected SHIFT does not advance onboarding or statistics")
    blocker.queue_free()
    await _frames(3)
    _check(bool(ability.call("try_shift")), "Successful SHIFT follows cleared landing")
    _check(int(dock.get("step")) == 4 and int(dock.get("shift_count")) == 1,
        "Successful SHIFT advances training and records one shift")
    _check(ability.get("echo_instance") != null,
        "SHIFT leaves the current P0 echo behind")
    _check(is_equal_approx((player.get_node("CameraPivot") as Node3D).rotation.y, old_yaw),
        "SHIFT preserves camera yaw")
    _check(not bool(ability.call("try_shift")),
        "Cooldown blocks repeated SHIFT input")
    ability.call("_advance_lifecycle", 1.6)
    _check(ability.get("echo_instance") == null, "Echo expires without leaking")

    var space: PhysicsDirectSpaceState3D = dock.get_world_3d().direct_space_state
    var ray := PhysicsRayQueryParameters3D.create(
        Vector3(0.3, 1.0, -7.8), Vector3(0.3, 1.0, -13.2), 1
    )
    var cover_hit: Dictionary = space.intersect_ray(ray)
    _check(cover_hit.get("collider") == dock.get_node("CrateCentralCover"),
        "Physical crate blocks fire and sight across the middle lane")
    first.call("apply_damage", 500.0)
    _check(not bool(dock.get("is_gate_unlocked"))
        and objective.text.contains("1 / 2"), "First elimination keeps the gate locked")
    first.call("apply_damage", 500.0)
    _check(int(dock.call("_remaining_guards")) == 1, "Repeated kill cannot double count")
    second.call("apply_damage", 500.0)
    _check(bool(dock.get("is_gate_unlocked")) and int(dock.get("step")) == 5,
        "Both guards clear the dock and advance to the gate")
    _check(objective.text.contains("PRESS E") and hint.text.contains("E INTERACT"),
        "Unlocked gate announces next action and control")
    _check(gate_sign.text.contains("PRESS E"),
        "The gate sign changes from locked to interaction instruction")
    _check((dock.get_node("GateFillLight") as OmniLight3D).light_color.g > 0.9,
        "Gate lighting turns cyan after clearing both guards")
    _check(not bool(dock.call("try_exit")),
        "Gate interaction requires player proximity after clear")
    player.global_position = (dock.get_node("ExitPoint") as Node3D).global_position
    await _frames(2)
    _check(bool(dock.call("try_exit")), "Nearby interaction finishes the dock")
    _check(int(dock.get("phase")) == 1 and outcome.visible,
        "Victory reveals the completion screen")
    _check((dock.get_node("Outcome/Card/Title") as Label).text.contains("DOCK SECURED"),
        "Victory title names Loading Dock completion")
    _check((dock.get_node("Outcome/Card/Details") as Label).text.contains("SECURITY CORE IS NEXT"),
        "Transition names the next zone without loading it")
    _check(not bool(player.get("controls_enabled"))
        and not bool(weapon.call("fire_once")),
        "Result disables movement and weapon firing")
    _check(not bool(ability.get("anchor_active"))
        and ability.get("echo_instance") == null,
        "Victory clears the SHIFT lifecycle")

    var old_dock: Node3D = dock
    dock.call("request_replay")
    dock.call("request_replay")
    await _frames(8)
    dock = current_scene as Node3D
    _check(dock != null and dock != old_dock,
        "Duplicate replay input performs one fresh scene load")
    if dock == null or dock == old_dock:
        quit(1)
        return
    _check(int(dock.get("phase")) == 0 and int(dock.get("step")) == 0,
        "Victory replay resets tutorial and encounter")
    _check(not bool(dock.get("is_gate_unlocked"))
        and int(dock.call("_remaining_guards")) == 2,
        "Replay locks the gate and restores both guards")
    player = dock.get_node("Player")
    ability = player.get_node("ShiftAbility")
    weapon = player.get_node("VisualRoot/WeaponPivot/VX7")
    _check(float(player.get("health")) == 100.0 and int(weapon.get("ammo")) == 24,
        "Replay restores full health and ammo")
    _check(not bool(ability.get("anchor_active"))
        and ability.get("echo_instance") == null
        and is_zero_approx(float(ability.get("cooldown_remaining_seconds"))),
        "Replay resets SHIFT timers, anchor and echo")

    player.set_physics_process(false)
    _check(bool(ability.call("_try_place_at", Vector3(0.0, 0.0, 10.0), Vector3.UP)),
        "Fresh run supports a new anchor")
    player.call("apply_damage", 999.0)
    _check(int(dock.get("phase")) == 2
        and (dock.get_node("Outcome") as CanvasLayer).visible,
        "Player death displays defeat and blocks progression")
    _check(not bool(ability.get("anchor_active"))
        and not bool(ability.get("owner_alive")),
        "Death cancels an armed anchor")
    _check(not bool(dock.call("try_exit")), "Death cannot complete the exit")
    var old_death: Node3D = dock
    (dock.get_node("Outcome/Card/ReplayButton") as Button).pressed.emit()
    await _frames(8)
    dock = current_scene as Node3D
    _check(dock != null and dock != old_death,
        "Death retry button reloads Loading Dock")
    if dock != null and dock != old_death:
        _check(int(dock.get("phase")) == 0
            and int(dock.call("_remaining_guards")) == 2
            and not bool(dock.get("is_gate_unlocked")),
            "Death retry starts with both guards, locked gate, active player")
        _check(float((dock.get_node("Player") as CharacterBody3D).get("health")) == 100.0,
            "Death retry restores armor")
        dock.queue_free()
    await _frames(3)

    # Separate fresh run reproduces the browser sequence: ignore the dummy,
    # use Q + SHIFT early, hit a real guard, then cross the tutorial marker.
    # All valid actions must advance the tutorial at once when it catches up.
    var alternate: Node3D = scene.instantiate()
    root.add_child(alternate)
    current_scene = alternate
    await _frames(8)
    var alternate_player: CharacterBody3D = alternate.get_node("Player")
    var alternate_ability: Node = alternate_player.get_node("ShiftAbility")
    var alternate_guard: Node = alternate.get_node("GuardWest")
    var alternate_hint: Label = alternate.get_node("DockHUD/Hint")
    alternate_player.set_physics_process(false)
    (alternate.get_node("GuardWest") as Node).set_physics_process(false)
    (alternate.get_node("GuardEast") as Node).set_physics_process(false)
    _check(bool(alternate_ability.call("_try_place_at", Vector3(0.0, 0.0, 10.0), Vector3.UP)),
        "Early anchor placement is accepted")
    _check(bool(alternate_ability.call("try_shift")),
        "Early SHIFT is accepted before the player completes rifle onboarding")
    _check(int(alternate.get("step")) == 0 and int(alternate.get("shift_count")) == 1,
        "Early SHIFT is remembered without skipping the movement lesson")
    alternate_guard.call("apply_damage", 0.0)
    _check(not bool(alternate.get("_target_hit")),
        "Invalid or zero damage is not credited as a rifle hit")
    alternate_guard.call("apply_damage", 20.0)
    _check(bool(alternate.get("_target_hit")),
        "Damage to a living guard counts as valid rifle training")
    _check(int(alternate.get("step")) == 0,
        "Guard damage alone cannot skip the movement-area trigger")
    alternate_player.global_position = Vector3(0.0, 1.1, 12.0)
    await _frames(4)
    _check(int(alternate.get("step")) == 4
        and alternate_hint.text.contains("CLEAR BOTH GUARDS"),
        "Previously completed guard hit, anchor and SHIFT advance to combat")
    _check(not bool(alternate.get("is_gate_unlocked")),
        "One damaged guard and an early SHIFT cannot unlock the gate")
    alternate.queue_free()
    await _frames(3)

    if failures.is_empty():
        print("MS-08 SMOKE PASS: guard/dummy onboarding, HUD, gate signs, SHIFT safety, cover, victory/death replay")
        quit(0)
    else:
        printerr("MS-08 SMOKE FAIL: %d checks" % failures.size())
        quit(1)
