extends Node2D

## Map.gd
## Manages procedural terrain generation and tile-based coordinate conversions.

# Reference to the TileMap child node
@onready var terrain_tilemap: TileMap = $TerrainTileMap

# 2D arrays storing map data: [y][x] format
var elevation_map: Array = []  # int elevation in meters (0-200)
var terrain_map: Array = []    # String terrain type ("grass", "forest", "road")

# Terrain type options
const TERRAIN_TYPES: Array = ["grass", "forest", "road"]


func _ready() -> void:
	_generate_map()


## Generates procedural terrain with random elevation and terrain types
func _generate_map() -> void:
	# Initialize 2D arrays
	elevation_map.resize(GameConfig.MAP_HEIGHT)
	terrain_map.resize(GameConfig.MAP_HEIGHT)

	for y in range(GameConfig.MAP_HEIGHT):
		elevation_map[y] = []
		terrain_map[y] = []
		elevation_map[y].resize(GameConfig.MAP_WIDTH)
		terrain_map[y].resize(GameConfig.MAP_WIDTH)

	# Start with baseline elevation
	var current_elevation: int = 50

	# Generate each tile
	for y in range(GameConfig.MAP_HEIGHT):
		for x in range(GameConfig.MAP_WIDTH):
			# Modify elevation with random delta
			var delta: int = randi_range(-20, 20)
			current_elevation = clamp(current_elevation + delta, 0, 200)
			elevation_map[y][x] = current_elevation

			# Assign random terrain type
			terrain_map[y][x] = TERRAIN_TYPES[randi() % TERRAIN_TYPES.size()]

			# Draw tile in TileMap (using tile ID 0 from the tileset)
			terrain_tilemap.set_cell(GameConfig.LAYER_TERRAIN, Vector2i(x, y), 0, Vector2i(0, 0))


## Converts world position to grid tile coordinates
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = to_local(world_pos)
	var tile_x: int = int(local_pos.x / GameConfig.TILE_SIZE)
	var tile_y: int = int(local_pos.y / GameConfig.TILE_SIZE)
	return Vector2i(tile_x, tile_y)


## Converts grid tile coordinates to world position (center of tile)
func grid_to_world(tile: Vector2i) -> Vector2:
	var local_x: float = (tile.x + 0.5) * GameConfig.TILE_SIZE
	var local_y: float = (tile.y + 0.5) * GameConfig.TILE_SIZE
	return to_global(Vector2(local_x, local_y))


## Returns elevation value for given tile (0 if out of bounds)
func get_elevation(tile: Vector2i) -> int:
	if not is_inside_map(tile):
		return 0
	return elevation_map[tile.y][tile.x]


## Checks if tile coordinates are within map bounds
func is_inside_map(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < GameConfig.MAP_WIDTH and \
	       tile.y >= 0 and tile.y < GameConfig.MAP_HEIGHT


## Converts tile coordinates to faux MGRS coordinate string
## Top-left tile (0,0) is "37U DB 13224 79170"
## Right +1 tile increases easting by 1
## Down +1 tile increases northing by 1
func tile_to_mgrs(tile: Vector2i) -> String:
	const BASE_EASTING: int = 13224
	const BASE_NORTHING: int = 79170

	var easting: int = BASE_EASTING + tile.x
	var northing: int = BASE_NORTHING + tile.y

	# Format with zero-padding to 5 digits
	return "37U DB %05d %05d" % [easting, northing]
