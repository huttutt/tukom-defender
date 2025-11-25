extends Control

## DistanceWheel.gd
## Rolling wheel UI control for distance selection in 25m increments.
## Displays up/down arrows with current distance value.

# Distance settings
var current_distance: int = 0
var step: int = GameConfig.DISTANCE_STEP  # 25m
var min_distance: int = GameConfig.MIN_DISTANCE  # 0m
var max_distance: int = GameConfig.MAX_DISTANCE  # 2000m

# Node references
@onready var up_button: Button = $VBoxContainer/UpButton
@onready var distance_label: Label = $VBoxContainer/DistanceLabel
@onready var down_button: Button = $VBoxContainer/DownButton


func _ready() -> void:
	# Connect button signals
	up_button.pressed.connect(_on_up_pressed)
	down_button.pressed.connect(_on_down_pressed)

	# Initialize display
	_update_display()
	_update_button_states()


## Increments distance by step amount
func _on_up_pressed() -> void:
	if current_distance < max_distance:
		current_distance = min(current_distance + step, max_distance)
		_update_display()
		_update_button_states()
		distance_changed.emit(current_distance)


## Decrements distance by step amount
func _on_down_pressed() -> void:
	if current_distance > min_distance:
		current_distance = max(current_distance - step, min_distance)
		_update_display()
		_update_button_states()
		distance_changed.emit(current_distance)


## Handles scroll wheel input for quick adjustment
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton:
		# Check if mouse is over this control
		if not get_global_rect().has_point(event.position):
			return

		# Scroll up = increase distance
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_on_up_pressed()
			get_viewport().set_input_as_handled()

		# Scroll down = decrease distance
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_on_down_pressed()
			get_viewport().set_input_as_handled()


## Updates the distance label display
func _update_display() -> void:
	distance_label.text = "%dm" % current_distance


## Updates button enabled/disabled states based on current value
func _update_button_states() -> void:
	up_button.disabled = (current_distance >= max_distance)
	down_button.disabled = (current_distance <= min_distance)


## Resets distance to 0
func reset() -> void:
	current_distance = 0
	_update_display()
	_update_button_states()


## Sets distance to a specific value (clamped to valid range)
func set_distance(distance: int) -> void:
	current_distance = clamp(distance, min_distance, max_distance)
	_update_display()
	_update_button_states()


## Returns current distance value
func get_distance() -> int:
	return current_distance


# Signal emitted when distance changes
signal distance_changed(new_distance: int)
