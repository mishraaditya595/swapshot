extends SceneTree
## MS-05: controlled physics-time combat, real damage and SHIFT signal lifecycle.

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        printerr("MS-05 FAIL: " + message)


func _frames(count: int) -> void:
    for _frame in range(count):
        await physics_frame


func _barrier(at: Vector3) -> StaticBody3D:
    var solid := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(2.0, 2.6, 0.45)
    shape.shape = box
    solid.add_child(shape)
    solid.position = at
    return solid


func _run() -> void:
    var packed: PackedScene = load("res://scenes/levels/ms05_firefight.tscn")
    _check(packed != null, "Encounter scene must load")
    if packed == null:
        quit(1)
        return

    var encounter: Node3D = packed.instantiate()
    root.add_child(encounter)
    await _frames(5)
    var enemy: StaticBody3D = encounter.get_node("HelixTrooper") as StaticBody3D
    var player: CharacterBody3D = encounter.get_node("Arena/Player") as CharacterBody3D
    var ability: Node = player.get_node("ShiftAbility")
    var rifle: Node = player.get_node("VisualRoot/WeaponPivot/VX7")
    _check(enemy.collision_layer == 1, "VX-7 world hit mask must hit trooper")
    _check(int(rifle.get("hit_mask")) == 1, "Existing rifle hit mask must remain unchanged")
    _check(int(enemy.get("state")) == 0, "Guard starts IDLE")

    # Remove animation timing and player gravity from the test; physics ray queries
    # still run against the real scene's collision bodies.
    enemy.set_physics_process(false)
    player.set_physics_process(false)
    player.global_position = Vector3(8.0, 1.03, 8.0)
    await _frames(3)
    _check(bool(enemy.call("_can_see_player")), "Visible player must clear world+player ray")
    enemy.call("advance_ai", 0.01)
    _check(int(enemy.get("state")) == 1, "Visible player triggers ALERT")
    enemy.call("advance_ai", 0.36)
    _check(int(enemy.get("state")) == 2, "ALERT reaction must reach ATTACK")

    var first_hp: float = float(player.get("health"))
    enemy.call("advance_ai", 0.01)
    _check((enemy.get_node("VisualRoot/WarningFlash") as MeshInstance3D).visible,
        "ATTACK begins visible windup")
    enemy.call("advance_ai", 0.25)
    _check(is_equal_approx(float(player.get("health")), first_hp),
        "Windup must not apply premature damage")
    enemy.call("advance_ai", 0.31)
    var second_hp: float = float(player.get("health"))
    _check(second_hp < first_hp and second_hp >= first_hp - 12.01,
        "Unobstructed enemy shot must apply bounded player damage")
    enemy.call("advance_ai", 0.1)
    _check(is_equal_approx(float(player.get("health")), second_hp),
        "One cooldown must prevent immediate double shots")

    # Cover is introduced after the guard spots the player. It must cancel
    # any attack and block subsequent fire, including late windup frames.
    var wall: StaticBody3D = _barrier(Vector3(8.0, 1.1, 3.5))
    encounter.add_child(wall)
    await _frames(3)
    _check(not bool(enemy.call("_can_see_player")), "Crate blocks player detection")
    enemy.call("advance_ai", 1.5)
    enemy.call("advance_ai", 1.5)
    _check(is_equal_approx(float(player.get("health")), second_hp),
        "Cover must prevent damage through collision")
    _check(int(enemy.get("state")) != 2, "Guard loses active attack behind cover")

    var blocked_echo := Node3D.new()
    encounter.add_child(blocked_echo)
    blocked_echo.global_position = player.global_position
    enemy.call("_on_echo_spawned", blocked_echo, blocked_echo.global_position)
    _check(enemy.get("_echo") == null, "Blocked SHIFT echo must be ignored")
    blocked_echo.queue_free()
    wall.queue_free()
    await _frames(4)

    # A real SHIFT creates a collision-free echo at the departure point.
    enemy.call("advance_ai", 0.01)
    enemy.call("advance_ai", 0.4)
    _check(int(enemy.get("state")) == 2, "Player reacquisition restores ATTACK")
    var anchor: Vector3 = Vector3(10.0, 0.0, 8.0)
    _check(bool(ability.call("_try_place_at", anchor, Vector3.UP)),
        "Real ability must place a valid nearby anchor")
    _check(bool(ability.call("try_shift")), "Real ability SHIFT must succeed")
    var ghost: Node3D = ability.get("echo_instance") as Node3D
    _check(ghost != null, "SHIFT spawns a holographic echo")
    _check(enemy.get("_echo") == ghost, "Nearby unobstructed guard must track echo")
    _check(int(enemy.get("state")) == 1, "Echo interrupts attacking guard")
    var echo_hp: float = float(player.get("health"))
    enemy.call("advance_ai", 0.8)
    _check(is_equal_approx(float(player.get("health")), echo_hp),
        "Echo distraction suppresses enemy fire")
    ability.call("_advance_lifecycle", 1.55)
    _check(enemy.get("_echo") == null, "Echo end signal clears target immediately")
    await _frames(3)
    _check(not is_instance_valid(ghost), "Expired echo is freed")

    enemy.call("advance_ai", 0.1)
    enemy.call("advance_ai", 0.4)
    enemy.call("advance_ai", 0.01)
    enemy.call("advance_ai", 0.56)
    _check(float(player.get("health")) < echo_hp,
        "After echo expiry, enemy reacquires and can damage player")

    # Freed holograms without a matching signal must also be forgotten.
    var orphan := Node3D.new()
    encounter.add_child(orphan)
    orphan.global_position = Vector3(8.0, 1.03, 8.0)
    enemy.call("_on_echo_spawned", orphan, orphan.global_position)
    _check(enemy.get("_echo") == orphan, "Valid echo event retargets guard")
    orphan.queue_free()
    await _frames(2)
    enemy.call("advance_ai", 0.1)
    _check(enemy.get("_echo") == null, "Freed echo cannot remain target")

    var before_death: float = float(enemy.get("health"))
    enemy.call("apply_damage", 20.0)
    _check(float(enemy.get("health")) == before_death - 20.0,
        "apply_damage must reduce enemy health")
    enemy.call("apply_damage", 500.0)
    _check(int(enemy.get("state")) == 3, "Lethal damage enters DEAD state")
    _check(enemy.collision_layer == 0, "Dead guard no longer blocks rifle rays")
    _check(not enemy.is_physics_processing(), "Dead guard AI must stop")
    var player_hp_after_death: float = float(player.get("health"))
    enemy.call("advance_ai", 30.0)
    enemy.call("apply_damage", 20.0)
    _check(float(enemy.get("health")) == 0.0, "Dead guard ignores extra damage")
    _check(float(player.get("health")) == player_hp_after_death,
        "Dead guard must never fire")
    var dead_echo := Node3D.new()
    encounter.add_child(dead_echo)
    enemy.call("_on_echo_spawned", dead_echo, player.global_position)
    _check(enemy.get("_echo") == null, "Dead guard ignores new SHIFT echoes")
    dead_echo.queue_free()

    # Separate rifle test avoids fragile camera reorientation during AI checks.
    var fresh: StaticBody3D = load(
        "res://scenes/enemies/security_trooper.tscn"
    ).instantiate() as StaticBody3D
    encounter.add_child(fresh)
    fresh.global_position = Vector3(10.0, 1.03, -1.0)
    await _frames(3)
    fresh.set_physics_process(false)
    rifle.set("hip_spread_degrees", 0.0)
    rifle.set("ads_spread_degrees", 0.0)
    var camera: Camera3D = player.get_node("CameraPivot/CameraBoom/Camera3D")
    camera.look_at(fresh.global_position + Vector3.UP * 0.15, Vector3.UP)
    var rifle_health: float = float(fresh.get("health"))
    var impact: Dictionary = rifle.call("_resolve_shot")
    _check(bool(impact.get("damaged", false)), "VX-7 must damage a trooper collider")
    _check(float(fresh.get("health")) < rifle_health, "Rifle reduces trooper HP")
    for _shot in range(5):
        rifle.call("_resolve_shot")
    _check(int(fresh.get("state")) == 3, "Rifle can defeat a full-health guard")

    encounter.queue_free()
    await _frames(3)
    _check(not is_instance_valid(enemy), "Scene teardown frees guard")
    if failures.is_empty():
        print("MS-05 SMOKE PASS: states, LOS, cover, cadence, damage, rifle, SHIFT, death and cleanup")
        quit(0)
    else:
        printerr("MS-05 SMOKE FAIL: %d checks" % failures.size())
        quit(1)
