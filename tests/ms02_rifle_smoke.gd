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
    var rifle: Node3D = player.get_node("CameraPivot/CameraBoom/Camera3D/VX7") as Node3D
    var target: StaticBody3D = arena.get_node("TargetNear") as StaticBody3D
    var camera: Camera3D = player.get_node("CameraPivot/CameraBoom/Camera3D") as Camera3D
    _check(rifle != null and target != null, "Rifle and target not instantiated")
    if rifle == null or target == null:
        quit(1)
        return
    var muzzle: Marker3D = rifle.get_node("Muzzle") as Marker3D

    rifle.set("hip_spread_degrees", 0.0)
    rifle.set("ads_spread_degrees", 0.0)
    _check(int(rifle.get("ammo")) == 24, "Must begin with 24 shots")
    var initial_health: float = float(target.get("health"))
    _check(bool(rifle.call("fire_once")), "First shot must fire")
    _check(int(rifle.get("ammo")) == 23, "One fired round consumes one cartridge")
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
    blocker.size = Vector3(1.2, 1.2, 0.2)
    shape.shape = blocker
    barrier.add_child(shape)
    arena.add_child(barrier)
    barrier.global_position = muzzle.global_position - camera.global_basis.z * 0.4
    await _frames(3)
    initial_health = float(target.get("health"))
    _check(bool(rifle.call("fire_once")), "Cover shot still uses a round")
    _check(is_equal_approx(float(target.get("health")), initial_health), "Bullet penetrated close cover")

    var hud: CanvasLayer = player.get_node("CombatHUD") as CanvasLayer
    var ammo_label: Label = hud.get_node("Ammo") as Label
    var reload_label: Label = hud.get_node("Reload") as Label
    _check(ammo_label.text.contains("23 / 24"), "HUD count disagrees with rifle")
    _check(reload_label.text == "R  RELOAD", "HUD shows stale reloading state")
    arena.queue_free()
    if failures.is_empty():
        print("MS-02 SMOKE PASS: ammo, cadence, damage, reload, cover, HUD")
        quit(0)
    else:
        printerr("MS-02 SMOKE FAIL: %d checks" % failures.size())
        quit(1)
