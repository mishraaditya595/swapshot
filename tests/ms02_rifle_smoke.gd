extends SceneTree
## Headless regression test for MS-02 gameplay state and physics checks.
var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        printerr("MS-02 FAIL: " + message)


func _frames(count: int) -> void:
    for frame in range(count):
        await physics_frame


func _run() -> void:
    for action in ["fire", "aim", "reload"]:
        _check(InputMap.has_action(action), "Missing InputMap action " + action)
    var packed: PackedScene = load("res://scenes/levels/greybox_arena.tscn")
    _check(packed != null, "Arena failed to load")
    if packed == null:
        quit(1)
        return

    var arena: Node3D = packed.instantiate()
    root.add_child(arena)
    await _frames(5)
    var player: CharacterBody3D = arena.get_node("Player") as CharacterBody3D
    var rifle: Node3D = player.get_node("VisualRoot/WeaponPivot/VX7") as Node3D
    var target: StaticBody3D = arena.get_node("TargetNear") as StaticBody3D
    var camera: Camera3D = player.get_node("CameraPivot/CameraBoom/Camera3D") as Camera3D
    _check(rifle != null and target != null, "Rifle and target not instantiated")
    if rifle == null or target == null:
        quit(1)
        return
    var muzzle: Marker3D = rifle.get_node("Muzzle") as Marker3D
    var visuals: Node3D = player.get_node("VisualRoot") as Node3D
    var mount: Node3D = visuals.get_node("WeaponPivot") as Node3D
    var pivot: Node3D = player.get_node("CameraPivot") as Node3D
    var boom: SpringArm3D = pivot.get_node("CameraBoom") as SpringArm3D
    _check(rifle.get_parent() == mount, "Rifle must be character-mounted")

    # Reproduce owner's browser report: the camera turned while the visor
    # and rifle remained pointed forward. Exercise stationary left/right,
    # back-facing 180-degree yaw and pitched aiming.
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    var original_forward: Vector3 = -muzzle.global_basis.z
    for motion in [
        Vector2(480.0, -160.0), Vector2(-960.0, 320.0),
        Vector2(480.0, -160.0), Vector2(-PI / 0.0025, 0.0)
    ]:
        player.call("_apply_mouse_look", motion)
        await _frames(3)
        _check(
            absf(wrapf(visuals.rotation.y - pivot.rotation.y, -PI, PI)) < 0.01,
            "Player visual yaw must follow combat camera yaw"
        )
        _check(
            is_equal_approx(mount.rotation.x, boom.rotation.x),
            "Shoulder rifle pitch must follow camera pitch"
        )
        _check(
            (-muzzle.global_basis.z).dot(-camera.global_basis.z) > 0.999,
            "Visible muzzle must aim in the camera crosshair direction"
        )
    _check(
        original_forward.dot(-muzzle.global_basis.z) < -0.99,
        "A 180-degree camera turn must aim the rifle backwards"
    )
    # Restore the original target direction for the firing/cover tests.
    player.call("_apply_mouse_look", Vector2(PI / 0.0025, 0.0))
    await _frames(3)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

    rifle.set("hip_spread_degrees", 0.0)
    rifle.set("ads_spread_degrees", 0.0)
    _check(int(rifle.get("ammo")) == 24, "Must begin with 24 shots")
    var initial_health: float = float(target.get("health"))
    _check(initial_health >= 80.0, "Training dummy needs enough HP for cover regression")
    _check(bool(rifle.call("fire_once")), "First shot must fire")
    _check(int(rifle.get("ammo")) == 23, "One fired round consumes one cartridge")
    var flash: MeshInstance3D = rifle.get_node("MuzzleFlash") as MeshInstance3D
    _check(flash.visible, "Shot must trigger visible muzzle flash")
    _check(float(rifle.get("_kick")) > 0.0, "Shot must impart cosmetic recoil")
    var hud: CanvasLayer = player.get_node("CombatHUD") as CanvasLayer
    var marker: Label = hud.get_node("HitMarker") as Label
    _check(marker.visible, "Damageable shot must trigger hit marker")
    _check(not bool(rifle.call("fire_once")), "No double-shot in same frame")
    _check(float(target.get("health")) < initial_health, "Aligned shot must damage dummy")
    await _frames(8)
    _check(bool(rifle.call("fire_once")), "Fire cadence should recover after 0.1 s")
    _check(int(rifle.get("ammo")) == 22, "Second shot consumes ammunition")

    _check(bool(rifle.call("request_reload")), "Partial magazine must reload")
    _check(not bool(rifle.call("request_reload")), "Concurrent reload prevented")
    _check(not bool(rifle.call("fire_once")), "Cannot shoot while reloading")
    await _frames(30)
    _check(int(rifle.get("ammo")) == 22, "Reload must not refill early")
    await _frames(70)
    _check(int(rifle.get("ammo")) == 24, "Reload finishes after 1.5 s")
    _check(not bool(rifle.call("request_reload")), "Full magazine should not reload")

    rifle.set("ammo", 1)
    await _frames(9)
    _check(bool(rifle.call("fire_once")), "Last round must fire")
    _check(int(rifle.get("ammo")) == 0, "Last round must leave zero ammo")
    await _frames(9)
    _check(not bool(rifle.call("fire_once")), "Dry fire must reject empty magazine")
    _check(int(rifle.get("ammo")) == 0, "Dry fire cannot decrement ammo")
    _check(bool(rifle.call("request_reload")), "Empty gun can reload")
    await _frames(100)
    _check(int(rifle.get("ammo")) == 24, "Empty gun reload restored ammunition")

    # Spawn solid nearby cover between muzzle and the target.
    # Collision protects damage regardless of crosshair visibility.
    var barrier := StaticBody3D.new()
    barrier.name = "TestCloseCover"
    var shape := CollisionShape3D.new()
    var blocker := BoxShape3D.new()
    # The narrow block covers the muzzle line without covering the camera ray.
    blocker.size = Vector3(0.10, 1.2, 0.2)
    shape.shape = blocker
    barrier.add_child(shape)
    arena.add_child(barrier)
    barrier.global_position = muzzle.global_position - camera.global_basis.z * 0.4
    await _frames(3)
    var crosshair_hit: Dictionary = rifle.call(
        "_ray", camera.global_position, camera.global_position - camera.global_basis.z * 100.0
    )
    _check(crosshair_hit.get("collider") == target, "Camera must still see target over the narrow cover")
    initial_health = float(target.get("health"))
    _check(bool(rifle.call("fire_once")), "Cover shot still uses a round")
    _check(is_equal_approx(float(target.get("health")), initial_health), "Bullet penetrated close cover")

    var ammo_label: Label = hud.get_node("Ammo") as Label
    var reload_label: Label = hud.get_node("Reload") as Label
    _check(ammo_label.text.contains("23 / 24"), "HUD count disagrees with rifle")
    _check(reload_label.text == "R  RELOAD", "HUD shows stale reloading state")

    # A target destroyed by consecutive hits stops receiving physics rays.
    barrier.queue_free()
    await _frames(3)
    for shot in range(2):
        await _frames(9)
        _check(bool(rifle.call("fire_once")), "Follow-up target shot blocked unexpectedly")
    _check(float(target.get("health")) <= 0.0, "Training dummy must be destructible")
    _check(target.collision_layer == 0, "Destroyed dummy must cease blocking subsequent shots")
    arena.queue_free()
    if failures.is_empty():
        print("MS-02 SMOKE PASS: aim alignment, ammo, cadence, damage, reload, cover, HUD")
        quit(0)
    else:
        printerr("MS-02 SMOKE FAIL: %d checks" % failures.size())
        quit(1)
