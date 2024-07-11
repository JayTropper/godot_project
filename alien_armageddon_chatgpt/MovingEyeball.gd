extends CharacterBody3D

@export var speed = 2.0
@export var position1 = Vector3(5, 0, 5)
@export var position2 = Vector3(-5, 0, 5)

var target_position = Vector3()
var moving_to_position2 = true

func _ready():
	global_transform.origin = position1
	target_position = position2

func _physics_process(delta):
	move_towards_target(delta)

func move_towards_target(delta):
	var direction = (target_position - global_transform.origin).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()

	if global_transform.origin.distance_to(target_position) < 0.1:
		print("Reached target position:", target_position)
		if moving_to_position2:
			target_position = position1
		else:
			target_position = position2
		moving_to_position2 = not moving_to_position2
		print("New target position:", target_position)
