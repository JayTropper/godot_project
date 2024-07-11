extends CharacterBody3D

const SHOTGUN_BULLET_SPEED = 30.0
const ASSAULT_RIFLE_BULLET_SPEED = 50.0

var speed = 5.0
var mouse_sensitivity = 0.05
var is_firing = false
var fire_rate = 0.1  # Time between shots for the assault rifle
var fire_timer = 0.0

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var weapons = $Camera3D/Weapons
@onready var shotgun = $Camera3D/Weapons/Shotgun
@onready var assault_rifle = $Camera3D/Weapons/AssaultRifle
@onready var ammo_ui = $AmmoUI

var Bullet = preload("res://Bullet.tscn")

enum WeaponType { SHOTGUN, ASSAULT_RIFLE }
var current_weapon = WeaponType.SHOTGUN

var max_ammo = {
	WeaponType.SHOTGUN: 1,
	WeaponType.ASSAULT_RIFLE: 30
}

var current_ammo = {
	WeaponType.SHOTGUN: 1,
	WeaponType.ASSAULT_RIFLE: 30
}

var is_reloading = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	collision_layer = 0b00000000_00000000_00000000_00000001  # Layer 1
	collision_mask = 0b00000000_00000000_00000000_00000010  # Layer 2 (environment)
	update_ammo_display()
	switch_weapon(current_weapon)

func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
	
	if is_firing and not is_reloading:
		if current_weapon == WeaponType.SHOTGUN:
			shoot()
			is_firing = false  # Prevent automatic fire for shotgun
		elif current_weapon == WeaponType.ASSAULT_RIFLE:
			fire_timer += delta
			if fire_timer >= fire_rate:
				shoot()
				fire_timer = 0.0
	else:
		fire_timer = 0.0

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event.is_action_pressed("shoot"):
		shoot()
		is_firing = true
	elif event.is_action_released("shoot"):
		is_firing = false
	
	if event.is_action_pressed("reload") and not is_reloading:
		reload()
	
	if event.is_action_pressed("weapon_1"):
		switch_weapon(WeaponType.SHOTGUN)
	
	if event.is_action_pressed("weapon_2"):
		switch_weapon(WeaponType.ASSAULT_RIFLE)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func shoot():
	if current_ammo[current_weapon] > 0 and not is_reloading:
		match current_weapon:
			WeaponType.SHOTGUN:
				spawn_shotgun_spread()
				play_shoot_sound()
				current_ammo[current_weapon] -= 1
			WeaponType.ASSAULT_RIFLE:
				spawn_single_bullet()
				play_shoot_sound()
				current_ammo[current_weapon] -= 1
		update_ammo_display()
	else:
		print("Need to reload!")
		is_firing = false  # Stop firing when out of ammo

func reload():
	if current_ammo[current_weapon] < max_ammo[current_weapon] and not is_reloading:
		is_reloading = true
		print("Reloading...")
		
		play_reload_sound()
		play_reload_animation()
		
		# Wait for the animation to finish
		var animation_player = get_current_weapon().get_node("ReloadAnimation")
		await animation_player.animation_finished
		
		current_ammo[current_weapon] = max_ammo[current_weapon]
		is_reloading = false
		update_ammo_display()
		print("Reload complete.")

func update_ammo_display():
	ammo_ui.update_ammo(current_ammo[current_weapon], max_ammo[current_weapon], current_weapon)

func switch_weapon(new_weapon):
	current_weapon = new_weapon
	shotgun.visible = (current_weapon == WeaponType.SHOTGUN)
	assault_rifle.visible = (current_weapon == WeaponType.ASSAULT_RIFLE)
	update_ammo_display()
	
	
####################################################################################################
## Helper methods

func get_current_muzzle():
	return shotgun.get_node("MuzzlePosition") if current_weapon == WeaponType.SHOTGUN else assault_rifle.get_node("MuzzlePosition")

func get_current_weapon():
	return shotgun if current_weapon == WeaponType.SHOTGUN else assault_rifle
	
func play_shoot_sound():
	var audio_player = shotgun.get_node("ShootSound") if current_weapon == WeaponType.SHOTGUN else assault_rifle.get_node("ShootSound")
	audio_player.play()

func play_reload_sound():
	var audio_player = shotgun.get_node("ReloadSound") if current_weapon == WeaponType.SHOTGUN else assault_rifle.get_node("ReloadSound")
	audio_player.play()

func play_reload_animation():
	var animation_player = get_current_weapon().get_node("ReloadAnimation")
	if animation_player:
		animation_player.play("reload")
	else:
		print("ReloadAnimation node not found!")
	
func spawn_shotgun_spread():
	var num_pellets = 8  # Adjust as needed
	var spread = 0.05  # Adjust for wider or tighter spread

	for i in range(num_pellets):
		var bullet = Bullet.instantiate()
		get_parent().add_child(bullet)
		
		var muzzle = get_current_muzzle()
		var spawn_point = muzzle.global_transform.origin
		bullet.global_transform.origin = spawn_point
		
		var direction = -camera.global_transform.basis.z.normalized()
		direction += Vector3(randf_range(-spread, spread), randf_range(-spread, spread), randf_range(-spread, spread))
		direction = direction.normalized()
		
		bullet.set_bullet_velocity(direction * SHOTGUN_BULLET_SPEED)

func spawn_single_bullet():
	var bullet = Bullet.instantiate()
	get_parent().add_child(bullet)
	
	var muzzle = get_current_muzzle()
	var spawn_point = muzzle.global_transform.origin
	bullet.global_transform.origin = spawn_point
	
	var direction = -camera.global_transform.basis.z.normalized()
	var spread = 0.02  # Adjust this value for more or less spread
	direction += Vector3(randf_range(-spread, spread), randf_range(-spread, spread), randf_range(-spread, spread))
	direction = direction.normalized()
	
	bullet.set_bullet_velocity(direction * bullet.speed)
