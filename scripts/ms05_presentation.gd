extends Node3D
## MS-05 visual framing only; preserve proven camera/rifle aim geometry.

func _ready() -> void:
    var player: CharacterBody3D = $Arena/Player as CharacterBody3D
    # Keep the collision capsule and muzzle unchanged; reduce only the
    # foreground suit's bulk so cover and the trooper remain readable.
    var body: MeshInstance3D = player.get_node("VisualRoot/Body") as MeshInstance3D
    var visor: MeshInstance3D = player.get_node("VisualRoot/Visor") as MeshInstance3D
    body.scale = Vector3(0.92, 0.96, 0.92)
    visor.scale = Vector3(0.94, 0.94, 0.94)
