extends Node2D

# ---------------- OUR ARMY ----------------
# One entry per unit. The buttons are created automatically from this list.
# "train_time" is optional (seconds in the queue, default is DEFAULT_TRAIN_TIME).
# Costs, times and scene paths below are placeholders: set them to our own.
# Press F4 in game to print power / fair cost for every unit.
const PLAYER_UNITS := {
	"bat": {"name": "Bat", "cost": 2, "scene": preload("res://Scenes/bat.tscn"), "train_time": 1.5,
		"hp": 2, "damage": 1, "interval": 1.1, "speed": 150.0},      # fast, fragile swarmer
	"ghost": {"name": "Ghost", "cost": 4, "scene": preload("res://Scenes/ghost.tscn"), "train_time": 3.0,
		"hp": 8, "damage": 1, "interval": 1.0, "speed": 80.0},       # slow tank that soaks damage
	"pumpkin": {"name": "Jack", "cost": 5, "scene": preload("res://Scenes/pumpkin.tscn"), "train_time": 3.0,
		"unlock_kills": 10, "unlock_sound": preload("res://Audio/pumpkin_unlock_sound.mp3"),
		"hp": 5, "damage": 2, "interval": 1.0, "speed": 100.0},      # strong all-round bruiser
	"skeleton": {"name": "Skeleton", "cost": 8, "scene": preload("res://Scenes/skeleton.tscn"), "train_time": 4.0,
		"unlock_kills": 15, "unlock_sound": preload("res://Audio/skeleton_unlock_sound.mp3"),   
		"hp": 12, "damage": 2, "interval": 1.2, "speed": 60.0},      # slow, tough tank
}

