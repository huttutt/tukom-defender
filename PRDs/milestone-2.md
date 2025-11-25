# PRODUCT REQUIREMENTS DOCUMENT (PRD) — Milestone 2 — TUKOM Defender

## 1. Overview
Milestone 2 expands the core prototype by adding directional enemy behavior and a new targeting/shooting UX flow. The player can now select a coordinate on the map, view a dynamic marker, read a faux MGRS coordinate for that tile, and press a FIRE button to trigger an area-effect shot that damages multiple tiles at once. Enemies gain more dynamic behavior, including zig-zag movement and momentary pauses while still maintaining forward (downwards) pressure. All Milestone 1 structures remain, updated only where required.

---

## 2. Enemy Behavior (Revised)
Enemy movement must now use a semi-random forward-biased pattern:

### Rules:
1. Enemies always move generally downward (towards the player) but may change horizontal direction or even pause.
2. Each “movement tick” (handled via _process or a movement timer) an enemy may choose one of four actions:
   - **Move Down**
   - **Move Down-Right**
   - **Move Down-Left**
   - **Pause** (no movement this tick)
3. They **never move upward** under any circumstances.
4. They may move left or right arbitrarily but **cannot perform more than three horizontal-only movements in a row** without moving down at least once. Example allowed sequence: left → right → left → *must* then include a downward component.
5. Enemies must remain fully inside the map bounds at all times; directional choices that would push them offscreen must be discarded for that tick.
6. Enemy speed is unchanged from Milestone 1; however direction vectors now vary per tick.
7. Enemy behavior randomness should be deterministic per enemy instance if needed (optionally: assign each enemy an RNG seed at spawn).

### Implementation Notes:
- Movement should be resolved once per frame for simplicity, but optionally controlled via an internal cooldown (e.g., enemy moves every X milliseconds).
- Track a counter for consecutive horizontal-only moves; when it reaches 3, force the next move to include downward motion.

---

## 3. Targeting + Shooting UX (New System)

### 3.1 Tile Selection Marker
- When the player taps anywhere on the map, instead of immediately firing, a **visible marker** appears exactly on the tapped tile’s center.
- Only one active marker exists at a time; placing a new marker removes or updates the previous one.
- The marker can be a sprite, shader highlight, or simple outlined tile indicator.

### 3.2 FIRE Button (Floating UI Element)
- A floating circular or rectangular FIRE button appears at the **bottom center** of the screen.
- The FIRE button is **disabled** until a marker has been placed.
- After firing, the button returns to disabled state until the player places another marker.
- This button initiates the shell logic.

### 3.3 Faux MGRS Coordinate Display
Displayed above the FIRE button, updating in real time whenever the marker changes.

Rules:
- The **top-left tile** of the map is defined as:
  **“37U DB 13224 79170”**
- The two 4-digit strings represent:
  - **Easting** (horizontal / X)  
  - **Northing** (vertical / Y)
- Moving **one tile right**: increase Easting by 1 (13224 → 13225, then 13226, etc.)
- Moving **one tile down**: increase Northing by 1  
- Moving **one tile up**: decrease Northing by 1 (cannot go below starting 79170)
- Values must remain zero-padded to **4 digits**.
- The displayed coordinate format must follow the pattern:
  `37U DB XXXXX YYYYY`
  where XXXXX is easting and YYYYY is northing.

### 3.4 FIRE Resolution Rules
- Pressing FIRE triggers one artillery shot at the selected tile.
- The hit area is a **3×3 tile square** centered around the marked tile:
  - This consists of the target tile plus all orthogonally and diagonally adjacent 8 tiles.
- Damage application:
  - Each enemy within the 3×3 area **loses 1 HP**.
  - Each ammo crate within the 3×3 area **loses 1 HP** (milestone 2 crates therefore must have HP = 1 minimum).
- After resolving impact:
  - The FIRE button is disabled.
  - The marker is cleared.
  - UI awaits new user tile selection.

---

## 4. UI Additions (Milestone 2)

### 4.1 Marker Sprite/Node
- Must be implemented as a scene or simple Node2D/Sprite2D.
- Drawn above terrain but below UI.
- Appears when user taps anywhere inside the map bounds.
- Should snap precisely to tile center.

### 4.2 FIRE Button
- New Control node inside UI layer (CanvasLayer).
- Properties:
  - Initially invisible or disabled.
  - Appears/enables when a marker exists.
  - Grays out or hides after firing.
- FIRE button fires only if:
  - Player has ≥ 1 ammo.
  - Marker exists.
- The firing does not remove ammo crates; that is handled by the damage logic.

### 4.3 Faux MGRS Display
- A small Label positioned directly **above** the FIRE button.
- Updates whenever the player selects a tile.
- Hidden or cleared when marker is cleared.

### 4.4 Preventing Conflicts with Existing UI
- Milestone 1 score and ammo counters remain.
- GameOverPanel stays unchanged.

---

## 5. Shooting & Damage Logic (Updated)

### 5.1 Revised Shell Logic
The shell scene may remain instant resolution (no animation needed yet).  
The difference:
- Instead of resolving only the exact target tile, the shell now resolves **all tiles within Manhattan/diagonal distance ≤ 1**.

### 5.2 Implementation Steps
1. FIRE button pressed → call a Main.gd function `fire_at_marker()`.
2. Determine target_tile.
3. Generate all tile coordinates in a 3×3 square around target_tile.
4. For each tile:
   - Identify all enemies whose grid positions equal that tile.
   - Identify all ammo crates whose grid positions equal that tile.
5. Reduce HP on each enemy/crate by 1.
6. Remove entities with HP ≤ 0.
7. Clear marker + disable FIRE.

---

## 6. Marker Lifecycle

### States:
1. **Idle:** No marker, FIRE disabled.
2. **Marker Placed:** Marker visible, FIRE enabled.
3. **Shot Fired:** Marker cleared, FIRE disabled.

UI behavior must obey these states.

---

## 7. Enemy HP Standardization (M2 Requirement)
- Enemies now must have:
  - `hp = 1` (or more if tuning is desired later).
- Ammo crates must have:
  - `hp = 1`
  - On destruction → restore ammo as in Milestone 1.

---

## 8. Map Interaction Enhancements
The map still uses TileMap and procedural generation from Milestone 1.  
New additions:
- A function to convert tile coordinates to faux MGRS.
- A function to handle marker placement:
  - Verify click position is inside map.
  - Convert world→grid.
  - Create or reposition marker.

---

## 9. Performance Requirements
- Enemy movement randomness must not introduce frame spikes.
- 3×3 hit checks per FIRE action are negligible—OK for mobile.

---

## 10. Milestone 2 Completion Criteria

Milestone 2 is complete when:
1. Enemies move with the new semi-random, forward-biased zig-zag logic while obeying the 3-step horizontal limit and staying within map bounds.
2. Clicking a tile places a visible marker; FIRE button appears/enables.
3. Faux MGRS coordinate updates correctly as marker moves.
4. FIRE executes a 3×3 area-effect shot that reduces HP of enemies/crates within range.
5. Marker clears after firing and FIRE button disables.
6. All Milestone 1 systems remain functional.
7. The game is fully playable end-to-end with the new targeting system.