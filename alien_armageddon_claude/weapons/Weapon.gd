# weapon.gd
class_name Weapon
extends Node3D

signal ammo_changed(current: int, maximum: int)

enum WeaponType { SHOTGUN, ASSAULT_RIFLE }

@export var weapon_type: WeaponType
@export var max_ammo: int
@export var bullet_speed: float
@export var spread: float
@export var fire_rate: float
@export var num_pellets: int = 1  # For shotgun

@onready var muzzle = $MuzzlePosition
@onready var shoot_sound = $ShootSound
@onready var reload_sound = $ReloadSound
@onready var shoot_animation = $ShootAnimation
@onready var reload_animation = $ReloadAnimation

var current_ammo: int
var is_reloading: bool = false
var Bullet = preload("res://bullet.tscn")

func _ready():
	current_ammo = max_ammo

func can_shoot() -> bool:
	return current_ammo > 0 and not is_reloading

func shoot(camera):
	if can_shoot():
		match weapon_type:
			WeaponType.SHOTGUN:
				spawn_shotgun_spread(camera)
			WeaponType.ASSAULT_RIFLE:
				spawn_single_bullet(camera)
		
		shoot_sound.play()
		shoot_animation.play("shoot")
		
		current_ammo -= 1
		emit_signal("ammo_changed", current_ammo, max_ammo)

func spawn_shotgun_spread(camera):
	for i in range(num_pellets):
		spawn_bullet(camera, spread)

func spawn_single_bullet(camera):
	spawn_bullet(camera, spread)

func spawn_bullet(camera, bullet_spread):
	var bullet = Bullet.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	bullet.global_transform.origin = muzzle.global_transform.origin
	
	var direction = -camera.global_transform.basis.z.normalized()
	direction += Vector3(
		randf_range(-bullet_spread, bullet_spread),
		randf_range(-bullet_spread, bullet_spread),
		randf_range(-bullet_spread, bullet_spread)
	)
	direction = direction.normalized()
	
	bullet.set_bullet_velocity(direction * bullet_speed)

func get_weapon_type() -> WeaponType:
	return weapon_type
	

func start_reload():
	is_reloading = true
	reload_animation.play("reload")
	reload_sound.play()

func finish_reload():
	is_reloading = false
	current_ammo = max_ammo
	await reload_animation.animation_finished
	emit_signal("ammo_changed", current_ammo, max_ammo)

func cancel_reload():
	is_reloading = false
	reload_animation.stop()
	reload_sound.stop()
