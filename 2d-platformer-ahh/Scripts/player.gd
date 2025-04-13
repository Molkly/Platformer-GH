extends CharacterBody2D
class_name PlayerController

@export var speed = 85.0
@export var jump_power = 7.0

var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction = 0
var right = true
var left = false


@export var coyote_time := 0.15
var coyote_timer := 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if direction == 1:
		right = true
		left = false
	elif direction == -1:
		left = true
		right = false

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("Jump") and coyote_timer > 0.0:
		velocity.y = jump_power * jump_multiplier
		coyote_timer = 0.0

	direction = Input.get_axis("Move_Left", "Move_Right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)

	if Input.is_action_pressed("Down"):
		set_collision_mask_value(2, false)
	else:
		set_collision_mask_value(2, true)

	move_and_slide()
