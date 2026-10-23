extends Node

const PATH := "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var fullscreen: bool = false
var show_damage_numbers: bool = true

func _ready() -> void:
	load_settings()
	apply()

func apply() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func _set_bus(bus_name: String, value: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i == -1:
		return   # bus doesn't exist yet
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(i, value <= 0.001)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("game", "damage_numbers", show_damage_numbers)
	cfg.save(PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master", 1.0)
	music_volume = cfg.get_value("audio", "music", 1.0)
	sfx_volume = cfg.get_value("audio", "sfx", 1.0)
	fullscreen = cfg.get_value("video", "fullscreen", false)
	show_damage_numbers = cfg.get_value("game", "damage_numbers", true)
