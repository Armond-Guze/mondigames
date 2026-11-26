extends CharacterBody3D

const HIP_FOV := 80.0
const AIM_FOV := 52.0
const MOUSE_SENSITIVITY := 0.0025

var aim_weight := 0.0
var weapon := preload("res://weapon_view.gd").new()
var camera := Camera3D.new()

func _ready() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.32
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	camera.position.y = 1.58
	camera.fov = HIP_FOV
	add_child(camera)
	camera.make_current()
	camera.add_child(weapon)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity := MOUSE_SENSITIVITY * lerpf(1.0, 0.65, aim_weight)
		rotate_y(-event.relative.x * sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity, -1.45, 1.45)

func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	var speed := 5.5
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		direction.x = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		direction.z = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		if Input.is_physical_key_pressed(KEY_SHIFT):
			speed = 2.6
	direction = transform.basis * direction.normalized()
	velocity.x = move_toward(velocity.x, direction.x * speed, 24.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 24.0 * delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_physical_key_pressed(KEY_SPACE):
		velocity.y = 5.0
	move_and_slide()

func _process(delta: float) -> void:
	var aiming := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	update_aim(aiming and weapon.reload_progress == 0.0, delta)

func update_aim(aiming: bool, delta: float) -> void:
	aim_weight = move_toward(aim_weight, float(aiming), delta * 7.0)
	camera.fov = lerpf(HIP_FOV, AIM_FOV, aim_weight)
	weapon.aim_weight = aim_weight
