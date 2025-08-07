extends Node

@export var animated_vector: Vector2 = Vector2(1, 0)
@export var angular_speed_radians_per_second: float = 1.0

var _time_elapsed_seconds: float = 0.0

func _process(delta: float) -> void:
    _time_elapsed_seconds += delta
    var angle := _time_elapsed_seconds * angular_speed_radians_per_second
    animated_vector = Vector2(cos(angle), sin(angle)) * 100
