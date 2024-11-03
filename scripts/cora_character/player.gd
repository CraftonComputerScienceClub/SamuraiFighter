class_name Player

extends CharacterBody2D

enum Direction {
	Left, Right, Up, Down
}

enum AttackState {
	Idle, HorizontalLight, UpLight, DownLight, Great
}

var gravity: float = 0.0
var jump_buffer: float = 0.0
var coyote_time: float = 0.0
var attack_duration: float = 0.0
var attack_cooldown: float = 0.0
var heavy_attack_charge: float = 0.0
var air_stall: bool = false
var facing: Direction = Direction.Right
var attack_dir: Direction = Direction.Right
var attack_state: AttackState = AttackState.Idle

@onready var horizontal_light_attack : Area2D = self.get_node("melee/horizontal_light_attack")
@onready var up_light_attack 		 : Area2D = self.get_node("melee/up_light_attack")
@onready var down_light_attack 		 : Area2D = self.get_node("melee/down_light_attack")
@onready var great_attack 			 : Area2D = self.get_node("melee/great_attack")
@onready var heavy_attack_marker 	 : Node2D = self.get_node("heavy_attack_marker")

const JUMP_BUFFER_TIME = 0.175
const COYOTE_TIME 	   = 0.175

const LIGHT_ATTACK_DURATION = 0.25
const GREAT_ATTACK_DURATION = 0.5
const HEAVY_ATTACK_CHARGE   = 1.35
const ATTACK_COOLDOWN		= 0.125

const GROUND_HORIZONTAL_ACCELERATION = 2400.0
const GROUND_HORIZONTAL_TURNAROUND   = 2800.0
const GROUND_HORIZONTAL_DECELERATION = 1800.0
const GROUND_MAX_HORIZONTAL_VELOCITY =  512.0
const AIR_HORIZONTAL_ACCELERATION = 3600.0
const AIR_HORIZONTAL_TURNAROUND   = 1600.0
const AIR_HORIZONTAL_DECELERATION = 1300.0
const AIR_MAX_HORIZONTAL_VELOCITY =  650.0

const JUMP_VELOCITY = 1536.0

const RISING_EDGE_GRAVITY = 4608.0
const RISING_CORNER_GRAVITY = 1024.0
const APEX_GRAVITY = 768.0
const FALLING_CORNER_GRAVITY = 3072.0
const FALLING_EDGE_GRAVITY = 2048.0

const RISING_JUMP_TARGET = 320.0
const FALLING_JUMP_TARGET = 480.0
const APEX_JUMP_TARGET = 80.0

func _process(delta: float):
	if jump_buffer > 0.0:
		jump_buffer -= delta
		jump_buffer = max(jump_buffer, 0.0)
	if coyote_time > 0.0 && not is_on_floor():
		coyote_time -= delta
		coyote_time = max(coyote_time, 0.0)
	if attack_duration > 0.0:
		attack_duration -= delta
		attack_duration = max(attack_duration, 0.0)
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		attack_cooldown = max(attack_cooldown, 0.0)
	if Input.is_action_pressed("attack"):
		heavy_attack_charge += delta
		heavy_attack_charge = min(heavy_attack_charge, HEAVY_ATTACK_CHARGE)
	
	if heavy_attack_charge == HEAVY_ATTACK_CHARGE:
		heavy_attack_marker.visible = true
	else:
		heavy_attack_marker.visible = false

	debug()

func _physics_process(delta: float):
	if is_on_floor():
		coyote_time = COYOTE_TIME

	handle_gravity()
	handle_jump()

	handle_horizontal_movement(delta)

	handle_attack_dir()
	handle_attack()

	velocity.y += gravity * delta
	move_and_slide()

func handle_gravity():
	if not is_on_floor():
		if air_stall:
			gravity = 0.0
			velocity.y = 0.0
		else:
			if velocity.y <= RISING_JUMP_TARGET:
				gravity = RISING_EDGE_GRAVITY
			elif velocity.y <= APEX_JUMP_TARGET:
				gravity = RISING_CORNER_GRAVITY
			elif velocity.y >= APEX_JUMP_TARGET:
				gravity = FALLING_CORNER_GRAVITY
			elif velocity.y >= FALLING_JUMP_TARGET:
				gravity = FALLING_EDGE_GRAVITY
			else:
				gravity = APEX_GRAVITY
	if is_on_ceiling():
		gravity = FALLING_EDGE_GRAVITY
		velocity.y = 0.0

