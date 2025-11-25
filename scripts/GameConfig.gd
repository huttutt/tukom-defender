extends Node

## GameConfig.gd
## Centralized configuration constants for TUKOM Defender.
## All gameplay values should be referenced from here to avoid hardcoding.

# Tile and Map Dimensions
const TILE_SIZE: int = 64  # Pixels per tile
const MAP_WIDTH: int = 20  # Tiles horizontally
const MAP_HEIGHT: int = 30  # Tiles vertically

# Enemy Settings
const ENEMY_SPEED: float = 40.0  # Pixels per second
const ENEMY_SPAWN_INTERVAL: float = 2.0  # Seconds between spawns
const MAX_ENEMIES: int = 50  # Maximum concurrent enemies

# Ammo Crate Settings
const CRATE_SPAWN_INTERVAL: float = 12.0  # Seconds between crate spawns
const AMMO_PER_CRATE: int = 5  # Ammo gained per crate destroyed
const MAX_CRATES: int = 3  # Maximum concurrent crates

# Player Settings
const INITIAL_AMMO: int = 20  # Starting ammunition

# TileMap Layer Indices
const LAYER_TERRAIN: int = 0  # TileMap layer for terrain tiles

# Tukom (Fire Command) Settings
const DISTANCE_STEP: int = 50  # Distance wheel increments in meters
const MIN_DISTANCE: int = 0  # Minimum distance value
const MAX_DISTANCE: int = 2000  # Maximum distance value (in meters)
const PERFECT_HIT_BONUS: int = 10  # Points for perfect alignment
const NORMAL_HIT_POINTS: int = 1  # Points for regular hits
