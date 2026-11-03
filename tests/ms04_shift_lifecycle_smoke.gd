extends SceneTree
## Physics-time lifecycle regression; manual Web QA is separate.
var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        printerr("MS-04 FAIL: " + message)


func _frames(count: int) -> void:
    for frame in range(count):
        await physics_frame


func _blocker(at: Vector3) -> StaticBody3D:
    var body := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.9, 1.8, 0.9)
    shape.shape = box
    body.add_child(shape)
    body.position = at
    return body


func _run() -> void:
    var scene: PackedScene = load("res://scenes/levels/greybox_arena.tscn")
    _check(scene != null, "Arena must load")
    if scene == null:
        quit(1)
        return
    var arena: Node3D = scene.instantiate()
    root.add_child(arena)
    await _frames(8)
    var player: CharacterBody3D = arena.get_node("Player") as CharacterBody3D
    var ability: Node = player.get_node("ShiftAbility")
    var point := Vector3(0.0, 0.0, 7.0)
    var original: Vector3 = player.global_position
    var expired := [0]
    var spawned := [0]
    var ended := [0]
    var recharged := [0]
    var states: Array[int] = []
    ability.connect("anchor_expired", func(_at: Vector3) -> void: expired[0] += 1)
    ability.connect("echo_spawned", func(_ghost: Node3D, _at: Vector3) -> void: spawned[0] += 1)
    ability.connect("echo_ended", func(_at: Vector3) -> void: ended[0] += 1)
    ability.connect("cooldown_finished", func() -> void: recharged[0] += 1)
    ability.connect("state_changed", func(next: int) -> void: states.append(next))

    _check(int(ability.get("state")) == 0, "Ability must start READY")
    _check(ability.call("_try_place_at", point, Vector3.UP), "Q must place a valid anchor")
    _check(is_equal_approx(float(ability.get("anchor_remaining_seconds")), 8.0), "Anchor must start with eight seconds")
    ability.call("_advance_lifecycle", 3.0)
    var remaining: float = ability.get("anchor_remaining_seconds")
    _check(not ability.call("_try_place_at", point, Vector3.UP), "Repeated Q must be rejected")
    _check(is_equal_approx(float(ability.get("anchor_remaining_seconds")), remaining), "Q must not refresh timer")
    ability.call("_advance_lifecycle", 5.0)
    _check(not ability.get("anchor_active"), "Eight seconds must expire anchor")
    _check(expired[0] == 1, "Expiry must emit one signal")
    _check(int(ability.get("state")) == 0, "Expiry must return READY")
    _check(not ability.call("try_shift"), "Expired anchor cannot SHIFT")
    _check(float(ability.get("cooldown_remaining_seconds")) == 0.0, "Expiry must not consume cooldown")
    _check(player.global_position.distance_to(original) < 0.01, "Expiry cannot move player")

    _check(ability.call("_try_place_at", point, Vector3.UP), "Anchor can be redeployed after expiry")
    var blocker: StaticBody3D = _blocker(Vector3(0.0, 0.95, 7.0))
    arena.add_child(blocker)
    await _frames(3)
    remaining = ability.get("anchor_remaining_seconds")
    _check(not ability.call("try_shift"), "Dynamic occupied landing must reject")
    _check(ability.get("anchor_active"), "Rejection must retain anchor")
    _check(is_equal_approx(float(ability.get("anchor_remaining_seconds")), remaining), "Rejection must preserve anchor timer")
    _check(float(ability.get("cooldown_remaining_seconds")) == 0.0, "Rejection must not start cooldown")
    blocker.queue_free()
    await _frames(3)

    var departure: Vector3 = player.get_node("VisualRoot").global_position
    _check(ability.call("try_shift"), "Clear landing must SHIFT")
    _check(not ability.get("anchor_active"), "Success consumes anchor")
    _check(int(ability.get("state")) == 2, "Success starts COOLDOWN")
    _check(is_equal_approx(float(ability.get("cooldown_remaining_seconds")), 4.0), "Cooldown starts at four seconds")
    var echo: Node3D = ability.get("echo_instance") as Node3D
    _check(echo != null, "SHIFT spawns an echo")
    if echo != null:
        _check(echo.top_level, "Echo must be in world space")
        _check(echo.global_position.distance_to(departure) < 0.01, "Echo stays at departure")
        _check(echo.find_children("*", "CollisionShape3D").is_empty(), "Echo must have no physics collider")
    _check(spawned[0] == 1, "One echo spawn signal must fire")
    _check(not ability.call("try_deploy"), "Q during cooldown must be rejected")
    _check(not ability.call("try_shift"), "Shift during cooldown must be rejected")
    _check(not ability.get("anchor_active"), "Spam cannot place another anchor")

    var cooldown_before_pause: float = ability.get("cooldown_remaining_seconds")
    paused = true
    ability.call("_advance_lifecycle", 10.0)
    _check(is_equal_approx(float(ability.get("cooldown_remaining_seconds")), cooldown_before_pause), "Pause must freeze cooldown")
    _check(not ability.call("try_deploy") and not ability.call("try_shift"), "Pause must block ability inputs")
    paused = false
    ability.call("_advance_lifecycle", 1.40)
    _check(ability.get("echo_instance") != null, "Echo survives before 1.5 seconds")
    ability.call("_advance_lifecycle", 0.15)
    _check(ability.get("echo_instance") == null, "Echo ends after 1.5 seconds")
    _check(ended[0] == 1, "Echo end signal must fire once")
    await _frames(2)
    if echo != null:
        _check(not is_instance_valid(echo), "Echo must be freed")
    _check(float(ability.get("cooldown_remaining_seconds")) > 0.0, "Echo expiry must not cancel cooldown")
    ability.call("_advance_lifecycle", 4.0)
    _check(float(ability.get("cooldown_remaining_seconds")) == 0.0, "Cooldown must reach zero")
    _check(int(ability.get("state")) == 0 and recharged[0] == 1, "Cooldown ends once and returns READY")

    _check(ability.call("_try_place_at", point, Vector3.UP), "Ready device can deploy again")
    ability.call("set_owner_alive", false)
    _check(not ability.get("anchor_active"), "Death clears anchor")
    _check(int(ability.get("state")) == 3, "Death disables device")
    _check(not ability.call("try_shift") and not ability.call("try_deploy"), "Dead player cannot use ability")
    ability.call("set_owner_alive", true)
    _check(int(ability.get("state")) == 0, "Respawn resets device")
    _check(ability.call("_try_place_at", point, Vector3.UP), "Respawn permits anchor")
    _check(ability.call("try_shift"), "Respawn permits SHIFT")
    var final_echo: Node3D = ability.get("echo_instance") as Node3D
    ability.call("set_owner_alive", false)
    _check(ability.get("echo_instance") == null, "Death removes echo")
    await _frames(2)
    if final_echo != null:
        _check(not is_instance_valid(final_echo), "Death frees echo")
    _check(ended[0] == 2, "Death notifies echo end")
    _check(states.has(1) and states.has(2) and states.has(3), "State signals must cover active, cooldown and disabled")

    arena.queue_free()
    await _frames(3)
    var reloaded: Node3D = scene.instantiate()
    root.add_child(reloaded)
    await _frames(8)
    var fresh: Node = reloaded.get_node("Player/ShiftAbility")
    _check(int(fresh.get("state")) == 0, "Reload starts ready")
    _check(fresh.get("echo_instance") == null, "Reload has no stale echo")
    _check(float(fresh.get("cooldown_remaining_seconds")) == 0.0, "Reload has no cooldown")
    reloaded.queue_free()
    await _frames(2)
    if failures.is_empty():
        print("MS-04 SMOKE PASS: expiry, cooldown, repeat input, rejection, pause, echo, death, reload and signals")
        quit(0)
    else:
        printerr("MS-04 SMOKE FAIL: %d checks" % failures.size())
        quit(1)
