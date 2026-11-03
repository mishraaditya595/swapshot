extends Node3D
@export var managed_objective: bool = false
## MS-05 visual framing only; preserve proven camera/rifle aim geometry.

func _ready() -> void:
    var player: CharacterBody3D = $Arena/Player as CharacterBody3D
    # Keep the collision capsule and muzzle unchanged; reduce only the
    # foreground suit's bulk so cover and the trooper remain readable.
    var body: MeshInstance3D = player.get_node("VisualRoot/Body") as MeshInstance3D
    var visor: MeshInstance3D = player.get_node("VisualRoot/Visor") as MeshInstance3D
    body.scale = Vector3(0.92, 0.96, 0.92)
    visor.scale = Vector3(0.94, 0.94, 0.94)
    $Arena/Instructions/ControlHints.text = (
        "SWAPSHOT  /  FIREFIGHT\n"
        + "WASD MOVE  |  LMB FIRE  |  RMB AIM  |  R RELOAD  |  Q ANCHOR  |  SHIFT TELEPORT"
    )
    $HelixTrooper.destroyed.connect(_on_trooper_destroyed)


func _on_trooper_destroyed() -> void:
    if managed_objective:
        return
    var mission: Label = $EncounterHUD/HelixHint as Label
    mission.text = "MISSION COMPLETE  /  HELIX TROOPER NEUTRALIZED"
    mission.add_theme_color_override("font_color", Color(0.45, 0.98, 0.86))
