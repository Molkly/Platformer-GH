extends CharacterBody2D
class_name PlayerController

@export var speed = 100
@export var jump_power = 9.0
@export var wall_jump_vertical_power := 9.0
@export var wall_jump_horizontal_power := 100.0
@export var max_wall_slide_speed := 30.0
@export var dash_speed := 400.0
@export var dash_time := 0.15
@export var dash_cooldown := 0.1

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

@export var coyote_time := 0.15
@export var wall_coyote_time := .2

var coyote_timer := 0.0
var wall_coyote_timer := 0.0

var is_wall_sliding := false
var last_wall_direction := 0  # -1 = left wall, 1 = right wall, 0 = none
var current_wall_direction := 0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Input direction
	direction = Input.get_axis("Move_Left", "Move_Right")
	if direction == 1:
		right = true
		left = false
	elif direction == -1:
		left = true
		right = false

	# Detect wall touch and wall direction
	var touching_left_wall = test_move(global_transform, Vector2(-1, 0))
	var touching_right_wall = test_move(global_transform, Vector2(1, 0))
	var new_wall_dir = 0

	if touching_left_wall and Input.get_action_strength("Move_Left") > 0.0:
		new_wall_dir = -1
	elif touching_right_wall and Input.get_action_strength("Move_Right") > 0.0:
		new_wall_dir = 1

	# Update wall coyote timer
	if new_wall_dir != 0:
		wall_coyote_timer = wall_coyote_time
		current_wall_direction = new_wall_dir
	else:
		wall_coyote_timer -= delta
		if wall_coyote_timer <= 0.0:
			current_wall_direction = 0

	# Update ground coyote timer
	if is_on_floor():
		coyote_timer = coyote_time
		last_wall_direction = 0  # Reset wall jump lockout
	else:
		coyote_timer -= delta

	# Wall sliding
	is_wall_sliding = not is_on_floor() and current_wall_direction != 0 and velocity.y > 0
	if is_wall_sliding:
		velocity.y = min(velocity.y, max_wall_slide_speed)

	# Jumping
	if Input.is_action_just_pressed("Jump"):
		if coyote_timer > 0.0:
			velocity.y = jump_power * jump_multiplier
			coyote_timer = 0.0
		elif wall_coyote_timer > 0.0 and current_wall_direction != last_wall_direction:
			velocity.y = wall_jump_vertical_power * jump_multiplier
			velocity.x = -current_wall_direction * wall_jump_horizontal_power
			last_wall_direction = current_wall_direction
			wall_coyote_timer = 0.0

	# Horizontal movement (except when sliding)
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

	# Dash input
	if Input.is_action_just_pressed("Dash") and can_dash and not has_dashed:
		is_dashing = true
		has_dashed = true
		can_dash = false
		dash_timer = dash_time
	
	# Get dash direction: horizontal/vertical or diagonal
		var x_input := Input.get_action_strength("Move_Right") - Input.get_action_strength("Move_Left")
		var y_input := Input.get_action_strength("Down") - Input.get_action_strength("Up")
		dash_direction = Vector2(x_input, y_input)

		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2(direction, 0)
		else:
			dash_direction = dash_direction.normalized()

		velocity = dash_direction * dash_speed

	if abs(dash_direction.y) > 0:
		dash_direction.y *= 0.9
# Dashing behavior
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed  # lock velocity
		if dash_timer <= 0.0:
			is_dashing = false
			
	if is_on_floor() and not is_dashing:
		coyote_timer = coyote_time
		can_dash = true
		has_dashed = false
		last_wall_direction = 0

	move_and_slide()
