extends StaticBody2D

signal destroyed

@export var max_health: int = 20
@export var is_player_base: bool = true

var health: int
var is_dead: bool = false
var last_number = null
var last_number_time: float = -1.0

const DamageNumber = preload("res://Scripts/damage_number.gd")

@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	add_to_group("player_base")
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	collision_mask = 0
	collision_layer = 2 if is_player_base else 4  # layer 2 = yours, layer 3 = enemy

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	health_bar.value = health
	_show_damage(amount)
	if health <= 0:
		is_dead = true
		destroyed.emit()
		queue_free()
		
func _show_damage(amount: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if is_instance_valid(last_number) and now - last_number_time < 0.3:
		last_number.add(amount)
		return
	var color := Color.WHITE if is_player_base else Color.RED
	var n := DamageNumber.new()
	n.setup(amount, color, global_position + Vector2(-8, -90))
	get_tree().current_scene.add_child(n)
	last_number = n
	last_number_time = now
