extends CharacterBody2D

@export var speed: float = 100.0
@export var direction: int = 1  # 1 = right, -1 = left

const GRAVITY := 900.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = speed * direction
	move_and_slide()
