extends CanvasLayer
## Minimal feedback; weapon remains the only ammo and reload authority.
@onready var ammo_label: Label = $Ammo
@onready var crosshair: Label = $Crosshair
@onready var hit_marker: Label = $HitMarker
@onready var reload_label: Label = $Reload
@onready var incoming: Label = $Incoming
@onready var health_label: Label = $Health
@onready var threat_label: Label = $Threat
@onready var damage_flash: ColorRect = $DamageFlash
@onready var owner_player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var weapon: Node = get_node("../VisualRoot/WeaponPivot/VX7")
var _hit_left: float = 0.0
var _incoming_left: float = 0.0
var _previous_health: float = 100.0
var _enemy: Node = null


func _ready() -> void:
    weapon.connect("ammo_changed", Callable(self, "_set_ammo"))
    weapon.connect("reload_state_changed", Callable(self, "_set_reload"))
    weapon.connect("shot_resolved", Callable(self, "_set_hit"))
    _set_ammo(int(weapon.get("ammo")), int(weapon.get("magazine_capacity")))
    _set_reload(bool(weapon.get("is_reloading")))
    hit_marker.visible = false
    incoming.visible = false
    _previous_health = float(owner_player.get("health"))
    owner_player.connect("health_changed", _on_health_changed)
    _set_health(_previous_health, float(owner_player.get("max_health")))
    damage_flash.visible = false
    call_deferred("_bind_enemy")


func _process(delta: float) -> void:
    crosshair.text = "·" if bool(weapon.get("is_aiming")) else "+"
    _hit_left = maxf(0.0, _hit_left - delta)
    hit_marker.visible = _hit_left > 0.0
    _incoming_left = maxf(0.0, _incoming_left - delta)
    incoming.visible = _incoming_left > 0.0
    damage_flash.visible = _incoming_left > 0.0
    damage_flash.modulate.a = minf(0.65, _incoming_left * 0.65)


func _set_ammo(loaded: int, capacity: int) -> void:
    ammo_label.text = "VX-7  %02d / %02d" % [loaded, capacity]


func _set_reload(reloading: bool) -> void:
    reload_label.text = "RELOADING..." if reloading else "R  RELOAD"


func _set_hit(damageable_hit: bool) -> void:
    if damageable_hit:
        _hit_left = 0.13
        hit_marker.visible = true


func _on_health_changed(remaining: float, _maximum: float) -> void:
    _set_health(remaining, _maximum)
    if remaining < _previous_health:
        incoming.text = "ARMOR HIT  -%d" % int(roundf(_previous_health - remaining))
        _incoming_left = 0.7
        incoming.visible = true
    _previous_health = remaining


func _set_health(remaining: float, maximum: float) -> void:
    health_label.text = "ARMOR  %d / %d" % [int(ceilf(remaining)), int(ceilf(maximum))]
    health_label.add_theme_color_override(
        "font_color", Color(1.0, 0.45, 0.31) if remaining <= maximum * 0.3
        else Color(0.71, 0.98, 0.90)
    )
    if remaining <= 0.0:
        threat_label.text = "YOU ARE DOWN  |  Enter to restart"


func _bind_enemy() -> void:
    var candidate: Node = get_tree().get_first_node_in_group("enemy")
    if candidate == null:
        threat_label.text = "ENCOUNTER  |  LOCATE THE TROOPER"
        return
    _enemy = candidate
    _enemy.connect("state_changed", _on_enemy_state_changed)
    _enemy.connect("echo_distracted", _on_echo_distracted)
    _enemy.connect("echo_released", _on_echo_released)
    _enemy.connect("windup_started", _on_windup_started)
    _enemy.connect("shot_fired", _on_enemy_shot)
    _enemy.connect("destroyed", _on_enemy_destroyed)
    _on_enemy_state_changed(int(_enemy.get("state")))


func _set_threat(message: String, tint: Color = Color(1.0, 0.74, 0.39)) -> void:
    threat_label.text = message
    threat_label.add_theme_color_override("font_color", tint)


func _on_enemy_state_changed(next_state: int) -> void:
    if not bool(owner_player.get("is_alive")):
        return
    if is_instance_valid(_enemy) and _enemy.get("_echo") != null:
        _set_threat("HELIX  /  DISTRACTED BY ECHO", Color(0.40, 1.0, 0.94))
        return
    match next_state:
        0: _set_threat("HELIX  /  NO CONTACT", Color(0.70, 0.86, 0.90))
        1: _set_threat("HELIX  /  TARGET ACQUIRED")
        2: _set_threat("HELIX  /  ENGAGING")
        3: _set_threat("HELIX  /  NEUTRALIZED", Color(0.40, 1.0, 0.90))
        4: _set_threat("HELIX  /  SEARCHING LAST SEEN")


func _on_echo_distracted(_position: Vector3) -> void:
    _set_threat("HELIX  /  DISTRACTED BY ECHO", Color(0.40, 1.0, 0.94))


func _on_echo_released() -> void:
    _set_threat("HELIX  /  REACQUIRING PLAYER")


func _on_windup_started() -> void:
    _set_threat("HELIX  /  SHOT INCOMING!", Color(1.0, 0.46, 0.25))


func _on_enemy_shot(_hit: bool) -> void:
    if not bool(owner_player.get("is_alive")):
        return
    _set_threat("HELIX  /  CYCLING WEAPON")


func _on_enemy_destroyed() -> void:
    _set_threat("HELIX  /  NEUTRALIZED", Color(0.40, 1.0, 0.90))
