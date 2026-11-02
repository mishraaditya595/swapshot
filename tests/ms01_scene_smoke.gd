extends SceneTree
## Headless MS-01 smoke: geometry/inputs/physics. Not a human camera-feel test.

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        printerr("MS-01 FAIL: " + message)


func _run() -> void:
    for action in ["move_forward", "move_backward", "move_left", "move_right", "release_mouse"]:
        _check(InputMap.has_action(action), "Missing InputMap action: " + action)

    var arena_resource: PackedScene = load("res://scenes/levels/greybox_arena.tscn")
    _check(arena_resource != null, "Arena scene could not load")
    if arena_resource == null:
        quit(1)
        return

    var arena: Node3D = arena_resource.instantiate()
    root.add_child(arena)
    await physics_frame
    await physics_frame

    var player: CharacterBody3D = arena.get_node_or_null("Player") as CharacterBody3D
    _check(player != null, "Reusable player scene is missing")
    if player == null:
        quit(1)
        return

    var boom: SpringArm3D = player.get_node_or_null("CameraPivot/CameraBoom") as SpringArm3D
    var camera: Camera3D = player.get_node_or_null("CameraPivot/CameraBoom/Camera3D") as Camera3D
    _check(boom != null and boom.shape != null, "Camera needs a SpringArm shape probe")
    _check(camera != null and camera.current, "Third-person camera must be active")

    var initial_z: float = player.global_position.z
    Input.action_press("move_forward")
    for frame in range(20):
        await physics_frame
    Input.action_release("move_forward")
    _check(player.global_position.z < initial_z - 0.35, "W movement did not advance player")
    for frame in range(65):
        await physics_frame
    _check(player.is_on_floor(), "Player did not settle on ground")
    _check(player.global_position.y > 0.85, "Player fell through the floor")

    # Static colliders must stop movement at the south wall.
    player.global_position = Vector3(0.0, 1.0, 14.5)
    player.velocity = Vector3.ZERO
    await physics_frame
    Input.action_press("move_backward")
    for frame in range(70):
        await physics_frame
    Input.action_release("move_backward")
    _check(player.global_position.z < 15.4, "Player moved through south arena wall")

    # Elevated landing is a physical surface, not merely decorative geometry.
    var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        Vector3(9.0, 5.0, -10.5),
        Vector3(9.0, -1.0, -10.5)
    )
    var landing_hit: Dictionary = arena.get_world_3d().direct_space_state.intersect_ray(ray)
    _check(not landing_hit.is_empty(), "No collider on upper landing")
    if not landing_hit.is_empty():
        _check(landing_hit.position.y > 1.3, "Elevated platform collider is too low")

    arena.queue_free()
    if failures.is_empty():
        print("MS-01 SMOKE PASS: InputMap, movement, ground/wall and elevated collider, camera rig")
        quit(0)
    else:
        printerr("MS-01 SMOKE FAIL: %d check(s)" % failures.size())
        quit(1)
