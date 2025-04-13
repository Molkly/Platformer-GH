extends Node2D

@export var player_controller : PlayerController
@export var animation_player : AnimationPlayer
@export var sprite : Sprite2D



func _ready() -> void:
	pass



func _process(delta: float) -> void:

	if player_controller.direction == 1:
		sprite.flip_h = false
	elif player_controller.direction == -1:
		sprite.flip_h = true


	if abs(player_controller.velocity.x) > 0.0 and player_controller.right == true:
		animation_player.play("move_right")
	elif abs(player_controller.velocity.x) > 0.0 and player_controller.left == true:
		animation_player.play("move_left")
	elif player_controller.velocity.x == 0 and player_controller.right == true:
		animation_player.play("idle_right")
	elif player_controller.velocity.x == 0 and player_controller.left == true:
		animation_player.play("idle_left")


	if player_controller.velocity.y < 0.0 and player_controller.right == true:
			animation_player.play("jump_right")
	elif player_controller.velocity.y < 0.0 and player_controller.left == true:
			animation_player.play("jump_left")


	if player_controller.velocity.y > 0.0 and player_controller.right == true:
			animation_player.play("fall_right")
	elif player_controller.velocity.y > 0.0 and player_controller.left == true:
			animation_player.play("fall_left")
