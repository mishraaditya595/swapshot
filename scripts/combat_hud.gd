extends CanvasLayer
## Minimal feedback; weapon remains the only ammo and reload authority.
@onready var ammo_label: Label = $Ammo
@onready var crosshair: Label = $Crosshair
@onready var hit_marker: Label = $HitMarker
@onready var reload_label: Label = $Reload
@onready var weapon: Node = get_node("../VisualRoot/WeaponPivot/VX7")
var _hit_left: float = 0.0


func _ready() -> void:
    weapon.connect("ammo_changed", Callable(self, "_set_ammo"))
    weapon.connect("reload_state_changed", Callable(self, "_set_reload"))
    weapon.connect("shot_resolved", Callable(self, "_set_hit"))
    _set_ammo(int(weapon.get("ammo")), int(weapon.get("magazine_capacity")))
    _set_reload(bool(weapon.get("is_reloading")))
    hit_marker.visible = false


func _process(delta: float) -> void:
    crosshair.text = "·" if bool(weapon.get("is_aiming")) else "+"
    _hit_left = maxf(0.0, _hit_left - delta)
    hit_marker.visible = _hit_left > 0.0


func _set_ammo(loaded: int, capacity: int) -> void:
    ammo_label.text = "VX-7  %02d / %02d" % [loaded, capacity]


func _set_reload(reloading: bool) -> void:
    reload_label.text = "RELOADING..." if reloading else "R  RELOAD"


func _set_hit(damageable_hit: bool) -> void:
    if damageable_hit:
        _hit_left = 0.13
        hit_marker.visible = true
