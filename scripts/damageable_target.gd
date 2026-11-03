extends StaticBody3D
## MS-02 training dummy; replace with an enemy health component in MS-05.
signal damaged(remaining_health: float)
signal destroyed()

@export_range(1.0, 500.0, 1.0) var max_health: float = 60.0
var health: float = 60.0


func _ready() -> void:
    health = max_health


func apply_damage(amount: float) -> void:
    if health <= 0.0 or amount <= 0.0:
        return
    health = maxf(0.0, health - amount)
    damaged.emit(health)
    if health <= 0.0:
        collision_layer = 0
        var mesh: MeshInstance3D = $MeshInstance3D
        var grey := StandardMaterial3D.new()
        grey.albedo_color = Color(0.17, 0.20, 0.23, 1.0)
        mesh.material_override = grey
        destroyed.emit()
