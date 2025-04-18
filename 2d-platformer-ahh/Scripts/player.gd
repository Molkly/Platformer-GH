extends CharacterBody2D
class_name PlayerController

@export var sfx_jump : AudioStream
@export var sfx_wall_jump : AudioStream
@export var sfx_land : AudioStream
@export var sfx_dash : AudioStream
@export var sfx_steps : AudioStream
@export var sfx_wall_slide : AudioStream

@export var pitch_jump := 1.0
@export var pitch_wall_jump := 1.0
@export var pitch_land := 1.5
@export var pitch_dash := 1.0
@export var pitch_wall_slide := 3

@export var volume_jump := -15
@export var volume_wall_jump := -15
@export var volume_land := -20
@export var volume_dash := -10
@export var volume_wall_slide := -25

@export_range(0.0, 1.0, 0.01) var sfx_pitch_variance := 0.15

@export var speed = 100
@export var jump_power = 9.0
@export var wall_jump_vertical_power := 9.0
@export var wall_jump_horizontal_power := 100.0
@export var max_wall_slide_speed := 30.0
@export var dash_speed := 400.0
@export var dash_time := 0.15
@export var dash_cooldown := 0.1
@export var background_color := Color(1, 0, 0)
@export var coyote_time := 0.15
@export var wall_coyote_time := .2

@onready var color_rect = $ColorRect

var has_dashed := false
var is_dashing := false
var dash_timer := 0.0
var can_dash := true
var dash_direction := Vector2.ZERO
var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction = 0
var right = true
var left = false

var coyote_timer := 0.0
var wall_coyote_timer := 0.0
var is_wall_sliding := false
var last_wall_direction := 0
var current_wall_direction := 0
var was_on_floor := false
var wall_slide_player: AudioStreamPlayer = null

func _ready() -> void:
	color_rect.color = background_color
	randomize()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	direction = Input.get_axis("Move_Left", "Move_Right")
	if direction == 1:
		right = true
		left = false
	elif direction == -1:
		left = true
		right = false

	var touching_left_wall = test_move(global_transform, Vector2(-1, 0))
	var touching_right_wall = test_move(global_transform, Vector2(1, 0))
	var new_wall_dir = 0

	if touching_left_wall and Input.get_action_strength("Move_Left") > 0.0:
		new_wall_dir = -1
	elif touching_right_wall and Input.get_action_strength("Move_Right") > 0.0:
		new_wall_dir = 1

	if new_wall_dir != 0:
		wall_coyote_timer = wall_coyote_time
		current_wall_direction = new_wall_dir
	else:
		wall_coyote_timer -= delta
		if wall_coyote_timer <= 0.0:
			current_wall_direction = 0

	if is_on_floor():
		coyote_timer = coyote_time
		last_wall_direction = 0
	else:
		coyote_timer -= delta

	# Landing SFX
	if not was_on_floor and is_on_floor():
		play_sfx_from_pool(sfx_land, pitch_land, volume_land)
	was_on_floor = is_on_floor()

	# Wall sliding
	var was_wall_sliding := is_wall_sliding
	is_wall_sliding = not is_on_floor() and current_wall_direction != 0 and velocity.y > 0

	if is_wall_sliding:
		velocity.y = min(velocity.y, max_wall_slide_speed)
		if not was_wall_sliding:
			wall_slide_player = AudioStreamPlayer.new()
			wall_slide_player.stream = sfx_wall_slide
			wall_slide_player.pitch_scale = pitch_wall_slide + randf_range(-sfx_pitch_variance, sfx_pitch_variance)
			wall_slide_player.pitch_scale *= 1 + (abs(velocity.y) / max_wall_slide_speed)
			wall_slide_player.volume_db = volume_wall_slide
			add_child(wall_slide_player)
			wall_slide_player.play()
	elif was_wall_sliding and wall_slide_player:
		wall_slide_player.stop()
		wall_slide_player.queue_free()
		wall_slide_player = null

	# Jumping
	if Input.is_action_just_pressed("Jump"):
		if coyote_timer > 0.0:
			velocity.y = jump_power * jump_multiplier
			coyote_timer = 0.0
			play_sfx_from_pool(sfx_jump, pitch_jump, volume_jump)
		elif wall_coyote_timer > 0.0 and current_wall_direction != last_wall_direction:
			velocity.y = wall_jump_vertical_power * jump_multiplier
			velocity.x = -current_wall_direction * wall_jump_horizontal_power
			last_wall_direction = current_wall_direction
			wall_coyote_timer = 0.0
			play_sfx_from_pool(sfx_wall_jump, pitch_wall_jump, volume_wall_jump)

	# Horizontal movement
	if not is_wall_sliding:
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)

	# Drop through one-way platforms
	if Input.is_action_pressed("Down"):
		set_collision_mask_value(2, false)
	else:
		set_collision_mask_value(2, true)

	# Dash
	if Input.is_action_just_pressed("Dash") and can_dash and not has_dashed:
		is_dashing = true
		has_dashed = true
		can_dash = false
		dash_timer = dash_time

		var x_input := Input.get_action_strength("Move_Right") - Input.get_action_strength("Move_Left")
		var y_input := Input.get_action_strength("Down") - Input.get_action_strength("Up")
		dash_direction = Vector2(x_input, y_input)

		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2(direction, 0)
		else:
			dash_direction = dash_direction.normalized()

		velocity = dash_direction * dash_speed

		# Only play dash sound if dash direction is not zero
		if dash_direction.length() > 0:
			play_sfx_from_pool(sfx_dash, pitch_dash, volume_dash)

	if abs(dash_direction.y) > 0:
		dash_direction.y *= 0.9

	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed
		if dash_timer <= 0.0:
			is_dashing = false

	if is_on_floor() and not is_dashing:
		coyote_timer = coyote_time
		can_dash = true
		has_dashed = false
		last_wall_direction = 0

	move_and_slide()

# Dynamic sound player (overlap-safe, pitch-controlled, and volume-controlled)
func play_sfx_from_pool(stream: AudioStream, base_pitch: float = 1.0, volume_db: float = 0.0):
	if not stream:
		return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = base_pitch + randf_range(-sfx_pitch_variance, sfx_pitch_variance)
	player.volume_db = volume_db
	add_child(player)
	player.play()
	player.connect("finished", Callable(player, "queue_free"))
