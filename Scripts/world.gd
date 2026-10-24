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
	{"scene": preload("res://Scenes/Santa.tscn"),   "weight": 3, "reward": 1, "ranged": false},
	{"scene": preload("res://Scenes/snowman.tscn"), "weight": 2, "reward": 2, "ranged": true},
	{"scene": preload("res://Scenes/elf.tscn"), "weight": 2, "reward": 1, "ranged": false},]

const StoryDialogue = preload("res://Scripts/story_dialogue.gd")

const INTRO_PART_1 := [
	{"speaker": "Jack", "text": "Look at that... Christmas has crept over the border. Snow, tinsel and carols, in OUR October!"},
	{"speaker": "Jack", "text": "Every year they steal a little more of the calendar. First it was November. Now they want it all."},
]
const INTRO_PART_2 := [
	{"speaker": "Jack", "text": "Enough is enough. It's time Halloween struck back!"},
	{"speaker": "Jack", "text": "Train warriors, skeletons, bats and ghosts. Gold is tight, so spend it wisely."},
	{"speaker": "Jack", "text": "Use Attack to push forward and Defend to hold the line. Scroll the map with A and D."},
	{"speaker": "Jack", "text": "Smash their base and Christmas will think twice before showing up early again. Go, my minions!"},
]

# ENEMY AI
const AI_THREAT_RANGE := 650.0        # your units this close to their base = base under attack
const AI_RECALL_RANGE := 600.0        # enemy units this close to their base get pulled back to defend
const AI_DEFEND_OFFSET := 220.0       # defend point distance in front of their base
const AI_MAX_ALIVE := 10             # hard cap on enemies alive (keeps the game beatable)
const AI_MIN_INTERVAL := 1.5          # fastest possible spawn rate (seconds)
const AI_PRESSURE_STEP := 0.25        # +25% spawn speed per attacker near the base (max 6 counted)
const AI_ALARM_MIN_ATTACKERS := 2     # this many of your units at their base triggers reinforcements
const AI_ALARM_UNITS := 2             # how many extra units spawn instantly
const AI_ALARM_COOLDOWN := 25.0       # seconds between emergency reinforcements
const AI_MAX_RANGED_SHARE := 0.5      # AI won't build an army that's more than 50% ranged
const SPAWN_JITTER := 25.0

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

# base heal
const BASE_HEAL_AMOUNT := 1
const BASE_HEAL_INTERVAL := 1.0

var money: int = 4
var game_over: bool = false
var queue: Array[String] = []
var spawn_progress: float = 0.0
var income_timer: float = 0.0
var elapsed: float = 0.0
var kills: int = 0
var defending: bool = false
var unit_buttons: Dictionary = {}   # unit type -> Button
var heal_timer: float = 0.0
var enemy_base_interval: float = 4.0
var enemy_threatened: bool = false
var alarm_cooldown: float = 0.0
var ai_think_timer: float = 0.0
var story: Node

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
	_setup_debug()
	enemy_timer.timeout.connect(_on_enemy_timer_timeout)
	restart_button.pressed.connect(_on_restart_pressed)
	player_base.destroyed.connect(_on_player_base_destroyed)
	enemy_base.destroyed.connect(_on_enemy_base_destroyed)
	spawn_bar.max_value = DEFAULT_TRAIN_TIME
	spawn_bar.value = 0.0
	enemy_base_interval = enemy_timer.wait_time

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
	if not GameMode.endless:
		story = StoryDialogue.new()
		add_child(story)   # added last, so it gets input before the pause menu
		if not GameMode.intro_seen:
			_play_intro()

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
	_tick_base_heal(delta)
	_tick_enemy_ai(delta)
	_update_debug()

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
	unit.global_position = marker.global_position + Vector2(randf_range(-SPAWN_JITTER, SPAWN_JITTER), 0)
	add_child(unit)
	return unit

func _on_enemy_timer_timeout() -> void:
	if game_over:
		return
	_spawn_enemy()
	enemy_timer.start(_next_spawn_interval())   # spawn faster when under pressure

func _spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemy_army").size() >= AI_MAX_ALIVE:
		return
	var entry := _pick_enemy()
	var enemy: Node2D = _spawn(entry["scene"], false, enemy_spawn_point)
	enemy.died.connect(_on_enemy_died.bind(entry.get("reward", 1)))
	if enemy_threatened and is_instance_valid(enemy_base):
		enemy.set_stance(true, _enemy_defend_x())   # new units join the defence

