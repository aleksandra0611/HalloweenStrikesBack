extends CharacterBody2D

signal died

const DamageNumber = preload("res://Scripts/damage_number.gd")
const ARROW_SCENE: PackedScene = preload("res://Scenes/arrow.tscn")
const GRAVITY := 900.0

# physics layers 
const LAYER_GROUND := 1 << 0          # layer 1
const LAYER_PLAYER_MELEE := 1 << 1    # layer 2 (also our base)
const LAYER_ENEMY_MELEE := 1 << 2     # layer 3 (also the enemy base)
const LAYER_PLAYER_RANGED := 1 << 3   # layer 4
const LAYER_ENEMY_RANGED := 1 << 4    # layer 5

@export var is_player: bool = true
@export var is_ranged: bool = false
@export var speed: float = 100.0
@export var max_health: int = 3
@export var damage: int = 2
@export var attack_interval: float = 1.0
@export var siege_zone: float = 250.0   # this close to the enemy base, units stop blocking friends
@export var siege_min: float = 55.0     # random stop distance from the base's centre
@export var siege_max: float = 120.0
@export var defend_back: float = 0.0    # wait this far behind the defend point (archers use this)

var direction: int = 1
var number_color: Color = Color.WHITE
var health: int
var targets: Array = []
var attack_timer: float = 0.0
var is_dead: bool = false
var last_number = null
var last_number_time: float = -1.0
var enemy_base: Node2D = null
var normal_mask: int = 0
var siege_distance: float = 0.0
var defending: bool = false
var defend_x: float = 0.0

@onready var attack_range: Area2D = $AttackRange
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	_setup_side()
	siege_distance = randf_range(siege_min, siege_max)
	enemy_base = get_tree().get_first_node_in_group("enemy_base" if is_player else "player_base") as Node2D
	attack_range.body_entered.connect(_on_body_entered)
	attack_range.body_exited.connect(_on_body_exited)

func _setup_side() -> void:
	attack_range.collision_layer = 0
	var own_layer: int
	var enemy_layers: int
	if is_player:
		direction = 1
		number_color = Color.WHITE
		own_layer = LAYER_PLAYER_RANGED if is_ranged else LAYER_PLAYER_MELEE
		enemy_layers = LAYER_ENEMY_MELEE | LAYER_ENEMY_RANGED
		add_to_group("player_army")
	else:
		direction = -1
		number_color = Color.RED
		own_layer = LAYER_ENEMY_RANGED if is_ranged else LAYER_ENEMY_MELEE
		enemy_layers = LAYER_PLAYER_MELEE | LAYER_PLAYER_RANGED
	collision_layer = own_layer
	collision_mask = LAYER_GROUND | own_layer   # ground + units of the same kind
	attack_range.collision_mask = enemy_layers
	normal_mask = collision_mask

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	targets = targets.filter(func(t): return is_instance_valid(t))

	var base_dx := INF
	if is_instance_valid(enemy_base):
		base_dx = enemy_base.global_position.x - global_position.x
	var near_base := absf(base_dx) < siege_zone
	collision_mask = LAYER_GROUND if near_base else normal_mask   # near the base: walk through friends

	if not targets.is_empty():
		# fight units in range first
		velocity.x = 0.0
		_try_attack(delta, _nearest_target())
	elif defending:
		# walk to the defend point and wait there
		var dx := (defend_x - defend_back) - global_position.x
		velocity.x = signf(dx) * speed if absf(dx) > 6.0 else 0.0
		attack_timer = attack_interval
	elif near_base and absf(base_dx) <= siege_distance:
		# in position: attack the base
		velocity.x = 0.0
		_try_attack(delta, enemy_base)
	else:
		velocity.x = speed * direction
		attack_timer = attack_interval

	move_and_slide()

func _try_attack(delta: float, target: Node2D) -> void:
	attack_timer -= delta
	if attack_timer > 0.0:
		return
	attack_timer = attack_interval
	if is_ranged:
		_shoot(target)
	else:
		target.take_damage(damage)

func _nearest_target() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for t in targets:
		var d: float = global_position.distance_squared_to(t.global_position)
		if d < best_dist:
			best_dist = d
			best = t
	return best

func _shoot(target: Node2D) -> void:
	if target == null:
		return
	var dir: Vector2 = target.global_position - global_position
	if dir.length() < 1.0:
		dir = Vector2(direction, 0)
	var arrow = ARROW_SCENE.instantiate()
	arrow.setup(dir, damage, attack_range.collision_mask)
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position + Vector2(20 * direction, 0)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	health_bar.value = health
	_show_damage(amount)
	if health <= 0:
		is_dead = true
		died.emit()
		queue_free()

func _show_damage(amount: int) -> void:
	if not GameSettings.show_damage_numbers:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if is_instance_valid(last_number) and now - last_number_time < 0.3:
		last_number.add(amount)
		return
	var n := DamageNumber.new()
	n.setup(amount, number_color, global_position + Vector2(-8, -70))
	get_tree().current_scene.add_child(n)
	last_number = n
	last_number_time = now

func _on_body_entered(body: Node2D) -> void:
	if body == enemy_base:
		return   # the base is handled by the siege logic above
	targets.append(body)

func _on_body_exited(body: Node2D) -> void:
	targets.erase(body)

func set_stance(is_defending: bool, x: float) -> void:
	if not is_player:
		return
	defending = is_defending
	defend_x = x
