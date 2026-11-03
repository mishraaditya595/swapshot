extends Node3D
## MS-02: one authoritative rifle state machine; no player movement changes.
signal ammo_changed(loaded: int, capacity: int)
signal reload_state_changed(reloading: bool)
signal shot_fired()
signal shot_resolved(damageable_hit: bool)
signal dry_fired()

@export_range(1, 120) var magazine_capacity: int = 24
@export_range(60.0, 1200.0, 1.0) var fire_rate_rpm: float = 600.0
@export_range(0.1, 5.0, 0.05) var reload_seconds: float = 1.5
@export_range(1.0, 200.0, 1.0) var damage: float = 20.0
@export_range(1.0, 300.0, 1.0) var range_meters: float = 100.0
@export var hip_spread_degrees: float = 2.0
@export var ads_spread_degrees: float = 0.35
@export_range(30.0, 90.0, 1.0) var ads_fov: float = 55.0
@export var hit_mask: int = 1

@onready var camera: Camera3D = get_parent() as Camera3D
@onready var player: CollisionObject3D = get_node("../../../..") as CollisionObject3D
@onready var muzzle: Marker3D = $Muzzle
@onready var rifle_mesh: MeshInstance3D = $RifleMesh
@onready var flash_mesh: MeshInstance3D = $MuzzleFlash
@onready var fx: Node3D = $RifleFX

var ammo: int = 24
var is_reloading: bool = false
var is_aiming: bool = false
var _fire_cooldown: float = 0.0
var _reload_remaining: float = 0.0
var _flash_remaining: float = 0.0
var _trigger_armed: bool = false
var _base_fov: float = 75.0
var _rest_mesh_position: Vector3 = Vector3.ZERO
var _kick: float = 0.0


func _ready() -> void:
    ammo = magazine_capacity
    _base_fov = camera.fov
    _rest_mesh_position = rifle_mesh.position
    flash_mesh.visible = false
    ammo_changed.emit(ammo, magazine_capacity)


func _unhandled_input(event: InputEvent) -> void:
    if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event.is_action_pressed("reload"):
        request_reload()
        get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
    _fire_cooldown = maxf(0.0, _fire_cooldown - delta)
    if is_reloading:
        _reload_remaining -= delta
        if _reload_remaining <= 0.0:
            is_reloading = false
            ammo = magazine_capacity
            reload_state_changed.emit(false)
            ammo_changed.emit(ammo, magazine_capacity)

    _flash_remaining = maxf(0.0, _flash_remaining - delta)
    flash_mesh.visible = _flash_remaining > 0.0
    _kick = move_toward(_kick, 0.0, 0.30 * delta)
    rifle_mesh.position = _rest_mesh_position + Vector3(0.0, 0.0, _kick)

    # A click used to acquire the pointer must never fire a surprise shot.
    # Releasing the trigger once while captured arms subsequent presses.
    if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        _trigger_armed = false
        is_aiming = false
    else:
        is_aiming = Input.is_action_pressed("aim")
        if not Input.is_action_pressed("fire"):
            _trigger_armed = true
        elif _trigger_armed:
            fire_once()
    camera.fov = lerpf(camera.fov, ads_fov if is_aiming else _base_fov, minf(1.0, delta * 12.0))


func request_reload() -> bool:
    if is_reloading or ammo == magazine_capacity:
        return false
    is_reloading = true
    _reload_remaining = reload_seconds
    reload_state_changed.emit(true)
    return true


func fire_once() -> bool:
    # The same cooldown is used by input-driven and test-driven firing.
    if is_reloading or _fire_cooldown > 0.0:
        return false
    _fire_cooldown = 60.0 / fire_rate_rpm
    if ammo <= 0:
        dry_fired.emit()
        return false
    ammo -= 1
    ammo_changed.emit(ammo, magazine_capacity)
    shot_fired.emit()
    _flash_remaining = 0.055
    flash_mesh.visible = true
    _kick = minf(0.12, _kick + 0.045)
    var result: Dictionary = _resolve_shot()
    shot_resolved.emit(bool(result.get("damaged", false)))
    return true


func _ray(from: Vector3, to: Vector3) -> Dictionary:
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        from, to, hit_mask, [player.get_rid()]
    )
    query.hit_from_inside = true
    return get_world_3d().direct_space_state.intersect_ray(query)


func _resolve_shot() -> Dictionary:
    var origin: Vector3 = camera.global_position
    var muzzle_point: Vector3 = muzzle.global_position
    var forward: Vector3 = -camera.global_basis.z
    # Center-camera ray defines the point under the crosshair.
    var crosshair_hit: Dictionary = _ray(origin, origin + forward * range_meters)
    var aim_point: Vector3 = (
        crosshair_hit["position"] if not crosshair_hit.is_empty()
        else origin + forward * range_meters
    )

    # Check camera-to-muzzle AND muzzle-to-aim. A visible camera target
    # must not be hit when a crate/wall blocks the actual barrel.
    var near_hit: Dictionary = _ray(origin, muzzle_point)
    if not near_hit.is_empty():
        fx.call("spawn_impact", near_hit["position"])
        return {"damaged": false, "collider": near_hit["collider"]}

    var barrel_hit: Dictionary = _ray(muzzle_point, aim_point)
    var impact: Vector3 = aim_point
    var collider: Object = null
    if not barrel_hit.is_empty():
        impact = barrel_hit["position"]
        collider = barrel_hit["collider"]
    fx.call("spawn_tracer", muzzle_point, impact)

    var did_damage: bool = false
    if collider != null and collider.has_method("apply_damage"):
        collider.call("apply_damage", damage)
        did_damage = true
    if collider != null:
        fx.call("spawn_impact", impact)
    return {"damaged": did_damage, "collider": collider}


func debug_fire_cooldown() -> float:
    return _fire_cooldown


func debug_reload_remaining() -> float:
    return _reload_remaining
