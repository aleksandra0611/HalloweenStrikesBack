extends PanelContainer

signal closed

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var damage_check: CheckBox = %DamageNumbersCheck
@onready var back_button: Button = %BackButton

func _ready() -> void:
	master_slider.value = GameSettings.master_volume
	music_slider.value = GameSettings.music_volume
	sfx_slider.value = GameSettings.sfx_volume
	fullscreen_check.button_pressed = GameSettings.fullscreen
	damage_check.button_pressed = GameSettings.show_damage_numbers

	master_slider.value_changed.connect(func(v): GameSettings.master_volume = v; GameSettings.apply())
	music_slider.value_changed.connect(func(v): GameSettings.music_volume = v; GameSettings.apply())
	sfx_slider.value_changed.connect(func(v): GameSettings.sfx_volume = v; GameSettings.apply())
	fullscreen_check.toggled.connect(func(on): GameSettings.fullscreen = on; GameSettings.apply())
	damage_check.toggled.connect(func(on): GameSettings.show_damage_numbers = on)
	back_button.pressed.connect(close)

func close() -> void:
	GameSettings.save_settings()
	closed.emit()
