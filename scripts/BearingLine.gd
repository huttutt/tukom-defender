extends Node2D

## BearingLine.gd
## Manages the draggable bearing line from observer icon to screen edge.
## Calculates Finnish piiru (6000 mils system) and displays distance notches.

# Line visual properties
const LINE_WIDTH: float = 3.0
const LINE_COLOR: Color = Color(1.0, 0.71, 0.0)  # Orange-yellow #FFB400
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const SHADOW_OFFSET: Vector2 = Vector2(2, 2)

# Default bearing: 15-00 piiru = pointing up (north)
const DEFAULT_ANGLE: float = -PI / 2.0  # -90 degrees = pointing up

# Distance notch settings (1 tile = 100m)
const TILE_SIZE_METERS: float = 100.0
const NOTCH_POSITIONS: Array = [250, 500, 750, 1000, 1250, 1500, 2000]
const NOTCH_LENGTH: float = 8.0

# State
var is_active: bool = false
var is_locked: bool = false  # True when bearing is frozen in place
var origin: Vector2 = Vector2.ZERO  # Observer icon position
var angle: float = DEFAULT_ANGLE
var length: float = 2000.0

# Line rendering nodes
var main_line: Line2D = null
var shadow_line: Line2D = null
var notch_container: Node2D = null
var label_container: Node2D = null

# Reference to TukomGeneratorUI (set by Main.gd)
var tukom_ui: Control = null


func _ready() -> void:
	# Create shadow line (drawn first, appears behind)
	shadow_line = Line2D.new()
	shadow_line.width = LINE_WIDTH
	shadow_line.default_color = SHADOW_COLOR
	shadow_line.z_index = -1
	add_child(shadow_line)

	# Create main line
	main_line = Line2D.new()
	main_line.width = LINE_WIDTH
	main_line.default_color = LINE_COLOR
	main_line.z_index = 0
	add_child(main_line)

	# Create containers for notches and labels
	notch_container = Node2D.new()
	notch_container.z_index = 1
	add_child(notch_container)

	label_container = Node2D.new()
	label_container.z_index = 2
	add_child(label_container)

	# Initially hidden
	visible = false


func _input(event: InputEvent) -> void:
	if not is_active:
		return

	# Handle mouse button release to lock bearing
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# Mouse/touch released - lock the bearing
			if not is_locked:
				lock_bearing()
			return

		# Mouse/touch pressed - check if clicking on the line to unlock
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_locked:
				var mouse_pos: Vector2 = get_global_mouse_position()
				if _is_click_near_line(mouse_pos):
					unlock_bearing()
					# Update angle immediately for new drag
					_update_angle_from_mouse(mouse_pos)
					_update_line_geometry()
					_update_piiru_display()
			return

	# Handle mouse motion for dragging (only when not locked)
	if event is InputEventMouseMotion and not is_locked:
		var mouse_pos: Vector2 = get_global_mouse_position()
		_update_angle_from_mouse(mouse_pos)
		_update_line_geometry()
		_update_piiru_display()


## Activates the bearing line for dragging
func activate() -> void:
	is_active = true
	is_locked = false
	visible = true

	# Set default angle (15-00 piiru = north)
	angle = DEFAULT_ANGLE

	# Update visuals
	_update_line_geometry()
	_update_piiru_display()


## Deactivates the bearing line
func deactivate() -> void:
	is_active = false
	is_locked = false
	visible = false


## Locks bearing in place (called on mouseup)
func lock_bearing() -> void:
	is_locked = true
	# Visual feedback could be added here (change line color, etc.)
	if tukom_ui:
		tukom_ui.bearing_locked.emit()


## Unlocks bearing for adjustment (called on click line)
func unlock_bearing() -> void:
	is_locked = false
	# Visual feedback could be added here
	if tukom_ui:
		tukom_ui.bearing_unlocked.emit()


## Sets the origin point (observer icon position)
func set_origin(pos: Vector2) -> void:
	origin = pos
	position = Vector2.ZERO  # We draw from global coords
	if visible:
		_update_line_geometry()


## Updates angle based on mouse position
func _update_angle_from_mouse(mouse_pos: Vector2) -> void:
	var direction: Vector2 = (mouse_pos - origin).normalized()
	var new_angle: float = direction.angle()

	# Clamp to ±90 degrees from default (15-00)
	var relative_angle: float = new_angle - DEFAULT_ANGLE
	relative_angle = clamp(relative_angle, -PI / 2.0, PI / 2.0)
	angle = DEFAULT_ANGLE + relative_angle


