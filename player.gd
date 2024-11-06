extends CharacterBody2D
# Controls: Arrow keys for diagonal movement, space bar for jumping

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 1000.0       # Speed during dash
const DASH_DURATION = 0.2       # Duration of the dash in seconds
const DOUBLE_TAP_TIME = 0.3     # Max time allowed between two presses for a double-tap

var dash_time = 0.0             # Time remaining for dash
var dash_direction = Vector2.ZERO  # Dash direction vector
var is_dashing = false          # Whether the character is currently dashing

# Last press time for each direction
var last_press_time = {
	"left": 0.0,
	"right": 0.0,
	"up": 0.0,
	"down": 0.0
}

func _physics_process(delta: float) -> void:
	# Handle dashing
	if is_dashing:
		dash_time -= delta
		if dash_time <= 0:
			is_dashing = false
			velocity = Vector2.ZERO  # Reset velocity after dash
		else:
			velocity = dash_direction * DASH_SPEED
			move_and_slide()
			return

	# Apply gravity if not on the floor
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	# Handle jumping
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Check for double-tap dash on arrow keys
	if Input.is_action_just_pressed("ui_right"):
		check_double_tap("right", Vector2.RIGHT)
	elif Input.is_action_just_pressed("ui_left"):
		check_double_tap("left", Vector2.LEFT)
	elif Input.is_action_just_pressed("ui_up"):
		check_double_tap("up", Vector2.UP)
	elif Input.is_action_just_pressed("ui_down"):
		check_double_tap("down", Vector2.DOWN)

	# Regular movement if not dashing
	if not is_dashing:
		var direction_x := Input.get_axis("ui_left", "ui_right")
		var direction_y := Input.get_axis("ui_up", "ui_down")
		var direction := Vector2(direction_x, direction_y).normalized()

		if direction != Vector2.ZERO:
			velocity.x = direction.x * SPEED
			velocity.y = direction.y * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()

# Function to check for double-tap and start a dash
func check_double_tap(direction_key: String, direction_vector: Vector2) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0  # Current time in seconds
	if current_time - last_press_time[direction_key] < DOUBLE_TAP_TIME:
		start_dash(direction_vector)
	last_press_time[direction_key] = current_time

# Function to start the dash
func start_dash(dash_vector: Vector2) -> void:
	is_dashing = true
	dash_time = DASH_DURATION
	dash_direction = dash_vector
