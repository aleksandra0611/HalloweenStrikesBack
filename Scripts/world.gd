extends Node2D

var character_scene: PackedScene = preload("res://Scenes/character1.tscn")
var enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")

@onready var button: Button = $CanvasLayer/VBoxContainer/Button
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var enemy_spawn_point: Marker2D = $SpawnPoint_enemies
@onready var enemy_timer: Timer = $Timer

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	enemy_timer.timeout.connect(_on_enemy_timer_timeout)

func _on_button_pressed() -> void:
	var character = character_scene.instantiate()
	character.global_position = spawn_point.global_position
	add_child(character)

func _on_enemy_timer_timeout() -> void:
	var enemy = enemy_scene.instantiate() 
	enemy.global_position = enemy_spawn_point.global_position
	add_child(enemy)
