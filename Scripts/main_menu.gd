extends Control

const WORLD_SCENE := "res://Scenes/world.tscn"

@onready var menu_container: CenterContainer = $CenterContainer
@onready var story_button: Button = %StoryButton
@onready var endless_button: Button = %EndlessButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var damage_check: CheckBox = %DamageNumbersCheck
@onready var back_button: Button = %BackButton

func _ready() -> void:
	settings_panel.visible = false
	story_button.pressed.connect(_start_story)
	endless_button.disabled = true
	endless_button.text = "Endless Mode (coming soon)"
	settings_button.pressed.connect(_open_settings)
	back_button.pressed.connect(func(): settings_panel.visible = false)
	quit_button.pressed.connect(func(): get_tree().quit())
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
	back_button.pressed.connect(_close_settings)

func _open_settings() -> void:
	menu_container.visible = false
	settings_panel.visible = true

func _close_settings() -> void:
	GameSettings.save_settings()
	settings_panel.visible = false
	menu_container.visible = true

func _start_story() -> void:
	GameMode.endless = false
	GameMode.intro_seen = false
	get_tree().change_scene_to_file(WORLD_SCENE)

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_fullscreen_toggled(on: bool) -> void:
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
