extends Node2D

# ---------------- OUR ARMY ----------------
# One entry per unit. The buttons are created automatically from this list.
# "train_time" is optional (seconds in the queue, default is DEFAULT_TRAIN_TIME).
# Costs, times and scene paths below are placeholders: set them to our own.
# Press F4 in game to print power / fair cost for every unit.
const PLAYER_UNITS := {
	"bat": {"name": "Bat", "cost": 2, "scene": preload("res://Scenes/bat.tscn"), "train_time": 1.5,
		"hp": 2, "damage": 1, "interval": 0.8, "speed": 150.0},      # fast, fragile swarmer
	"ghost": {"name": "Ghost", "cost": 4, "scene": preload("res://Scenes/ghost.tscn"), "train_time": 3.0,
		"hp": 8, "damage": 1, "interval": 1.0, "speed": 80.0},       # slow tank that soaks damage
	"pumpkin": {"name": "Jack", "cost": 5, "scene": preload("res://Scenes/pumpkin.tscn"), "train_time": 3.0,
		"unlock_kills": 10, "unlock_sound": preload("res://Audio/pumpkin_unlock_sound.mp3"),
		"hp": 5, "damage": 2, "interval": 1.0, "speed": 100.0},      # strong all-round bruiser
	"skeleton": {"name": "Skeleton", "cost": 8, "scene": preload("res://Scenes/skeleton.tscn"), "train_time": 4.0,
		"unlock_kills": 20, "unlock_sound": preload("res://Audio/skeleton_unlock_sound.mp3"),   
		"hp": 12, "damage": 2, "interval": 1.2, "speed": 60.0},      # slow, tough tank
}

# ---------------- ENEMY ARMY ----------------
# "cost"        = what it costs THE ENEMY (they have a gold budget, see AI_INCOME_PER_SEC)
# "weight"      = how much the AI wants it compared to the others
# "reward"      = gold you get for killing it
# "unlock_with" = (optional) key of one of out units: it unlocks for them when you unlock that one
const ENEMY_UNITS := [
	{"name": "Santa", "scene": preload("res://Scenes/Santa.tscn"), "cost": 4, "weight": 3, "reward": 2, "ranged": false,
		"hp": 4, "damage": 2, "interval": 1.2, "speed": 80.0},       # slow bruiser
	{"name": "Elf", "scene": preload("res://Scenes/elf.tscn"), "cost": 2, "weight": 2, "reward": 1, "ranged": false,
		"hp": 2, "damage": 1, "interval": 0.6, "speed": 100.0},      # fast and fragile
	{"name": "Snowman", "scene": preload("res://Scenes/snowman.tscn"), "cost": 3, "weight": 2, "reward": 2, "ranged": true,
		"unlock_with": "pumpkin", "hp": 3, "damage": 1, "interval": 1.1, "speed": 90.0},       # snowball thrower
	]

const StoryDialogue = preload("res://Scripts/story_dialogue.gd")

