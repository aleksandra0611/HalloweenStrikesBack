extends Node2D

var character_scene: PackedScene = preload("res://Scenes/character1.tscn")
var enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")

const WARRIOR_COST := 2
const KILL_REWARD := 1

var money: int = 4

@onready var button: Button = $CanvasLayer/VBoxContainer/Button
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var enemy_spawn_point: Marker2D = $SpawnPoint_enemies
@onready var enemy_timer: Timer = $Timer
@onready var money_label: Label = $CanvasLayer/Money/MoneyLabel

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	enemy_timer.timeout.connect(_on_enemy_timer_timeout)
	update_money_ui()

func _on_button_pressed() -> void:
	if money < WARRIOR_COST:
		return
	money -= WARRIOR_COST
	update_money_ui() 
	var character = character_scene.instantiate()
	character.global_position = spawn_point.global_position
	add_child(character)

func _on_enemy_timer_timeout() -> void:
	var enemy = enemy_scene.instantiate() 
	enemy.global_position = enemy_spawn_point.global_position
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)

func _on_enemy_died() -> void:
	money += KILL_REWARD
	update_money_ui()

func update_money_ui() -> void:
	money_label.text = "Gold: %d" % money
	button.disabled = money < WARRIOR_COST
	button.text = "Warrior (%d)" % WARRIOR_COST
	
	
