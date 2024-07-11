extends CanvasLayer

@onready var ammo_label = $Control/AmmoLabel
@onready var weapon_icon = $Control/WeaponIcon

var shotgun_icon = preload("res://images/shotgun_shell.png")
var assault_rifle_icon = preload("res://images/assault_rifle_shell.png")

var tween: Tween

func update_ammo(current: int, max: int, weapon_type: int):
	ammo_label.text = str(current) + " / " + str(max)
	
	if tween:
		tween.kill()
	
	match weapon_type:
		0:  # Shotgun
			weapon_icon.texture = shotgun_icon
		1:  # Assault Rifle
			weapon_icon.texture = assault_rifle_icon
	
	tween = create_tween()
	var target_color = Color.WHITE if current > 0 else Color.RED
	tween.tween_property(weapon_icon, "modulate", target_color, 0.3)
	tween.parallel().tween_property(ammo_label, "modulate", target_color, 0.3)
	
	# Add a "pop" effect
	tween.parallel().tween_property(ammo_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(ammo_label, "scale", Vector2(1, 1), 0.1)
