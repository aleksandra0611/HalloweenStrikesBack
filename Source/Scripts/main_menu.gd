extends Control

const WORLD_SCENE := "res://Scenes/world.tscn"

@onready var menu_container: CenterContainer = $CenterContainer
@onready var story_button: Button = %StoryButton
@onready var endless_button: Button = %EndlessButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_panel: PanelContainer = %SettingsPanel

func _ready() -> void:
	settings_panel.visible = false
	story_button.pressed.connect(_start_story)
	endless_button.pressed.connect(_start_endless)
	if GameSettings.best_wave > 0:
		endless_button.text = "Endless Mode (best: wave %d)" % GameSettings.best_wave
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(func(): get_tree().quit())
	settings_panel.closed.connect(_close_settings)

func _open_settings() -> void:
	menu_container.visible = false
	settings_panel.visible = true

func _close_settings() -> void:
	settings_panel.visible = false
	menu_container.visible = true

func _start_story() -> void:
	GameMode.endless = false
	GameMode.level = 1
	GameMode.carry_unlocked = {}
	GameMode.intro_seen = false
	get_tree().change_scene_to_file(WORLD_SCENE)

func _start_endless() -> void:
	GameMode.endless = true
	GameMode.level = 1
	GameMode.carry_unlocked = {}
	GameMode.intro_seen = false
	get_tree().change_scene_to_file(WORLD_SCENE)