const INTRO_PART_1 := [
	{"speaker": "Jack", "text": "Look at that... Christmas has crept over the border. Snow, tinsel and carols, in OUR October!", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Every year they steal a little more of the calendar. First it was November. Now they want it all.", "portrait":"res://Art/jack.png" },
]
const INTRO_PART_2 := [
	{"speaker": "Jack", "text": "Enough is enough. It's time Halloween struck back!", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Bats and ghosts answer my call first. Defeat enough Christmas goons and stronger minions will join us. Spend your gold wisely!", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Use Attack to push forward and Defend to hold the line. Scroll the map with A and D.", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Smash their base and Christmas will think twice before showing up early again. Go, my minions!", "portrait":"res://Art/jack.png" },
]

# ENEMY AI
const AI_THREAT_RANGE := 650.0        # our units this close to their base = base under attack
const AI_RECALL_RANGE := 600.0        # enemy units this close to their base get pulled back to defend
const AI_DEFEND_OFFSET := 220.0       # defend point distance in front of their base
const AI_MAX_ALIVE := 15             # hard cap on enemies alive (keeps the game beatable)
const AI_ALARM_MIN_ATTACKERS := 2     # this many of our units at their base triggers reinforcements
const AI_ALARM_UNITS := 2             # how many extra units spawn instantly
const AI_ALARM_COOLDOWN := 25.0       # seconds between emergency reinforcements
const AI_MAX_RANGED_SHARE := 0.5      # AI won't build an army that's more than 50% ranged
const AI_SORTIE_RANGE := 330.0        # defenders charge out at one of our ranged units this close (archers outrange melee)
# enemy economy: they pay for every unit, just like you
const AI_START_GOLD := 5.0
const AI_INCOME_PER_SEC := 0.12        # passive gold per second 
const AI_KILL_REWARD_RATIO := 0.5     # they get this share of the cost of every unit of ours that dies
const AI_GOLD_CAP := 10.0              # they can't stockpile more than this
const AI_BUY_GAP := 0.5               # minimum seconds between two purchases
const AI_BUY_GAP_DEFENDING := 0.0     # ... while their base is under attack
const AI_ALARM_BONUS := 5.0           # one-off emergency gold when a real push arrives (0 = off)
const SPAWN_JITTER := 25.0

# ---------------- SETTINGS ----------------
const DEFAULT_TRAIN_TIME := 2.0   # seconds per unit in the queue
const MAX_QUEUE := 5
const UNIT_BUTTON_SIZE := Vector2(110, 50)

# passive income (set INCOME_AMOUNT to 0 to turn it off)
const INCOME_AMOUNT := 1
const INCOME_INTERVAL := 15

# score
const KILL_POINTS := 100
const PAR_TIME := 240.0          # win faster than this (seconds) to earn a time bonus
const TIME_POINTS_PER_SEC := 10

# base heal
const BASE_HEAL_AMOUNT := 1
const ENEMY_BASE_HEAL_AMOUNT := 0.7
const BASE_HEAL_INTERVAL := 1.0

const UNLOCK_SOUND_MAX := 1.5 

var money: int = 5
var game_over: bool = false
var queue: Array[String] = []
var spawn_progress: float = 0.0
var income_timer: float = 0.0
var elapsed: float = 0.0
var kills: int = 0
var defending: bool = false
var unit_buttons: Dictionary = {}   # unit type -> Button
var heal_timer: float = 0.0
var enemy_heal_timer: float = 0.0
var enemy_gold: float = AI_START_GOLD
var buy_cooldown: float = 0.0
var ai_plan: Dictionary = {}   # the unit the AI is currently saving up for
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
@onready var level_music: AudioStreamPlayer2D = $LevelMusic

func _ready() -> void:
	$CanvasLayer/PauseButton.pressed.connect($PauseMenu.toggle)
	_build_unit_buttons()
	_setup_debug()
	enemy_timer.stop()  
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
	if not GameMode.endless:
		story = StoryDialogue.new()
		add_child(story)   # added last, so it gets input before the pause menu
		if not GameMode.intro_seen:
			_play_intro()
		else:
			_start_level_music()
	else:
		_start_level_music()

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
	if game_over or not _is_unlocked(type) or money < cost or queue.size() >= MAX_QUEUE:
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
	var unit: Node2D = _spawn(info, true, spawn_point)
	unit.set_stance(defending, defend_point.global_position.x)
	unit.died.connect(_on_player_unit_died.bind(info["cost"]))
	update_ui()

# ---------- spawning ----------

func _spawn(info: Dictionary, is_player: bool, marker: Marker2D) -> Node2D:
	var unit = info["scene"].instantiate()
	unit.is_player = is_player
	_apply_stats(unit, info)   # before add_child, so health starts full
	unit.global_position = marker.global_position + Vector2(randf_range(-SPAWN_JITTER, SPAWN_JITTER), 0)
	add_child(unit)
	return unit

func _apply_stats(unit: Node, info: Dictionary) -> void:
	unit.max_health = info.get("hp", unit.max_health)
	unit.damage = info.get("damage", unit.damage)
	unit.attack_interval = info.get("interval", unit.attack_interval)
	unit.speed = info.get("speed", unit.speed)

func _enemy_unlocked(e: Dictionary) -> bool:
	return not e.has("unlock_with") or _is_unlocked(e["unlock_with"])

# The enemy pays for units, this is the only place enemy units get bought
func _enemy_try_buy(ignore_gap: bool = false) -> bool:
	if game_over or not is_instance_valid(enemy_base):
		return false
	if buy_cooldown > 0.0 and not ignore_gap:
		return false
	if get_tree().get_nodes_in_group("enemy_army").size() >= AI_MAX_ALIVE:
		return false
	if ai_plan.is_empty():
		ai_plan = _pick_enemy()                 # decide what we want next...
	var price := minf(float(ai_plan["cost"]), AI_GOLD_CAP)
	if enemy_gold < price:
		return false                            # ...and save up for it
	enemy_gold -= price
	_spawn_enemy(ai_plan)
	ai_plan = {}
	buy_cooldown = AI_BUY_GAP_DEFENDING if enemy_threatened else AI_BUY_GAP
	return true

func _spawn_enemy(entry: Dictionary) -> void:
	var enemy: Node2D = _spawn(entry, false, enemy_spawn_point)
	enemy.died.connect(_on_enemy_died.bind(entry.get("reward", 1)))
	if enemy_threatened and is_instance_valid(enemy_base):
		enemy.set_stance(true, _enemy_defend_x())   # new units join the defence

# every unit of ours that dies pays them a share of its cost
func _on_player_unit_died(cost: int) -> void:
	enemy_gold = minf(enemy_gold + ceil(cost * AI_KILL_REWARD_RATIO), AI_GOLD_CAP)
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
	enemy_gold = minf(enemy_gold + AI_INCOME_PER_SEC * delta, AI_GOLD_CAP)
	buy_cooldown = maxf(0.0, buy_cooldown - delta)
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
		ai_plan = {}   # the situation changed: decide again what to buy

	if enemy_threatened:
		_sortie_check()

	# emergency reinforcements when a real push reaches the base
	if attackers >= AI_ALARM_MIN_ATTACKERS and alarm_cooldown <= 0.0:
		alarm_cooldown = AI_ALARM_COOLDOWN
		_alarm_reinforce()

	_enemy_try_buy()
func _alarm_reinforce() -> void:
	enemy_gold = minf(enemy_gold + AI_ALARM_BONUS, AI_GOLD_CAP)
	for i in AI_ALARM_UNITS:
		if not _enemy_try_buy(true):   # only what they can afford
			return
		await get_tree().create_timer(0.5).timeout
func _set_enemy_stance(defend: bool) -> void:
	for u in get_tree().get_nodes_in_group("enemy_army"):
		if not defend:
			u.set_stance(false, 0.0)   # threat gone: push forward again
		elif absf(u.global_position.x - enemy_base.global_position.x) <= AI_RECALL_RANGE:
			u.set_stance(true, _enemy_defend_x())   # only recall units near home

func _count_player_ranged_near_base(radius: float) -> int:
	if not is_instance_valid(enemy_base):
		return 0
	var n := 0
	for u in get_tree().get_nodes_in_group("player_army"):
		if u.is_ranged and absf(u.global_position.x - enemy_base.global_position.x) <= radius:
			n += 1
	return n

# Anyone close enough to a ranged unit of ours charges out, everyone else holds the defend point
func _sortie_check() -> void:
	var snipers: Array = []
	for p in get_tree().get_nodes_in_group("player_army"):
		if p.is_ranged and absf(p.global_position.x - enemy_base.global_position.x) <= AI_THREAT_RANGE:
			snipers.append(p)
	for u in get_tree().get_nodes_in_group("enemy_army"):
		if absf(u.global_position.x - enemy_base.global_position.x) > AI_RECALL_RANGE:
			continue
		var charge := false
		for p in snipers:
			if absf(p.global_position.x - u.global_position.x) <= AI_SORTIE_RANGE:
				charge = true
				break
		u.set_stance(not charge, _enemy_defend_x())

func _pick_enemy() -> Dictionary:
	var pool := ENEMY_UNITS.filter(_enemy_unlocked)
	# look at our army
	var p_ranged := 0
	var p_total := 0
	for u in get_tree().get_nodes_in_group("player_army"):
		p_total += 1
		if u.is_ranged:
			p_ranged += 1
	var p_ranged_share := float(p_ranged) / p_total if p_total > 0 else 0.0
	var snipers := _count_player_ranged_near_base(AI_THREAT_RANGE)

	# look at their own army
	var e_ranged := 0
	var e_total := 0
	for u in get_tree().get_nodes_in_group("enemy_army"):
		e_total += 1
		if u.is_ranged:
			e_ranged += 1
	var e_ranged_share := float(e_ranged) / e_total if e_total > 0 else 0.0

	# our archers are at the gates and nobody can shoot back: guarantee a ranged answer
	if enemy_threatened and snipers > 0 and e_ranged == 0:
		var shooters := pool.filter(func(e): return e.get("ranged", false))
		if not shooters.is_empty():
			return shooters.pick_random()

	var weights: Array[float] = []
	var sum := 0.0
	for e in pool:
		var w := float(e["weight"])
		var is_r: bool = e.get("ranged", false)
		if is_r:
			if enemy_threatened:
				w *= 1.5 + snipers                           # defending: shooters answer our shooters
			elif p_total > 0:
				w *= 1.0 + (1.0 - p_ranged_share)            # attacking: more shooters vs a melee army
			if e_ranged_share >= AI_MAX_RANGED_SHARE and snipers == 0:
				w *= 0.2                                     # don't overbuild shooters
		elif not enemy_threatened and p_total > 0:
			w *= 1.0 + p_ranged_share                        # attacking: rush down our archers
		weights.append(w)
		sum += w

	var roll := randf() * sum
	for i in pool.size():
		roll -= weights[i]
		if roll <= 0.0:
			return pool[i]
	return pool[0]

func _on_enemy_died(reward: int) -> void:
	money += reward
	kills += 1
	for type in PLAYER_UNITS:
		if PLAYER_UNITS[type].get("unlock_kills", 0) == kills:
			var msg := "New unit unlocked: %s!" % PLAYER_UNITS[type]["name"]
			for e in ENEMY_UNITS:
				if e.get("unlock_with", "") == type:
					msg += "\nChristmas answers with: %s!" % e.get("name", "a new unit")
			_toast(msg)
			var snd = PLAYER_UNITS[type].get("unlock_sound")
			if snd:
				_play_sfx(snd)
	update_ui()
	update_stats()

func _play_sfx(stream: AudioStream) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "SFX"      
	p.volume_db = 7.0                    # the SFX slider controls it
	add_child(p)
	p.finished.connect(p.queue_free)       # remove the player when the sound ends
	p.play()
	# if a limit is set and the sound is longer, fade it out and stop it
	

# ---------- UI ----------

func update_ui() -> void:
	money_label.text = "Gold: %d" % money
	var full := queue.size() >= MAX_QUEUE
	for type in PLAYER_UNITS:
		var info: Dictionary = PLAYER_UNITS[type]
		var b: Button = unit_buttons[type]
		if _is_unlocked(type):
			b.disabled = full or money < info["cost"]
			b.text = "%s (%d)" % [info["name"], info["cost"]]
		else:
			b.disabled = true
			b.text = "%s\n%d kills" % [info["name"], info["unlock_kills"]]
	queue_label.text = "Queue: %d/%d" % [queue.size(), MAX_QUEUE]

func _is_unlocked(type: String) -> bool:
	return kills >= PLAYER_UNITS[type].get("unlock_kills", 0)

func _toast(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(600, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Color("ffcf4a"))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.position = Vector2((get_viewport_rect().size.x - 600.0) / 2.0, 230.0)
	$CanvasLayer.add_child(l)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)

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
	else:
		heal_timer += delta
		if heal_timer >= BASE_HEAL_INTERVAL:
			heal_timer = 0.0
			player_base.heal(BASE_HEAL_AMOUNT)

	var enemy_has_army := not get_tree().get_nodes_in_group("enemy_army").is_empty()
	if not enemy_threatened or not enemy_has_army or not is_instance_valid(enemy_base) \
			or enemy_base.health >= enemy_base.max_health:
		enemy_heal_timer = 0.0
	else:
		enemy_heal_timer += delta
		if enemy_heal_timer >= BASE_HEAL_INTERVAL:
			enemy_heal_timer = 0.0
			enemy_base.heal(ENEMY_BASE_HEAL_AMOUNT)

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
	_start_level_music()

func _start_level_music() -> void:
	level_music.volume_db = -40.0
	level_music.play()
	create_tween().tween_property(level_music, "volume_db", 0.0, 2.0)   # 2 second fade-in


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
		KEY_F2:   # spawn 5 of our warriors just outside the enemy base range
			for i in 5:
				var u := _spawn(PLAYER_UNITS["pumpkin"], true, spawn_point)
				u.global_position = Vector2(enemy_base.global_position.x - AI_THREAT_RANGE + 100 - i * 30, spawn_point.global_position.y)
		KEY_F3:   # +20 gold
			money += 20
			update_ui()
		KEY_F4:   # print map/unit info to the Output panel
			_print_layout_info()

func _update_debug() -> void:
	if not debug_on:
		return
	debug_label.text = "Threatened: %s\nAttackers near base: %d\nEnemies alive: %d / %d\nEnemy gold: %.1f / %.0f (income %.2f/s)\nSaving for: %s (cost %s)\nBuy cooldown: %.1fs   Alarm cooldown: %.1fs" % [
		enemy_threatened, _count_player_near_base(AI_THREAT_RANGE),
		get_tree().get_nodes_in_group("enemy_army").size(), AI_MAX_ALIVE,
		enemy_gold, AI_GOLD_CAP, AI_INCOME_PER_SEC,
		ai_plan.get("name", "-"), ai_plan.get("cost", "-"),
		buy_cooldown, alarm_cooldown]
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
	_print_balance()

func _print_balance() -> void:
	print("--- balance: power -> fair cost (power / 2) vs the numbers you set ---")
	var all: Array = []
	for k in PLAYER_UNITS:
		all.append(["Player " + PLAYER_UNITS[k]["name"], PLAYER_UNITS[k]])
	for e in ENEMY_UNITS:
		all.append(["Enemy " + e["scene"].resource_path.get_file(), e])
	for a in all:
		var info: Dictionary = a[1]
		var u = info["scene"].instantiate()
		var hp: float = info.get("hp", u.max_health)
		var dmg: float = info.get("damage", u.damage)
		var interval: float = info.get("interval", u.attack_interval)
		var spd: float = info.get("speed", u.speed)
		var power := hp * (dmg / interval) * (1.5 if u.is_ranged else 1.0) * sqrt(spd / 100.0)
		print("%s | ranged=%s power=%.1f fair cost~%.1f | cost=%s reward=%s" % [
			a[0], u.is_ranged, power, power / 2.0, info.get("cost", "-"), info.get("reward", "-")])
		u.free()
