extends Node2D

## Main.gd
## Main game controller managing enemies, crates, targeting system, UI, and game state.

# Game state
var ammo: int = GameConfig.INITIAL_AMMO
var score: int = 0
var is_game_over: bool = false

# Marker state
var marker_tile: Vector2i = Vector2i(-1, -1)  # Invalid tile when no marker
var marker_node: Node2D = null

# Scene references
@export var enemy_scene: PackedScene
@export var ammo_crate_scene: PackedScene
@export var marker_scene: PackedScene

# Node references
@onready var map: Node2D = $Map
@onready var enemy_container: Node2D = $EnemyContainer
@onready var crate_container: Node2D = $CrateContainer
@onready var observer_icon: Node2D = $ObserverIcon
@onready var ammo_label: Label = $UI/AmmoLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var tukom_ui: Control = $UI/TukomGeneratorUI
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var game_over_label: Label = $UI/GameOverPanel/GameOverLabel
@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer
@onready var crate_spawn_timer: Timer = $CrateSpawnTimer


func _ready() -> void:
	# Load default scenes if not set via editor
	if enemy_scene == null:
		enemy_scene = load("res://scenes/Enemy.tscn")
	if ammo_crate_scene == null:
		ammo_crate_scene = load("res://scenes/AmmoCrate.tscn")
	if marker_scene == null:
		marker_scene = load("res://scenes/Marker.tscn")

	# Initialize UI
	game_over_panel.visible = false
	_update_ui()

	# Position observer icon
	_position_observer_icon()

	# Connect Tukom UI to Map reference
	tukom_ui.map = map

	# Connect signals
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)
	crate_spawn_timer.timeout.connect(_on_crate_spawn_timer_timeout)
	tukom_ui.target_coordinates_set.connect(_on_target_coordinates_set)
	tukom_ui.fire_command_reset.connect(_on_fire_command_reset)

	# Connect FIRE button from TukomGeneratorUI
	var fire_button: Button = tukom_ui.get_node("Panel/HBoxContainer/FireButton")
	if fire_button:
		fire_button.pressed.connect(_on_fire_button_pressed)


func _input(event: InputEvent) -> void:
	# Ignore input if game is over
	if is_game_over:
		return

	# Handle left mouse button clicks for coordinate selection
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Check if click is in Tukom UI area - if so, ignore (UI will handle it)
			var tukom_rect: Rect2 = tukom_ui.get_global_rect()
			if tukom_rect.has_point(event.position):
				return

			# Use global mouse position to account for viewport/camera transforms
			var mouse_pos: Vector2 = get_global_mouse_position()
			_handle_map_tap(mouse_pos)


## Positions the observer icon at bottom-center of playable map area
## Must be above Tukom UI and fully visible
func _position_observer_icon() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var tukom_ui_height: float = 120.0

	# Position at bottom-center of playable area (above Tukom UI)
	var observer_x: float = viewport_size.x / 2.0
	var observer_y: float = viewport_size.y - tukom_ui_height - 40.0  # 40px margin above UI

	observer_icon.position = Vector2(observer_x, observer_y)


## Handles map tap for coordinate selection (Phase 2)
## Does NOT fire immediately - only sets coordinates in Tukom UI
func _handle_map_tap(screen_pos: Vector2) -> void:
	# Convert screen position to tile coordinates
	var tile: Vector2i = map.world_to_grid(screen_pos)

	# Check if tile is inside map bounds
	if not map.is_inside_map(tile):
		return

	# Check if click is below the observer icon (in UI reserved area)
	if screen_pos.y > observer_icon.position.y:
		return

	# Remove old marker if exists
	if marker_node != null:
		marker_node.queue_free()
		marker_node = null

	# Set coordinates in Tukom UI (will trigger target_coordinates_set signal)
	tukom_ui.set_target_coordinates(tile)


## Called when target coordinates are set in Tukom UI
func _on_target_coordinates_set(tile: Vector2i) -> void:
	# Update internal state
	marker_tile = tile

	# Create new marker at target position
	marker_node = marker_scene.instantiate()
	var marker_world_pos: Vector2 = map.grid_to_world(tile)
	marker_node.position = marker_world_pos
	add_child(marker_node)


## Called when fire command is reset (after firing)
func _on_fire_command_reset() -> void:
	_clear_marker()


## Handles FIRE button press
func _on_fire_button_pressed() -> void:
	# Check if player has ammo
	if ammo <= 0:
		return

	# Check if Tukom UI is ready (all fields set)
	if not tukom_ui.is_ready():
		return

	# Get target tile from Tukom UI
	var target: Vector2i = tukom_ui.get_target_tile()
	if target.x < 0 or target.y < 0:
		return

	# Consume ammo
	ammo -= 1

	# Fire at target with 3x3 AOE
	# For Phase 1-2, we use standard scoring (1 point per hit)
	# Phase 5 will add perfect alignment detection for 10x scoring
	_fire_at_target(target, false)

	# Reset Tukom UI (triggers fire_command_reset signal)
	tukom_ui.reset_after_fire()

	# Update UI
	_update_ui()


