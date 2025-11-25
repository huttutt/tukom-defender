extends Node2D

## Main.gd
## Main game controller managing enemies, crates, shells, UI, and game state.

# Game state
var ammo: int = GameConfig.INITIAL_AMMO
var score: int = 0
var is_game_over: bool = false

# Scene references
@export var enemy_scene: PackedScene
@export var ammo_crate_scene: PackedScene
@export var shell_scene: PackedScene

# Node references
@onready var map: Node2D = $Map
@onready var enemy_container: Node2D = $EnemyContainer
@onready var crate_container: Node2D = $CrateContainer
@onready var ammo_label: Label = $UI/AmmoLabel
@onready var score_label: Label = $UI/ScoreLabel
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
	if shell_scene == null:
		shell_scene = load("res://scenes/Shell.tscn")

	# Initialize UI
	game_over_panel.visible = false
	_update_ui()

	# Connect timer signals
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)
	crate_spawn_timer.timeout.connect(_on_crate_spawn_timer_timeout)


func _input(event: InputEvent) -> void:
	# Ignore input if game is over
	if is_game_over:
		return

	# Handle left mouse button clicks
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_shot(event.position)


## Handles player firing a shell at screen position
func _handle_shot(screen_pos: Vector2) -> void:
	# Check if player has ammo
	if ammo <= 0:
		return

	# Convert screen position to tile coordinates
	var tile: Vector2i = map.world_to_grid(screen_pos)

	# Check if tile is inside map bounds
	if not map.is_inside_map(tile):
		return

	# Consume ammo
	ammo -= 1
	_update_ui()

	# Instantiate and configure shell
	var shell: Node2D = shell_scene.instantiate()
	shell.target_tile = tile
	shell.main_ref = self
	shell.position = map.grid_to_world(tile)
	add_child(shell)


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


## Resolves what entities are hit when a shell lands on a tile
func resolve_shell_hit(tile: Vector2i) -> void:
	var enemies_to_destroy: Array = []
	var crates_to_destroy: Array = []

	# Check all enemies
	for enemy in enemy_container.get_children():
		var enemy_tile: Vector2i = map.world_to_grid(enemy.position)
		if enemy_tile == tile:
			enemies_to_destroy.append(enemy)

	# Check all crates
	for crate in crate_container.get_children():
		var crate_tile: Vector2i = map.world_to_grid(crate.position)
		if crate_tile == tile:
			crates_to_destroy.append(crate)

	# Destroy enemies and update score
	for enemy in enemies_to_destroy:
		score += 1
		enemy.queue_free()

	# Destroy crates and add ammo
	for crate in crates_to_destroy:
		ammo += GameConfig.AMMO_PER_CRATE
		crate.queue_free()

	# Update UI after all changes
	if enemies_to_destroy.size() > 0 or crates_to_destroy.size() > 0:
		_update_ui()


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
