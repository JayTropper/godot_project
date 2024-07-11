extends MeshInstance3D

func _ready():
	hide()

func shoot():
	show()
	$Timer.start()

func _on_timer_timeout():
	hide()
