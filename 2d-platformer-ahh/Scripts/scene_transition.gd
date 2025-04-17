extends CanvasLayer

@onready var animation_player = $AnimationPlayer

func change_scene():
	animation_player.play("dissolve")
	await animation_player.animation_finished
	GameManager.next_level()
	animation_player.play_backwards("dissolve")
