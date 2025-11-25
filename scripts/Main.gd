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
@onready var ammo_label: Label = $UI/AmmoLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var mgrs_label: Label = $UI/MGRSLabel
@onready var fire_button: Button = $UI/FireButton
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
	mgrs_label.visible = false
	fire_button.disabled = true
	_update_ui()

	# Connect signals
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)
	crate_spawn_timer.timeout.connect(_on_crate_spawn_timer_timeout)
	fire_button.pressed.connect(_on_fire_button_pressed)


func _input(event: InputEvent) -> void:
	# Ignore input if game is over
	if is_game_over:
		return

	# Handle left mouse button clicks for marker placement
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("DEBUG INPUT: Mouse click detected at screen pos: ", event.position)

			# Check if click is on the FIRE button - if so, ignore (button will handle it)
			var button_rect: Rect2 = fire_button.get_global_rect()
			if button_rect.has_point(event.position):
				print("DEBUG INPUT: Click is on FIRE button, ignoring for marker placement")
				return

			# Use global mouse position to account for viewport/camera transforms
			var mouse_pos: Vector2 = get_global_mouse_position()
			print("DEBUG INPUT: Global mouse position: ", mouse_pos)
			_handle_marker_placement(mouse_pos)


## Handles marker placement when player clicks on map
func _handle_marker_placement(screen_pos: Vector2) -> void:
	print("DEBUG MARKER: Screen click at: ", screen_pos)

	# Convert screen position to tile coordinates
	var tile: Vector2i = map.world_to_grid(screen_pos)
	print("DEBUG MARKER: Converted to tile: ", tile)

	# Check if tile is inside map bounds
	if not map.is_inside_map(tile):
		print("DEBUG MARKER: Tile outside map bounds, ignoring")
		return

	# Remove old marker if exists
	if marker_node != null:
		marker_node.queue_free()
		marker_node = null

	# Create new marker
	marker_tile = tile
	marker_node = marker_scene.instantiate()
	var marker_world_pos: Vector2 = map.grid_to_world(tile)
	marker_node.position = marker_world_pos
	add_child(marker_node)

	print("DEBUG MARKER: Placed at world pos: ", marker_world_pos)
	print("DEBUG MARKER: Marker node position: ", marker_node.position)

	# Update UI
	mgrs_label.text = map.tile_to_mgrs(tile)
	mgrs_label.visible = true
	fire_button.disabled = false


## Handles FIRE button press
func _on_fire_button_pressed() -> void:
	print("DEBUG FIRE BUTTON: Pressed! marker_tile = ", marker_tile)

	# Check if player has ammo
	if ammo <= 0:
		print("DEBUG FIRE BUTTON: No ammo!")
		return

	# Check if marker exists
	if marker_tile.x < 0 or marker_tile.y < 0:
		print("DEBUG FIRE BUTTON: No valid marker!")
		return

	print("DEBUG FIRE BUTTON: About to fire at marker_tile: ", marker_tile)

	# Consume ammo
	ammo -= 1

	# Fire at marker with 3x3 AOE
	_fire_at_marker()

	# Clear marker
	_clear_marker()

	# Update UI
	_update_ui()


## Fires artillery at marker position with 3x3 AOE damage
func _fire_at_marker() -> void:
	print("DEBUG: Firing at marker tile: ", marker_tile)

	# Calculate the bounding box of the 3x3 affected area in world coordinates
	# Top-left tile of 3x3 grid
	var min_tile: Vector2i = Vector2i(marker_tile.x - 1, marker_tile.y - 1)
	var max_tile: Vector2i = Vector2i(marker_tile.x + 1, marker_tile.y + 1)

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

	print("DEBUG: AOE bounding box: ", aoe_min, " to ", aoe_max)
	print("DEBUG: Enemy count: ", enemy_container.get_child_count())
	print("DEBUG: Crate count: ", crate_container.get_child_count())

	# Build list of entities to damage (avoid modifying containers while iterating)
	var enemies_to_damage: Array = []
	var crates_to_damage: Array = []

	# Check all enemies - any entity whose position is within the AOE box gets hit
	for enemy in enemy_container.get_children():
		var pos: Vector2 = enemy.position
		print("DEBUG: Enemy at ", pos)
		# Check if position is within bounding box
		if pos.x >= aoe_min.x and pos.x <= aoe_max.x and \
		   pos.y >= aoe_min.y and pos.y <= aoe_max.y:
			enemies_to_damage.append(enemy)
			print("DEBUG:   *** HIT! Enemy in AOE area")

	# Check all crates
	for crate in crate_container.get_children():
		var pos: Vector2 = crate.position
		print("DEBUG: Crate at ", pos)
		if pos.x >= aoe_min.x and pos.x <= aoe_max.x and \
		   pos.y >= aoe_min.y and pos.y <= aoe_max.y:
			crates_to_damage.append(crate)
			print("DEBUG:   *** HIT! Crate in AOE area")

	# Apply damage to all hit entities
	print("DEBUG: Damaging ", enemies_to_damage.size(), " enemies and ", crates_to_damage.size(), " crates")

	for enemy in enemies_to_damage:
		if enemy.has_method("take_damage"):
			var was_destroyed: bool = enemy.take_damage(1)
			if was_destroyed:
				score += 1
				print("DEBUG: Enemy destroyed, score now: ", score)

	for crate in crates_to_damage:
		if crate.has_method("take_damage"):
			var was_destroyed: bool = crate.take_damage(1)
			if was_destroyed:
				ammo += GameConfig.AMMO_PER_CRATE
				print("DEBUG: Crate destroyed, ammo now: ", ammo)


## Clears the marker and resets UI
func _clear_marker() -> void:
	if marker_node != null:
		marker_node.queue_free()
		marker_node = null

	marker_tile = Vector2i(-1, -1)
	mgrs_label.visible = false
	fire_button.disabled = true


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

	print("DEBUG SPAWN: Spawning enemy at tile ", tile, " -> world pos: ", world_pos)

	# Instantiate and configure enemy
	var enemy: Node2D = enemy_scene.instantiate()
	enemy.position = world_pos
	enemy_container.add_child(enemy)

	print("DEBUG SPAWN: Enemy actual position after add_child: ", enemy.position)

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
