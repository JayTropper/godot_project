extends Node

var current_level = 1
var levels = [
	{
		"car_count": 3,
		"min_speed": 100,
		"max_speed": 150,
		"min_spawn_interval": 2.0,
		"max_spawn_interval": 5.0,
		"spawner_activated": true
	},
	{
		"car_count": 4,
		"min_speed": 150,
		"max_speed": 200,
		"min_spawn_interval": 1.5,
		"max_spawn_interval": 4.0,
		"spawner_activated": true
	},
	{
		"car_count": 5,
		"min_speed": 200,
		"max_speed": 250,
		"min_spawn_interval": 1.0,
		"max_spawn_interval": 3.0,
		"spawner_activated": true
	}
	# Add more levels as needed
]

func get_current_level_data():
	return levels[current_level - 1]

func advance_level():
	if current_level < levels.size():
		current_level += 1
		return true
	return false

func reset_level():
	current_level = 1
