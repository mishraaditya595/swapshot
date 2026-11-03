extends SceneTree
## MS-06: real encounter state, terminal input, SHIFT cleanup and whole-scene replay.

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        printerr("MS-06 FAIL: " + message)


func _frames(count: int) -> void:
    for _frame in range(count):
        await physics_frame


func _run() -> void:
    var scene: PackedScene = load("res://scenes/levels/ms06_firefight.tscn")
    _check(scene != null, "MS-06 mission scene must load")
    if scene == null:
        quit(1)
        return
    var main: PackedScene = load("res://scenes/main.tscn")
    _check(main != null, "Main boot scene must load")
    if main != null:
        var startup: Node = main.instantiate()
        _check(startup.has_node("Firefight/Firefight/Arena/Player"),
            "Main must launch MS-06 encounter")
        startup.free()

    var encounter: Node3D = scene.instantiate()
    root.add_child(encounter)
    current_scene = encounter
    await _frames(8)
    var player: CharacterBody3D = encounter.get_node("Firefight/Arena/Player")
    var hud: Node = player.get_node("CombatHUD")
    var health_label: Label = hud.get_node("Health")
    var health_fill: ColorRect = hud.get_node("HealthBarTrack/HealthBarFill")
    var weapon: Node = player.get_node("VisualRoot/WeaponPivot/VX7")
    var ability: Node = player.get_node("ShiftAbility")
    var result_layer: CanvasLayer = encounter.get_node("Outcome")
    var objective: Label = encounter.get_node("Firefight/EncounterHUD/HelixHint")
    _check(bool(player.get("managed_restart")), "Mission must own keyboard retry")
    _check(bool(player.get("is_alive")) and bool(player.get("controls_enabled")),
        "Player begins fully active")
    _check(is_equal_approx(float(player.get("health")), 100.0), "Player starts at 100 HP")
    _check(int(weapon.get("ammo")) == 24, "Rifle starts with full 24-round magazine")
    _check(int(encounter.call("_remaining_guards")) == 3, "Three guards must be present")
    _check(objective.text.contains("0 / 3"), "Objective starts with explicit progress")
    _check(not result_layer.visible, "Outcome must be hidden during active combat")
    _check(bool(hud.get("mission_managed")), "Encounter must own threat status")
    _check(is_equal_approx(health_fill.scale.x, 1.0), "Health bar starts full")

    player.call("apply_damage", 20.0)
    _check(is_equal_approx(float(player.get("health")), 80.0), "Player takes bounded damage")
    _check(health_label.text.contains("80 / 100"), "HUD tracks current and maximum HP")
    _check(is_equal_approx(health_fill.scale.x, 0.8), "Health bar tracks actual HP")
    _check(not result_layer.visible, "Nonlethal hit cannot end mission")

    var first: Node = encounter.get_node("Firefight/HelixTrooper")
    var second: Node = encounter.get_node("FlankGuard")
    var third: Node = encounter.get_node("UpperGuard")
    for guard: Node in [first, second, third]:
        guard.set_physics_process(false)
    player.set_physics_process(false)
    _check(bool(ability.call("_try_place_at", Vector3(0.0, 0.0, 7.0), Vector3.UP)),
        "Real SHIFT must place a safe anchor in encounter")
    _check(bool(ability.call("try_shift")), "SHIFT should work during mission")
    _check(int(encounter.get("shift_count")) == 1, "Director must count real SHIFT events")
    _check(ability.get("echo_instance") != null, "Teleport leaves echo")
    ability.call("_advance_lifecycle", 1.55)
    _check(ability.get("echo_instance") == null, "Echo expires during active mission")

    first.call("apply_damage", 500.0)
    _check(int(encounter.get("phase")) == 0, "One kill must not cause premature victory")
    _check(objective.text.contains("1 / 3"), "First kill advances objective")
    _check(not hud.get_node("Threat").text.contains("NEUTRALIZED"),
        "One dead guard must not label entire encounter neutralized")
    first.call("apply_damage", 500.0)
    _check(objective.text.contains("1 / 3"), "Repeated death event cannot double-count")
    second.call("apply_damage", 500.0)
    _check(int(encounter.get("phase")) == 0 and objective.text.contains("2 / 3"),
        "Two kills leave one live hostile")
    third.call("apply_damage", 500.0)
    _check(int(encounter.get("phase")) == 1, "Last guard must trigger victory exactly once")
    _check(result_layer.visible and objective.text.contains("MISSION COMPLETE"),
        "Victory overlay and objective must appear")
    _check(not bool(player.get("controls_enabled")), "Victory locks player movement")
    _check(not bool(weapon.call("fire_once")), "Victory prevents further shots")
    _check(not bool(weapon.call("request_reload")), "Victory prevents reload")
    _check(not bool(ability.call("try_deploy")), "Victory disables SHIFT")
    _check(not bool(ability.get("anchor_active")), "Outcome clears anchor")
    _check(ability.get("echo_instance") == null, "Outcome clears echo")
    _check((encounter.get_node("Outcome/Card/Details") as Label).text.contains("3 / 3"),
        "Victory summary reports correct count")
    _check((encounter.get_node("Outcome/Card/Details") as Label).text.contains("SHIFTS  1"),
        "Victory summary reports SHIFT flanks")
    _check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
        "Outcome releases pointer for button access")
    _check(int(encounter.get("phase")) == 1, "No stale callback changes victory state")

    var old_encounter: Node3D = encounter
    encounter.call("request_replay")
    encounter.call("request_replay")
    _check(int(encounter.get("phase")) == 3, "Repeated replay input must be idempotent")
    await _frames(8)
    encounter = current_scene as Node3D
    _check(encounter != null and encounter != old_encounter, "Retry loads a fresh encounter")
    if encounter == null or encounter == old_encounter:
        quit(1)
        return
    _check(not is_instance_valid(old_encounter), "Old scene and signal listeners are freed")
    player = encounter.get_node("Firefight/Arena/Player")
    ability = player.get_node("ShiftAbility")
    weapon = player.get_node("VisualRoot/WeaponPivot/VX7")
    _check(int(encounter.get("phase")) == 0, "Retry returns to ACTIVE")
    _check(is_equal_approx(float(player.get("health")), 100.0), "Retry restores 100 HP")
    _check(int(weapon.get("ammo")) == 24 and not bool(weapon.get("is_reloading")),
        "Retry resets rifle ammo/reload")
    _check(not bool(ability.get("anchor_active")) and ability.get("echo_instance") == null,
        "Retry resets anchor and echo")
    _check(is_equal_approx(float(ability.get("cooldown_remaining_seconds")), 0.0),
        "Retry resets SHIFT cooldown")
    _check(int(encounter.call("_remaining_guards")) == 3, "All guards respawn on replay")
    _check(not (encounter.get_node("Outcome") as CanvasLayer).visible,
        "Fresh run hides terminal overlay")

    weapon.set("ammo", 12)
    _check(bool(weapon.call("request_reload")), "Mid-run reload begins")
    _check(bool(ability.call("_try_place_at", Vector3(0.0, 0.0, 7.0), Vector3.UP)),
        "Anchor can be armed before death")
    player.call("apply_damage", 500.0)
    _check(int(encounter.get("phase")) == 2, "Lethal hit triggers DEFEAT")
    _check((encounter.get_node("Outcome") as CanvasLayer).visible,
        "Death reveals retry overlay")
    _check(not bool(player.get("is_alive")), "Dead player is no longer alive")
    _check(is_equal_approx(float(player.get("health")), 0.0), "Player HP clamps to zero")
    _check(not bool(ability.get("anchor_active")) and int(ability.get("state")) == 3,
        "Death cancels anchor and disables SHIFT")
    _check(not bool(weapon.get("is_reloading")), "Death cancels pending reload")
    _check(not bool(weapon.call("fire_once")), "Dead player cannot shoot")
    _check(not bool(weapon.call("request_reload")), "Dead player cannot reload")
    _check((encounter.get_node("Outcome/Card/Title") as Label).text.contains("DOWN"),
        "Death state uses a distinct message")
    for guard: Node in [
        encounter.get_node("Firefight/HelixTrooper"),
        encounter.get_node("FlankGuard"),
        encounter.get_node("UpperGuard")
    ]:
        guard.call("advance_ai", 20.0)
    _check(is_equal_approx(float(player.get("health")), 0.0),
        "Enemy AI cannot damage an already-dead player further")

    # ReplayButton must use the same safe reload path as Enter.
    var old_death_scene: Node3D = encounter
    (encounter.get_node("Outcome/Card/ReplayButton") as Button).pressed.emit()
    await _frames(8)
    encounter = current_scene as Node3D
    _check(encounter != null and encounter != old_death_scene,
        "Retry button starts another clean run")
    if encounter == null or encounter == old_death_scene:
        quit(1)
        return
    player = encounter.get_node("Firefight/Arena/Player")
    ability = player.get_node("ShiftAbility")
    _check(int(encounter.get("phase")) == 0 and int(encounter.call("_remaining_guards")) == 3,
        "Death retry restores objective and enemy roster")
    _check(float(player.get("health")) == 100.0,
        "Death retry restores full health")
    _check(not bool(ability.get("anchor_active")) and ability.get("echo_instance") == null,
        "Death retry carries no stale SHIFT state")
    _check(not bool(encounter.get("player").get("managed_restart")) == false,
        "New player retains mission-managed replay")

    encounter.queue_free()
    await _frames(3)
    if failures.is_empty():
        print("MS-06 SMOKE PASS: HP, HUD, SHIFT, multi-guard objective, win, death, retry and scene cleanup")
        quit(0)
    else:
        printerr("MS-06 SMOKE FAIL: %d checks" % failures.size())
        quit(1)
