extends CharacterBody2D

signal died

const DamageNumber = preload("res://Scripts/damage_number.gd")
const ARROW_SCENE: PackedScene = preload("res://Scenes/arrow.tscn")
const GRAVITY := 900.0

@export var is_player: bool = true
@export var speed: float = 100.0
@export var max_health: int = 2
@export var damage: int = 1
@export var shoot_interval: float = 0.5
@export var siege_zone: float = 450.0
@export var siege_min: float = 180.0
@export var siege_max: float = 290.0
@export var defend_back: float = 90.0   # archers wait this far behind the defend point

var direction: int = 1
var number_color: Color = Color.WHITE
var health: int
var targets: Array = []
var shoot_timer: float = 0.0
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
	attack_range.collision_layer = 0
	if is_player:
		direction = 1
		number_color = Color.WHITE
		collision_layer = 1 << 3                    # layer 4: your archers
		collision_mask = (1 << 0) | (1 << 3)        # ground + your archers
		attack_range.collision_mask = (1 << 2) | (1 << 4)   # layers 3 and 5
	else:
		direction = -1
		number_color = Color.RED
		collision_layer = 1 << 4                    # layer 5: enemy archers
		collision_mask = (1 << 0) | (1 << 4)        # ground + enemy archers
		attack_range.collision_mask = (1 << 1) | (1 << 3)   # layers 2 and 4
	if is_player:
		add_to_group("player_army")
	normal_mask = collision_mask
	siege_distance = randf_range(siege_min, siege_max)
	enemy_base = get_tree().get_first_node_in_group("enemy_base" if is_player else "player_base") as Node2D
	attack_range.body_entered.connect(_on_body_entered)
	attack_range.body_exited.connect(_on_body_exited)
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	targets = targets.filter(func(t): return is_instance_valid(t))

	var base_dx := INF
	if is_instance_valid(enemy_base):
		base_dx = enemy_base.global_position.x - global_position.x
	var near_base := absf(base_dx) < siege_zone
	collision_mask = 1 if near_base else normal_mask

	if not targets.is_empty():
		velocity.x = 0.0
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = shoot_interval
			_shoot(_nearest_target())
	elif defending:
		var dx := (defend_x - defend_back) - global_position.x
		velocity.x = signf(dx) * speed if absf(dx) > 6.0 else 0.0
		shoot_timer = shoot_interval
	elif near_base and absf(base_dx) <= siege_distance:
		velocity.x = 0.0
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = shoot_interval
			_shoot(enemy_base)
	else:
		velocity.x = speed * direction
		shoot_timer = shoot_interval

	move_and_slide()

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
		return
	targets.append(body)

func _on_body_exited(body: Node2D) -> void:
	targets.erase(body)

func set_stance(is_defending: bool, x: float) -> void:
	if not is_player:
		return
	defending = is_defending
	defend_x = x
