extends SceneTree
## MS-09 Godot physics smoke: vertical paths, SHIFT safety, staged troopers, terminal and replay.

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")
    call_deferred("_start_watchdog")


# A runtime exception in an awaited smoke test must not leave CI waiting forever.
func _start_watchdog() -> void:
    await create_timer(35.0).timeout
    printerr("MS-09 FAIL: smoke did not finish within 35 seconds")
    quit(1)


func _frames(count: int) -> void:
    for _frame in range(count):
        await physics_frame


func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        printerr("MS-09 FAIL: " + message)


func _blocker(parent: Node3D, where: Vector3, dimensions: Vector3) -> StaticBody3D:
    var solid := StaticBody3D.new()
    solid.collision_layer = 1
    solid.position = where
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = dimensions
    collision.shape = box
    solid.add_child(collision)
    parent.add_child(solid)
    return solid


func _run() -> void:
    var scene: PackedScene = load("res://scenes/levels/security_core.tscn")
    _check(scene != null, "Security Core scene loads")
    if scene == null:
        quit(1)
        return
    var startup_scene: PackedScene = load("res://scenes/main.tscn")
    _check(startup_scene != null, "Preview main scene loads")
    if startup_scene != null:
        var preview: Node = startup_scene.instantiate()
        _check(preview.has_node("SecurityCore/Player"), "Main previews Security Core")
        preview.free()
    var core: Node3D = scene.instantiate()
    root.add_child(core)
    current_scene = core
    await _frames(8)

    var player: CharacterBody3D = core.get_node("Player") as CharacterBody3D
    var ability: Node = player.get_node("ShiftAbility")
    var weapon: Node = player.get_node("VisualRoot/WeaponPivot/VX7")
    var guards: Array[Node] = [
        core.get_node("GuardLowerWest"), core.get_node("GuardLowerEast"),
        core.get_node("GuardUpperEast"), core.get_node("GuardUpperWest")
    ]
    var terminal: StaticBody3D = core.get_node("Terminal") as StaticBody3D
    var objective: Label = core.get_node("CoreHUD/Objective") as Label
    var hint: Label = core.get_node("CoreHUD/Hint") as Label
    var shift_status: Label = ability.get_node("ShiftHUD/Status") as Label
    var shift_timer: Label = ability.get_node("ShiftHUD/Timer") as Label
    _check(bool(player.get("managed_restart")), "Scene owns standalone retry")
    _check(int(core.get("phase")) == 0 and not bool(core.get("upper_active")),
        "Starts in active lower-floor phase")
    _check(core.has_node("WorldGeometry/EastRamp")
        and core.has_node("WorldGeometry/WestRamp")
        and core.has_node("WorldGeometry/NorthWalk")
        and core.has_node("WorldGeometry/WestTerminalDeck"),
        "Both ramps, upper walk and terminal deck exist")
    _check(player.global_position.y > 0.7 and player.global_position.y < 1.4
        and absf(player.global_position.z - 15.0) < 1.0,
        "Player starts at the clear south entrance")
    _check(is_equal_approx(float(player.get("health")), 100.0)
        and int(weapon.get("ammo")) == 24,
        "Health and rifle ammo are fresh")
    _check(objective.text.contains("LOWER") and objective.text.contains("0 / 2"),
        "Lower objective explains the first phase")
    _check(not bool(core.get("is_terminal_unlocked"))
        and not bool(core.get("is_terminal_disabled")),
        "Terminal starts locked")
    _check(not bool(core.call("try_shutdown")), "Early shutdown is rejected")
    _check((core.get_node("CoreHUD/Feedback") as Label).text.contains("LOCKED"),
        "Early shutdown gives a clear reason")
    _check(not bool(guards[2].get("combat_enabled"))
        and not bool(guards[3].get("combat_enabled")),
        "Upper troopers are dormant and non-colliding initially")

    for index: int in [0, 1, 2, 3]:
        guards[index].set_physics_process(false)
    # A real motor traversal up the east ramp, with input and gravity.
    player.global_position = Vector3(10.4, 1.03, 10.5)
    await _frames(5)
    Input.action_press("move_forward")
    await _frames(130)
    Input.action_release("move_forward")
    _check(player.global_position.y > 2.2,
        "East ramp physically elevates the moving player")
    _check(player.global_position.x > 8.0 and player.global_position.x < 12.5,
        "East ramp keeps the player inside its collision-safe lane")
    player.global_position = Vector3(-10.4, 1.03, 10.5)
    player.velocity = Vector3.ZERO
    await _frames(5)
    Input.action_press("move_forward")
    await _frames(130)
    Input.action_release("move_forward")
    _check(player.global_position.y > 2.2
        and player.global_position.x < -8.0,
        "West return ramp also physically reaches the upper deck")
    player.set_physics_process(false)
    player.global_position = Vector3(10.4, 3.93, -3.6)
    player.velocity = Vector3.ZERO
    await _frames(6)

    # Current SHIFT implementation must validate the actual upper floor.
    var elevated: Vector3 = Vector3(10.4, 2.9, -6.5)
    _check(bool(ability.call("_try_place_at", elevated, Vector3.UP)),
        "Valid elevated landing is reachable from the upper ramp approach")
    _check(bool(ability.call("try_shift")),
        "SHIFT crosses from ramp to validated upper landing")
    _check(absf(player.global_position.y - 3.88) < 0.2
        and player.global_position.distance_to(Vector3(10.4, 3.88, -6.5)) < 0.3,
        "Successful elevated SHIFT lands above the platform")
    _check(float(ability.get("cooldown_remaining_seconds")) > 0.0
        and ability.get("echo_instance") != null,
        "SHIFT consumes anchor and generates cooldown and echo")
    _check(not bool(ability.call("try_shift")),
        "Repeated SHIFT during cooldown is rejected")
    ability.call("_advance_lifecycle", 4.1)
    _check(is_zero_approx(float(ability.get("cooldown_remaining_seconds"))),
        "Cooldown completes deterministically")
    ability.call("reset_lifecycle")
    _check(bool(ability.call("_try_place_at", Vector3(0, 2.9, -12.0), Vector3.UP)),
        "Lateral catwalk SHIFT has a clear line over its safety rail")
    _check(bool(ability.call("try_shift")),
        "Lateral elevated SHIFT crosses onto the north catwalk")
    player.global_position = Vector3(0, 3.88, -10.5)
    player.velocity = Vector3.ZERO
    ability.call("reset_lifecycle")
    await _frames(4)
    _check(bool(ability.call("_try_place_at", Vector3(0, 0, -7), Vector3.UP)),
        "Open north overlook permits safe downward anchor placement")
    _check(bool(ability.call("try_shift"))
        and player.global_position.y < 1.3,
        "Downward SHIFT reaches unobstructed lower cover")

    # Expiry and unsafe landing must not spend ability or move the player.
    ability.call("reset_lifecycle")
    player.global_position = Vector3(0, 1.03, 15)
    player.velocity = Vector3.ZERO
    await _frames(5)
    _check(not bool(ability.call("_try_place_at", Vector3(10.4, 2.9, -12.0), Vector3.UP)),
        "Out-of-range elevated placement cannot bypass 18 m limit")
    _check(not bool(ability.get("anchor_active"))
        and is_zero_approx(float(ability.get("cooldown_remaining_seconds"))),
        "Invalid placement leaves charge intact")
    var nearby: Vector3 = Vector3(0, 0, 12.0)
    _check(bool(ability.call("_try_place_at", nearby, Vector3.UP)),
        "Unobstructed lower floor accepts an anchor")
    var obstacle: StaticBody3D = _blocker(core, Vector3(0, 1.0, 12),
        Vector3(1.4, 2.0, 1.4))
    await _frames(3)
    var previous: Vector3 = player.global_position
    _check(not bool(ability.call("try_shift")),
        "Obstructed destination is rejected at activation")
    _check(player.global_position.distance_to(previous) < 0.01
        and is_zero_approx(float(ability.get("cooldown_remaining_seconds"))),
        "Blocked SHIFT preserves player position and cooldown")
    obstacle.queue_free()
    await _frames(3)
    ability.call("_advance_lifecycle", 8.1)
    _check(not bool(ability.get("anchor_active")),
        "Expired anchor clears without teleport")
    _check(is_zero_approx(float(ability.get("cooldown_remaining_seconds"))),
        "Anchor expiry does not start cooldown")

    # Reject a spawn directly under the player or on an active anchor.
    var east: StaticBody3D = guards[2] as StaticBody3D
    player.global_position = Vector3(8.5, 3.93, -12)
    await _frames(3)
    var no_other_spawns: Array[Vector3] = []
    _check(not bool(core.call("_safe_upper_spawn", east,
        Vector3(8.5, 3.93, -12), no_other_spawns)),
        "Upper activation cannot overlap the player")
    player.global_position = Vector3(0, 1.03, 13)
    ability.call("reset_lifecycle")
    ability.set("anchor_active", true)
    ability.set("anchor_point", Vector3(8.5, 2.9, -12.0))
    _check(not bool(core.call("_safe_upper_spawn", east,
        Vector3(8.5, 3.93, -12), no_other_spawns)),
        "Upper spawn rejects positions reserved for an armed anchor")
    ability.call("reset_lifecycle")
    await _frames(4)

    # Actual destroyed signals stage the next encounter.
    guards[0].call("apply_damage", 250.0)
    _check(not bool(core.get("upper_pending")),
        "First lower guard death alone cannot launch upper response")
    guards[1].call("apply_damage", 250.0)
    _check(bool(core.get("upper_pending"))
        and not bool(core.get("upper_active")),
        "Both lower deaths schedule, but do not immediately spawn, upper guards")
    core.set("upper_countdown", 0.0)
    core.call("_physics_process", 0.016)
    await _frames(3)
    _check(bool(core.get("upper_active"))
        and not bool(core.get("upper_pending")),
        "Upper sentries activate after physics-safe placement")
    _check(bool(guards[2].get("combat_enabled"))
        and bool(guards[3].get("combat_enabled")),
        "Both second-stage guards enable together")
    _check(objective.text.contains("UPPER")
        and (core.get_node("CoreHUD/Hint") as Label).text.contains("SHIFT"),
        "Upper phase objective and tactical hint are visible")

    # Eye and muzzle traces must respect real upper geometry and temporary cover.
    player.global_position = Vector3(8.5, 1.03, -12)
    await _frames(4)
    _check(not bool(guards[2].call("_can_see_player")),
        "Upper sentry cannot detect the player through the solid catwalk floor")
    player.global_position = Vector3(8.5, 3.93, -8.0)
    await _frames(4)
    _check(bool(guards[2].call("_can_see_player")),
        "Upper trooper can see a player on the same open catwalk")
    var barrier: StaticBody3D = _blocker(core, Vector3(8.5, 4.1, -10.1),
        Vector3(1.5, 2.6, 0.65))
    await _frames(3)
    _check(not bool(guards[2].call("_can_see_player")),
        "Solid upper-level cover blocks eye line of sight")
    var hp_before: float = float(player.get("health"))
    guards[2].call("_set_state", 2)
    guards[2].call("_fire")
    _check(is_equal_approx(float(player.get("health")), hp_before),
        "Guard does not hit through blocking geometry")
    barrier.queue_free()
    await _frames(3)

    # Upper death and final terminal interaction.
    guards[2].call("apply_damage", 250.0)
    guards[2].call("advance_ai", 5.0)
    _check(int(guards[2].get("state")) == 3
        and is_equal_approx(float(player.get("health")), hp_before),
        "Dead trooper cannot resume combat")
    _check(not bool(core.get("is_terminal_unlocked")),
        "Terminal remains locked with an upper guard alive")
    guards[3].call("apply_damage", 250.0)
    _check(bool(core.get("is_terminal_unlocked"))
        and (terminal.get_node("Status") as Label3D).text.contains("PRESS E"),
        "Four unique guard deaths unlock terminal and change its sign")
    _check(not bool(core.call("try_shutdown")),
        "Distant upper-floor interaction is rejected")
    player.global_position = Vector3(-11.2, 1.03, -13)
    await _frames(3)
    _check(not bool(core.call("try_shutdown")),
        "Terminal cannot activate through the floor from below")
    player.global_position = Vector3(-11.2, 3.93, -12.6)
    await _frames(3)
    var console_blocker: StaticBody3D = _blocker(
        core, Vector3(-11.2, 4.1, -13.35), Vector3(0.9, 1.6, 0.18))
    await _frames(3)
    _check(not bool(core.call("try_shutdown")),
        "Terminal line of sight rejects nearby but obstructed interaction")
    console_blocker.queue_free()
    await _frames(3)
    _check(bool(core.call("try_shutdown")),
        "Near and unobstructed upper-deck E disables the terminal")
    _check(bool(core.get("is_terminal_disabled"))
        and int(core.get("phase")) == 1
        and (core.get_node("Outcome") as CanvasLayer).visible,
        "Terminal shutdown ends the section with a victory panel")
    _check(not bool(core.call("try_shutdown")), "Repeated shutdown cannot complete twice")

    # Only one scene reload, and every transient system returns to fresh state.
    core.call("request_replay")
    _check(int(core.get("phase")) == 3, "Replay enters one RESTARTING state")
    core.call("request_replay")
    await _frames(9)
    var fresh: Node3D = current_scene as Node3D
    _check(fresh != null and fresh.has_node("Player"),
        "Victory replay loads a fresh Security Core")
    if fresh != null and fresh.has_node("Player"):
        var new_player: CharacterBody3D = fresh.get_node("Player") as CharacterBody3D
        var new_ability: Node = new_player.get_node("ShiftAbility")
        var new_rifle: Node = new_player.get_node("VisualRoot/WeaponPivot/VX7")
        _check(int(fresh.get("phase")) == 0
            and not bool(fresh.get("upper_active"))
            and not bool(fresh.get("is_terminal_unlocked"))
            and not bool(fresh.get("is_terminal_disabled")),
            "Replay resets encounter and terminal progression")
        _check(is_equal_approx(float(new_player.get("health")), 100.0)
            and int(new_rifle.get("ammo")) == 24
            and not bool(new_ability.get("anchor_active"))
            and is_zero_approx(float(new_ability.get("cooldown_remaining_seconds"))),
            "Replay resets health, ammunition and SHIFT lifecycle")
        new_player.call("apply_damage", 200.0)
        _check(int(fresh.get("phase")) == 2
            and (fresh.get_node("Outcome") as CanvasLayer).visible,
            "Death exposes a separate defeat and retry path")
        fresh.call("request_replay")
        await _frames(9)
        var death_replay: Node3D = current_scene as Node3D
        _check(death_replay != null and int(death_replay.get("phase")) == 0
            and is_equal_approx(float(death_replay.get_node("Player").get("health")), 100.0),
            "Death retry restores active scene and full armor")

    # Compact Web HUD must preserve separation of core objectives and SHIFT.
    var active: Node3D = current_scene as Node3D
    if active != null:
        var status: Label = active.get_node("Player/ShiftAbility/ShiftHUD/Status") as Label
        var timer: Label = active.get_node("Player/ShiftAbility/ShiftHUD/Timer") as Label
        var old_size: Vector2i = root.size
        root.size = Vector2i(960, 540)
        await _frames(3)
        for panel: Label in [
            active.get_node("CoreHUD/Objective") as Label,
            active.get_node("CoreHUD/Hint") as Label,
            active.get_node("CoreHUD/Clock") as Label,
            active.get_node("Player/CombatHUD/Ammo") as Label
        ]:
            _check(not status.get_global_rect().intersects(panel.get_global_rect())
                and not timer.get_global_rect().intersects(panel.get_global_rect()),
                "Compact Web HUD keeps SHIFT status clear of objectives and ammo")
        _check(not status.get_global_rect().intersects(timer.get_global_rect()),
            "SHIFT timer and status remain separate")
        root.size = old_size

    if failures.is_empty():
        print("MS-09 SMOKE PASS: vertical paths, SHIFT safety, staged troopers, cover, terminal, replay")
        quit(0)
    else:
        printerr("MS-09 FAILED: %d checks" % failures.size())
        quit(1)
