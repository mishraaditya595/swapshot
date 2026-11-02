extends CharacterBody3D
## MS-01 third-person locomotion. Combat and SHIFT are implemented in later milestones.

@export var move_speed: float = 6.0
@export var acceleration: float = 22.0
@export var deceleration: float = 28.0
@export var turn_speed: float = 12.0
@export var mouse_sensitivity: float = 0.0025
@export_range(15.0, 85.0, 1.0) var pitch_limit_degrees: float = 65.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_boom: SpringArm3D = $CameraPivot/CameraBoom
@onready var visual_root: Node3D = $VisualRoot


func _ready() -> void:
    # A click enters look mode. Escape (or losing window focus) releases it.
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_window().focus_exited.connect(_release_mouse)


func _unhandled_input(event: InputEvent) -> void:
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
        camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
        var pitch_limit: float = deg_to_rad(pitch_limit_degrees)
        camera_boom.rotation.x = clampf(
            camera_boom.rotation.x - event.relative.y * mouse_sensitivity,
            -pitch_limit,
            pitch_limit
        )
        get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
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

    # Turn the visual mesh instead of the physics body, so look yaw and the
    # over-the-shoulder camera do not snap when movement direction changes.
    if not world_direction.is_zero_approx():
        var desired_angle: float = atan2(-world_direction.x, -world_direction.z)
        visual_root.rotation.y = lerp_angle(
            visual_root.rotation.y,
            desired_angle,
            minf(1.0, turn_speed * delta)
        )


func _release_mouse() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
