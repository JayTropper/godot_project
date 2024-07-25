extends Node2D

@onready var frog = $Frog  # Adjust the path to your frog node
@onready var level_manager = $LevelManager  # Adjust the path to your LevelManager node

var level_heights = [-850, -3100, -6000]  # Adjust based on your level design

func _process(_delta):
	check_level_progress()

func check_level_progress():
	if frog.position.y < level_heights[level_manager.current_level - 1]:
		if level_manager.advance_level():
			print("Advancing to level ", level_manager.current_level)
			update_difficulty()
		else:
			print("You won the game!")
			# Implement win condition here
				

func update_difficulty():
	# Update car spawners with new level data
	for spawner in get_tree().get_nodes_in_group("car_spawners"):
		spawner._start_timer()  # This will use the new level data

func _on_frog_hit_car():
	level_manager.reset_level()
	get_tree().reload_current_scene()
