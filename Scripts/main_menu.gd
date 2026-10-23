extends Control

const WORLD_SCENE := "res://Scenes/world.tscn"

@onready var story_button: Button = %StoryButton
@onready var endless_button: Button = %EndlessButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var volume_slider: HSlider = %VolumeSlider
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var back_button: Button = %BackButton

func _ready() -> void:
	settings_panel.visible = false
	story_button.pressed.connect(_start_story)
	endless_button.disabled = true
	endless_button.text = "Endless Mode (coming soon)"
	settings_button.pressed.connect(func(): settings_panel.visible = true)
	back_button.pressed.connect(func(): settings_panel.visible = false)
	quit_button.pressed.connect(func(): get_tree().quit())
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

func _start_story() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_fullscreen_toggled(on: bool) -> void:
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
