extends Node3D
## MS-03: safe anchor placement and teleport. Lifecycle/cooldown belong to MS-04.

signal anchor_placed(surface_point: Vector3)
signal shifted(from_position: Vector3, to_position: Vector3)
signal placement_rejected(reason: String)
signal shift_rejected(reason: String)

@export_range(1.0, 40.0, 0.5) var max_range_meters: float = 18.0
@export_range(0.0, 75.0, 1.0) var max_slope_degrees: float = 40.0
@export_range(0.5, 8.0, 0.5) var max_height_difference: float = 4.0

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var camera: Camera3D = get_node("../CameraPivot/CameraBoom/Camera3D") as Camera3D
@onready var body_collider: CollisionShape3D = get_node("../CollisionShape3D") as CollisionShape3D
@onready var preview_mesh: MeshInstance3D = $Preview
@onready var anchor_mesh: MeshInstance3D = $Anchor
@onready var status_label: Label = $ShiftHUD/Status

var anchor_active: bool = false
var anchor_point: Vector3 = Vector3.ZERO
var _clearance_shape: CapsuleShape3D
var _valid_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D


func _ready() -> void:
    var capsule: CapsuleShape3D = body_collider.shape as CapsuleShape3D
    if capsule == null:
        push_error("MS-03 SHIFT requires the player's CapsuleShape3D")
        set_physics_process(false)
        return
    # A small margin around the actual player capsule avoids barely touching walls.
    _clearance_shape = CapsuleShape3D.new()
    _clearance_shape.radius = capsule.radius + 0.035
    _clearance_shape.height = capsule.height + 0.08
    _valid_material = _indicator_material(Color(0.32, 0.96, 0.90, 0.8))
    _invalid_material = _indicator_material(Color(1.0, 0.43, 0.24, 0.8))
    anchor_mesh.material_override = _valid_material
    preview_mesh.visible = false
    anchor_mesh.visible = false
    _say("SHIFT  |  Aim at floor, Q deploy")


func _indicator_material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = color
    return material


func _unhandled_input(event: InputEvent) -> void:
    if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        return
    if event is InputEventKey and event.echo:
        return
    if event.is_action_pressed("deploy_anchor"):
        try_deploy()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("shift_teleport"):
        try_shift()
        get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
    # Only the prospective marker follows the reticle. An armed anchor stays put.
    if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or anchor_active:
        preview_mesh.visible = false
        return
    var hit: Dictionary = _aim_surface()
    preview_mesh.visible = not hit.is_empty()
    if hit.is_empty():
        return
    var point: Vector3 = hit["position"]
    var normal: Vector3 = hit["normal"]
    preview_mesh.global_position = point + Vector3.UP * 0.035
    preview_mesh.material_override = (
        _valid_material if _validate_landing(point, normal).is_empty()
        else _invalid_material
    )


func _ray(from: Vector3, to: Vector3, mask: int = 3) -> Dictionary:
    var query := PhysicsRayQueryParameters3D.create(
        from, to, mask, [player.get_rid()]
    )
    query.hit_from_inside = true
    return get_world_3d().direct_space_state.intersect_ray(query)


func _aim_surface() -> Dictionary:
    var origin: Vector3 = camera.global_position
    # Shoulder camera may be several metres behind the player.
    var reach: float = max_range_meters + origin.distance_to(player.global_position) + 1.0
    return _ray(origin, origin - camera.global_basis.z * reach)


func _arrival_origin(surface_point: Vector3) -> Vector3:
    var capsule: CapsuleShape3D = body_collider.shape as CapsuleShape3D
    return surface_point + Vector3.UP * (capsule.height * 0.5 + 0.08)