## Fires artillery at target position with 3x3 AOE damage
## is_perfect: if true, grants 10 points per hit, otherwise 1 point
func _fire_at_target(target_tile: Vector2i, is_perfect: bool) -> void:
	# Calculate the bounding box of the 3x3 affected area in world coordinates
	# Top-left tile of 3x3 grid
	var min_tile: Vector2i = Vector2i(target_tile.x - 1, target_tile.y - 1)
	var max_tile: Vector2i = Vector2i(target_tile.x + 1, target_tile.y + 1)

	# Clamp to map bounds
	min_tile.x = max(0, min_tile.x)
	min_tile.y = max(0, min_tile.y)
	max_tile.x = min(GameConfig.MAP_WIDTH - 1, max_tile.x)
	max_tile.y = min(GameConfig.MAP_HEIGHT - 1, max_tile.y)

	# Convert to world coordinates using map's coordinate system
	# Get top-left corner of min_tile and bottom-right corner of max_tile
	var min_center: Vector2 = map.grid_to_world(min_tile)
	var max_center: Vector2 = map.grid_to_world(max_tile)
	var half_tile: float = GameConfig.TILE_SIZE / 2.0

	var aoe_min: Vector2 = min_center - Vector2(half_tile, half_tile)
	var aoe_max: Vector2 = max_center + Vector2(half_tile, half_tile)

	# Build list of entities to damage (avoid modifying containers while iterating)
	var enemies_to_damage: Array = []
	var crates_to_damage: Array = []

	# Check all enemies - any entity whose position is within the AOE box gets hit
	for enemy in enemy_container.get_children():
		var pos: Vector2 = enemy.position
		if pos.x >= aoe_min.x and pos.x <= aoe_max.x and \
		   pos.y >= aoe_min.y and pos.y <= aoe_max.y:
			enemies_to_damage.append(enemy)

	# Check all crates
	for crate in crate_container.get_children():
		var pos: Vector2 = crate.position
		if pos.x >= aoe_min.x and pos.x <= aoe_max.x and \
		   pos.y >= aoe_min.y and pos.y <= aoe_max.y:
			crates_to_damage.append(crate)

	# Determine points per hit based on alignment
	var points_per_hit: int = GameConfig.PERFECT_HIT_BONUS if is_perfect else GameConfig.NORMAL_HIT_POINTS

	# Apply damage to all hit entities
	for enemy in enemies_to_damage:
		if enemy.has_method("take_damage"):
			var was_destroyed: bool = enemy.take_damage(1)
			if was_destroyed:
				score += points_per_hit

	for crate in crates_to_damage:
		if crate.has_method("take_damage"):
			var was_destroyed: bool = crate.take_damage(1)
			if was_destroyed:
				ammo += GameConfig.AMMO_PER_CRATE


## Clears the target marker
func _clear_marker() -> void:
	if marker_node != null:
		marker_node.queue_free()
		marker_node = null

	marker_tile = Vector2i(-1, -1)


## Spawns an enemy at a random top-row tile
func _on_enemy_spawn_timer_timeout() -> void:
	# Don't spawn if game is over
	if is_game_over:
		return

	# Don't spawn if at max enemy count
	if enemy_container.get_child_count() >= GameConfig.MAX_ENEMIES:
		return

	# Choose random x position on top row
	var x: int = randi_range(0, GameConfig.MAP_WIDTH - 1)
	var tile: Vector2i = Vector2i(x, 0)
	var world_pos: Vector2 = map.grid_to_world(tile)

	# Instantiate and configure enemy
	var enemy: Node2D = enemy_scene.instantiate()
	enemy.position = world_pos
	enemy_container.add_child(enemy)

	# Connect enemy signal
	enemy.reached_bottom.connect(_on_enemy_reached_bottom)


## Spawns an ammo crate at a random tile (not top or bottom row)
func _on_crate_spawn_timer_timeout() -> void:
	# Don't spawn if game is over
	if is_game_over:
		return

	# Don't spawn if at max crate count
	if crate_container.get_child_count() >= GameConfig.MAX_CRATES:
		return

	# Choose random position (avoid top and bottom rows)
	var x: int = randi_range(0, GameConfig.MAP_WIDTH - 1)
	var y: int = randi_range(1, GameConfig.MAP_HEIGHT - 2)
	var tile: Vector2i = Vector2i(x, y)
	var world_pos: Vector2 = map.grid_to_world(tile)

	# Instantiate and configure crate
	var crate: Node2D = ammo_crate_scene.instantiate()
	crate.position = world_pos
	crate_container.add_child(crate)


## Called when an enemy reaches the bottom of the map
func _on_enemy_reached_bottom(enemy: Node2D) -> void:
	_trigger_game_over("Enemy reached your position!")


## Triggers game over state with a reason message
func _trigger_game_over(reason: String) -> void:
	# Prevent multiple game over triggers
	if is_game_over:
		return

	is_game_over = true

	# Stop spawning
	enemy_spawn_timer.stop()
	crate_spawn_timer.stop()

	# Update game over UI
	game_over_label.text = "%s\nFinal Score: %d" % [reason, score]
	game_over_panel.visible = true


## Updates the UI labels with current game state
func _update_ui() -> void:
	ammo_label.text = "Ammo: %d" % ammo
	score_label.text = "Score: %d" % score
