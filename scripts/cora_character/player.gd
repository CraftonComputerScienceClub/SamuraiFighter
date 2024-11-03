class_name Player

extends CharacterBody2D
#Controls: Arrow keys for diagonal movement, space bar for jumping

var jump_buffer: float = 0.0
var coyote_time: float = 0.0

const JUMP_VELOCITY = 400.0
const JUMP_BUFFER_TIME 	= 0.175
const COYOTE_TIME 		= 0.175

const HORIZONTAL_ACCELERATION =  800.0
const HORIZONTAL_TURNAROUND   = 2400.0
const HORIZONTAL_DECELERATION = 1600.0
const MAX_HORIZONTAL_VELOCITY =  400.0

func _process(delta: float):
	if jump_buffer > 0.0:
		jump_buffer -= delta
		jump_buffer = max(jump_buffer, 0.0)
	if coyote_time > 0.0 && not is_on_floor():
		coyote_time -= delta
		coyote_time = max(coyote_time, 0.0)
	debug()

func _physics_process(delta: float):
	if is_on_floor():
		coyote_time = COYOTE_TIME

	handle_gravity(delta)
	handle_jump()

	handle_horizontal_movement(delta)

	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

func handle_jump():
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer = JUMP_BUFFER_TIME

	if can_jump():
		# we set the velocity to negative, because up is negative
		velocity.y = -JUMP_VELOCITY
		jump_buffer = 0.0
		coyote_time = 0.0

func handle_horizontal_movement(delta):
	var direction : float = Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		var dir_sign = sign(direction)

		if sign(velocity.x) != dir_sign:
			velocity.x += HORIZONTAL_TURNAROUND * delta * dir_sign
		elif abs(velocity.x) < MAX_HORIZONTAL_VELOCITY:
			velocity.x += HORIZONTAL_ACCELERATION * delta * dir_sign
			velocity.x = min(abs(velocity.x), MAX_HORIZONTAL_VELOCITY) * dir_sign
		# When any event causes our player to move faster than our max acceleration, we want to smoothly decelerate to this speed
		elif abs(velocity.x) >= MAX_HORIZONTAL_VELOCITY:
			velocity.x -= HORIZONTAL_DECELERATION * delta * dir_sign
			velocity.x = max(abs(velocity.x), MAX_HORIZONTAL_VELOCITY) * dir_sign
	else:
		if abs(velocity.x) > 0.0:
			if HORIZONTAL_DECELERATION * delta >= abs(velocity.x):
				velocity.x = 0.0
			else:
				velocity.x -= HORIZONTAL_DECELERATION * delta * sign(velocity.x)

func can_jump() -> bool:
	return jump_buffer > 0.0 && coyote_time > 0.0

func debug():
	pass
