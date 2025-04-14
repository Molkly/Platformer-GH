extends AnimatedSprite2D

@onready var animation_player = $"AnimatedSprite2D"

var on = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play("default")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
