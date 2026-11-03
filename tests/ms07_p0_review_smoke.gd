extends SceneTree
## MS-07: SHIFT clearance, echo-safe reinforcements, blocked-wave recovery and replay.

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        printerr("MS-07 FAIL: " + message)


func _frames(count: int) -> void:
    for _frame in range(count):
        await physics_frame


func _blocker(parent: Node3D, point: Vector3, width: float = 1.4) -> StaticBody3D:
    var solid := StaticBody3D.new()
    solid.collision_layer = 1
    solid.collision_mask = 1
    solid.global_position = point
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(width, 2.2, width)
    collision.shape = shape
    solid.add_child(collision)
    parent.add_child(solid)
    return solid


func _run() -> void:
    var scene: PackedScene = load("res://scenes/levels/ms06_firefight.tscn")
    _check(scene != null, "P0 encounter resource loads")
    if scene == null:
        quit(1)
        return
    var encounter: Node3D = scene.instantiate()
    root.add_child(encounter)
    current_scene = encounter
    await _frames(8)
    var player: CharacterBody3D = encounter.get_node("Firefight/Arena/Player")
    var ability: Node3D = player.get_node("ShiftAbility")
    var weapon: Node = player.get_node("VisualRoot/WeaponPivot/VX7")
    var reserve: StaticBody3D = encounter.get_node("ReinforcementWest")
    player.set_physics_process(false)
    ability.set_physics_process(false)
    for guard_path: NodePath in [
        NodePath("Firefight/HelixTrooper"),
        NodePath("FlankGuard"),
        NodePath("UpperGuard")
    ]:
        encounter.get_node(guard_path).set_physics_process(false)

    # A live SHIFT echo must exclude an otherwise usable entry point.
    var chosen: Array[Vector3] = []
    var preferred: Vector3 = encounter.call("_find_spawn", reserve, 0, chosen)
    _check(preferred.is_finite(), "A normal reinforcement entry exists")
    if preferred.is_finite():
        ability.call("_spawn_echo", Transform3D(Basis.IDENTITY, preferred))
        _check(ability.get("echo_instance") != null, "Live echo created at available entry")
        var alternative: Vector3 = encounter.call("_find_spawn", reserve, 0, chosen)
        _check(alternative.is_finite() and alternative.distance_to(preferred) >= 2.5,
            "Reinforcements avoid the active echo's position")
        ability.call("_remove_echo")

    # An anchor that was valid during placement can become obstructed.
    var landing: Vector3 = Vector3(0.0, 0.0, 7.0)
    var yaw_before: float = (player.get_node("CameraPivot") as Node3D).rotation.y
    _check(bool(ability.call("_try_place_at", landing, Vector3.UP)),
        "SHIFT anchor places on supported open floor")
    var origin: Vector3 = player.global_position
    var obstacle: StaticBody3D = _blocker(encounter, Vector3(0.0, 1.05, 7.0))
    await _frames(3)
    _check(not bool(ability.call("try_shift")),
        "SHIFT rechecks collision when landing becomes occupied")
    _check(player.global_position.distance_to(origin) < 0.05,
        "Rejected SHIFT does not move the player")
    _check(bool(ability.get("anchor_active"))
        and is_zero_approx(float(ability.get("cooldown_remaining_seconds"))),
        "Rejected SHIFT retains anchor without charging cooldown")
    obstacle.queue_free()
    await _frames(3)
    _check(bool(ability.call("try_shift")), "SHIFT can succeed after the obstruction clears")
    _check(is_equal_approx((player.get_node("CameraPivot") as Node3D).rotation.y, yaw_before),
        "Successful SHIFT preserves camera yaw")
    _check(player.velocity.is_zero_approx(), "Successful SHIFT clears stale movement velocity")
    _check(not bool(ability.call("try_shift")), "Cooldown prevents immediate repeated teleport")
    _check(int(encounter.get("shift_count")) == 1, "Successful SHIFT counted once")
    ability.call("_remove_echo")
    ability.call("_advance_lifecycle", 4.1)
    _check(is_zero_approx(float(ability.get("cooldown_remaining_seconds"))),
        "SHIFT becomes ready after cooldown without leaving stale state")

    # Entire wave blocked: retry without spawning any guard inside solid geometry.
    # Site coordinates match the current MS-06 fixed-entry arena.
    var sites: Array[Vector3] = [
        Vector3(-11.2, 1.03, -10.8), Vector3(0.0, 1.03, -12.8),
        Vector3(10.8, 2.48, -11.0), Vector3(-11.6, 1.03, 8.3),
        Vector3(11.6, 1.03, 8.4), Vector3(-11.6, 1.03, -0.8),
        Vector3(11.7, 1.03, 0.5), Vector3(0.0, 1.03, 13.0)
    ]
    var blockers: Array[StaticBody3D] = []
    for site: Vector3 in sites:
        blockers.append(_blocker(encounter, site))
    await _frames(3)
    for guard_path: NodePath in [
        NodePath("Firefight/HelixTrooper"),
        NodePath("FlankGuard"),
        NodePath("UpperGuard")
    ]:
        encounter.get_node(guard_path).call("apply_damage", 999.0)
    _check(bool(encounter.get("reinforcements_inbound")), "Patrol clear starts wave warning")
    encounter.call("_advance_waves", 4.1)
    _check(bool(encounter.get("reinforcements_inbound"))
        and int(encounter.get("current_wave")) == 1,
        "Blocked entry sites defer wave rather than skipping its objective")
    _check(not bool(reserve.get("combat_enabled")) and reserve.collision_layer == 0,
        "No reinforcement is activated through blocked cover")
    for solid: StaticBody3D in blockers:
        solid.queue_free()
    await _frames(3)
    encounter.call("_advance_waves", 0.1)
    _check(int(encounter.get("current_wave")) == 2
        and not bool(encounter.get("reinforcements_inbound")),
        "Wave proceeds when safe entries become available")
    for guard_path: NodePath in [
        NodePath("ReinforcementWest"),
        NodePath("ReinforcementNorth"),
        NodePath("ReinforcementHigh")
    ]:
        var guard: StaticBody3D = encounter.get_node(guard_path)
        _check(bool(guard.get("combat_enabled")) and guard.collision_layer == 1,
            "Each reserve becomes a live, damageable enemy after clearance")
        guard.set_physics_process(false)
        guard.call("apply_damage", 999.0)
    _check(int(encounter.get("phase")) == 1, "All six kills lead to victory")
    _check((encounter.get_node("Outcome") as CanvasLayer).visible,
        "Victory has a visible replay action")

    encounter.call("request_replay")
    encounter.call("request_replay")
    await _frames(8)
    var replayed: Node3D = current_scene as Node3D
    _check(replayed != null and replayed != encounter,
        "Repeated terminal input schedules only one clean scene restart")
    if replayed != null and replayed != encounter:
        var new_player: CharacterBody3D = replayed.get_node("Firefight/Arena/Player")
        var new_weapon: Node = new_player.get_node("VisualRoot/WeaponPivot/VX7")
        var new_ability: Node = new_player.get_node("ShiftAbility")
        _check(int(replayed.get("phase")) == 0 and int(replayed.get("current_wave")) == 1,
            "Replay resets phase and reinforcement wave")
        _check(is_equal_approx(float(new_player.get("health")), 100.0)
            and int(new_weapon.get("ammo")) == 24,
            "Replay restores armor and full magazine")
        _check(not bool(new_ability.get("anchor_active"))
            and new_ability.get("echo_instance") == null,
            "Replay clears old anchors and decoys")
        _check(int(replayed.call("_remaining_guards")) == 6,
            "Replay restores all six guards")
        replayed.queue_free()
    await _frames(3)

    if failures.is_empty():
        print("MS-07 SMOKE PASS: echo-safe entry, SHIFT revalidation, blocked-wave recovery, replay")
        quit(0)
    else:
        printerr("MS-07 SMOKE FAIL: %d checks" % failures.size())
        quit(1)
