extends CharacterBody2D

@export var speed = 100  # Will be set by spawner
@export var direction = 1  # Will be set by spawner

@onready var animated_sprite = $Car

var car_types = ["car_1_move", "car_2_move", "car_3_move"]  # Add more car types as needed

func _ready():
	# Randomly select a car type
	var car_type = car_types[randi() % car_types.size()]
	
	# Set the animation based on the car type and direction
	var animation_name = car_type + "_" + ("right" if direction == 1 else "left")
	animated_sprite.play(animation_name)
	
	# No need to flip the sprite, as we're using different animations for each direction

func _physics_process(delta):
	# Move the car
	position.x += speed * direction * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	# Remove the car when it exits the screen
	queue_free()
