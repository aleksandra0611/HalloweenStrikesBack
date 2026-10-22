extends CharacterBody2D

signal died

@export var speed: float = 100.0
@export var direction: int = 1  # 1 = right, -1 = left
@export var max_health: int = 3
@export var damage: int = 1
@export var attack_interval: float = 1.0

const GRAVITY := 900.0

var health: int
var targets: Array = []
var attack_timer: float = 0.0
var is_dead: bool = false

@onready var attack_range: Area2D = $AttackRange
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	attack_range.body_entered.connect(_on_body_entered)
	attack_range.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	targets = targets.filter(func(t): return is_instance_valid(t))
	
	if targets.is_empty():
		velocity.x = speed * direction
		attack_timer = attack_interval
	else:
		velocity.x = 0.0
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = attack_interval
			targets[0].take_damage(damage)

	move_and_slide()

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	health_bar.value = health
	if health <= 0:
		is_dead = true
		died.emit()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	targets.append(body)

func _on_body_exited(body: Node2D) -> void:
	targets.erase(body)
	move_and_slide()
