# Milestone 3.1: Tukom Generator Integration - Phased Implementation Plan

## Overview
Replace the simple tap-to-fire mechanic with a structured Finnish artillery fire command (tulikomento) workflow. This implements indirect fire doctrine where the player acts as an observer calling coordinates, bearing, and distance to an off-map artillery unit.

**Reference**: [debug/tukom.png](../debug/tukom.png) shows the doctrinal fire command structure.

## Core Concepts

### Observer Position
- Fixed blue icon at bottom-center of playable map area
- Positioned ABOVE the Tukom Generator UI section
- Must remain fully visible (not overlapping UI)
- Acts as anchor point for all bearing calculations

### Tukom Generator UI
- Bottom screen region, permanently visible
- Displays: `Tulikomentoja | [coords] | [piiru] | [distance] | 3 kertaa | ampukaa!`
- Structure mirrors Finnish doctrine (see reference image)
- Fields are interactive (coords/bearing/distance) or pre-filled/locked (tulimuoto/suoritusosa)

### Fire Command Workflow
1. Tap map → Set coordinates only (no immediate fire)
2. Tap direction field → Activate draggable bearing line
3. Drag bearing line → Updates piiru display in real-time
4. Use distance wheel → Set distance in 25m increments
5. FIRE button → Execute 3×3 AoE attack when all fields valid

---

## Phase 1: UI Foundation & Observer Icon

**Goal**: Establish the Tukom Generator UI layout and observer position.

### Tasks

#### 1.1 Map Area Adjustment
**File**: `scripts/Map.gd`, `scenes/Game.tscn`

- Reserve bottom 120-150px of screen for Tukom Generator UI
- Adjust map rendering area to end above this reserved space
- Ensure grid tiles don't overlap with UI region
- Update bounds checking logic

#### 1.2 Observer Icon Implementation
**File**: `scenes/ObserverIcon.tscn`, `scripts/ObserverIcon.gd`

- Create observer icon scene (Sprite node)
- Use blue circle/marker placeholder (20×20px minimum)
- Position at bottom-center of playable map area
- Must be above Tukom UI, fully visible
- Add to Game scene hierarchy

Positioning logic:
```gdscript
# Pseudo-code
var map_bottom = map_area.get_bottom_edge()
var tukom_ui_height = 120
var observer_y = map_bottom - tukom_ui_height - 20
var observer_x = viewport_width / 2
```

#### 1.3 Tukom Generator UI Container
**File**: `scenes/TukomGeneratorUI.tscn`, `scripts/TukomGeneratorUI.gd`

Create Control node hierarchy:
- Root: Panel (120-150px height, anchored to bottom)
- HBoxContainer for field layout
- Labels for static elements: "Tulikomentoja", "3 kertaa", "ampukaa!"
- Interactive fields: coordinate display, piiru display, distance display
- FIRE button (initially disabled)

Visual structure:
```
[Tulikomentoja] | [coord_label] | [piiru_label] | [distance_label] | [3 kertaa] | [ampukaa!] | [FIRE]
```

Styling:
- Use monospace font (mimics military display)
- High contrast colors (yellow/orange text on dark background)
- Separator pipes "|" between fields

#### 1.4 State Management
**File**: `scripts/TukomGeneratorUI.gd`

Define three UI states:
- **Idle**: No coordinate selected, FIRE disabled, no bearing line
- **Partial**: Coordinates set, bearing/distance missing, FIRE disabled
- **Ready**: All fields filled, FIRE enabled

Properties:
```gdscript
var current_coords: String = ""
var current_piiru: int = 0
var current_distance: int = 0
var target_tile: Vector2 = Vector2.ZERO
var state: int = STATE_IDLE  # Enum: IDLE, PARTIAL, READY
```

---

## Phase 2: Coordinate Selection & Display

**Goal**: Allow map taps to set MGRS coordinates without firing.

### Tasks

#### 2.1 Input Handling for Map Taps
**File**: `scripts/Game.gd`

Modify `_input()` or `_unhandled_input()`:
- Detect mouse/touch press events
- Convert screen coords to map tile coords
- Validate click is within map bounds (not in Tukom UI area)
- Signal TukomGeneratorUI with tile coordinates

```gdscript
func _unhandled_input(event):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == BUTTON_LEFT:
            var click_pos = event.position
            if is_click_in_map_area(click_pos):
                var tile = map.screen_to_tile(click_pos)
                if map.is_valid_tile(tile):
                    tukom_ui.set_target_coordinates(tile)
```

