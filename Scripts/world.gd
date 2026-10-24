extends Node2D

# ---------------- YOUR ARMY ----------------
# One entry per unit. The buttons are created automatically from this list.
# "train_time" is optional (seconds in the queue, default is DEFAULT_TRAIN_TIME).
# Costs, times and scene paths below are placeholders: set them to your own.
const PLAYER_UNITS := {
	"warrior":  {"name": "Warrior",  "cost": 2, "scene": preload("res://Scenes/character1.tscn")},
	"archer":   {"name": "Archer",   "cost": 3, "scene": preload("res://Scenes/archer.tscn")},
	"skeleton": {"name": "Skeleton", "cost": 3, "scene": preload("res://Scenes/skeleton.tscn")},
	"bat":      {"name": "Bat",      "cost": 2, "scene": preload("res://Scenes/bat.tscn"), "train_time": 1.5},
	"ghost":    {"name": "Ghost",    "cost": 4, "scene": preload("res://Scenes/ghost.tscn"), "train_time": 3.0},
}

# ---------------- ENEMY ARMY ----------------
# "weight" = how often it spawns compared to the others
# "reward" = gold you get for killing it
const ENEMY_UNITS := [
	{"scene": preload("res://Scenes/Santa.tscn"),   "weight": 3, "reward": 1},
	{"scene": preload("res://Scenes/Snowman.tscn"), "weight": 3, "reward": 1},
]

# ---------------- SETTINGS ----------------
const DEFAULT_TRAIN_TIME := 2.0   # seconds per unit in the queue
const MAX_QUEUE := 5
const UNIT_BUTTON_SIZE := Vector2(110, 50)

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
var defending: bool = false
var unit_buttons: Dictionary = {}   # unit type -> Button

@onready var unit_row: Container = $CanvasLayer/VBoxContainer/HBoxContainer
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
@onready var attack_button: Button = %AttackButton
@onready var defend_button: Button = %DefendButton
@onready var defend_point: Marker2D = $DefendPoint

func _ready() -> void:
	$CanvasLayer/PauseButton.pressed.connect($PauseMenu.toggle)
	_build_unit_buttons()
	enemy_timer.timeout.connect(_on_enemy_timer_timeout)
	restart_button.pressed.connect(_on_restart_pressed)
	player_base.destroyed.connect(_on_player_base_destroyed)
	enemy_base.destroyed.connect(_on_enemy_base_destroyed)
	spawn_bar.max_value = DEFAULT_TRAIN_TIME
	spawn_bar.value = 0.0

	var stance_group := ButtonGroup.new()
	attack_button.toggle_mode = true
	defend_button.toggle_mode = true
	attack_button.button_group = stance_group
	defend_button.button_group = stance_group
	attack_button.button_pressed = true
	attack_button.pressed.connect(func(): _set_stance(false))
	defend_button.pressed.connect(func(): _set_stance(true))

	update_ui()
	update_stats()

# ---------- unit buttons ----------

func _build_unit_buttons() -> void:
	# remove any buttons that were placed by hand
	for child in unit_row.get_children():
		unit_row.remove_child(child)
		child.queue_free()
	for type in PLAYER_UNITS:
		var b := Button.new()
		b.custom_minimum_size = UNIT_BUTTON_SIZE
		b.pressed.connect(_queue_unit.bind(type))
		unit_row.add_child(b)
		unit_buttons[type] = b

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

# ---------- training queue ----------

func _queue_unit(type: String) -> void:
	var cost: int = PLAYER_UNITS[type]["cost"]
	if game_over or money < cost or queue.size() >= MAX_QUEUE:
		return
	money -= cost
	queue.append(type)
	update_ui()

func _tick_queue(delta: float) -> void:
	if queue.is_empty():
		return
	var info: Dictionary = PLAYER_UNITS[queue[0]]
	var train_time: float = info.get("train_time", DEFAULT_TRAIN_TIME)
	spawn_bar.max_value = train_time
	spawn_progress += delta
	spawn_bar.value = spawn_progress
	if spawn_progress < train_time:
		return
	spawn_progress = 0.0
	spawn_bar.value = 0.0
	queue.pop_front()
	var unit: Node2D = _spawn(info["scene"], true, spawn_point)
	unit.set_stance(defending, defend_point.global_position.x)
	update_ui()

# ---------- spawning ----------

func _spawn(scene: PackedScene, is_player: bool, marker: Marker2D) -> Node2D:
	var unit = scene.instantiate()
	unit.is_player = is_player
	unit.global_position = marker.global_position
	add_child(unit)
	return unit

func _on_enemy_timer_timeout() -> void:
	if game_over:
		return
	var entry := _pick_enemy()
	var enemy: Node2D = _spawn(entry["scene"], false, enemy_spawn_point)
	enemy.died.connect(_on_enemy_died.bind(entry.get("reward", 1)))

func _pick_enemy() -> Dictionary:
	var total := 0
	for e in ENEMY_UNITS:
		total += int(e["weight"])
	var roll := randi_range(1, total)
	for e in ENEMY_UNITS:
		roll -= int(e["weight"])
		if roll <= 0:
			return e
	return ENEMY_UNITS[0]

func _on_enemy_died(reward: int) -> void:
	money += reward
	kills += 1
	update_ui()
	update_stats()

# ---------- UI ----------

func update_ui() -> void:
	money_label.text = "Gold: %d" % money
	var full := queue.size() >= MAX_QUEUE
	for type in PLAYER_UNITS:
		var info: Dictionary = PLAYER_UNITS[type]
		var b: Button = unit_buttons[type]
		b.disabled = full or money < info["cost"]
		b.text = "%s (%d)" % [info["name"], info["cost"]]
	queue_label.text = "Queue: %d/%d" % [queue.size(), MAX_QUEUE]

func update_stats() -> void:
	stats_label.text = "Time: %s    Kills: %d" % [format_time(elapsed), kills]

func format_time(t: float) -> String:
	return "%02d:%02d" % [floori(t / 60.0), int(t) % 60]

# ---------- score and game end ----------

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

# ---------- stance ----------

func _set_stance(is_defending: bool) -> void:
	defending = is_defending
	get_tree().call_group("player_army", "set_stance", defending, defend_point.global_position.x)
