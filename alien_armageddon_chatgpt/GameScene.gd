extends CharacterBody3D

@export var speed = 10.0
@export var gravity = -24.8
@export var jump_force = 8.0
@export var weapon_idle_position = Vector3(0.3, -0.6, -1.3)  # Position relative to the camera when not aiming
@export var weapon_aimed_position = Vector3(0, -0.35, -1.3)  # Position relative to the camera when aiming

@onready var camera = $Camera3D

@onready var shotgun = $Camera3D/Shotgun  # Reference to the shotgun
@onready var shotgun_shoot_sound = $Camera3D/Shotgun/shoot_sound 
@onready var shotgun_shoot_animation = $Camera3D/Shotgun/shoot_animation 
@onready var shotgun_reload_sound = $Camera3D/Shotgun/reload_sound 
@onready var reload_animation_aiming = $Camera3D/Shotgun/reload_animation_aiming
@onready var reload_animation_not_aiming = $Camera3D/Shotgun/reload_animation_not_aiming

@onready var assault_rifle = $Camera3D/AssaultRifle
@onready var assault_rifle_shoot_sound = $Camera3D/AssaultRifle/shoot_sound
@onready var assault_rifle_reload_sound = $Camera3D/AssaultRifle/reload_sound

@onready var current_weapon = shotgun  # Start with the shotgun as the current weapon

var reload_timer = Timer.new()  # Create the Timer instance
var assault_rifle_fire_timer = Timer.new()  # Timer for automatic fire
var is_weapon_aimed = false
var can_shoot = true
var is_reloading = false  # Flag to indicate if the gun is currently reloading
var assault_rifle_magazine = 31
var score = 0
var score_label

# Define reload times and fire rates
const RELOAD_TIME_SHOTGUN = 0.8
const RELOAD_TIME_ASSAULT_RIFLE = 3.0
const ASSAULT_RIFLE_FIRE_RATE = 0.1
var current_reload_time = RELOAD_TIME_SHOTGUN  # Default reload time

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	assault_rifle.visible = false
	shotgun.visible = true
	
	score_label = get_node("/root/Main/OverlayElements/ScoreLabel")
	score_label.text = "Score: " + str(score)
	
	reload_timer.connect("timeout", Callable(self, "_on_reload_timeout"))
	add_child(reload_timer)  # Add the Timer to the scene tree
	
	assault_rifle_fire_timer.connect("timeout", Callable(self, "_on_assault_rifle_fire_timeout"))
	add_child(assault_rifle_fire_timer)  # Add the Timer to the scene tree

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * Global.mouse_sensitivity))
		var camera_rotation = camera.rotation_degrees
		camera_rotation.x -= event.relative.y * Global.mouse_sensitivity
		camera_rotation.x = clamp(camera_rotation.x, -89, 89)
		camera.rotation_degrees = camera_rotation

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
		switch_to_next_weapon()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
		switch_to_previous_weapon()

	if Input.is_action_just_pressed("fire") and can_shoot:
		if current_weapon == assault_rifle:
			assault_rifle_fire_timer.start(ASSAULT_RIFLE_FIRE_RATE)
		else:
			shoot()
	elif Input.is_action_just_released("fire") and current_weapon == assault_rifle:
		assault_rifle_fire_timer.stop()
	
	if Input.is_action_just_pressed("aim"):
		toggle_weapon_position()

	if Input.is_action_just_pressed("reload"):
		reload_weapon()

func switch_to_next_weapon():
	current_weapon.visible = false
	if current_weapon == shotgun:
		current_weapon = assault_rifle
		current_reload_time = RELOAD_TIME_ASSAULT_RIFLE
	else:
		current_weapon = shotgun
		current_reload_time = RELOAD_TIME_SHOTGUN
	current_weapon.visible = true

func switch_to_previous_weapon():
	current_weapon.visible = false  # Hide current weapon
	if current_weapon == shotgun:
		current_weapon = assault_rifle
		current_reload_time = RELOAD_TIME_ASSAULT_RIFLE
	else:
		current_weapon = shotgun
		current_reload_time = RELOAD_TIME_SHOTGUN
	current_weapon.visible = true

func _physics_process(delta):
	var direction = Vector3.ZERO

	if Input.is_action_pressed("ui_up"):
		direction -= transform.basis.z
	if Input.is_action_pressed("ui_down"):
		direction += transform.basis.z
	if Input.is_action_pressed("ui_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("ui_right"):
		direction += transform.basis.x

	direction = direction.normalized()

	if is_on_floor():
		velocity.y = 0
		if Input.is_action_just_pressed("ui_select"):
			velocity.y = jump_force
	else:
		velocity.y += gravity * delta

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()

func shoot():
	var ray_origin = camera.global_transform.origin
	var ray_direction = -camera.global_transform.basis.z

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = ray_origin
	query.to = ray_origin + ray_direction * 1000

	var result = space_state.intersect_ray(query)

	if result:
		if result.collider.name == "MovingCharacter":  # Check if the moving character is hit
			score += 10
			score_label.text = "Score: " + str(score)
		print("Hit: ", result.collider.name)

	if current_weapon == shotgun:
		shotgun_shoot_sound.play()
		shotgun_shoot_animation.play("shoot")
		can_shoot = false
	elif current_weapon == assault_rifle:
		if assault_rifle_magazine > 0:
			assault_rifle_shoot_sound.play()
			assault_rifle_magazine -= 1
			if assault_rifle_magazine == 0:
				can_shoot = false

func _on_assault_rifle_fire_timeout():
	if can_shoot and assault_rifle_magazine > 0:
		shoot()
	else:
		assault_rifle_fire_timer.stop()

func reload_weapon():
	if is_reloading:
		return  # Prevent consecutive reloads

	if current_weapon == shotgun:
		shotgun_reload_sound.play()
		if is_weapon_aimed:
			reload_animation_aiming.play("reload_aiming")
		else:
			reload_animation_not_aiming.play("reload_not_aiming")
	elif current_weapon == assault_rifle:
		assault_rifle_reload_sound.play()
		assault_rifle_magazine = 31
	
	is_reloading = true  # Set the reloading flag
	can_shoot = false  # Ensure shooting is disabled during reload
	
	reload_timer.start(current_reload_time)  # Start the reload timer with the current weapon's reload time

func toggle_weapon_position():
	if is_weapon_aimed:
		current_weapon.position = weapon_idle_position
	else:
		current_weapon.position = weapon_aimed_position
	is_weapon_aimed = not is_weapon_aimed

func _on_reload_timeout():
	print("Timeout detected")
	can_shoot = true  # Re-enable shooting after the reload timer completes
	is_reloading = false  # Reset the reloading flag
