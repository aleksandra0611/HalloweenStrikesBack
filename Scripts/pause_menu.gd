extends CanvasLayer

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton
@onready var menu_button: Button = %MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_resume)
	restart_button.pressed.connect(_restart)
	menu_button.pressed.connect(_to_menu)
	quit_button.pressed.connect(func(): get_tree().quit())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):   # Esc by default
		if get_parent().game_over:             # don't open over the win/lose screen
			return
		if visible:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()

func _pause() -> void:
	visible = true
	get_tree().paused = true

func _resume() -> void:
	visible = false
	get_tree().paused = false

func _to_menu() -> void:
	get_tree().paused = false   # always unpause before changing scenes
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
