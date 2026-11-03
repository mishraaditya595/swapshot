extends CharacterBody3D
## MS-01 third-person locomotion. Combat and SHIFT are implemented in later milestones.

signal health_changed(remaining: float, maximum: float)
signal died()

@export_range(1.0, 500.0, 1.0) var max_health: float = 100.0
var health: float = 100.0
var is_alive: bool = true

@export var move_speed: float = 6.0
@export var acceleration: float = 22.0
@export var deceleration: float = 28.0
@export var turn_speed: float = 12.0
@export var mouse_sensitivity: float = 0.0025
@export_range(15.0, 85.0, 1.0) var pitch_limit_degrees: float = 65.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_boom: SpringArm3D = $CameraPivot/CameraBoom
@onready var visual_root: Node3D = $VisualRoot
@onready var weapon_pitch: Node3D = $VisualRoot/WeaponPivot


func _ready() -> void:
    health = max_health
    health_changed.emit(health, max_health)
    # A click enters look mode. Escape (or losing window focus) releases it.
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_window().focus_exited.connect(_release_mouse)


# MS-05 minimal damage receiver. MS-06 owns the HUD, retry and full death flow.
func apply_damage(amount: float) -> void:
    if not is_alive or amount <= 0.0:
        return
    health = maxf(0.0, health - amount)
    health_changed.emit(health, max_health)
    if health <= 0.0:
        is_alive = false
        velocity = Vector3.ZERO
        $ShiftAbility.set_owner_alive(false)
        died.emit()


func reset_health() -> void:
    health = max_health
    is_alive = true
    health_changed.emit(health, max_health)
    $ShiftAbility.set_owner_alive(true)


func _unhandled_input(event: InputEvent) -> void:
    if not is_alive:
        return
    if event.is_action_pressed("release_mouse"):
        _release_mouse()
        get_viewport().set_input_as_handled()
        return

    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
                Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
                get_viewport().set_input_as_handled()
        return

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _apply_mouse_look(event.relative)
        get_viewport().set_input_as_handled()


# This pure rotation step is directly testable in headless mode; native pointer
# capture itself requires an actual window and a manual editor test.
func _apply_mouse_look(relative_motion: Vector2) -> void:
    camera_pivot.rotation.y -= relative_motion.x * mouse_sensitivity
    var pitch_limit: float = deg_to_rad(pitch_limit_degrees)
    camera_boom.rotation.x = clampf(
        camera_boom.rotation.x - relative_motion.y * mouse_sensitivity,
        -pitch_limit,
        pitch_limit
    )


func _physics_process(delta: float) -> void:
    if not is_alive:
        velocity = Vector3.ZERO
        return
    var input_vector: Vector2 = Input.get_vector(
        "move_left", "move_right", "move_forward", "move_backward"
    )

    # The pivot handles yaw, while the boom handles pitch. Movement remains
    # horizontal even when the player looks sharply up or down.
    var world_direction: Vector3 = camera_pivot.global_basis * Vector3(
        input_vector.x, 0.0, input_vector.y
    )
    world_direction.y = 0.0
    world_direction = world_direction.normalized()

    var target_velocity: Vector3 = world_direction * move_speed
    var speed_change: float = acceleration if not world_direction.is_zero_approx() else deceleration
    velocity.x = move_toward(velocity.x, target_velocity.x, speed_change * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, speed_change * delta)

    if not is_on_floor():
        velocity += get_gravity() * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    move_and_slide()

    _update_combat_pose(world_direction, Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, delta)


# Pure aim-pose update shared by input-driven gameplay and headless tests.
# Headless Godot cannot acquire native OS pointer capture, so tests provide
# look_active directly while browser input reads Input.mouse_mode above.
func _update_combat_pose(world_direction: Vector3, look_active: bool, delta: float) -> void:
    if look_active:
        # Keep the visible character facing camera yaw even while stationary.
        visual_root.rotation.y = camera_pivot.rotation.y
    elif not world_direction.is_zero_approx():
        var desired_angle: float = atan2(-world_direction.x, -world_direction.z)
        visual_root.rotation.y = lerp_angle(
            visual_root.rotation.y, desired_angle, minf(1.0, turn_speed * delta)
        )

    # Tilt only the shoulder weapon, not the character collision/body.
    weapon_pitch.rotation.x = camera_boom.rotation.x


func _release_mouse() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
