extends Node3D
## Transient, low-poly combat VFX. No external textures or Web-heavy particles.
var _tracer_mat: StandardMaterial3D
var _impact_mat: StandardMaterial3D


func _ready() -> void:
    _tracer_mat = StandardMaterial3D.new()
    _tracer_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _tracer_mat.albedo_color = Color(1.0, 0.79, 0.43, 1.0)
    _impact_mat = StandardMaterial3D.new()
    _impact_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _impact_mat.albedo_color = Color(1.0, 0.47, 0.18, 1.0)


func _make_transient(mesh: Mesh, material: Material, where: Vector3, lifetime: float) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.material_override = material
    get_tree().root.add_child(node)
    node.global_position = where
    get_tree().create_timer(lifetime).timeout.connect(func() -> void:
        if is_instance_valid(node):
            node.queue_free()
    )
    return node


func spawn_tracer(start: Vector3, finish: Vector3) -> void:
    var step: Vector3 = finish - start
    if step.length_squared() < 0.0001:
        return
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.012
    cylinder.bottom_radius = 0.012
    cylinder.height = step.length()
    var visual: MeshInstance3D = _make_transient(
        cylinder, _tracer_mat, (start + finish) * 0.5, 0.075
    )
    visual.quaternion = Quaternion(Vector3.UP, step.normalized())


func spawn_impact(where: Vector3) -> void:
    var sphere := SphereMesh.new()
    sphere.radius = 0.085
    sphere.height = 0.17
    _make_transient(sphere, _impact_mat, where, 0.16)