#### 2.2 MGRS Coordinate Calculation
**File**: `scripts/Map.gd`

Implement faux MGRS system:
- Top-left tile: `37U DB 13224 79170`
- Moving right: easting +1
- Moving down: northing +1
- Four-digit zero-padded format

```gdscript
func tile_to_mgrs(tile: Vector2) -> String:
    var base_easting = 13224
    var base_northing = 79170
    var easting = base_easting + int(tile.x)
    var northing = base_northing + int(tile.y)
    return "37U DB %04d %04d" % [easting, northing]
```

#### 2.3 Coordinate Display Update
**File**: `scripts/TukomGeneratorUI.gd`

```gdscript
func set_target_coordinates(tile: Vector2):
    target_tile = tile
    current_coords = map.tile_to_mgrs(tile)
    coord_label.text = current_coords
    state = STATE_PARTIAL
    show_target_marker(tile)
    update_fire_button_state()
```

#### 2.4 Target Marker Visual
**File**: `scenes/TargetMarker.tscn`, `scripts/TargetMarker.gd`

- Create marker sprite (crosshair or circle)
- Position at selected tile center
- Visible only when coordinates are set
- Cleared on FIRE or reset

---

## Phase 3: Bearing Line & Piiru System

**Goal**: Implement draggable directional arc with piiru calculation.

### Tasks

#### 3.1 Bearing Line Node
**File**: `scenes/BearingLine.tscn`, `scripts/BearingLine.gd`

