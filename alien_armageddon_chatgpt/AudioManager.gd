extends Node

@onready var background_music_player = $AudioStreamPlayer

func _ready():
	# Check if background_music_player is valid and not already playing
	if background_music_player and not background_music_player.playing:
		background_music_player.autoplay = true
		background_music_player.volume_db = Global.volume_level  # Set the initial volume
		background_music_player.play()

func set_volume(volume):
	if background_music_player:
		background_music_player.volume_db = volume

func stop_background_music():
	if background_music_player.playing:
		background_music_player.stop()
