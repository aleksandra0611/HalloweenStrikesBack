extends Label

var amount: int = 0
var number_color: Color = Color.WHITE
var start_position: Vector2 = Vector2.ZERO
var tween: Tween

func setup(value: int, color: Color, pos: Vector2) -> void:
	amount = value
	number_color = color
	start_position = pos

func _ready() -> void:
	text = str(amount)
	z_index = 100
	add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_color", number_color)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 6)
	global_position = start_position + Vector2(randf_range(-12.0, 12.0), 0.0)
	_play()

func add(value: int) -> void:
	amount += value
	text = str(amount)
	_play()

func _play() -> void:
	if tween:
		tween.kill()
	modulate.a = 1.0
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 60.0, 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.finished.connect(queue_free)