Create Line2D-based bearing indicator:
- Extends from observer icon to screen edge
- 3px width, orange-yellow color (#FFB400)
- Drop shadow effect (duplicate Line2D offset 2px, alpha 0.5)
- Initially hidden, activated by tapping direction field

Properties:
```gdscript
var origin: Vector2  # Observer icon position
var angle: float = 0.0  # Rotation in radians
var length: float = 1000.0  # Extends to screen edge
var is_active: bool = false
```

#### 3.2 Bearing Line Rotation Logic
**File**: `scripts/BearingLine.gd`

```gdscript
func _input(event):
    if not is_active:
        return

    if event is InputEventMouseMotion:
        var mouse_pos = event.position
        var direction = (mouse_pos - origin).normalized()
        angle = direction.angle()

        # Clamp to ±90 degrees from default (15-00)
        var default_angle = -PI/2  # Pointing up
        var relative_angle = angle - default_angle
        relative_angle = clamp(relative_angle, -PI/2, PI/2)
        angle = default_angle + relative_angle

        update_line_geometry()
        update_piiru_display()
```

#### 3.3 Piiru Calculation
**File**: `scripts/BearingLine.gd`

Convert angle to Finnish piiru (6000 mils in full circle):
```gdscript
func angle_to_piiru(angle_rad: float) -> int:
    var angle_deg = rad2deg(angle_rad)
    # Normalize to 0-360
    angle_deg = fmod(angle_deg + 360.0, 360.0)
    # Convert to piiru
    var piiru = int(round(angle_deg * (6000.0 / 360.0)))
    return piiru

func piiru_to_display(piiru: int) -> String:
    var xx = piiru / 100
    var yy = piiru % 100
    return "%02d-%02d" % [xx, yy]
```

Default orientation (15-00) = pointing toward top-center of screen.

#### 3.4 Distance Notches
**File**: `scripts/BearingLine.gd`

Add tick marks and labels along the line:
- Each tile = 100m
- Draw notches at: 250m, 500m, 750m, 1000m, 1250m, etc.
- Use small perpendicular lines as notches (5px length)
- Place distance labels (e.g., "500m") adjacent to notches

```gdscript
func draw_distance_notches():
    var tile_size = 100  # meters per tile
    var notch_positions = [250, 500, 750, 1000, 1250, 1500]

    for dist in notch_positions:
        var dist_pixels = (dist / 100.0) * tile_size_pixels
        if dist_pixels > length:
            break

        var notch_pos = origin + Vector2.RIGHT.rotated(angle) * dist_pixels
        # Draw perpendicular notch
        draw_notch_at(notch_pos, angle)
        # Draw label
        draw_label_at(notch_pos, "%dm" % dist)
```

#### 3.5 Direction Field Interaction
**File**: `scripts/TukomGeneratorUI.gd`

```gdscript
func _on_piiru_field_pressed():
    bearing_line.activate()
    bearing_line.origin = observer_icon.global_position
    state = STATE_PARTIAL
    update_fire_button_state()
```

---

## Phase 4: Distance Wheel & Manual Entry

**Goal**: Implement rolling wheel control for distance selection.

### Tasks

#### 4.1 Distance Wheel Control
**File**: `scenes/DistanceWheel.tscn`, `scripts/DistanceWheel.gd`

Create wheel-style UI control:
- VBoxContainer with up/down arrows
- Center label showing current distance
- Increments: 25m steps
- Range: 0m to 2000m (or max map distance)
- Scroll wheel support

```gdscript
var current_distance: int = 0
var step: int = 25

func increment_distance():
    current_distance = min(current_distance + step, max_distance)
    update_display()

func decrement_distance():
    current_distance = max(current_distance - step, 0)
    update_display()
```

Visual:
```
  ▲
[450m]
  ▼
```

#### 4.2 Distance Field Integration
**File**: `scripts/TukomGeneratorUI.gd`

Replace distance label with DistanceWheel instance:
- Positioned in distance field slot
- Updates Tukom state on change
- Signals Game when distance is set

```gdscript
func _on_distance_changed(new_distance: int):
    current_distance = new_distance
    distance_label.text = "%dm" % current_distance
    check_ready_state()
```

#### 4.3 Distance Validation
**File**: `scripts/TukomGeneratorUI.gd`

Validate distance is reasonable:
- Must be > 0m
- Should align roughly with bearing line length
- Visual indicator if distance is set (field highlighted)

---

## Phase 5: Perfect Alignment & FIRE Execution

**Goal**: Implement alignment detection and 3×3 AoE firing.

### Tasks

#### 5.1 Perfect Alignment Detection
**File**: `scripts/BearingLine.gd`, `scripts/TukomGeneratorUI.gd`

Check if bearing line passes through target tile center:
```gdscript
func check_perfect_alignment() -> bool:
    if target_tile == Vector2.ZERO:
        return false

    var target_world_pos = map.tile_to_world(target_tile)
    var line_end = origin + Vector2.RIGHT.rotated(angle) * 2000

    # Calculate closest point on line to target
    var closest_point = closest_point_on_line(origin, line_end, target_world_pos)
    var distance_to_line = closest_point.distance_to(target_world_pos)

    # Threshold: within 10 pixels of tile center
    return distance_to_line < 10.0
```

Display "Perfect Alignment" indicator when true (overlay near bearing line).

#### 5.2 FIRE Button Logic
**File**: `scripts/TukomGeneratorUI.gd`

Enable FIRE button when:
- Coordinates set (target_tile valid)
- Bearing set (piiru calculated)
- Distance set (distance > 0)
- Static fields present (always true)

```gdscript
func check_ready_state():
    if current_coords != "" and current_piiru > 0 and current_distance > 0:
        state = STATE_READY
        fire_button.disabled = false
    else:
        fire_button.disabled = true
```

#### 5.3 3×3 AoE Execution
**File**: `scripts/Game.gd`

```gdscript
func execute_fire_command():
    var center_tile = tukom_ui.target_tile
    var is_perfect = tukom_ui.is_perfect_alignment()
    var points_per_hit = 10 if is_perfect else 1

    # Generate 3×3 grid around center
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            var tile = center_tile + Vector2(dx, dy)
            if not map.is_valid_tile(tile):
                continue

            apply_damage_to_tile(tile, 1, points_per_hit)

    # Reset UI state
    tukom_ui.reset_after_fire()

    # Decrement ammo (if applicable)
    current_ammo -= 1
    update_ammo_display()
```

#### 5.4 Damage Application
**File**: `scripts/Game.gd`

```gdscript
func apply_damage_to_tile(tile: Vector2, damage: int, points: int):
    # Check for enemies at tile
    var enemies = get_enemies_at_tile(tile)
    for enemy in enemies:
        enemy.take_damage(damage)
        if enemy.is_dead():
            score += points
            update_score_display()

    # Check for crates at tile
    var crate = get_crate_at_tile(tile)
    if crate:
        crate.collect()  # Grants ammo, no points
```

#### 5.5 Post-Fire Reset
**File**: `scripts/TukomGeneratorUI.gd`

```gdscript
func reset_after_fire():
    # Clear interactive fields
    target_tile = Vector2.ZERO
    current_coords = ""
    current_piiru = 0
    current_distance = 0

    # Update displays
    coord_label.text = ""
    piiru_label.text = ""
    distance_wheel.reset()

    # Hide visuals
    bearing_line.deactivate()
    target_marker.hide()
    perfect_alignment_indicator.hide()

    # Reset state
    state = STATE_IDLE
    fire_button.disabled = true

    # Static fields remain: "3 kertaa", "ampukaa!"
```

---

## Phase 6: Visual Polish & Testing

**Goal**: Add visual effects and validate all mechanics.

### Tasks

#### 6.1 Visual Effects
- Shell impact effects at each 3×3 tile (particles/flashes)
- Observer icon glow effect when bearing line is active
- Bearing line pulse animation during drag
- Distance notch highlighting when near target

#### 6.2 Audio Integration
- Sound when activating bearing line
- Sound when setting distance
- Fire command sound (artillery call)
- Impact sounds for each hit tile

#### 6.3 Edge Case Handling
- Bearing line rotation clamping (±90° enforced)
- Target outside map bounds (reject)
- Distance wheel at map edge (cap at max)
- Multiple rapid FIRE presses (debounce)
- Game over during fire command (cancel state)

#### 6.4 Testing Checklist
- [ ] Observer icon positioned correctly above UI
- [ ] Map area adjusted, no overlap with Tukom UI
- [ ] Tap map sets coordinates only (no fire)
- [ ] Coordinates display in MGRS format
- [ ] Direction field activates bearing line
- [ ] Bearing line originates from observer icon
- [ ] Bearing line extends to screen edge
- [ ] Dragging rotates bearing line (clamped ±90°)
- [ ] Piiru displays as XX-YY format
- [ ] Default bearing is 15-00 (top-center)
- [ ] Distance notches visible with labels
- [ ] Distance wheel increments in 25m steps
- [ ] Perfect alignment detected when line crosses target center
- [ ] FIRE disabled until all fields set
- [ ] FIRE executes 3×3 AoE damage
- [ ] Perfect alignment grants 10× points
- [ ] Non-perfect hits grant 1 point each
- [ ] Crates grant ammo, no points
- [ ] UI resets after FIRE (except static fields)
- [ ] Static fields "3 kertaa" and "ampukaa!" always visible

---

## Success Criteria

- Observer icon visible and positioned above Tukom UI
- Tukom Generator UI matches doctrinal structure (see [debug/tukom.png](../debug/tukom.png))
- Map taps set coordinates without firing
- Bearing line draggable, originates from observer, extends to screen edge
- Piiru calculation correct (6000 mils system)
- Distance wheel functional (25m steps)
- Perfect alignment detection accurate
- 3×3 AoE damage application works
- Point scoring: 10 for perfect, 1 for normal
- All Milestone 1 & 2 features remain functional

---

## Implementation Order

1. **Phase 1**: UI Foundation & Observer Icon (2-3 hours)
2. **Phase 2**: Coordinate Selection & Display (1-2 hours)
3. **Phase 3**: Bearing Line & Piiru System (3-4 hours)
4. **Phase 4**: Distance Wheel & Manual Entry (1-2 hours)
5. **Phase 5**: Perfect Alignment & FIRE Execution (2-3 hours)
6. **Phase 6**: Visual Polish & Testing (2-3 hours)

**Total Estimated Effort**: 11-17 hours

---

## Dependencies

- Existing Map system (tile/world coordinate conversion)
- Existing Enemy system (damage handling)
- Existing Crate system (ammo collection)
- Existing Score/Ammo UI (updates)
- Existing Game state management

---

## Technical Notes

- **Collision Layers**: Not applicable (no projectile travel, instant AoE)
- **Performance**: Bearing line is single Line2D, minimal overhead
- **Coordinate System**: MGRS is faux, purely cosmetic
- **Piiru System**: 6000 mils = 360°, integer math only
- **Distance Scale**: 1 tile = 100m (for notch calculations)
- **UI Anchoring**: Tukom Generator anchored to bottom, observer icon relative to map bottom

---

## Future Enhancements (Post-Milestone 3)

- Variable tulimuoto (change "3 kertaa" to "5 kertaa", "kerta", etc.)
- Different suoritusosa commands ("huti", "seiso", etc.)
- Multiple observer positions
- Elevation/height adjustments
- Wind effects on bearing
- Time-of-flight delay (shells travel to target)

---

## GitFlow Branch Strategy

Following [CLAUDE.md](../CLAUDE.md):

- Feature branch: `feature/milestone-3-tukom-generator`
- Base: `develop`
- Each phase commits separately with descriptive messages
- PR title: `[Feature] Implement Tukom Generator (Milestone 3)`
- Merge to `develop` when all phases complete and tested
