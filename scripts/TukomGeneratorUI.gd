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
@onready var piiru_label: Label = $Panel/HBoxContainer/PiiruLabel
@onready var distance_label: Label = $Panel/HBoxContainer/DistanceLabel
@onready var fire_button: Button = $Panel/HBoxContainer/FireButton

# Reference to Map node (set by Main.gd)
var map: Node2D = null


func _ready() -> void:
	# Initialize UI state
	_reset_ui()


## Resets all fields to initial state
func _reset_ui() -> void:
	coord_label.text = ""
	piiru_label.text = ""
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

	# Move to PARTIAL state (waiting for bearing and distance)
	state = State.PARTIAL
	_update_fire_button_state()

	# Emit signal for Main to show target marker
	target_coordinates_set.emit(tile)


## Updates piiru display (will be called by BearingLine in Phase 3)
func set_piiru(piiru: int) -> void:
	current_piiru = piiru
	var xx: int = piiru / 100
	var yy: int = piiru % 100
	piiru_label.text = "%02d-%02d" % [xx, yy]
	_check_ready_state()


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
	piiru_label.text = ""
	distance_label.text = ""

	state = State.IDLE
	fire_button.disabled = true

	# Emit signal for Main to clear target marker
	fire_command_reset.emit()


## Returns current target tile (for Main.gd to execute fire command)
func get_target_tile() -> Vector2i:
	return target_tile


## Returns whether all fields are set and ready to fire
func is_ready() -> bool:
	return state == State.READY


# Signals
signal target_coordinates_set(tile: Vector2i)
signal fire_command_reset()
signal fire_button_pressed()
