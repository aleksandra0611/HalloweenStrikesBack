extends Node2D

var character_scene: PackedScene = preload("res://Scenes/character1.tscn")
var enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")
var archer_scene: PackedScene = preload("res://Scenes/archer.tscn")

const WARRIOR_COST := 2
const ARCHER_COST := 3
const KILL_REWARD := 1
const SPAWN_TIME := 2.0
const MAX_QUEUE := 5
const ENEMY_ARCHER_CHANCE := 0.3

# passive income (set INCOME_AMOUNT to 0 to turn it off)
const INCOME_AMOUNT := 1
const INCOME_INTERVAL := 5.0

# score
const KILL_POINTS := 100
const PAR_TIME := 240.0          # win faster than this (seconds) to earn a time bonus
const TIME_POINTS_PER_SEC := 10

var money: int = 4
var game_over: bool = false
var queue: Array[String] = []
var spawn_progress: float = 0.0
var income_timer: float = 0.0
var elapsed: float = 0.0
var kills: int = 0

@onready var button: Button = $CanvasLayer/VBoxContainer/HBoxContainer/Button
@onready var archer_button: Button = $CanvasLayer/VBoxContainer/HBoxContainer/ArcherButton
@onready var spawn_bar: ProgressBar = $CanvasLayer/VBoxContainer/SpawnBar
@onready var queue_label: Label = $CanvasLayer/VBoxContainer/QueueLabel
@onready var stats_label: Label = $CanvasLayer/StatsLabel
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var enemy_spawn_point: Marker2D = $SpawnPoint_enemies
@onready var enemy_timer: Timer = $Timer
@onready var money_label: Label = $CanvasLayer/Money/MoneyLabel
@onready var player_base: StaticBody2D = $Base
@onready var enemy_base: StaticBody2D = $EnemyBase
@onready var result_box: PanelContainer = $CanvasLayer/ResultBox
@onready var result_label: Label = $CanvasLayer/ResultBox/VBoxContainer/ResultLabel
@onready var restart_button: Button = $CanvasLayer/ResultBox/VBoxContainer/RestartButton

func _ready() -> void:
	button.pressed.connect(func(): _queue_unit("warrior", WARRIOR_COST))
	archer_button.pressed.connect(func(): _queue_unit("archer", ARCHER_COST))
	enemy_timer.timeout.connect(_on_enemy_timer_timeout)
	restart_button.pressed.connect(_on_restart_pressed)
	player_base.destroyed.connect(_on_player_base_destroyed)
	enemy_base.destroyed.connect(_on_enemy_base_destroyed)
	spawn_bar.max_value = SPAWN_TIME
	spawn_bar.value = 0.0
	update_ui()
	update_stats()

func _process(delta: float) -> void:
	if game_over:
		return
	elapsed += delta
	update_stats()
	_tick_income(delta)
	_tick_queue(delta)

func _tick_income(delta: float) -> void:
	income_timer += delta
	if income_timer >= INCOME_INTERVAL:
		income_timer -= INCOME_INTERVAL
		money += INCOME_AMOUNT
		update_ui()

func _tick_queue(delta: float) -> void:
	if queue.is_empty():
		return
	spawn_progress += delta
	spawn_bar.value = spawn_progress
	if spawn_progress >= SPAWN_TIME:
		spawn_progress = 0.0
		spawn_bar.value = 0.0
		var type: String = queue.pop_front()
		if type == "archer":
			_spawn_archer(true, spawn_point)
		else:
			_spawn_unit(character_scene, spawn_point)
		update_ui()

func _queue_unit(type: String, cost: int) -> void:
	if game_over or money < cost or queue.size() >= MAX_QUEUE:
		return
	money -= cost
	queue.append(type)
	update_ui()

func _spawn_unit(scene: PackedScene, marker: Marker2D) -> Node2D:
	var unit = scene.instantiate()
	unit.global_position = marker.global_position
	add_child(unit)
	return unit

func _spawn_archer(is_player: bool, marker: Marker2D) -> Node2D:
	var unit = archer_scene.instantiate()
	unit.is_player = is_player
	unit.global_position = marker.global_position
	add_child(unit)
	return unit

func _on_enemy_timer_timeout() -> void:
	if game_over:
		return
	var enemy: Node2D
	if randf() < ENEMY_ARCHER_CHANCE:
		enemy = _spawn_archer(false, enemy_spawn_point)
	else:
		enemy = _spawn_unit(enemy_scene, enemy_spawn_point)
	enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	money += KILL_REWARD
	kills += 1
	update_ui()
	update_stats()

func update_ui() -> void:
	money_label.text = "Gold: %d" % money
	var full := queue.size() >= MAX_QUEUE
	button.disabled = full or money < WARRIOR_COST
	archer_button.disabled = full or money < ARCHER_COST
	button.text = "Warrior (%d)" % WARRIOR_COST
	archer_button.text = "Archer (%d)" % ARCHER_COST
	queue_label.text = "Queue: %d/%d" % [queue.size(), MAX_QUEUE]

func update_stats() -> void:
	stats_label.text = "Time: %s    Kills: %d" % [format_time(elapsed), kills]

func format_time(t: float) -> String:
	return "%02d:%02d" % [floori(t / 60.0), int(t) % 60]

func calc_score(won: bool) -> int:
	var score := kills * KILL_POINTS
	if won:
		score += int(maxf(0.0, PAR_TIME - elapsed) * TIME_POINTS_PER_SEC)
	return score

func _on_enemy_base_destroyed() -> void:
	end_game(true)

func _on_player_base_destroyed() -> void:
	end_game(false)

func end_game(won: bool) -> void:
	if game_over:
		return
	game_over = true
	var title := "YOU WIN!" if won else "YOU LOSE"
	result_label.text = "%s\nTime: %s\nEnemies defeated: %d\nScore: %d" % [
		title, format_time(elapsed), kills, calc_score(won)]
	result_box.visible = true
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
