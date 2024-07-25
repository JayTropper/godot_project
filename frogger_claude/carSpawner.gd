extends Node2D

@export var car_scene: PackedScene
@export var direction = 1  # 1 for right, -1 for left
@export var lane_y_position = 0  # Y position of the lane
@export var activated = true

var timer: Timer
var level_manager: Node

func _ready():
	level_manager = get_node("../../../../LevelManager")  # Adjust path as needed
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	_start_timer()

func _start_timer():
	var level_data = level_manager.get_current_level_data()
	activated = level_data["spawner_activated"]
	var interval = randf_range(level_data["min_spawn_interval"], level_data["max_spawn_interval"])
	timer.start(interval)

func _on_timer_timeout():
	if activated:
		spawn_car()
		_start_timer()

func spawn_car():
	var level_data = level_manager.get_current_level_data()
	var car_instance = car_scene.instantiate()
	car_instance.position = Vector2(global_position.x, lane_y_position)
	car_instance.direction = direction
	car_instance.speed = randf_range(level_data["min_speed"], level_data["max_speed"])
	
	car_instance.add_to_group("cars")
	
	get_tree().current_scene.add_child(car_instance)