# ---------------- ENEMY ARMY ----------------
# "cost"        = what it costs THE ENEMY (they have a gold budget, see AI_INCOME_PER_SEC)
# "weight"      = how much the AI wants it compared to the others
# "reward"      = gold you get for killing it
# "unlock_with" = (optional) key of one of out units: it unlocks for them when you unlock that one
# "endless_wave" = (endless mode) the first wave this enemy can appear in
const ENEMY_UNITS := [
	{"name": "Santa", "scene": preload("res://Scenes/Santa.tscn"), "cost": 4, "weight": 3, "reward": 2, "ranged": false,
		"endless_wave": 3, "hp": 4, "damage": 2, "interval": 1.2, "speed": 80.0},       # slow bruiser
	{"name": "Elf", "scene": preload("res://Scenes/elf.tscn"), "cost": 2, "weight": 2, "reward": 1, "ranged": false,
		"endless_wave": 1, "hp": 2, "damage": 1, "interval": 0.6, "speed": 100.0},      # fast and fragile
	{"name": "Snowman", "scene": preload("res://Scenes/snowman.tscn"), "cost": 3, "weight": 2, "reward": 2, "ranged": true,
		"unlock_with": "pumpkin", "endless_wave": 5, "hp": 3, "damage": 1, "interval": 0.9, "speed": 93.0},       # snowball thrower
		{"name": "Gingerbread", "scene": preload("res://Scenes/gingerbread_man.tscn"), "cost": 5, "weight": 2, "reward": 3, "ranged": false,
		"unlock_with": "skeleton", "endless_wave": 8, "hp": 9, "damage": 4, "interval": 1.5, "speed": 63.0},       # tough melee bruiser
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

const ENDLESS_INTRO := [
	{"speaker": "Jack", "text": "Christmas isn't giving up. They're coming in waves, and every wave is stronger than the last!", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "There's no base to smash this time. All that matters is surviving as long as we can. Protect our base at all costs!", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Bats and ghosts answer my call first. Defeat enough Christmas goons and stronger minions will join us. Spend your gold wisely!", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Defend holds the line near our base and heals it. Advance moves the army out to meet them. Scroll the map with A and D.", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Between waves you get a short break and bonus gold. How many waves can we survive? Go, my minions!", "portrait":"res://Art/jack.png" },
]
const LEVEL2_PART_1 := [
	{"speaker": "Jack", "text": "Their forward camp is gone, but look! Christmas has a fortress deeper in the snow.", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "And this time they know we're coming.", "portrait":"res://Art/jack.png" },
]
const LEVEL2_PART_2 := [
	{"speaker": "Jack", "text": "My minions will have to earn their place again. Bats and ghosts first, then the stronger ones!", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Tear that fortress down, and let's finish this once and for all!", "portrait":"res://Art/jack.png" },
]
const ENDING := [
	{"speaker": "Jack", "text": "Their fortress is nothing but snow and splinters now. The tinsel is ash.", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "They called us a spooky little holiday. Said we should stay in our corner of the calendar.", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Christmas can have its December. All we ask is that it waits its turn.", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Now the night belongs to us again.", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "...Though I'd sleep with one eye open. Something tells me they'll be back next October.", "portrait":"res://Art/jack.png" },
	{"speaker": "Jack", "text": "Happy Halloween!", "portrait":"res://Art/jack.png" },
]

const STORY_INTROS := [
	[INTRO_PART_1, INTRO_PART_2],
	[LEVEL2_PART_1, LEVEL2_PART_2],
]
const LEVEL_ENEMY_INCOME := [1.0, 1.4]   # enemy income multiplier per level (level 2 = 40% harder)
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
const LEVEL_ENEMY_ATTACK_SPEED := [1.0, 1.3]   # enemy attack speed multiplier per level (1.3 = 30% faster hits)
# enemy economy: they pay for every unit, just like you
const AI_START_GOLD := 5.0
const AI_INCOME_PER_SEC := 0.12        # passive gold per second 
const AI_KILL_REWARD_RATIO := 0.5     # they get this share of the cost of every unit of ours that dies
const AI_GOLD_CAP := 10.0              # they can't stockpile more than this
const AI_BUY_GAP := 0.5               # minimum seconds between two purchases
const AI_BUY_GAP_DEFENDING := 0.0     # ... while their base is under attack
const AI_ALARM_BONUS := 5.0           # one-off emergency gold when a real push arrives (0 = off)
const AI_REPAIR_BELOW := 0.25        # base under 25% health: switch to repair mode
const AI_REPAIR_UNTIL := 0.5         # ...and stay in it until it's back above 50%

const SPAWN_JITTER := 25.0
# ---------------- ENDLESS MODE ----------------
const ENDLESS_START_GOLD := 8          # starting gold (the story starts with 5)
const ENDLESS_FIRST_DELAY := 12.0      # seconds before wave 1
const ENDLESS_BREAK := 8.0             # pause between waves, counted from the moment the last enemy dies
const ENDLESS_WAVE_MAX_TIME := 60.0    # if a wave drags on, the next one starts anyway after this
const ENDLESS_BUDGET_BASE := 6.0       # "points" the enemy can spend on wave 1 (units cost their "cost")
const ENDLESS_BUDGET_PER_WAVE := 2.5   # extra points for every later wave
const ENDLESS_HP_SCALE := 0.08         # enemies get +8% hp per wave
const ENDLESS_DAMAGE_EVERY := 6        # enemies get +1 damage every 6 waves
const ENDLESS_SPAWN_GAP := 0.8         # seconds between enemies of the same wave
const ENDLESS_CLEAR_BONUS := 2         # gold for clearing a wave (+1 more every 5 waves)
const ENDLESS_WAVE_POINTS := 250       # score per wave reached
const ENDLESS_FORWARD_X := 650.0       # "Advance" holds our army at this x (there is no enemy base to march to)

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
const BASE_HEAL_AMOUNT := 2
const ENEMY_BASE_HEAL_AMOUNT := 1
const BASE_HEAL_INTERVAL := 1.0

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
var enemy_repairing: bool = false
var story: Node
# endless mode
var wave: int = 0
var wave_active: bool = false
var wave_budget: float = 0.0
var wave_time: float = 0.0
var wave_spawn_timer: float = 0.0
var wave_countdown: float = ENDLESS_FIRST_DELAY
var enemy_income: float = AI_INCOME_PER_SEC

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
@onready var menu_button: Button = $CanvasLayer/ResultBox/VBoxContainer/MenuButton
@onready var attack_button: Button = %AttackButton
@onready var defend_button: Button = %DefendButton
@onready var defend_point: Marker2D = $DefendPoint
@onready var level_music: AudioStreamPlayer2D = $LevelMusic
@onready var next_button: Button = $CanvasLayer/ResultBox/VBoxContainer/NextLevelButton

@export var level_number: int = 1

func _ready() -> void:
	if not GameMode.endless:
		GameMode.level = level_number
	$CanvasLayer/PauseButton.pressed.connect($PauseMenu.toggle)
	_build_unit_buttons()
	enemy_timer.stop()  
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	player_base.destroyed.connect(_on_player_base_destroyed)
	if GameMode.endless:
		enemy_base.queue_free()   # no enemy base in endless mode
	else:
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

	if GameMode.endless:
		defend_button.button_pressed = true   # endless starts on Defend, near our base
		defending = true
		attack_button.text = "Advance"        # no enemy base, so Attack becomes "hold a forward line"
		money = ENDLESS_START_GOLD
	
	if not GameMode.endless:
		enemy_income = AI_INCOME_PER_SEC * LEVEL_ENEMY_INCOME[GameMode.level - 1]
	next_button.visible = false
	next_button.pressed.connect(_on_next_level_pressed)
	update_ui()
	update_stats()
	story = StoryDialogue.new()
	add_child(story)   # added last, so it gets input before the pause menu
	if GameMode.intro_seen:
		_start_level_music()
	elif GameMode.endless:
		_play_endless_intro()
	else:
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
	if GameMode.endless:
		_tick_endless(delta)
	else:
		_tick_enemy_ai(delta)


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
	_apply_stance(unit)
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
	if not unit.is_player and not GameMode.endless:
		unit.attack_interval /= LEVEL_ENEMY_ATTACK_SPEED[GameMode.level - 1]

func _enemy_unlocked(e: Dictionary) -> bool:
	if GameMode.endless:
		return wave >= e.get("endless_wave", 1)   # waves unlock enemies
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
	enemy_gold = minf(enemy_gold + enemy_income * delta, AI_GOLD_CAP)
	buy_cooldown = maxf(0.0, buy_cooldown - delta)
	alarm_cooldown = maxf(0.0, alarm_cooldown - delta)
	ai_think_timer -= delta
	if ai_think_timer > 0.0:
		return
	ai_think_timer = 0.5
	if not is_instance_valid(enemy_base):
		return

	var base_ratio := float(enemy_base.health) / float(enemy_base.max_health)
	if base_ratio < AI_REPAIR_BELOW:
		enemy_repairing = true
	elif base_ratio >= AI_REPAIR_UNTIL:
		enemy_repairing = false

	var attackers := _count_player_near_base(AI_THREAT_RANGE)
	var threatened := attackers > 0 or enemy_repairing
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
				if not GameMode.endless and e.get("unlock_with", "") == type:
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
	if GameMode.endless:
		var t := "Wave %d    Time: %s\nKills: %d" % [maxi(wave, 1), format_time(elapsed), kills]
		if not wave_active:
			t += "\nNext wave in %ds" % ceili(wave_countdown)
		stats_label.text = t
	else:
		stats_label.text = "Time: %s    Kills: %d" % [format_time(elapsed), kills]
		
func format_time(t: float) -> String:
	return "%02d:%02d" % [floori(t / 60.0), int(t) % 60]

# ---------- score and game end ----------

func calc_score(won: bool) -> int:
	var score := kills * KILL_POINTS
	if GameMode.endless:
		return score + maxi(wave - 1, 0) * ENDLESS_WAVE_POINTS
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
	if GameMode.endless:
		var best_text := ""
		if wave > GameSettings.best_wave:
			GameSettings.best_wave = wave
			GameSettings.save_settings()
			best_text = "\nNEW BEST!"
		else:
			best_text = "\nBest: wave %d" % GameSettings.best_wave
		result_label.text = "GAME OVER\nReached wave: %d\nTime: %s\nEnemies defeated: %d\nScore: %d%s" % [
			wave, format_time(elapsed), kills, calc_score(false), best_text]
	else:
		if won and not GameMode.has_next_level():
			story.skip_all = false
			create_tween().tween_property(level_music, "volume_db", -40.0, 3.0)
			await get_tree().create_timer(1.5).timeout
			await _say(ENDING)
		var title := ("LEVEL COMPLETE!" if GameMode.has_next_level() else "YOU WIN!") if won else "YOU LOSE"
		result_label.text = "%s\nTime: %s\nEnemies defeated: %d\nScore: %d" % [
			title, format_time(elapsed), kills, calc_score(won)]
	next_button.visible = won and not GameMode.endless and GameMode.has_next_level()
	result_box.visible = true
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	
func _on_next_level_pressed() -> void:
	GameMode.level += 1
	GameMode.intro_seen = false
	get_tree().paused = false
	get_tree().change_scene_to_file(GameMode.scene_for_level())
	
# ---------- stance ----------

func _set_stance(is_defending: bool) -> void:
	defending = is_defending
	for u in get_tree().get_nodes_in_group("player_army"):
		_apply_stance(u)

# Story: Attack = march on, Defend = hold the defend point.
# Endless has no enemy base to march to, so both buttons hold a line:
# Defend = the line near our base, Advance = the forward line.
func _apply_stance(unit: Node) -> void:
	if GameMode.endless:
		unit.set_stance(true, defend_point.global_position.x if defending else ENDLESS_FORWARD_X)
	else:
		unit.set_stance(defending, defend_point.global_position.x)


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

# ---------- ENDLESS MODE ----------
# Each wave gets a budget of points that grows every wave. The AI spends it on enemies that
# are unlocked for that wave (and counter-picks them like in the story). Enemies also get
# tougher with every wave. A wave ends when everything is spawned and dead, then there is a short break.

func _tick_endless(delta: float) -> void:
	if not wave_active:
		wave_countdown -= delta
		if wave_countdown <= 0.0:
			_start_wave()
		return

	wave_time += delta
	var alive := get_tree().get_nodes_in_group("enemy_army").size()

	# send the wave out one unit at a time (respecting the alive cap)
	wave_spawn_timer -= delta
	if wave_budget > 0.0 and wave_spawn_timer <= 0.0 and alive < AI_MAX_ALIVE:
		var e := _endless_next_unit()
		if e.is_empty():
			wave_budget = 0.0   # nothing affordable is left
		else:
			wave_budget -= float(e["cost"])
			_spawn_enemy(_scaled(e))
			wave_spawn_timer = ENDLESS_SPAWN_GAP
			alive += 1

	if wave_budget <= 0.0 and alive == 0:
		_end_wave()
	elif wave_time >= ENDLESS_WAVE_MAX_TIME:
		_start_wave()   # the wave dragged on: the next one comes anyway (leftover budget carries over)

func _start_wave() -> void:
	wave += 1
	wave_active = true
	wave_time = 0.0
	wave_spawn_timer = 0.0
	wave_budget += ENDLESS_BUDGET_BASE + ENDLESS_BUDGET_PER_WAVE * (wave - 1)
	var msg := "Wave %d" % wave
	for e in ENEMY_UNITS:
		if wave > 1 and e.get("endless_wave", 1) == wave:
			msg += "\nNew enemy: %s!" % e.get("name", "???")
	_toast(msg)
	update_stats()

func _end_wave() -> void:
	wave_active = false
	wave_countdown = ENDLESS_BREAK
	var bonus := ENDLESS_CLEAR_BONUS + floori(wave / 5.0)
	money += bonus
	update_ui()
	_toast("Wave %d cleared!  +%d gold" % [wave, bonus])

# the counter-picking logic from the story picks what we want, but it has to fit in what is left of the budget
func _endless_next_unit() -> Dictionary:
	var pool := ENEMY_UNITS.filter(_enemy_unlocked)
	var affordable := pool.filter(func(e): return float(e["cost"]) <= wave_budget)
	if affordable.is_empty():
		return {}
	var pick := _pick_enemy()
	if float(pick["cost"]) <= wave_budget:
		return pick
	return affordable.pick_random()

# stronger enemies every wave: more hp, +1 damage every few waves, a little more reward
func _scaled(entry: Dictionary) -> Dictionary:
	var e := entry.duplicate()
	var w := wave - 1
	e["hp"] = ceili(float(entry["hp"]) * (1.0 + ENDLESS_HP_SCALE * w))
	e["damage"] = int(entry["damage"]) + floori(w / float(ENDLESS_DAMAGE_EVERY))
	e["reward"] = int(entry.get("reward", 1)) + floori(w / 4.0)
	return e

func _play_endless_intro() -> void:
	GameMode.intro_seen = true
	await _say(ENDLESS_INTRO)
	_start_level_music()

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

	var intro: Array = STORY_INTROS[GameMode.level - 1]
	await _say(intro[0])

	if cam:
		if story.skip_all:
			cam.position.x = home_x
		else:
			var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(cam, "position:x", home_x, 2.0) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await tw.finished

	await _say(intro[1])
	get_tree().paused = false
	_start_level_music()

func _start_level_music() -> void:
	level_music.volume_db = -40.0
	level_music.play()
	create_tween().tween_property(level_music, "volume_db", 0.0, 2.0)   # 2 second fade-in

# ---------- F2 cheat: spawn 5 pumpkins ----------

func _unhandled_input(event: InputEvent) -> void:
	if game_over or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F2:
		for i in 5:
			var u := _spawn(PLAYER_UNITS["pumpkin"], true, spawn_point)
			u.global_position = Vector2((enemy_base.global_position.x if is_instance_valid(enemy_base) else 1600.0) - AI_THREAT_RANGE + 100 - i * 30, spawn_point.global_position.y)
