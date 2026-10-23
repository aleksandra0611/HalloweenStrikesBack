extends CharacterBody2D

signal died

const DamageNumber = preload("res://Scripts/damage_number.gd")
const GRAVITY := 900.0

@export var speed: float = 100.0
@export var direction: int = -1  # 1 = right, -1 = left
@export var max_health: int = 3
@export var damage: int = 1
@export var attack_interval: float = 1.0
@export var number_color: Color = Color.RED

@export var siege_zone: float = 250.0   # this close to your base, enemies stop blocking friends
@export var siege_min: float = 55.0     # random stop distance from the base's centre
@export var siege_max: float = 120.0

var health: int
var targets: Array = []
var attack_timer: float = 0.0
var is_dead: bool = false
var last_number = null
var last_number_time: float = -1.0

var enemy_base: Node2D = null   # for this unit, the base it attacks (your base)
var normal_mask: int = 0
var siege_distance: float = 0.0

@onready var attack_range: Area2D = $AttackRange
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	normal_mask = collision_mask
	siege_distance = randf_range(siege_min, siege_max)
	enemy_base = get_tree().get_first_node_in_group("enemy_base" if direction == 1 else "player_base") as Node2D
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
	collision_mask = 1 if near_base else normal_mask   # near the tower: walk through friends

	if not targets.is_empty():
		# fight units first
		velocity.x = 0.0
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = attack_interval
			targets[0].take_damage(damage)
	elif near_base and absf(base_dx) <= siege_distance:
		# in position: hit the tower
		velocity.x = 0.0
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = attack_interval
			enemy_base.take_damage(damage)
	else:
		velocity.x = speed * direction
		attack_timer = attack_interval

	move_and_slide()

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
		return   # the tower is handled by the siege logic above
	targets.append(body)

func _on_body_exited(body: Node2D) -> void:
	targets.erase(body)
