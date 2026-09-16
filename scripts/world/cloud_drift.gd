extends Node3D

@export var speed: float = 0.6
@export var min_x: float = -35.0
@export var max_x: float = 35.0

func _process(delta: float) -> void:
	position.x += speed * delta
	if position.x > max_x:
		position.x = min_x
