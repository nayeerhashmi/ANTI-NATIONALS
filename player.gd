extends CharacterBody3D

@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.0
@export var mouse_sensitivity: float = 0.0025
@export var gravity_strength: float = 18.0

var pivot: Node3D
var camera_pitch := -0.12

func _ready() -> void:
    pivot = Node3D.new()
    pivot.position = Vector3(0, 1.2, 0)
    add_child(pivot)
    var spring := SpringArm3D.new()
    spring.spring_length = 4.5
    pivot.add_child(spring)
    var camera := Camera3D.new()
    camera.current = true
    camera.fov = 72.0
    spring.add_child(camera)
    var mesh_instance := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    mesh_instance.mesh = capsule
    mesh_instance.material_override = _mat(Color(0.18, 0.52, 0.78))
    add_child(mesh_instance)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.35
    shape.height = 1.8
    collision.shape = shape
    add_child(collision)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera_pitch = clamp(camera_pitch - event.relative.y * mouse_sensitivity, -0.9, 0.45)
        pivot.rotation.x = camera_pitch
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity_strength * delta
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (global_transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
    var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, walk_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, walk_speed * 5.0 * delta)
    move_and_slide()

func _mat(colour: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    return material
