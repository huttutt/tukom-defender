# PRODUCT REQUIREMENTS DOCUMENT (PRD) — Milestone 3 — Tukom Generator Integration (Single-String Version)

This document defines the full specification for adding the Tukom (tulikomento) generator into TUKOM DEFENDER. Everything below is a single continuous Markdown file without breaks.

Milestone 3 introduces a structured fire-command workflow based on Finnish indirect fire doctrine. Tapping the map no longer fires; it only provides coordinates to the Tukom Generator. A directional piiru-bearing arc tool and a distance-reading system are added. The observer’s location becomes a fixed reference point. Tulimuoto (“3 kertaa”) and suoritusosa (“ampukaa!”) remain fixed for this milestone.

The user’s observer position is displayed as a permanent blue placeholder icon located at the bottom-center of the map area. It must always be visible and must not overlap with the Tukom Generator UI space. The bottom portion of the screen is reserved exclusively for the Tukom Generator. The map ends just above this reserved area so that the observer icon remains fully within the map.

The Tukom Generator must visually emulate the structure in the doctrinal screenshot (found at /mnt/data/Screenshot 2025-11-25 at 10.36.05.png). It contains the following elements in order: the fixed label “Tulikomentoja”; a coordinate field receiving MGRS-like coordinates from user taps; a direction field displaying Finnish piiru bearing; a distance field; a fixed tulimuoto field set to “3 kertaa”; and a fixed suoritusosa field set to “ampukaa!”. The final displayed format is: “Tulikomentoja | [MGRS coords] | [piiru XX-YY] | [distance m] | 3 kertaa | ampukaa!”

Tapping the map must only update the coordinate field. The marker appears at the tapped tile, but no firing occurs. Coordinates use the faux MGRS system established earlier: top-left tile is “37U DB 13224 79170”, moving right increases easting by +1, and moving down increases northing by +1. Values remain four-digit padded.

The direction field, when tapped, activates a draggable directional arc. This arc must originate exactly from the observer's fixed position at the bottom-center of the map. The arc extends outward until it hits the edge of the screen. Dragging left or right rotates the arc around the observer’s position. Rotation converts into piiru values using the rule: piiru = round(angle_degrees * (6000/360)). The displayed bearing uses the format XX-YY, where XX = piiru/100 and YY = piiru%100 zero-padded. The arc’s rotation is clamped to ±90 degrees relative to the default orientation.

The default orientation (15-00) corresponds to the bearing from the observer position to the top-center of the screen. This is the neutral forward direction. The arc may swing 90 degrees left or right from this starting vector, but no further.

During dragging, the piiru value must update in real time. The directional arc must display distance notches. Each tile represents 100 meters. Labels appear at 250m, 500m, 750m, 1000m, 1250m, and continue as needed. The user visually reads the distance from the arc and manually enters it into the distance field.

A perfect-alignment mechanic must exist: if the direction line, when adjusted, passes exactly through the tapped target tile’s center, a “Perfect alignment” indicator appears. Any enemies hit in this state score 10× the normal points.

The FIRE button now triggers execution of a full Tukom command rather than an instant shot. FIRE must remain disabled until: coordinates are set; direction is selected; distance is entered; tulimuoto (“3 kertaa”) and suoritusosa (“ampukaa!”) are in place (these are static); and the internal state is valid. After FIRE is pressed, effects apply to the 3×3 AoE around the target coordinates. Each enemy or crate in the AoE loses 1 HP. Enemies score +1 normally, but +10 each under perfect alignment. Crates still grant ammo only. After firing, reset the direction arc, hide the perfect-alignment indicator, disable FIRE, and leave static Tukom fields intact until the next user tap.

UI must respond through three main states: Idle (no coordinate selected, no arc visible, FIRE disabled); Tukom-Partial (coordinate selected, arc may or may not be active, FIRE disabled); Tukom-Ready (all fields filled, FIRE enabled). After firing, revert to Idle except for continuous display of static Tukom fields.

Technical notes: The direction arc can be implemented using Line2D or a custom-drawn vector. Distance notches may be Line2D children or dynamically generated tick marks. All drawing must remain synchronized to the observer’s fixed anchor point. Piiru calculations must remain stable across different framerates and aspect ratios. UI elements must not overlap or obscure the observer icon, target marker, or map area.

Performance: The milestone adds only UI rendering and lightweight geometry. There are no heavy computations. Hit resolution still uses tile-grid logic from Milestone 2.

Milestone 3 completion criteria: observer icon visible and fixed at bottom-center; Tukom Generator occupies bottom UI region; map tap only updates coordinate field; direction arc activates through direction field; arc drags correctly and converts to piiru; arc rotation clamped to ±90 degrees; distance notches displayed with labels; manual distance input required; perfect alignment detection works; FIRE executes full Tukom using AoE and appropriate scoring; all Milestone 1 & 2 features remain functional.