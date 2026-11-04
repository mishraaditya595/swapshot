extends SceneTree
## MS-10 physics smoke: core, two-stage lockdown, safe spawns, waiver and replay.

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")
    call_deferred("_watchdog")


func _watchdog() -> void:
    await create_timer(42.0).timeout
    printerr("MS-10 FAIL: smoke exceeded 42-second watchdog")
    quit(1)


func _frames(count: int) -> void:
    for _index in range(count):
        await physics_frame


func _check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        printerr("MS-10 FAIL: " + message)


func _blocker(parent: Node3D, location: Vector3, size: Vector3) -> StaticBody3D:
    var solid := StaticBody3D.new()
    solid.collision_layer = 1
    solid.position = location
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    solid.add_child(collider)
    parent.add_child(solid)
    return solid


func _run() -> void:
    var packed: PackedScene = load("res://scenes/levels/extraction.tscn")
    _check(packed != null, "Extraction standalone scene loads")
    if packed == null:
        quit(1)
        return
    var preview_scene: PackedScene = load("res://scenes/main.tscn")
    if preview_scene != null:
        var preview: Node = preview_scene.instantiate()
        _check(preview.has_node("Extraction/Player"), "Main previews Extraction")
        preview.free()
    else:
        _check(false, "Main preview loads")

    var extraction: Node3D = packed.instantiate()
    root.add_child(extraction)
    current_scene = extraction
    await _frames(20)

    var player: CharacterBody3D = extraction.get_node("Player") as CharacterBody3D
    var ability: Node = player.get_node("ShiftAbility")
    var weapon: Node = player.get_node("VisualRoot/WeaponPivot/VX7")
    var upper: Array[Node] = [
        extraction.get_node("GuardUpperWest"),
        extraction.get_node("GuardUpperEast")
    ]
    var lower: Array[Node] = [
        extraction.get_node("GuardLowerMid"),
        extraction.get_node("GuardLowerExit")
    ]
    for guard: Node in upper + lower:
        guard.set_physics_process(false)
        _check(not bool(guard.get("combat_enabled"))
            and (guard as CollisionObject3D).collision_layer == 0,
            "Each reserve guard starts invisible and non-colliding")

    _check(int(extraction.get("phase")) == 0
        and not bool(extraction.get("core_collected"))
        and not bool(extraction.get("extraction_done")),
        "Starts in RETRIEVE with core intact and exit locked")
    _check(is_equal_approx(float(player.get("health")), 100.0)
        and int(weapon.get("ammo")) == 24
        and not bool(ability.get("anchor_active")),
        "Fresh armor, ammo and SHIFT lifecycle")
    _check(extraction.has_node("WorldGeometry/WestRamp")
        and extraction.has_node("WorldGeometry/NorthGantry")
        and extraction.has_node("WorldGeometry/EastOverlook")
        and extraction.has_node("WorldGeometry/LowerDropPad"),
        "Collision greybox and both SHIFT decks are built")
    _check(extraction.has_node("WorldGeometry/UpperWestCoverAccentTop")
        and extraction.has_node("WorldGeometry/LowerWestCoverAccentTop")
        and extraction.has_node("WorldGeometry/ShuttleCoverAccentTop")
        and extraction.has_node("WorldGeometry/CargoWestAccentSide"),
        "Upper, lower, shuttle and cargo covers have distinct visual accent strips")
    _check(extraction.get_node("WorldGeometry/UpperWestCoverAccentTop") is MeshInstance3D
        and not extraction.get_node("WorldGeometry/UpperWestCoverAccentTop") is CollisionObject3D,
        "Decorative accents cannot modify physics or SHIFT traces")
    _check(player.global_position.x < -8.0 and player.global_position.z > 14.0
        and player.is_on_floor(), "Southwest entrance has supported ground")
    _check((extraction.get_node("ExtractionHUD/Objective") as Label).text.contains("CORE")
        and not (extraction.get_node("Outcome") as CanvasLayer).visible,
        "Initial objective is readable and result is hidden")
    var core_sign: Label3D = extraction.get_node("ExperimentalCore/Status") as Label3D
    var exit_sign: Label3D = extraction.get_node("ExtractionGate/Status") as Label3D
    _check(core_sign.visible, "Core prompt is visible before pickup")
    _check(core_sign.font_size <= 30 and core_sign.pixel_size < 0.0041,
        "Core prompt uses compact world-space text sizing")
    _check(exit_sign.text == "EXIT LOCKED"
        and exit_sign.font_size <= 40 and exit_sign.pixel_size <= 0.005,
        "Gate label is short enough to fit on the physical sign panel")
    _check(not bool(extraction.call("try_extract")), "Early extraction is rejected")
    _check(not bool(extraction.call("try_collect_core")), "Remote pickup is rejected")

    # Interaction must not use 3-D proximity to bypass the upper floor.
    player.set_physics_process(false)
    player.global_position = Vector3(0, 1.03, -10.9)
    await _frames(4)
    _check(not bool(extraction.call("try_collect_core")),
        "Pickup beneath the gantry is rejected")
    player.global_position = Vector3(0, 3.93, -9.7)
    await _frames(4)
    var occluder: StaticBody3D = _blocker(extraction,
        Vector3(0, 4.1, -10.3), Vector3(1.1, 1.8, 0.20))
    await _frames(3)
    _check(not bool(extraction.call("try_collect_core")),
        "Physical cover blocks pickup ray")
    occluder.queue_free()
    await _frames(4)

    # Landing safety is the shared MS-03/MS-04 ability, unchanged.
    player.global_position = Vector3(-11.0, 3.93, -3.6)
    await _frames(4)
    _check(bool(ability.call("_try_place_at", Vector3(-11.0, 2.9, -6.5), Vector3.UP)),
        "West ramp offers an upper SHIFT landing")
    _check(bool(ability.call("try_shift")), "SHIFT reaches a supported upper pad")
    ability.call("reset_lifecycle")
    player.global_position = Vector3(-7.3, 3.93, -10.5)
    await _frames(4)
    _check(bool(ability.call("_try_place_at", Vector3(7.3, 2.9, -10.5), Vector3.UP)),
        "Cross-gantry flank offers a visible SHIFT destination")
    _check(bool(ability.call("try_shift")), "SHIFT traverses the upper gantry")
    ability.call("reset_lifecycle")
    player.global_position = Vector3(0, 3.88, -10.5)
    await _frames(4)
    _check(bool(ability.call("_try_place_at", Vector3(0, 0, -6.7), Vector3.UP)),
        "Open gantry edge permits a safe downward anchor")
    _check(bool(ability.call("try_shift")) and player.global_position.y < 1.4,
        "Downward SHIFT lands on the lower bay")
    ability.call("reset_lifecycle")
    player.global_position = Vector3(-11, 1.03, 16)
    await _frames(4)
    _check(not bool(ability.call("_try_place_at", Vector3(10, 2.9, -12), Vector3.UP)),
        "Distant upper destination fails range validation")
    _check(not bool(ability.get("anchor_active"))
        and is_zero_approx(float(ability.get("cooldown_remaining_seconds"))),
        "Rejected SHIFT does not consume resources")
    _check(bool(ability.call("_try_place_at", Vector3(-8.0, 0, 15), Vector3.UP)),
        "Clear lower reposition anchor is accepted")
    var shift_blocker: StaticBody3D = _blocker(extraction,
        Vector3(-8.0, 1.0, 15), Vector3(1.4, 2.0, 1.4))
    await _frames(3)
    var old_position: Vector3 = player.global_position
    _check(not bool(ability.call("try_shift")), "Blocked SHIFT revalidates at activation")
    _check(player.global_position.distance_to(old_position) < 0.01
        and is_zero_approx(float(ability.get("cooldown_remaining_seconds"))),
        "Failed activation leaves player and cooldown intact")
    shift_blocker.queue_free()
    ability.call("reset_lifecycle")
    await _frames(4)

    # Core pickup and first warning are one-shot; no guard is live yet.
    player.global_position = Vector3(0, 3.93, -9.7)
    await _frames(4)
    _check(bool(extraction.call("try_collect_core")), "Near, visible E takes core once")
    _check(bool(extraction.get("core_collected"))
        and int(extraction.get("phase")) == 1
        and not (extraction.get_node("ExperimentalCore/CoreCrystal") as MeshInstance3D).visible,
        "Pickup hides core and queues UPPER_WARNING")
    _check(not core_sign.visible
        and (extraction.get_node("ExtractionHUD/Feedback") as Label).text.contains("CORE SECURED"),
        "Core confirmation moves to HUD and 3D sign vanishes before the firefight")
    _check(not bool(extraction.call("try_collect_core")),
        "Duplicate pickup cannot launch another wave")
    _check(not bool(extraction.call("try_extract")),
        "Extraction stays locked through upper warning")

    var trial: Array[Vector3] = []
    player.global_position = Vector3(-9, 3.93, -12)
    await _frames(3)
    _check(not bool(extraction.call("_safe_spawn", upper[0],
        Vector3(-9, 3.93, -12), trial, 2.9)),
        "Upper candidate directly on player is invalid")
    player.global_position = Vector3(0, 3.93, -9.7)
    ability.set("anchor_active", true)
    ability.set("anchor_point", Vector3(-9, 2.9, -12))
    _check(not bool(extraction.call("_safe_spawn", upper[0],
        Vector3(-9, 3.93, -12), trial, 2.9)),
        "Armed anchor protects the upper spawn pad")
    ability.call("reset_lifecycle")
    extraction.set("warning_remaining", 0.0)
    extraction.set("retry_remaining", 0.0)
    extraction.call("_physics_process", 0.26)
    await _frames(3)
    _check(int(extraction.get("phase")) == 2
        and bool(upper[0].get("combat_enabled"))
        and bool(upper[1].get("combat_enabled")),
        "Two upper guards activate atomically")
    _check((upper[0] as Node3D).global_position.distance_to(
        (upper[1] as Node3D).global_position) >= 2.0,
        "Upper guards never overlap each other")
    _check(not bool(extraction.call("try_extract")),
        "Gate cannot be unlocked during upper combat")

    player.global_position = Vector3(-9, 1.03, -12)
    await _frames(4)
    _check(not bool(upper[0].call("_can_see_player")),
        "Solid gantry blocks upper-to-lower enemy sightline")

    var hit_mesh: MeshInstance3D = upper[0].get_node("VisualRoot/ImpactPulse") as MeshInstance3D
    var hit_visual: Node3D = upper[0].get_node("VisualRoot") as Node3D
    _check(not hit_mesh.visible, "Inactive trooper impact flash is hidden")
    upper[0].call("apply_damage", 16.0)
    _check(hit_mesh.visible and hit_visual.rotation.x < -0.05,
        "Live damaging hit triggers impact flash and small armor recoil")
    await _frames(20)
    _check(not hit_mesh.visible and absf(hit_visual.rotation.x) < 0.01,
        "Visual recoil and flash end without modifying enemy state or aim")
    _check(int(upper[0].get("state")) != 3
        and is_equal_approx(float(upper[0].get("health")), 84.0),
        "A nonlethal hit keeps the original 100 HP combat contract")

    upper[0].call("apply_damage", 250.0)
    _check(not hit_mesh.visible, "Fatal hit leaves no lingering impact flash")
    _check(int(extraction.get("phase")) == 2,
        "One destroyed upper guard cannot resolve the group")
    upper[0].call("advance_ai", 5.0)
    _check(int(upper[0].get("state")) == 3,
        "Destroyed guard stays dead after AI advances")
    upper[0].emit_signal("destroyed")
    _check(int(extraction.get("_defeated").size()) == 1,
        "Duplicate destruction cannot inflate kill count")
    upper[1].call("apply_damage", 250.0)
    _check(int(extraction.get("phase")) == 3
        and bool(extraction.get("upper_resolved")),
        "Upper clear starts lower warning")

    player.global_position = Vector3(-11, 3.93, -7)
    extraction.set("warning_remaining", 0.0)
    extraction.set("retry_remaining", 0.0)
    extraction.call("_physics_process", 0.26)
    await _frames(3)
    _check(int(extraction.get("phase")) == 4
        and bool(lower[0].get("combat_enabled"))
        and bool(lower[1].get("combat_enabled")),
        "Two lower guards activate on supported ground")
    _check(not bool(extraction.call("try_extract")),
        "Live lower sentries keep extraction locked")

    player.global_position = Vector3(2, 1.03, 11)
    await _frames(4)
    var cover: StaticBody3D = _blocker(extraction,
        Vector3(2, 1.5, 9.0), Vector3(2.0, 2.5, 0.7))
    await _frames(4)
    _check(not bool(lower[0].call("_can_see_player")),
        "Physical cover prevents lower guard sight")
    var before_hp: float = float(player.get("health"))
    lower[0].call("_set_state", 2)
    lower[0].call("_fire")
    _check(is_equal_approx(float(player.get("health")), before_hp),
        "Guard muzzle cannot shoot through cover")
    cover.queue_free()
    await _frames(3)

    lower[0].call("apply_damage", 250.0)
    _check(int(extraction.get("phase")) == 4,
        "One live lower sentry still blocks extraction")
    lower[1].call("apply_damage", 250.0)
    _check(int(extraction.get("phase")) == 5
        and bool(extraction.get("lower_resolved"))
        and exit_sign.text == "EXIT READY\nPRESS E",
        "Lower clear exposes a compact cyan extraction prompt")
    _check(not bool(extraction.call("try_extract")),
        "Remote extraction is rejected")
    player.global_position = Vector3(11, 3.93, 16.0)
    await _frames(3)
    _check(not bool(extraction.call("try_extract")),
        "Wrong-floor extraction is rejected")
    player.global_position = Vector3(11, 1.03, 15.8)
    await _frames(3)
    var exit_cover: StaticBody3D = _blocker(extraction,
        Vector3(11, 1.35, 16.45), Vector3(2.2, 2.2, 0.18))
    await _frames(3)
    _check(not bool(extraction.call("try_extract")),
        "Nearby extraction through solid cover is rejected")
    exit_cover.queue_free()
    await _frames(4)
    _check(bool(extraction.call("try_extract")), "Near clear E extracts core once")
    _check(not bool(extraction.call("try_extract")),
        "Second extraction cannot emit another victory")
    _check(int(extraction.get("phase")) == 6
        and (extraction.get_node("Outcome") as CanvasLayer).visible,
        "Victory stops combat and shows outcome")
    _check((extraction.get_node("Outcome/Card/Details") as Label).text.contains("4 / 4"),
        "Outcome counts only four genuinely defeated guards")

    extraction.call("request_replay")
    _check(int(extraction.get("phase")) == 8, "Victory replay starts one reload")
    extraction.call("request_replay")
    await _frames(9)
    var new_run: Node3D = current_scene as Node3D
    _check(new_run != null and int(new_run.get("phase")) == 0
        and not bool(new_run.get("core_collected"))
        and not bool(new_run.get("extraction_done")),
        "Victory replay restores core and locked gate")
    if new_run != null:
        var fresh_player: CharacterBody3D = new_run.get_node("Player") as CharacterBody3D
        var fresh_ability: Node = fresh_player.get_node("ShiftAbility")
        var fresh_rifle: Node = fresh_player.get_node("VisualRoot/WeaponPivot/VX7")
        _check(is_equal_approx(float(fresh_player.get("health")), 100.0)
            and int(fresh_rifle.get("ammo")) == 24
            and not bool(fresh_ability.get("anchor_active"))
            and is_zero_approx(float(fresh_ability.get("cooldown_remaining_seconds"))),
            "Victory replay refreshes HP, rifle and SHIFT")

        # All three pads per upper guard are physically obstructed.
        var blocked_west: StaticBody3D = _blocker(new_run,
            Vector3(-10, 4.0, -15), Vector3(6, 2.8, 8))
        var blocked_east: StaticBody3D = _blocker(new_run,
            Vector3(10, 4.0, -15), Vector3(6, 2.8, 8))
        fresh_player.set_physics_process(false)
        fresh_player.global_position = Vector3(0, 3.93, -9.7)
        await _frames(5)
        _check(bool(new_run.call("try_collect_core")), "Waiver run collects core")
        new_run.set("warning_remaining", 0.0)
        new_run.set("retry_remaining", 0.0)
        new_run.call("_physics_process", 0.26)
        _check(int(new_run.get("phase")) == 1
            and not bool(new_run.get("upper_resolved")),
            "Blocked pads first retry instead of unsafe partial spawn")
        new_run.set("retry_elapsed", 8.0)
        new_run.set("retry_remaining", 0.0)
        new_run.call("_physics_process", 0.26)
        _check(bool(new_run.get("upper_resolved"))
            and int(new_run.get("phase")) == 3,
            "Eight-second blocked upper wave advances to lower response")
        _check((new_run.get("waived_waves") as Array).has("UPPER")
            and (new_run.get("_defeated") as Array).is_empty(),
            "Waived guards never become defeated kills")
        blocked_west.queue_free()
        blocked_east.queue_free()
        await _frames(4)
        # Death during warning must cancel all pending enemy entry.
        fresh_player.call("apply_damage", 250.0)
        _check(int(new_run.get("phase")) == 7
            and (new_run.get_node("Outcome") as CanvasLayer).visible,
            "Death during lower warning produces defeat")
        new_run.call("_physics_process", 20.0)
        _check(int(new_run.get("phase")) == 7,
            "Death cancels future deployments")
        new_run.call("request_replay")
        await _frames(9)
        var retry: Node3D = current_scene as Node3D
        _check(retry != null and int(retry.get("phase")) == 0
            and (retry.get("waived_waves") as Array).is_empty()
            and not (retry.get_node("Outcome") as CanvasLayer).visible,
            "Death retry restores fresh fight and clears waived state")
        if retry != null:
            var old_size: Vector2i = root.size
            root.size = Vector2i(960, 540)
            await _frames(4)
            var shift_status: Label = retry.get_node("Player/ShiftAbility/ShiftHUD/Status") as Label
            var shift_timer: Label = retry.get_node("Player/ShiftAbility/ShiftHUD/Timer") as Label
            for label: Label in [
                retry.get_node("ExtractionHUD/Objective") as Label,
                retry.get_node("ExtractionHUD/Hint") as Label,
                retry.get_node("ExtractionHUD/Clock") as Label,
                retry.get_node("Player/CombatHUD/Ammo") as Label
            ]:
                _check(not shift_status.get_global_rect().intersects(label.get_global_rect())
                    and not shift_timer.get_global_rect().intersects(label.get_global_rect()),
                    "960x540 mission/ammo labels do not overlap SHIFT")
            _check(not shift_status.get_global_rect().intersects(shift_timer.get_global_rect()),
                "SHIFT status and timer do not overlap")
            root.size = old_size

    if failures.is_empty():
        print("MS-10 SMOKE PASS: core, decks, SHIFT, two waves, LOS, waiver, extraction, replay")
        quit(0)
    else:
        printerr("MS-10 FAILED: %d checks" % failures.size())
        quit(1)
