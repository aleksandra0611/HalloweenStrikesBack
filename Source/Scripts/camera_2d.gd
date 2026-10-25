extends Camera2D

@export var speed: float = 600.0

func _process(delta: float) -> void:
	var dir := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir += 1.0
	position.x += dir * speed * delta
	
	var half_width := get_viewport_rect().size.x * 0.5 / zoom.x
	position.x = clampf(position.x, limit_left + half_width, limit_right - half_width)