func _next_spawn_interval() -> float:
	var pressure := mini(_count_player_near_base(AI_THREAT_RANGE), 6)
	return maxf(enemy_base_interval / (1.0 + AI_PRESSURE_STEP * pressure), AI_MIN_INTERVAL)

func _count_player_near_base(radius: float) -> int:
	if not is_instance_valid(enemy_base):
		return 0
	var n := 0
	for u in get_tree().get_nodes_in_group("player_army"):
		if absf(u.global_position.x - enemy_base.global_position.x) <= radius:
			n += 1
	return n

func _enemy_defend_x() -> float:
	return enemy_base.global_position.x - AI_DEFEND_OFFSET

func _tick_enemy_ai(delta: float) -> void:
	alarm_cooldown = maxf(0.0, alarm_cooldown - delta)
	ai_think_timer -= delta
	if ai_think_timer > 0.0:
		return
	ai_think_timer = 0.5
	if not is_instance_valid(enemy_base):
		return

	var attackers := _count_player_near_base(AI_THREAT_RANGE)
	var threatened := attackers > 0
	if threatened != enemy_threatened:
		enemy_threatened = threatened
		_set_enemy_stance(threatened)

	# emergency reinforcements when a real push reaches the base
	if attackers >= AI_ALARM_MIN_ATTACKERS and alarm_cooldown <= 0.0:
		alarm_cooldown = AI_ALARM_COOLDOWN
		_alarm_reinforce()

func _alarm_reinforce() -> void:
	for i in AI_ALARM_UNITS:
		if game_over:
			return
		_spawn_enemy()
		await get_tree().create_timer(0.5).timeout

func _set_enemy_stance(defend: bool) -> void:
	for u in get_tree().get_nodes_in_group("enemy_army"):
		if not defend:
			u.set_stance(false, 0.0)   # threat gone: push forward again
		elif absf(u.global_position.x - enemy_base.global_position.x) <= AI_RECALL_RANGE:
			u.set_stance(true, _enemy_defend_x())   # only recall units near home

func _pick_enemy() -> Dictionary:
	# look at your army
	var p_ranged := 0
	var p_total := 0
	for u in get_tree().get_nodes_in_group("player_army"):
		p_total += 1
		if u.is_ranged:
			p_ranged += 1
	var p_ranged_share := float(p_ranged) / p_total if p_total > 0 else 0.0

	# look at their own army
	var e_ranged := 0
	var e_total := 0
	for u in get_tree().get_nodes_in_group("enemy_army"):
		e_total += 1
		if u.is_ranged:
			e_ranged += 1
	var e_ranged_share := float(e_ranged) / e_total if e_total > 0 else 0.0

	var weights: Array[float] = []
	var sum := 0.0
	for e in ENEMY_UNITS:
		var w := float(e["weight"])
		var is_r: bool = e.get("ranged", false)
		if p_total > 0:
			# lots of melee on your side -> more archers; lots of archers -> rush them with melee
			w *= (1.0 + (1.0 - p_ranged_share)) if is_r else (1.0 + p_ranged_share)
		if is_r:
			if enemy_threatened:
				w *= 1.5                      # archers behind the defenders
			if e_ranged_share >= AI_MAX_RANGED_SHARE:
				w *= 0.2                      # don't overbuild archers
		weights.append(w)
		sum += w

	var roll := randf() * sum
	for i in ENEMY_UNITS.size():
		roll -= weights[i]
		if roll <= 0.0:
			return ENEMY_UNITS[i]
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


func _tick_base_heal(delta: float) -> void:
	var has_army := not get_tree().get_nodes_in_group("player_army").is_empty()
	if not defending or not has_army or not is_instance_valid(player_base) \
			or player_base.health >= player_base.max_health:
		heal_timer = 0.0
		return
	heal_timer += delta
	if heal_timer >= BASE_HEAL_INTERVAL:
		heal_timer = 0.0
		player_base.heal(BASE_HEAL_AMOUNT)

# STORY INTRO
# Pauses the game while a dialogue is open. Reusable for any in-game message.
func _say(lines: Array) -> void:
	var was_paused := get_tree().paused
	get_tree().paused = true
	await story.play(lines)
	get_tree().paused = was_paused

