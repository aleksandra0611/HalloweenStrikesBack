extends Area2D

@export var speed: float = 600.0
@export var max_distance: float = 900.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 1
var travelled: float = 0.0
var hit: bool = false

func setup(dir: Vector2, dmg: int, mask: int) -> void:
	direction = dir.normalized()
	damage = dmg
	collision_mask = mask
	rotation = direction.angle()

func _ready() -> void:
	collision_layer = 0
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	travelled += step.length()
	if travelled >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if hit:
		return
	if body.has_method("take_damage"):
		hit = true
		body.take_damage(damage)
		queue_free()
