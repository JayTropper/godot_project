extends CharacterBody2D

const GRID_SIZE = 50  # Adjust based on your tile size
const MOVE_DELAY = 0.2  # Delay between moves to prevent rapid movement

@onready var animated_sprite = $Frog
@onready var move_timer = $MoveTimer
@onready var camera = $Camera2D

var can_move = true
var start_y_position: float

func _ready():
	move_timer = Timer.new()
	move_timer.one_shot = true
	move_timer.wait_time = MOVE_DELAY
	move_timer.timeout.connect(_on_move_timer_timeout)
	add_child(move_timer)
	
	start_y_position = position.y
	
	# Initialize camera position and limits
	call_deferred("_init_camera")

func _init_camera():
	var viewport_height = get_viewport_rect().size.y
	camera.limit_top = position.y - viewport_height / 2
	camera.limit_bottom = position.y + viewport_height / 2
	camera.limit_left = 0
	camera.limit_right = get_viewport_rect().size.x
	camera.reset_smoothing()

func _physics_process(_delta):
	if can_move:
		var move_direction = Vector2.ZERO
		
		if Input.is_action_just_pressed("move_up"):
			move_direction = Vector2.UP
			animated_sprite.play("jump")
		elif Input.is_action_just_pressed("move_down"):
			move_direction = Vector2.DOWN
			animated_sprite.play("jump")
		elif Input.is_action_just_pressed("move_left"):
			move_direction = Vector2.LEFT
			animated_sprite.play("jump")
		elif Input.is_action_just_pressed("move_right"):
			move_direction = Vector2.RIGHT
			animated_sprite.play("jump")
		
		if move_direction != Vector2.ZERO:
			position += move_direction * GRID_SIZE
			can_move = false
			move_timer.start()
			update_camera()

func _on_move_timer_timeout():
	can_move = true
	animated_sprite.play("idle")

func _on_area_2d_body_entered(body):
	if body.is_in_group("cars"):
		call_deferred("_reload_scene")

func _reload_scene():
	get_tree().reload_current_scene()

func update_camera():
	var viewport_height = get_viewport_rect().size.y
	var camera_top = camera.limit_top
	
	# Update top limit if frog is in upper half of view
	if position.y < camera_top + viewport_height / 2:
		camera.limit_top = position.y - viewport_height / 2
		camera.limit_top = max(camera.limit_top, -100000)  # Don't go above the start
	
	# Update bottom limit to show one screen height below the frog
	camera.limit_bottom = position.y + viewport_height / 2
	
	# Ensure we don't show below the start position
	camera.limit_bottom = min(camera.limit_bottom, start_y_position + viewport_height)
