extends Node2D

## Enemy.gd
## Enemy entity that moves downward toward the player position.
## Emits a signal when reaching the bottom of the map.

# Signal emitted when enemy reaches the bottom line
signal reached_bottom(enemy: Node2D)

# Movement speed in pixels per second
@export var speed: float = GameConfig.ENEMY_SPEED

# World Y coordinate of the bottom line (player position)
var bottom_y: float = 0.0


func _ready() -> void:
	# Calculate the bottom y position (MAP_HEIGHT * TILE_SIZE)
	bottom_y = GameConfig.MAP_HEIGHT * GameConfig.TILE_SIZE


func _process(delta: float) -> void:
	# Move downward
	position.y += speed * delta

	# Check if reached bottom
	if position.y >= bottom_y:
		reached_bottom.emit(self)
		queue_free()
