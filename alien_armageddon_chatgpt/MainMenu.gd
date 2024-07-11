extends CanvasLayer

@onready var start_button = $start_button

func _ready():
	# Ensure the volume is correctly set
	AudioManager.set_volume(Global.volume_level)

func _on_start_button_pressed():
	var game_scene = "res://GameScene.tscn"
	get_tree().change_scene_to_file(game_scene)
	AudioManager.stop_background_music()

func _on_exit_button_pressed():
	get_tree().quit()

func _on_settings_button_pressed():
	var settings_scene = "res://SettingsMenu.tscn"
	get_tree().change_scene_to_file(settings_scene)
