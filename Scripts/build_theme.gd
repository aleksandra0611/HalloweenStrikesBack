@tool
extends EditorScript
# Run once: open this file in the Script editor and use File > Run (Ctrl+Shift+X).
# It saves the theme file below. Then set it in:
# Project Settings > GUI > Theme > Custom
# Re-run it any time you change the colors.

const SAVE_PATH := "res://UI/halloween_theme.tres"
const FONT_PATH := "res://Fonts/font.ttf"   # optional pixel font
const FONT_SIZE := 16
const CORNER_RADIUS := 6   # 0 = sharp corners, 4 to 8 looks like a small curve

# ---------- palette ----------
const C_PANEL := Color("#1b1228")            # near-black purple
const C_PURPLE := Color("#2e1a47")
const C_PURPLE_LIGHT := Color("#4a2a72")
const C_ORANGE := Color("#ff7a1a")           # pumpkin
const C_ORANGE_LIGHT := Color("#ffb347")
const C_ORANGE_DARK := Color("#c85a00")
const C_TEXT := Color("#f2ead3")             # bone white
const C_DISABLED_FILL := Color("#1f1a26")
const C_DISABLED_BORDER := Color("#4a4455")
const C_DISABLED_TEXT := Color("#6f6a7a")

func _run() -> void:
	var t := _build_theme()
	DirAccess.make_dir_recursive_absolute("res://UI")
	var err := ResourceSaver.save(t, SAVE_PATH)
	print("Theme saved to %s: %s" % [SAVE_PATH, error_string(err)])

func _build_theme() -> Theme:
	var t := Theme.new()

	# ----- font -----
	# For a pixel font, double-click the font file in the FileSystem panel and set
	# Antialiasing to None in the Import tab, then click Reimport.
	if ResourceLoader.exists(FONT_PATH):
		t.default_font = load(FONT_PATH)
	t.default_font_size = FONT_SIZE

	# ----- buttons -----
	# "pressed" is bright on purpose: Attack/Defend are toggle buttons,
	# so this is also how the active stance is shown.
	t.set_stylebox("normal", "Button", _box(C_PURPLE, C_ORANGE))
	t.set_stylebox("hover", "Button", _box(C_PURPLE_LIGHT, C_ORANGE_LIGHT))
	t.set_stylebox("pressed", "Button", _box(C_ORANGE_DARK, C_ORANGE_LIGHT))
	t.set_stylebox("hover_pressed", "Button", _box(C_ORANGE, C_ORANGE_LIGHT))
	t.set_stylebox("disabled", "Button", _box(C_DISABLED_FILL, C_DISABLED_BORDER))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", C_PANEL)
	t.set_color("font_hover_pressed_color", "Button", C_PANEL)
	t.set_color("font_disabled_color", "Button", C_DISABLED_TEXT)

	# ----- labels -----
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_outline_color", "Label", Color.BLACK)
	t.set_constant("outline_size", "Label", 4)

	# ----- panels (money box, result box, pause menu) -----
	var panel := _box(Color(C_PANEL, 0.92), C_ORANGE, 3, 10)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)

	# ----- HUD progress bar (spawn bar) -----
	# A type variation, so the health bars above units and bases are not affected.
	# Select the SpawnBar node and set Theme > Theme Type Variation to "HudBar".
	t.set_type_variation("HudBar", "ProgressBar")
	t.set_stylebox("background", "HudBar", _box(C_DISABLED_FILL, C_ORANGE, 2, 0, 4))
	t.set_stylebox("fill", "HudBar", _box(C_ORANGE, C_ORANGE, 0, 0, 3))

	return t

func _box(fill: Color, border: Color, border_width: int = 3, margin: int = 8, radius: int = CORNER_RADIUS) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)      # was 0
	s.set_content_margin_all(margin)
	s.anti_aliasing = true               # was false
	return s
