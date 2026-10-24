extends Area2D

@export var speed: float = 600.0
@export var max_distance: float = 900.0
@export var hit_sound: AudioStream   

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
		_play_hit_sound()
		queue_free()

func _play_hit_sound() -> void:
	if hit_sound == null:
		return   # projectiles with no sound set stay silent
	var p := AudioStreamPlayer.new()
	p.stream = hit_sound
	p.bus = "SFX"
	p.volume_db = -4.0
	p.pitch_scale = randf_range(0.9, 1.1)
	p.finished.connect(p.queue_free)
	get_tree().current_scene.add_child(p)   # on the level, because the snowball deletes itself right after
	p.play()
