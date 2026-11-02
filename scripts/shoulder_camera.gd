extends Camera3D
## MS-01: the shoulder camera only moves sideways when a sphere can fit.
## The SpringArm3D origin stays on the player's centerline, within the
## capsule silhouette, so its backwards sweep cannot start inside cover.

@export_range(0.0, 1.5, 0.05) var shoulder_offset: float = 0.55
@export_range(0.0, 0.2, 0.005) var clearance_margin: float = 0.04

@onready var camera_boom: SpringArm3D = get_parent() as SpringArm3D
@onready var player: CharacterBody3D = get_node("../../..") as CharacterBody3D


func _physics_process(_delta: float) -> void:
    # SpringArm3D has already moved its direct child along Z. Sweep the
    # shoulder offset from that *safe centerline endpoint*, not from an
    # offset pivot which may be embedded in a wall or corner.
    var shape: Shape3D = camera_boom.shape
    if shape == null:
        position.x = 0.0
        return

    var params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(
        Basis.IDENTITY, camera_boom.to_global(Vector3(0.0, 0.0, position.z))
    )
    params.motion = camera_boom.global_basis.x * shoulder_offset
    params.collision_mask = camera_boom.collision_mask
    params.exclude = [player.get_rid()]
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

    # cast_motion ignores colliders already touching the start shape.
    # In that exceptional case, do not push the camera further sideways.
    if not space.intersect_shape(params, 1).is_empty():
        position.x = 0.0
        return

    var safe: PackedFloat32Array = space.cast_motion(params)
    if safe.is_empty():
        position.x = 0.0
        return
    position.x = maxf(0.0, shoulder_offset * safe[0] - clearance_margin)
