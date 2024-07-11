extends CharacterBody3D

var speed = 5.0
var mouse_sensitivity = 0.05

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D

var Bullet = preload("res://bullet.tscn")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Set the player's collision layer and mask
	collision_layer = 0b00000000_00000000_00000000_00000001  # Layer 1
	collision_mask = 0b00000000_00000000_00000000_00000010  # Layer 2 (environment)

func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event.is_action_pressed("shoot"):
		shoot()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func shoot():
	var bullet = Bullet.instantiate()
	get_parent().add_child(bullet)
	
	# Spawn the bullet further in front of the camera
	var spawn_point = camera.global_transform.origin - camera.global_transform.basis.z * 2.0
	bullet.global_transform.origin = spawn_point
	
	var direction = -camera.global_transform.basis.z.normalized()
	bullet.set_bullet_velocity(direction * bullet.speed)
	
	if raycast.is_colliding():
		var target = raycast.get_collider()
		print("Aiming at: ", target.name)