func handle_jump():
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER_TIME

	if can_jump():
		# we set the velocity to negative, because up is negative
		velocity.y = -JUMP_VELOCITY
		jump_buffer = 0.0
		coyote_time = 0.0

func handle_horizontal_movement(delta):
	if air_stall:
		velocity.x = 0.0
		return
	
	var direction : float = Input.get_axis("left", "right")

	if direction != 0:
		var dir_sign = sign(direction)
		
		if direction < 0.0 && facing == Direction.Right:
			scale.x *= -1
			facing = Direction.Left
			attack_duration = 0.0
		elif direction > 0.0 && facing == Direction.Left:
			scale.x *= -1
			facing = Direction.Right
			attack_duration = 0.0

		if sign(velocity.x) != dir_sign:
			velocity.x += GROUND_HORIZONTAL_TURNAROUND * delta * dir_sign
		elif abs(velocity.x) < GROUND_MAX_HORIZONTAL_VELOCITY:
			velocity.x += GROUND_HORIZONTAL_ACCELERATION * delta * dir_sign
			velocity.x = min(abs(velocity.x), GROUND_MAX_HORIZONTAL_VELOCITY) * dir_sign
		# When any event causes our player to move faster than our max acceleration, we want to smoothly decelerate to this speed
		elif abs(velocity.x) >= GROUND_MAX_HORIZONTAL_VELOCITY:
			velocity.x -= GROUND_HORIZONTAL_DECELERATION * delta * dir_sign
			velocity.x = max(abs(velocity.x), GROUND_MAX_HORIZONTAL_VELOCITY) * dir_sign
	else:
		if abs(velocity.x) > 0.0:
			if GROUND_HORIZONTAL_DECELERATION * delta >= abs(velocity.x):
				velocity.x = 0.0
			else:
				velocity.x -= GROUND_HORIZONTAL_DECELERATION * delta * sign(velocity.x)

func handle_attack_dir():
	var direction := Vector2i.ZERO

	if Input.is_action_pressed("up"):
		direction += Vector2i.UP
	if Input.is_action_pressed("down"):
		direction += Vector2i.DOWN
	if Input.is_action_pressed("left"):
		direction += Vector2i.LEFT
	if Input.is_action_pressed("right"):
		direction += Vector2i.RIGHT
	
	match [direction.x, direction.y]:
		[_, -1]: attack_dir = Direction.Up
		[_, 1]: attack_dir = Direction.Down
		[-1, 0]: attack_dir = Direction.Left
		[1, 0]: attack_dir = Direction.Right
		_ : attack_dir = facing
	

func handle_attack():
	if attack_duration == 0.0:
		match attack_state:
			AttackState.Idle: pass
			AttackState.HorizontalLight: horizontal_light_attack.visible = false
			AttackState.UpLight: up_light_attack.visible = false
			AttackState.DownLight: down_light_attack.visible = false
			AttackState.Great: great_attack.visible = false
		if attack_state != AttackState.Idle:
			attack_cooldown = ATTACK_COOLDOWN
			attack_state = AttackState.Idle
		air_stall = false
	
	# light attack
	if Input.is_action_just_pressed("attack") && can_attack():
		match attack_dir:
			Direction.Left, Direction.Right: 
				horizontal_light_attack.visible = true
				attack_duration = LIGHT_ATTACK_DURATION
				attack_state = AttackState.HorizontalLight
			Direction.Up: 
				up_light_attack.visible = true
				attack_duration = LIGHT_ATTACK_DURATION
				attack_state = AttackState.UpLight
			Direction.Down: 
				if not is_on_floor():
					down_light_attack.visible = true
					attack_duration = LIGHT_ATTACK_DURATION
					attack_state = AttackState.DownLight
				# for light attacks, we treat this as a horizontal attack because the ground is in the way
				else:
					horizontal_light_attack.visible = true
					attack_duration = LIGHT_ATTACK_DURATION
					attack_state = AttackState.HorizontalLight
	elif Input.is_action_just_released("attack"):
		if heavy_attack_charge == HEAVY_ATTACK_CHARGE:
			match attack_dir:
				Direction.Left, Direction.Right: 
					great_attack.visible = true
					attack_duration = GREAT_ATTACK_DURATION
					attack_state = AttackState.Great
					air_stall = true
				_: print("not implemented yet")
		heavy_attack_charge = 0.0

func can_jump() -> bool:
	return jump_buffer > 0.0 && coyote_time > 0.0

func can_attack() -> bool:
	return attack_duration == 0.0 && attack_cooldown == 0.0

func debug():
	pass
