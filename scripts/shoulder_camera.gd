extends Camera3D
## Collision-safe shoulder camera with comfortable obstacle recovery.
##
## SpringArm3D retracts immediately on contact (required for safety). This
## script applies the safe endpoint, but restores the normal follow distance
## and right-shoulder offset gradually instead of snapping in a single frame.
## Once the camera retracts into the player silhouette, its materials become
## fully transparent. The weapon/muzzle geometry and aim rays never move.

@export_range(0.0, 1.5, 0.05) var shoulder_offset: float = 0.55
@export_range(0.0, 0.2, 0.005) var clearance_margin: float = 0.04
@export_range(1.0, 15.0, 0.5) var distance_recovery_speed: float = 5.0
@export_range(1.0, 15.0, 0.5) var shoulder_recovery_speed: float = 3.0
@export_range(0.2, 3.0, 0.05) var fade_full_distance: float = 2.1
@export_range(0.5, 3.5, 0.05) var fade_start_distance: float = 2.85
@export_range(1.0, 15.0, 0.5) var fade_recovery_speed: float = 3.0

@onready var camera_boom: SpringArm3D = get_parent() as SpringArm3D
@onready var player: CharacterBody3D = get_node("../../..") as CharacterBody3D

var _distance: float = 0.0
var _shoulder: float = 0.0
var _visual_opacity: float = 1.0
# A mission may ask for a closer view of enemies by fading only the player's
# rendered suit. Default 1.0 preserves the camera in every other arena.
var external_visual_opacity: float = 1.0
var _side_query: PhysicsShapeQueryParameters3D
var _suit_material: StandardMaterial3D
var _visor_material: StandardMaterial3D
var _fade_materials: Array[StandardMaterial3D] = []


func _ready() -> void:
    _distance = camera_boom.spring_length
    _side_query = PhysicsShapeQueryParameters3D.new()
    _side_query.shape = camera_boom.shape
    _side_query.collision_mask = camera_boom.collision_mask
    _side_query.exclude = [player.get_rid()]

    # GeometryInstance3D.transparency is ignored by the Compatibility
    # renderer. Duplicate the two existing materials and fade their alpha
    # instead, leaving shared scene materials and other players untouched.
    _suit_material = _make_fade_material(player.get_node("VisualRoot/Body") as MeshInstance3D)
    _visor_material = _make_fade_material(player.get_node("VisualRoot/Visor") as MeshInstance3D)
    _fade_materials.append(_suit_material)
    _fade_materials.append(_visor_material)
    # All added character and weapon meshes fade near a retracted lens.
    for child in player.get_node("VisualRoot").find_children("*", "MeshInstance3D", true, false):
        var mesh: MeshInstance3D = child as MeshInstance3D
        if mesh.name == "Body" or mesh.name == "Visor":
            continue
        if mesh.mesh != null and mesh.mesh.surface_get_material(0) is StandardMaterial3D:
            _fade_materials.append(_make_fade_material(mesh))


func _make_fade_material(mesh: MeshInstance3D) -> StandardMaterial3D:
    var original: StandardMaterial3D = mesh.mesh.surface_get_material(0) as StandardMaterial3D
    if original == null:
        push_error("MS-01 camera fade requires a StandardMaterial3D on " + mesh.name)
        return null
    var material: StandardMaterial3D = original.duplicate() as StandardMaterial3D
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh.material_override = material
    return material


func _physics_process(delta: float) -> void:
    # The SpringArm3D updates its direct child before this camera callback.
    # Its Z placement is the safe collision endpoint for this physics frame.
    var safe_distance: float = clampf(position.z, 0.0, camera_boom.spring_length)

    # Never lag *into* an obstruction. Ease only outward when free space
    # returns, eliminating the instant full-distance pop seen in the video.
    _distance = minf(safe_distance, _distance + distance_recovery_speed * delta)
    position.z = _distance

    # Slide right only when the probe can fit beside the safe centerline.
    # Retraction is immediate; lateral recovery is rate-limited as well.
    var allowed_shoulder: float = _safe_shoulder_offset()
    _shoulder = minf(
        allowed_shoulder, _shoulder + shoulder_recovery_speed * delta
    )
    position.x = _shoulder

    _update_player_visibility(delta)


func _safe_shoulder_offset() -> float:
    if _side_query.shape == null:
        return 0.0

    _side_query.transform = Transform3D(
        Basis.IDENTITY, camera_boom.to_global(Vector3(0.0, 0.0, position.z))
    )
    _side_query.motion = camera_boom.global_basis.x * shoulder_offset

    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    # cast_motion skips shapes already overlapping the sweep's starting
    # position; that case must not push the camera further into geometry.
    if not space.intersect_shape(_side_query, 1).is_empty():
        return 0.0

    var safe_fraction: PackedFloat32Array = space.cast_motion(_side_query)
    if safe_fraction.is_empty():
        return 0.0
    return maxf(0.0, shoulder_offset * safe_fraction[0] - clearance_margin)


func _update_player_visibility(delta: float) -> void:
    # Start fading before the suit reaches the lens and hide it completely
    # while the boom is compressed. Alpha is Compatibility-renderer safe.
    var desired_opacity: float = minf(
        smoothstep(fade_full_distance, maxf(fade_full_distance + 0.01, fade_start_distance), _distance),
        clampf(external_visual_opacity, 0.0, 1.0)
    )
    # Hide immediately in a tight space; fade back in smoothly as we leave.
    _visual_opacity = minf(
        desired_opacity, _visual_opacity + fade_recovery_speed * delta
    )

    for material: StandardMaterial3D in _fade_materials:
        if material == null:
            continue
        if absf(material.albedo_color.a - _visual_opacity) < 0.001:
            continue
        var tint: Color = material.albedo_color
        tint.a = _visual_opacity
        material.albedo_color = tint
