extends Control

@onready var sensitivity_slider = $MouseSensitivityContainer/MouseSensitivitySlider  # Adjust the node path as needed
@onready var sensitivity_value_label = $MouseSensitivityContainer/MouseSensitivityValue

@onready var volume_slider = $VolumeContainer/VolumeSlider  # Adjust the node path as needed
@onready var volume_value_label = $VolumeContainer/VolumeValue  # Adjust the node path as needed

@onready var resolution_option_button = $ResolutionContainer/ResolutionOptionButton  # Adjust the node path as needed
@onready var windowed_mode_checkbox = $WindowedModeContainer/WindowedModeCheckBox  # Adjust the node path as needed

var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

func _ready():
	sensitivity_slider.value = Global.mouse_sensitivity  # Initialize with the current sensitivity
	sensitivity_value_label.text = str(Global.mouse_sensitivity)
	
	volume_slider.value = Global.volume_level  # Initialize with the current volume level
	volume_value_label.text = str(Global.volume_level)

	# Populate the resolution options
	for resolution in resolutions:
		resolution_option_button.add_item("%dx%d" % [resolution.x, resolution.y])
	resolution_option_button.select(Global.resolution_index)  # Select the saved resolution

	windowed_mode_checkbox.button_pressed = Global.windowed_mode  # Set the saved windowed mode

func _on_save_button_pressed():
	Global.mouse_sensitivity = sensitivity_slider.value  # Save the new sensitivity value

	# Save resolution settings
	var selected_index = resolution_option_button.selected
	Global.resolution_index = selected_index
	var selected_resolution = resolutions[selected_index]
	DisplayServer.window_set_size(selected_resolution)
	
	if windowed_mode_checkbox.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Global.windowed_mode = windowed_mode_checkbox.button_pressed

	var main_menu_scene = "res://MainMenu.tscn"
	get_tree().change_scene_to_file(main_menu_scene)

func _on_back_button_pressed():
	var main_screen = "res://MainMenu.tscn"
	get_tree().change_scene_to_file(main_screen)

func _on_mouse_sensitivity_slider_value_changed(value):
	sensitivity_value_label.text = str(value)

func _on_volume_slider_value_changed(value):
	volume_value_label.text = str(value)
	Global.volume_level = value  # Save the new volume level
	AudioManager.set_volume(Global.volume_level)  # Apply the volume change in real-time
