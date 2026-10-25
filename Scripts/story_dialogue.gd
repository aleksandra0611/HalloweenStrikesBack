extends CanvasLayer

signal finished

const CHARS_PER_SEC := 45.0
const ORANGE := Color("e8731a")

var skip_all: bool = false   # true once the player skipped the dialogue

var _lines: Array = []
var _index: int = 0
var _typing: bool = false
var _shown: float = 0.0

var _dim: ColorRect
var _panel: PanelContainer
var _pumpkin: PumpkinPortrait
var _portrait_tex: TextureRect
var _name_label: Label
var _text_label: Label
var _hint_label: Label
var _skip_button: Button
var _blip: AudioStreamPlayer
var _voice_pitch: float = 1.0

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep working while the game is paused

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.35)
	add_child(_dim)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.gui_input.connect(_on_gui_input)

	# the box at the bottom of the screen
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.04, 0.12, 0.95)
	style.border_color = ORANGE
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_left = 30
	_panel.offset_right = -30
	_panel.offset_top = 24
	_panel.offset_bottom = 210

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_panel.add_child(row)

	# portrait
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(130, 130)
	row.add_child(holder)
	_pumpkin = PumpkinPortrait.new()
	holder.add_child(_pumpkin)
	_pumpkin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_tex = TextureRect.new()
	_portrait_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp pixel art
	_portrait_tex.visible = false
	holder.add_child(_portrait_tex)
	_portrait_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# name + text + hint
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 24)
	_name_label.add_theme_color_override("font_color", ORANGE)
	col.add_child(_name_label)

	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.custom_minimum_size = Vector2(0, 80)
	_text_label.add_theme_font_size_override("font_size", 20)
	col.add_child(_text_label)

	var bottom := HBoxContainer.new()
	col.add_child(bottom)
	_hint_label = Label.new()
	_hint_label.text = "Click or press Space to continue"
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	bottom.add_child(_hint_label)
	_skip_button = Button.new()
	_skip_button.text = "Skip (Esc)"
	_skip_button.pressed.connect(_skip)
	bottom.add_child(_skip_button)

	# labels and containers must not eat clicks, so clicking the box advances the text
	_ignore_mouse(_panel)

	_set_open(false)
	
	_blip = AudioStreamPlayer.new()
	_blip.stream = load("res://Audio/blip.wav")
	_blip.bus = "SFX"
	add_child(_blip)

func _ignore_mouse(n: Node) -> void:
	if n is Control and not n is Button:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore_mouse(c)

func _set_open(open: bool) -> void:
	_dim.visible = open
	_panel.visible = open


# Shows the lines one after another. Finishes when the player reaches the end or skips.
func play(lines: Array) -> void:
	if skip_all or lines.is_empty():
		return
	_lines = lines
	_index = 0
	_set_open(true)
	_show_line()
	await finished
	_set_open(false)


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	_name_label.text = line.get("speaker", "Jack")
	_text_label.text = line["text"]
	_text_label.visible_characters = 0
	_shown = 0.0
	_typing = true
	_hint_label.visible = false

	var art: String = line.get("portrait", "")
	if art != "" and ResourceLoader.exists(art):
		_portrait_tex.texture = load(art)
		_portrait_tex.visible = true
		_pumpkin.visible = false
	else:
		_portrait_tex.visible = false
		_pumpkin.visible = true

func _process(delta: float) -> void:
	if not _typing:
		return
	var before := int(_shown)
	_shown += CHARS_PER_SEC * delta
	var now := int(_shown)
	_text_label.visible_characters = now
	# a blip every second letter, skipping spaces
	if now != before and now % 2 == 0 and now <= _text_label.text.length() \
			and _text_label.text[now - 1] != " ":
		_blip.pitch_scale = _voice_pitch * randf_range(0.85, 1.15)
		_blip.play()
	if now >= _text_label.text.length():
		_finish_typing()

func _finish_typing() -> void:
	_typing = false
	_text_label.visible_characters = -1
	_hint_label.visible = true

func _advance() -> void:
	if _typing:
		_finish_typing()   # first click shows the whole line
		return
	_index += 1
	if _index >= _lines.size():
		finished.emit()
	else:
		_show_line()

func _skip() -> void:
	skip_all = true
	_typing = false
	finished.emit()

# ---------- input ----------

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()

func _unhandled_input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_skip()   # Esc skips (and doesn't open the pause menu)
		get_viewport().set_input_as_handled()

# placeholder jack-o'-lantern 

class PumpkinPortrait extends Control:
	func _draw() -> void:
		var glow := Color("ffcf4a")
		var c := size * 0.5 + Vector2(0, 8)
		var r := minf(size.x, size.y) * 0.36
		# body
		draw_set_transform(c, 0.0, Vector2(1.2, 1.0))
		draw_circle(Vector2.ZERO, r, Color("e8731a"))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color("a84a0a"), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# stem
		draw_rect(Rect2(c.x - 6, c.y - r - 14, 12, 18), Color("4a7a1e"))
		# eyes
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(-34, -12), c + Vector2(-12, -12), c + Vector2(-23, -34)]), glow)
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(12, -12), c + Vector2(34, -12), c + Vector2(23, -34)]), glow)
		# toothy mouth
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(-32, 12), c + Vector2(-16, 26), c + Vector2(-8, 14), c + Vector2(0, 28),
			c + Vector2(8, 14), c + Vector2(16, 26), c + Vector2(32, 12),
			c + Vector2(20, 40), c + Vector2(-20, 40)]), glow)
