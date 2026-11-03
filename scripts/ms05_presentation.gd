extends Node3D
## MS-05-only camera tuning; legacy training scenes keep their tested aim geometry.

func _ready() -> void:
    var player: CharacterBody3D = $Arena/Player as CharacterBody3D
    var boom: SpringArm3D = player.get_node("CameraPivot/CameraBoom") as SpringArm3D
    var camera: Camera3D = player.get_node("CameraPivot/CameraBoom/Camera3D") as Camera3D
    boom.spring_length = 3.85
    camera.set("shoulder_offset", 0.70)