func _play_intro() -> void:
	GameMode.intro_seen = true
	get_tree().paused = true
	var cam := get_viewport().get_camera_2d()
	var home_x := 0.0
	if cam:
		home_x = cam.position.x
		# start by looking at the Christmas base
		cam.position.x = cam.limit_right - get_viewport_rect().size.x * 0.5 / cam.zoom.x

	await _say(INTRO_PART_1)

	if cam:
		if story.skip_all:
			cam.position.x = home_x
		else:
			var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(cam, "position:x", home_x, 2.0) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await tw.finished

	await _say(INTRO_PART_2)
	get_tree().paused = false



#  DEBUG (delete before release)
const DEBUG_KEYS := true
var debug_on := false
var debug_label: Label

func _setup_debug() -> void:
	debug_label = Label.new()
	debug_label.position = Vector2(10, 90)
	debug_label.visible = false
	$CanvasLayer.add_child(debug_label)

func _unhandled_input(event: InputEvent) -> void:
	if not DEBUG_KEYS or not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F1:   # toggle overlay
			debug_on = not debug_on
			debug_label.visible = debug_on
			queue_redraw()
		KEY_F2:   # spawn 5 of your warriors just outside the enemy base range
			for i in 5:
				var u := _spawn(PLAYER_UNITS["warrior"]["scene"], true, spawn_point)
				u.global_position = Vector2(enemy_base.global_position.x - AI_THREAT_RANGE + 100 - i * 30, spawn_point.global_position.y)
		KEY_F3:   # +20 gold
			money += 20
			update_ui()
		KEY_F4:   # print map/unit info to the Output panel
			_print_layout_info()

func _update_debug() -> void:
	if not debug_on:
		return
	debug_label.text = "Threatened: %s\nAttackers near base: %d\nEnemies alive: %d / %d\nNext spawn in: %.1fs (interval %.1fs)\nAlarm cooldown: %.1fs" % [
		enemy_threatened, _count_player_near_base(AI_THREAT_RANGE),
		get_tree().get_nodes_in_group("enemy_army").size(), AI_MAX_ALIVE,
		enemy_timer.time_left, _next_spawn_interval(), alarm_cooldown]
	queue_redraw()

func _draw() -> void:
	if not debug_on or not is_instance_valid(enemy_base):
		return
	var bx := enemy_base.global_position.x
	var y := enemy_base.global_position.y
	_debug_line(bx - AI_THREAT_RANGE, y, Color.RED)                 # threat range
	_debug_line(bx - AI_RECALL_RANGE, y, Color.ORANGE)              # recall range
	_debug_line(bx - AI_DEFEND_OFFSET, y, Color.YELLOW)             # defend point
	_debug_line(bx - 250.0, y, Color.CYAN)                          # siege zone (unit default)

func _debug_line(x: float, y: float, c: Color) -> void:
	draw_line(to_local(Vector2(x, y - 400)), to_local(Vector2(x, y + 200)), c, 3.0)

func _print_layout_info() -> void:
	print("===== LAYOUT INFO =====")
	var vp := get_viewport_rect().size
	print("Viewport size: ", vp)
	print("Your base x: ", player_base.global_position.x if is_instance_valid(player_base) else "gone")
	print("Enemy base x: ", enemy_base.global_position.x if is_instance_valid(enemy_base) else "gone")
	print("Your spawn: ", spawn_point.global_position, "   Enemy spawn: ", enemy_spawn_point.global_position)
	print("Defend point: ", defend_point.global_position)
	print("Enemy timer wait_time: ", enemy_timer.wait_time)
	var cam := get_viewport().get_camera_2d()
	if cam:
		print("Camera limits L/R/T/B: ", cam.limit_left, " / ", cam.limit_right, " / ", cam.limit_top, " / ", cam.limit_bottom)
	print("--- units ---")
	var scenes: Array = []
	for k in PLAYER_UNITS:
		scenes.append([PLAYER_UNITS[k]["name"], PLAYER_UNITS[k]["scene"]])
	for e in ENEMY_UNITS:
		scenes.append([e["scene"].resource_path.get_file(), e["scene"]])
	for s in scenes:
		var u = s[1].instantiate()
		var rng := "?"
		var ar = u.get_node_or_null("AttackRange")
		if ar:
			for c in ar.get_children():
				if c is CollisionShape2D and c.shape:
					rng = str(c.shape.get_rect().size) + " at " + str(c.position)
		print("%s | ranged=%s speed=%s hp=%s dmg=%s interval=%s attack_range_box=%s" % [
			s[0], u.is_ranged, u.speed, u.max_health, u.damage, u.attack_interval, rng])
		u.free()
	print("=======================")
