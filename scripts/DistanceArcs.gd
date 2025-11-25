extends Node2D

## DistanceArcs.gd
## Draws concentric arc circles from observer icon at 250m intervals.
## Provides visual reference for distance selection.

# Arc settings
const ARC_INTERVAL_METERS: int = 250  # Distance between arcs
const METERS_PER_TILE: float = 10.0  # 1 tile = 10 meters
const ARC_COLOR: Color = Color(0, 0, 0, 1)  # Black
const ARC_WIDTH: float = 2.0  # Make more visible
const LABEL_COLOR: Color = Color(0, 0, 0, 1)  # Black
const MAX_DISTANCE: int = 2000  # Maximum arc distance

# State
var origin: Vector2 = Vector2.ZERO  # Observer icon position
var is_active: bool = false

# Drawing nodes
var arc_lines: Array = []  # Array of Line2D nodes
var arc_labels: Array = []  # Array of Label nodes


func _ready() -> void:
	# Initially hidden
	visible = false


## Activates distance arcs display
func activate(observer_position: Vector2) -> void:
	origin = observer_position
	is_active = true
	visible = true
	print("DistanceArcs: Activating at position ", origin)
	_draw_arcs()
	print("DistanceArcs: Drew ", arc_lines.size(), " arc lines")


## Deactivates distance arcs display
func deactivate() -> void:
	is_active = false
	visible = false
	_clear_arcs()


## Draws all distance arcs from observer position
func _draw_arcs() -> void:
	_clear_arcs()

	# Get viewport dimensions for arc clipping
	var viewport_size: Vector2 = get_viewport_rect().size

	# Calculate how many arcs we need
	var num_arcs: int = MAX_DISTANCE / ARC_INTERVAL_METERS

	for i in range(1, num_arcs + 1):
		var distance_meters: int = i * ARC_INTERVAL_METERS
		var radius_pixels: float = (distance_meters / METERS_PER_TILE) * GameConfig.TILE_SIZE

		# Draw arc (portion of circle)
		_draw_arc_segment(radius_pixels, distance_meters, viewport_size)


## Draws a single arc segment (circular arc from left to right edge of screen)
func _draw_arc_segment(radius: float, distance_meters: int, viewport_size: Vector2) -> void:
	# Create Line2D for this arc
	var arc_line: Line2D = Line2D.new()
	arc_line.width = ARC_WIDTH
	arc_line.default_color = ARC_COLOR
	arc_line.z_index = 10  # Draw above map and markers

	# Calculate arc points
	# We want the arc to span from left edge to right edge of screen
	var points: PackedVector2Array = _calculate_arc_points(radius, viewport_size)

	if points.size() > 0:
		for point in points:
			arc_line.add_point(point)

		add_child(arc_line)
		arc_lines.append(arc_line)

		# Add distance label at center-top of arc
		_add_arc_label(radius, distance_meters, viewport_size)
	else:
		print("DistanceArcs: No points generated for radius ", radius)


## Calculates points for an arc spanning screen width
func _calculate_arc_points(radius: float, viewport_size: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()

	# Calculate angle range based on screen width
	# We want the arc to go from left edge to right edge
	var screen_half_width: float = viewport_size.x / 2.0
	var center_x: float = origin.x

	# Calculate start and end angles
	# Left edge
	var dx_left: float = -center_x
	var dy_left: float = sqrt(max(0, radius * radius - dx_left * dx_left))
	var angle_start: float = atan2(-dy_left, dx_left)

	# Right edge
	var dx_right: float = viewport_size.x - center_x
	var dy_right: float = sqrt(max(0, radius * radius - dx_right * dx_right))
	var angle_end: float = atan2(-dy_right, dx_right)

	# Generate arc points
	var num_segments: int = 64  # Smoothness of arc
	var angle_step: float = (angle_end - angle_start) / float(num_segments)

	for i in range(num_segments + 1):
		var angle: float = angle_start + i * angle_step
		var x: float = origin.x + radius * cos(angle)
		var y: float = origin.y + radius * sin(angle)

		# Only add points that are on screen
		if y >= 0 and y <= viewport_size.y:
			points.append(Vector2(x, y))

	return points


## Adds distance label above arc at screen center
func _add_arc_label(radius: float, distance_meters: int, viewport_size: Vector2) -> void:
	# Calculate label position (center-top of arc)
	var center_x: float = viewport_size.x / 2.0
	var label_y: float = origin.y - radius - 15.0  # 15px above arc

	# Only show label if it's on screen
	if label_y < 0 or label_y > viewport_size.y:
		return

	var label: Label = Label.new()
	label.text = "%dm" % distance_meters
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", LABEL_COLOR)
	label.position = Vector2(center_x - 20, label_y)  # Center approximately
	label.z_index = 11  # Above arc lines

	add_child(label)
	arc_labels.append(label)


## Clears all arc lines and labels
func _clear_arcs() -> void:
	for arc in arc_lines:
		arc.queue_free()
	arc_lines.clear()

	for label in arc_labels:
		label.queue_free()
	arc_labels.clear()
