extends Node2D

## Enemy.gd
## Enemy entity with zig-zag movement pattern and HP system.
## Emits a signal when reaching the bottom of the map.

# Signal emitted when enemy reaches the bottom line
signal reached_bottom(enemy: Node2D)

# Movement speed in pixels per second
@export var speed: float = GameConfig.ENEMY_SPEED

# Hit points
@export var hp: int = 1

# World Y coordinate of the bottom line (player position)
var bottom_y: float = 0.0

# Movement state tracking
var horizontal_move_count: int = 0  # Consecutive horizontal-only moves
var movement_timer: float = 0.0
const MOVEMENT_INTERVAL: float = 0.3  # Seconds between direction changes

# Movement direction options
enum MoveDirection { DOWN, DOWN_RIGHT, DOWN_LEFT, PAUSE }


func _ready() -> void:
	# Calculate the bottom y position (MAP_HEIGHT * TILE_SIZE)
	bottom_y = GameConfig.MAP_HEIGHT * GameConfig.TILE_SIZE


func _process(delta: float) -> void:
	# Update movement timer
	movement_timer += delta

	if movement_timer >= MOVEMENT_INTERVAL:
		movement_timer = 0.0
		_perform_movement_tick(delta * (MOVEMENT_INTERVAL / delta))
	else:
		# Continue previous direction smoothly
		_apply_current_direction(delta)

	# Check if reached bottom
	if position.y >= bottom_y:
		reached_bottom.emit(self)
		queue_free()


## Performs one movement decision tick
func _perform_movement_tick(tick_delta: float) -> void:
	var possible_moves: Array[MoveDirection] = []

	# If we've made 3 horizontal moves, force downward
	if horizontal_move_count >= 3:
		possible_moves = [MoveDirection.DOWN, MoveDirection.DOWN_RIGHT, MoveDirection.DOWN_LEFT]
	else:
		# All directions available
		possible_moves = [MoveDirection.DOWN, MoveDirection.DOWN_RIGHT, MoveDirection.DOWN_LEFT, MoveDirection.PAUSE]

	# Try random direction until we find valid one
	var attempts: int = 0
	var chosen_dir: MoveDirection = possible_moves[randi() % possible_moves.size()]

	while not _is_move_valid(chosen_dir) and attempts < 10:
		chosen_dir = possible_moves[randi() % possible_moves.size()]
		attempts += 1

	_apply_movement_direction(chosen_dir, tick_delta)


## Checks if a movement direction would keep enemy in bounds
func _is_move_valid(dir: MoveDirection) -> bool:
	var test_pos: Vector2 = position
	var move_dist: float = speed * MOVEMENT_INTERVAL

	match dir:
		MoveDirection.DOWN:
			test_pos.y += move_dist
		MoveDirection.DOWN_RIGHT:
			test_pos.x += move_dist * 0.7
			test_pos.y += move_dist * 0.7
		MoveDirection.DOWN_LEFT:
			test_pos.x -= move_dist * 0.7
			test_pos.y += move_dist * 0.7
		MoveDirection.PAUSE:
			return true

	# Check bounds (with small margin)
	var margin: float = 16.0
	return test_pos.x >= margin and test_pos.x < (GameConfig.MAP_WIDTH * GameConfig.TILE_SIZE - margin)


## Applies the chosen movement direction
var current_direction: MoveDirection = MoveDirection.DOWN

func _apply_movement_direction(dir: MoveDirection, tick_delta: float) -> void:
	current_direction = dir

	# Track horizontal movement count
	if dir == MoveDirection.DOWN:
		horizontal_move_count = 0
	elif dir != MoveDirection.PAUSE:
		if dir == MoveDirection.DOWN_RIGHT or dir == MoveDirection.DOWN_LEFT:
			# These have downward component, reset counter
			horizontal_move_count = 0


## Applies current direction smoothly each frame
func _apply_current_direction(delta: float) -> void:
	var move_dist: float = speed * delta

	match current_direction:
		MoveDirection.DOWN:
			position.y += move_dist
		MoveDirection.DOWN_RIGHT:
			position.x += move_dist * 0.7
			position.y += move_dist * 0.7
		MoveDirection.DOWN_LEFT:
			position.x -= move_dist * 0.7
			position.y += move_dist * 0.7
		MoveDirection.PAUSE:
			pass  # No movement


## Takes damage and destroys if HP reaches 0
func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		queue_free()