## Updates the line geometry to extend from origin to screen edge
func _update_line_geometry() -> void:
	# Calculate endpoint extending to screen edge
	var direction: Vector2 = Vector2.RIGHT.rotated(angle)
	var end_point: Vector2 = origin + direction * length

	# Update main line points
	main_line.clear_points()
	main_line.add_point(origin)
	main_line.add_point(end_point)

	# Update shadow line points (offset)
	shadow_line.clear_points()
	shadow_line.add_point(origin + SHADOW_OFFSET)
	shadow_line.add_point(end_point + SHADOW_OFFSET)

	# Update distance notches
	_draw_distance_notches()


## Draws distance notches and labels along the line
func _draw_distance_notches() -> void:
	# Clear existing notches and labels
	for child in notch_container.get_children():
		child.queue_free()
	for child in label_container.get_children():
		child.queue_free()

	var direction: Vector2 = Vector2.RIGHT.rotated(angle)
	var perpendicular: Vector2 = direction.rotated(PI / 2.0)

	# Tile size in pixels (from GameConfig)
	var tile_size_pixels: float = 64.0  # GameConfig.TILE_SIZE

	for dist_meters in NOTCH_POSITIONS:
		# Convert distance to pixels
		var dist_pixels: float = (dist_meters / TILE_SIZE_METERS) * tile_size_pixels

		if dist_pixels > length:
			break

		# Calculate notch position
		var notch_pos: Vector2 = origin + direction * dist_pixels

		# Draw notch (perpendicular line)
		var notch_line: Line2D = Line2D.new()
		notch_line.width = 2.0
		notch_line.default_color = LINE_COLOR
		var notch_start: Vector2 = notch_pos - perpendicular * (NOTCH_LENGTH / 2.0)
		var notch_end: Vector2 = notch_pos + perpendicular * (NOTCH_LENGTH / 2.0)
		notch_line.add_point(notch_start)
		notch_line.add_point(notch_end)
		notch_container.add_child(notch_line)

		# Draw distance label
		var label: Label = Label.new()
		label.text = "%dm" % dist_meters
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", LINE_COLOR)
		label.position = notch_pos + perpendicular * 12.0  # Offset from line
		label.rotation = angle  # Align with line
		label_container.add_child(label)


## Updates piiru display in TukomGeneratorUI
func _update_piiru_display() -> void:
	if tukom_ui == null:
		return

	var piiru: int = _angle_to_piiru(angle)
	tukom_ui.set_piiru(piiru)


## Converts angle (radians) to Finnish piiru (6000 mils system)
func _angle_to_piiru(angle_rad: float) -> int:
	# Convert radians to degrees
	var angle_deg: float = rad_to_deg(angle_rad)

	# Normalize to 0-360 range
	angle_deg = fmod(angle_deg + 360.0, 360.0)

	# Convert to piiru (6000 mils = 360 degrees)
	var piiru: int = int(round(angle_deg * (6000.0 / 360.0)))

	# Ensure range is 0-5999
	piiru = piiru % 6000

	return piiru


## Returns current angle in radians
func get_angle() -> float:
	return angle


## Returns current piiru value
func get_piiru() -> int:
	return _angle_to_piiru(angle)


## Checks if bearing line passes through a target position (for perfect alignment)
func check_alignment_with_target(target_world_pos: Vector2) -> bool:
	if not is_active:
		return false

	var line_end: Vector2 = origin + Vector2.RIGHT.rotated(angle) * length
	var closest: Vector2 = _closest_point_on_line(origin, line_end, target_world_pos)
	var distance_to_line: float = closest.distance_to(target_world_pos)

	# Threshold: within 10 pixels of tile center
	return distance_to_line < 10.0


## Calculates closest point on line segment to a given point
func _closest_point_on_line(line_start: Vector2, line_end: Vector2, point: Vector2) -> Vector2:
	var line_vec: Vector2 = line_end - line_start
	var point_vec: Vector2 = point - line_start
	var line_length_sq: float = line_vec.length_squared()

	if line_length_sq == 0.0:
		return line_start

	var t: float = clamp(point_vec.dot(line_vec) / line_length_sq, 0.0, 1.0)
	return line_start + line_vec * t


## Checks if a click position is near the bearing line (for unlock detection)
func _is_click_near_line(click_pos: Vector2) -> bool:
	var line_end: Vector2 = origin + Vector2.RIGHT.rotated(angle) * length
	var closest: Vector2 = _closest_point_on_line(origin, line_end, click_pos)
	var distance: float = closest.distance_to(click_pos)

	# Click threshold: within 20 pixels of line
	return distance < 20.0


## Returns whether bearing is currently locked
func is_bearing_locked() -> bool:
	return is_locked
