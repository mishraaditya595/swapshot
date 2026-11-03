extends SceneTree
## Headless MS-03 physics safety regression. Manual Web feel is checked separately.
var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        printerr("MS-03 FAIL: " + message)


func _frames(count: int) -> void:
    for frame in range(count):
        await physics_frame


func _make_blocker(at: Vector3) -> StaticBody3D:
    var body := StaticBody3D.new()
    var collider := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.9, 1.8, 0.9)
    collider.shape = box
    body.add_child(collider)
    body.position = at
    return body


func _run() -> void:
    _check(InputMap.has_action("deploy_anchor"), "Q deploy action missing")
    _check(InputMap.has_action("shift_teleport"), "Shift teleport action missing")
    var packed: PackedScene = load("res://scenes/levels/greybox_arena.tscn")
    _check(packed != null, "Arena missing")
    if packed == null:
        quit(1)
        return
    var arena: Node3D = packed.instantiate()
    root.add_child(arena)
    await _frames(8)

    var player: CharacterBody3D = arena.get_node("Player") as CharacterBody3D
    var ability: Node3D = player.get_node("ShiftAbility") as Node3D
    var camera_pivot: Node3D = player.get_node("CameraPivot") as Node3D
    var boom: SpringArm3D = player.get_node("CameraPivot/CameraBoom") as SpringArm3D
    var point := Vector3(0.0, 0.0, 7.0)
    _check(not ability.call("try_shift"), "Cannot SHIFT without an anchor")
    _check(
        not ability.call("_try_place_at", Vector3(0.0, 0.0, -22.0), Vector3.UP),
        "Must reject out-of-range destination"
    )
    _check(
        not ability.call("_try_place_at", point, Vector3.RIGHT),
        "Must reject vertical wall surface"
    )
    _check(
        not ability.call("_try_place_at", Vector3(1.0, 3.5, 7.0), Vector3.UP),
        "Must reject destination without supporting floor"
    )
    _check(
        not ability.call("_try_place_at", Vector3(0.0, 9.0, 7.0), Vector3.UP),
        "Must reject excessive landing height"
    )
    _check(
        not ability.call("_try_place_at", Vector3(3.0, 0.0, -5.0), Vector3.UP),
        "Must reject a landing behind existing cover"
    )
    _check(not ability.get("anchor_active"), "Rejected placements cannot arm anchor")

    # Deployment clearance must check the *whole* capsule, not the point.
    var blocked := _make_blocker(Vector3(0.66, 0.95, 7.0))
    arena.add_child(blocked)
    await _frames(3)
    _check(
        ability.call("_validate_landing", point, Vector3.UP) == "Player capsule would overlap an obstacle",
        "Capsule edge must be rejected by shape overlap, not by line of sight"
    )
    _check(
        not ability.call("_try_place_at", point, Vector3.UP),
        "Must reject a capsule edge overlapping nearby cover"
    )
    _check(not ability.get("anchor_active"), "Blocked placement cannot consume ability")
    blocked.queue_free()
    await _frames(3)

    _check(ability.call("_try_place_at", point, Vector3.UP), "Clear floor must accept anchor")
    _check(ability.get("anchor_active"), "Anchor should become active")
    _check(
        not ability.call("_try_place_at", Vector3(0.0, 0.0, 6.0), Vector3.UP),
        "Active anchor cannot be replaced by spam"
    )

    # Regression from the owner's Nov 3 browser recording: the deployed
    # anchor mesh moved with the player because it inherited Player's
    # transform. Both indicators must use world-space transforms.
    var anchor_marker: MeshInstance3D = ability.get_node("Anchor") as MeshInstance3D
    var preview_marker: MeshInstance3D = ability.get_node("Preview") as MeshInstance3D
    _check(anchor_marker.top_level, "Anchor marker must use world-space transforms")
    _check(preview_marker.top_level, "Preview marker must use world-space transforms")
    var saved_anchor_marker: Vector3 = anchor_marker.global_position
    var saved_anchor_point: Vector3 = ability.get("anchor_point")
    var original_position: Vector3 = player.global_position
    player.global_position += Vector3(1.25, 0.0, 0.0)
    player.rotation.y = 0.6
    await _frames(4)
    _check(
        anchor_marker.global_position.distance_to(saved_anchor_marker) < 0.001,
        "Deployed anchor marker followed player movement or rotation"
    )
    _check(
        anchor_marker.global_position.distance_to(saved_anchor_point + Vector3.UP * 0.045) < 0.001,
        "Anchor marker disagrees with saved teleport destination"
    )
    player.global_position = original_position
    player.rotation.y = 0.0
    player.velocity = Vector3.ZERO
    await _frames(4)

    # A new obstruction may appear after Q and before Left Shift.
    blocked = _make_blocker(Vector3(0.0, 0.95, 7.0))
    arena.add_child(blocked)
    await _frames(3)
    _check(not ability.call("try_shift"), "Occupied landing must reject activation")
    _check(ability.get("anchor_active"), "Rejected activation must retain anchor")
    _check(player.global_position.distance_to(original_position) < 0.01, "Rejected SHIFT moved player")
    blocked.queue_free()
    await _frames(3)

    camera_pivot.rotation.y = 0.75
    boom.rotation.x = -0.22
    player.velocity = Vector3(4.0, -6.0, -3.0)
    _check(ability.call("try_shift"), "Retry after clearing obstruction must work")
    _check(not ability.get("anchor_active"), "Success must consume the anchor")
    _check(
        player.global_position.distance_to(Vector3(0.0, 0.98, 7.0)) < 0.03,
        "SHIFT must land at floor plus collision capsule height"
    )
    _check(player.velocity.is_zero_approx(), "SHIFT must clear unsafe incoming velocity")
    _check(is_equal_approx(camera_pivot.rotation.y, 0.75), "SHIFT snapped camera yaw")
    _check(is_equal_approx(boom.rotation.x, -0.22), "SHIFT snapped camera pitch")
    _check(not ability.call("try_shift"), "Repeated SHIFT cannot use a consumed anchor")

    # MS-04 cooldown must elapse before repeated use.
    ability.call("_advance_lifecycle", 4.0)

    # Repeated landings must not depend on stale state from first activation.
    player.global_position = Vector3(0.0, 0.98, 10.5)
    player.velocity = Vector3.ZERO
    await _frames(4)
    _check(ability.call("_try_place_at", point, Vector3.UP), "Fresh anchor should place again")
    _check(ability.call("try_shift"), "Second safe SHIFT should succeed")

    ability.call("_advance_lifecycle", 4.0)

    # Exercise the real camera-targeted Q path, not only direct validation.
    player.global_position = Vector3(0.0, 0.98, 10.5)
    player.velocity = Vector3.ZERO
    camera_pivot.rotation.y = 0.0
    boom.rotation.x = -0.4
    await _frames(5)
    var camera_hit: Dictionary = ability.call("_aim_surface")
    _check(not camera_hit.is_empty(), "Aim ray must find arena floor")
    _check(ability.call("try_deploy"), "Q deployment must use the camera ray safely")
    _check(ability.call("try_shift"), "Camera-ray anchor must SHIFT safely")

    arena.queue_free()
    if failures.is_empty():
        print("MS-03 SMOKE PASS: range, slope, floor, capsule, anchored visual, revalidation, retry, camera, velocity")
        quit(0)
    else:
        printerr("MS-03 SMOKE FAIL: %d checks" % failures.size())
        quit(1)
