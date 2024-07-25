extends CharacterBody3D

const SHOTGUN_RELOAD_TIME = 2.1

var speed = 5.0
var run_speed = 8.0
var crouch_speed = 2.5
var jump_velocity = 4.5
var mouse_sensitivity = 0.05

var is_firing = false
var fire_timer = 0.0
var shotgun_cooldown_timer = 0.0
var shotgun_cooldown = 0.8

var reload_timer = 0.0
var is_reloading = false

var is_crouching = false
var is_running = false

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var weapons = $Camera3D/Weapons
@onready var shotgun = $Camera3D/Weapons/Shotgun
@onready var assault_rifle = $Camera3D/Weapons/AssaultRifle
@onready var ammo_ui = $AmmoUI
@onready var collision_shape = $CollisionShape3D

var current_weapon: Weapon

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	collision_layer = 0b00000000_00000000_00000000_00000001  # Layer 1
	collision_mask = 0b00000000_00000000_00000000_00000011  # Layer 2 (environment)
	
	# Initialize weapons
	shotgun.weapon_type = Weapon.WeaponType.SHOTGUN
	assault_rifle.weapon_type = Weapon.WeaponType.ASSAULT_RIFLE
	
	for weapon in [shotgun, assault_rifle]:
		weapon.ammo_changed.connect(_on_weapon_ammo_changed)
	
	switch_weapon(Weapon.WeaponType.SHOTGUN)

func _physics_process(delta):
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Handle crouch
	if Input.is_action_just_pressed("crouch"):
		toggle_crouch()

	# Handle run
	is_running = Input.is_action_pressed("run") and not is_crouching

	# Get the input direction and handle the movement/deceleration
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Calculate speed based on state
	var target_speed = speed
	if is_running:
		target_speed = run_speed
	elif is_crouching:
		target_speed = crouch_speed

	# Move the player
	if direction != Vector3.ZERO:
		velocity.x = direction.x * target_speed
		velocity.z = direction.z * target_speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta)
		velocity.z = move_toward(velocity.z, 0, speed * delta)

	move_and_slide()
	handle_firing(delta)
	update_cooldown(delta)
	update_reload(delta)

func handle_input_actions(event):
	if event.is_action_pressed("shoot") and not is_reloading:
		is_firing = true
		# Immediate shot for the first press, if not in cooldown
		if current_weapon.weapon_type == Weapon.WeaponType.SHOTGUN:
			if shotgun_cooldown_timer <= 0:
				current_weapon.shoot(camera)
				shotgun_cooldown_timer = shotgun_cooldown
				is_firing = false
		elif fire_timer == 0.0:
			current_weapon.shoot(camera)
	elif event.is_action_released("shoot"):
		is_firing = false
	
	if event.is_action_pressed("reload") and not is_reloading:
		start_reload()
	
	if event.is_action_pressed("weapon_1"):
		switch_weapon(Weapon.WeaponType.SHOTGUN)
	
	if event.is_action_pressed("weapon_2"):
		switch_weapon(Weapon.WeaponType.ASSAULT_RIFLE)

func _input(event):
	handle_camera_rotation(event)
	handle_input_actions(event)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func handle_firing(delta):
	if is_firing and not current_weapon.is_reloading:
		if current_weapon.weapon_type == Weapon.WeaponType.SHOTGUN:
			if shotgun_cooldown_timer <= 0:
				current_weapon.shoot(camera)
				shotgun_cooldown_timer = shotgun_cooldown
				is_firing = false
		elif current_weapon.weapon_type == Weapon.WeaponType.ASSAULT_RIFLE:
			fire_timer += delta
			if fire_timer >= current_weapon.fire_rate:
				current_weapon.shoot(camera)
				fire_timer = 0.0
	else:
		fire_timer = 0.0

func update_cooldown(delta):
	if shotgun_cooldown_timer > 0:
		shotgun_cooldown_timer -= delta

func handle_camera_rotation(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func switch_weapon(new_weapon_type):
	if is_reloading:
		cancel_reload()
		
	match new_weapon_type:
		Weapon.WeaponType.SHOTGUN:
			current_weapon = shotgun
		Weapon.WeaponType.ASSAULT_RIFLE:
			current_weapon = assault_rifle
	
	shotgun.visible = (current_weapon == shotgun)
	assault_rifle.visible = (current_weapon == assault_rifle)
	update_ammo_display()
	fire_timer = 0.0
	shotgun_cooldown_timer = 0.0  # Reset cooldown when switching weapons

func _on_weapon_ammo_changed(current_ammo: int, max_ammo: int):
	update_ammo_display()

func update_ammo_display():
	ammo_ui.update_ammo(current_weapon.current_ammo, current_weapon.max_ammo, current_weapon.weapon_type)
	
func start_reload():
	if current_weapon.current_ammo < current_weapon.max_ammo:
		is_reloading = true
		reload_timer = SHOTGUN_RELOAD_TIME if current_weapon.weapon_type == Weapon.WeaponType.SHOTGUN else 0.0
		current_weapon.start_reload()
		
func update_reload(delta):
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			finish_reload()

func finish_reload():
	is_reloading = false
	current_weapon.finish_reload()
	update_ammo_display()
	
func cancel_reload():
	is_reloading = false
	reload_timer = 0.0
	current_weapon.cancel_reload()

func toggle_crouch():
	is_crouching = !is_crouching
	if is_crouching:
		collision_shape.scale.y = 0.5
		camera.position.y -= 0.5
	else:
		collision_shape.scale.y = 1.0
		camera.position.y += 0.5