func _validate_landing(point: Vector3, normal: Vector3) -> String:
    if _clearance_shape == null:
        return "No player collision capsule"
    if player.global_position.distance_to(point) > max_range_meters:
        return "Out of range (18 m)"
    if absf(point.y - player.global_position.y) > max_height_difference:
        return "Landing too far above or below"
    var min_up: float = cos(deg_to_rad(max_slope_degrees))
    if normal.dot(Vector3.UP) < min_up:
        return "Surface is too steep"

    # Player-eye visibility is independent of the offset shoulder camera.
    # The ray stops above the floor so the floor itself is not an obstruction.
    var eye: Vector3 = player.global_position + Vector3.UP * 0.52
    var sight_target: Vector3 = point + Vector3.UP * 0.16
    if not _ray(eye, sight_target).is_empty():
        return "Landing blocked from player"

    # Require level, solid floor under the capsule center AND its perimeter.
    # A point at a ledge may fit the capsule but still have no footing.
    var inset: float = _clearance_shape.radius * 0.85
    var offsets: Array[Vector3] = [
        Vector3.ZERO, Vector3(inset, 0.0, 0.0),
        Vector3(-inset, 0.0, 0.0), Vector3(0.0, 0.0, inset),
        Vector3(0.0, 0.0, -inset)
    ]
    for offset: Vector3 in offsets:
        var support: Dictionary = _ray(
            point + offset + Vector3.UP * 0.34,
            point + offset - Vector3.UP * 0.26,
            1
        )
        if support.is_empty():
            return "No safe floor beneath landing"
        var floor_point: Vector3 = support["position"]
        var floor_normal: Vector3 = support["normal"]
        if absf(floor_point.y - point.y) > 0.14 or floor_normal.dot(Vector3.UP) < min_up:
            return "Floor edge, step or steep surface"

    var shape_query := PhysicsShapeQueryParameters3D.new()
    shape_query.shape = _clearance_shape
    shape_query.transform = Transform3D(Basis.IDENTITY, _arrival_origin(point))
    shape_query.collision_mask = 0xFFFFFFFF
    shape_query.exclude = [player.get_rid()]
    if not get_world_3d().direct_space_state.intersect_shape(shape_query, 16).is_empty():
        return "Player capsule would overlap an obstacle"
    return ""


func _try_place_at(point: Vector3, normal: Vector3) -> bool:
    if anchor_active:
        placement_rejected.emit("Anchor already armed")
        _say("SHIFT  |  Anchor armed; press Left Shift")
        return false
    var problem: String = _validate_landing(point, normal)
    if not problem.is_empty():
        placement_rejected.emit(problem)
        _say("SHIFT BLOCKED  |  " + problem)
        return false
    anchor_point = point
    anchor_active = true
    anchor_mesh.global_position = point + Vector3.UP * 0.045
    anchor_mesh.visible = true
    preview_mesh.visible = false
    anchor_placed.emit(point)
    _say("ANCHOR SET  |  Left Shift to teleport")
    return true


func try_deploy() -> bool:
    if anchor_active:
        return _try_place_at(anchor_point, Vector3.UP)
    var hit: Dictionary = _aim_surface()
    if hit.is_empty():
        placement_rejected.emit("No surface under crosshair")
        _say("SHIFT BLOCKED  |  Aim at a floor")
        return false
    return _try_place_at(hit["position"], hit["normal"])


func try_shift() -> bool:
    if not anchor_active:
        shift_rejected.emit("No anchor")
        _say("SHIFT  |  Deploy with Q first")
        return false
    # Revalidate floor, line of sight, slope, height, distance and FULL
    # capsule clearance at the moment of arrival, not only at placement.
    var problem: String = _validate_landing(anchor_point, Vector3.UP)
    if not problem.is_empty():
        shift_rejected.emit(problem)
        _say("SHIFT BLOCKED  |  " + problem)
        return false

    var previous: Vector3 = player.global_position
    var destination: Vector3 = _arrival_origin(anchor_point)
    player.global_position = destination
    player.velocity = Vector3.ZERO
    player.reset_physics_interpolation()
    anchor_active = false
    anchor_mesh.visible = false
    shifted.emit(previous, destination)
    _say("SHIFT COMPLETE  |  Q to place next anchor")
    return true


func _say(message: String) -> void:
    status_label.text = message
