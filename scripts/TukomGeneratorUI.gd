extends Control

## TukomGeneratorUI.gd
## Manages the Tukom (artillery fire command) generator UI panel.
## Displays fire command structure: Tulikomentoja | coords | piiru | distance | 3 kertaa | ampukaa!

# State enum
enum State {
	IDLE,      # No coordinates selected
	PARTIAL,   # Coordinates set, but bearing/distance incomplete
	READY      # All fields filled, ready to fire
}

# Current state
var state: int = State.IDLE

# Fire command data
var target_tile: Vector2i = Vector2i(-1, -1)  # Invalid tile when not set
var current_coords: String = ""
var current_piiru: int = 0
var current_distance: int = 0

# Node references (will be connected in _ready)
@onready var coord_label: Label = $Panel/HBoxContainer/CoordLabel
@onready var piiru_button: Button = $Panel/HBoxContainer/PiiruButton
@onready var distance_label: Label = $Panel/HBoxContainer/DistanceLabel
@onready var fire_button: Button = $Panel/HBoxContainer/FireButton
@onready var add_bearing_prompt: Label = $Panel/HBoxContainer/AddBearingPrompt

# Reference to Map node (set by Main.gd)
var map: Node2D = null

# Reference to BearingLine node (set by Main.gd)
var bearing_line: Node2D = null


func _ready() -> void:
	# Initialize UI state
	_reset_ui()

	# Connect piiru button
	piiru_button.pressed.connect(_on_piiru_button_pressed)

	# Connect bearing lock/unlock signals (will be emitted by BearingLine)
	bearing_locked.connect(_on_bearing_locked)
	bearing_unlocked.connect(_on_bearing_unlocked)


## Resets all fields to initial state
func _reset_ui() -> void:
	coord_label.text = ""
	piiru_button.text = ""
	piiru_button.visible = true
	add_bearing_prompt.visible = false
	distance_label.text = ""
	fire_button.disabled = true
	state = State.IDLE


## Sets target coordinates from a tile position
## Called when player taps on map
func set_target_coordinates(tile: Vector2i) -> void:
	if map == null:
		push_error("TukomGeneratorUI: Map reference not set")
		return

	target_tile = tile
	current_coords = map.tile_to_mgrs(tile)
	coord_label.text = current_coords

	# Show pulsating "ADD BEARING" prompt
	_show_add_bearing_prompt()

	# Move to PARTIAL state (waiting for bearing and distance)
	state = State.PARTIAL
	_update_fire_button_state()

	# Emit signal for Main to show target marker
	target_coordinates_set.emit(tile)


## Updates piiru display (called by BearingLine during drag)
func set_piiru(piiru: int) -> void:
	current_piiru = piiru
	var xx: int = piiru / 100
	var yy: int = piiru % 100
	piiru_button.text = "%02d-%02d" % [xx, yy]
	_check_ready_state()


## Called when piiru button is pressed
func _on_piiru_button_pressed() -> void:
	if bearing_line == null:
		push_error("TukomGeneratorUI: BearingLine reference not set")
		return

	# If bearing is locked, clicking piiru deselects bearing and returns to coord selection
	if bearing_line.is_active and bearing_line.is_bearing_locked():
		_deselect_bearing()
		return

	# Only activate if coordinates are set
	if target_tile.x < 0 or target_tile.y < 0:
		return

	# Activate bearing line for dragging
	bearing_line.activate()

	# Hide the prompt
	add_bearing_prompt.visible = false
	piiru_button.visible = true

	# Emit signal for Main to handle
	bearing_line_activated.emit()


## Updates distance display (will be called by DistanceWheel in Phase 4)
func set_distance(distance: int) -> void:
	current_distance = distance
	distance_label.text = "%dm" % distance
	_check_ready_state()


## Checks if all fields are filled and updates state
func _check_ready_state() -> void:
	if current_coords != "" and current_piiru > 0 and current_distance > 0:
		state = State.READY
		fire_button.disabled = false
	else:
		fire_button.disabled = true


## Updates FIRE button state based on current conditions
func _update_fire_button_state() -> void:
	# For Phase 1-2, FIRE button stays disabled until Phase 5
	# Phase 3-4 will enable it once all fields are set
	_check_ready_state()


## Resets UI after firing (clears interactive fields, keeps static labels)
func reset_after_fire() -> void:
	target_tile = Vector2i(-1, -1)
	current_coords = ""
	current_piiru = 0
	current_distance = 0

	coord_label.text = ""
	piiru_button.text = ""
	distance_label.text = ""

	state = State.IDLE
	fire_button.disabled = true

	# Deactivate bearing line
	if bearing_line != null:
		bearing_line.deactivate()

	# Emit signal for Main to clear target marker
	fire_command_reset.emit()


## Returns current target tile (for Main.gd to execute fire command)
func get_target_tile() -> Vector2i:
	return target_tile


## Returns whether all fields are set and ready to fire
func is_ready() -> bool:
	return state == State.READY


## Shows pulsating "ADD BEARING" prompt
func _show_add_bearing_prompt() -> void:
	add_bearing_prompt.visible = true
	piiru_button.visible = false

	# Create pulsating animation
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(add_bearing_prompt, "modulate:a", 0.3, 0.5)
	tween.tween_property(add_bearing_prompt, "modulate:a", 1.0, 0.5)


## Deselects bearing and returns to coordinate selection
func _deselect_bearing() -> void:
	# Clear bearing data
	current_piiru = 0
	piiru_button.text = ""

	# Deactivate bearing line
	if bearing_line != null:
		bearing_line.deactivate()

	# Show prompt again
	_show_add_bearing_prompt()

	# Update state
	_check_ready_state()

	# Emit signal for Main
	bearing_deselected.emit()


## Called when bearing is locked (mouseup)
func _on_bearing_locked() -> void:
	# Stop pulsating animation if any
	add_bearing_prompt.visible = false
	piiru_button.visible = true


## Called when bearing is unlocked (click line)
func _on_bearing_unlocked() -> void:
	# Visual feedback could be added here
	pass


## Returns whether bearing line is currently active
func is_bearing_active() -> bool:
	return bearing_line != null and bearing_line.is_active


# Signals
signal target_coordinates_set(tile: Vector2i)
signal fire_command_reset()
signal fire_button_pressed()
signal bearing_line_activated()
signal bearing_locked()
signal bearing_unlocked()
signal bearing_deselected()
