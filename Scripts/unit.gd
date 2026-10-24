extends CharacterBody2D

signal died

const DamageNumber = preload("res://Scripts/damage_number.gd")
const GRAVITY := 900.0

# physics layers (layer 1 = bit 0)
const LAYER_GROUND := 1 << 0          # layer 1
const LAYER_PLAYER_MELEE := 1 << 1    # layer 2 (also your base)
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
@export var projectile_scene: PackedScene = preload("res://Scenes/arrow.tscn")

@export_group("Animation")
@export var sprite_faces_right: bool = true   # untick if your art faces LEFT by default
@export var hit_frame: int = 2                # attack frame (starting at 0) where the hit lands
@export var head_offset: float = 70.0         # height above the feet where damage numbers appear
@export var arrow_offset: Vector2 = Vector2(20, 0)   # where arrows spawn, relative to the unit

var direction: int = 1
var facing: int = 1
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

var attacking: bool = false
var attack_hit_done: bool = false
var attack_target: Node2D = null

@onready var attack_range: Area2D = $AttackRange
@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	_setup_side()
	siege_distance = randf_range(siege_min, siege_max)
	enemy_base = get_tree().get_first_node_in_group("enemy_base" if is_player else "player_base") as Node2D
	attack_range.body_entered.connect(_on_body_entered)
	attack_range.body_exited.connect(_on_body_exited)
	facing = direction
	if sprite:
		sprite.frame_changed.connect(_on_sprite_frame_changed)
		sprite.animation_finished.connect(_on_sprite_animation_finished)
		_apply_facing()
		_play("idle")

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
		add_to_group("enemy_army")
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
	collision_mask = LAYER_GROUND if (near_base or defending) else normal_mask  

	if not targets.is_empty():
		# fight units in range first
		velocity.x = 0.0
		_try_attack(delta, _nearest_target())
	elif defending:
		# walk to the defend point and wait there
		var dx := (defend_x - defend_back * direction) - global_position.x
		velocity.x = signf(dx) * speed if absf(dx) > 6.0 else 0.0
		attack_timer = attack_interval
	elif near_base and absf(base_dx) <= siege_distance:
		# in position: attack the base
		velocity.x = 0.0
		_try_attack(delta, enemy_base)
	else:
		velocity.x = speed * direction
		attack_timer = attack_interval

	if attacking:
		velocity.x = 0.0   # stand still during the attack animation

	move_and_slide()
	_update_animation()

# ---------- attacking ----------

func _try_attack(delta: float, target: Node2D) -> void:
	if attacking:
		return
	attack_timer -= delta
	if attack_timer > 0.0:
		return
	attack_timer = attack_interval
	_start_attack(target)

func _start_attack(target: Node2D) -> void:
	if target == null:
		return
	# no sprite or no "attack" animation: hit instantly
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("attack"):
		_do_attack(target)
		return
	attacking = true
	attack_hit_done = false
	attack_target = target
	var dx := target.global_position.x - global_position.x
	if absf(dx) > 1.0:
		facing = 1 if dx > 0.0 else -1
		_apply_facing()
	sprite.play("attack")

func _on_sprite_frame_changed() -> void:
	if not attacking or attack_hit_done or sprite.animation != "attack":
		return
	var last_frame := sprite.sprite_frames.get_frame_count("attack") - 1
	if sprite.frame >= mini(hit_frame, last_frame):
		_finish_hit()

func _on_sprite_animation_finished() -> void:
	if sprite.animation != "attack":
		return
	if not attack_hit_done:
		_finish_hit()   # safety: never skip the damage
	attacking = false
	attack_target = null

func _finish_hit() -> void:
	attack_hit_done = true
	if is_instance_valid(attack_target):
		_do_attack(attack_target)

func _do_attack(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
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
	var dir: Vector2 = target.global_position - global_position
	if dir.length() < 1.0:
		dir = Vector2(direction, 0)
	var projectile = projectile_scene.instantiate()
	projectile.setup(dir, damage, attack_range.collision_mask)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + Vector2(arrow_offset.x * facing, arrow_offset.y)

# ---------- animation ----------

func _update_animation() -> void:
	if sprite == null or attacking:
		return
	if absf(velocity.x) > 1.0:
		var new_facing := 1 if velocity.x > 0.0 else -1
		if new_facing != facing:
			facing = new_facing
			_apply_facing()
		_play("run")
	else:
		var look := direction
		if not targets.is_empty():
			var t := _nearest_target()
			if t != null and absf(t.global_position.x - global_position.x) > 1.0:
				look = 1 if t.global_position.x > global_position.x else -1
		if look != facing:
			facing = look
			_apply_facing()
		_play("idle")

func _play(anim: String) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim):
		return
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)

func _apply_facing() -> void:
	sprite.flip_h = (facing < 0) if sprite_faces_right else (facing > 0)

# ---------- health ----------

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
	n.setup(amount, number_color, global_position + Vector2(-8, -head_offset))
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
	defending = is_defending
	defend_x = x
