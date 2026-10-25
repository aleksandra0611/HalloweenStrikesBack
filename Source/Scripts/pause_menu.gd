extends CanvasLayer

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var pause_buttons: Control = %PauseButtons

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	settings_panel.visible = false
	settings_button.pressed.connect(_open_settings)
	settings_panel.closed.connect(_close_settings)
	resume_button.pressed.connect(_resume)
	restart_button.pressed.connect(_restart)
	menu_button.pressed.connect(_to_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_panel.visible:
			settings_panel.close()
		else:
			toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if get_parent().game_over:
		return
	if visible:
		_resume()
	else:
		_pause()

func _pause() -> void:
	visible = true
	get_tree().paused = true

func _open_settings() -> void:
	pause_buttons.visible = false
	settings_panel.visible = true

func _close_settings() -> void:
	settings_panel.visible = false
	pause_buttons.visible = true

func _resume() -> void:
	_close_settings()
	visible = false
	get_tree().paused = false

func _to_menu() -> void:
	get_tree().paused = false   # always unpause before changing scenes
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
