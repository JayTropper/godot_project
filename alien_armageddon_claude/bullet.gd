extends CharacterBody3D

var speed = 50.0
var lifetime = 5.0

func _ready():
	# Set the bullet's collision layer and mask
	collision_layer = 0b00000000_00000000_00000000_00000100  # Layer 3
	collision_mask = 0b00000000_00000000_00000000_00000010  # Layer 2 (environment)

	var timer = Timer.new()
	timer.connect("timeout", queue_free)
	add_child(timer)
	timer.start(lifetime)

func set_bullet_velocity(new_velocity: Vector3):
	velocity = new_velocity

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		print("Bullet hit: ", collision.get_collider().name)
		queue_free()
