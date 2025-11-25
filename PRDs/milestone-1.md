# PRODUCT REQUIREMENTS DOCUMENT (PRD) — Milestone 1 – TUKOM Defender

## 1. Overview

Project Name: TUKOM Defender  
Engine: Godot 4.x  
Game Type: 2D top-down / angled shooter with random terrain

Goal of Milestone 1: implement the core gameplay loop without tukom commands. The player taps a tile; an artillery shell lands; any enemies on that tile are destroyed.

This milestone must provide:
- Procedural map with basic elevation.
- Enemies spawning from the top and walking downward toward the player position.
- Player tap-to-fire mechanic with limited ammo.
- Ammo crates that must be shot to replenish ammo.
- Game-over if an enemy reaches the bottom of the map.
- Placeholder-based asset setup so visuals can be swapped later with minimal changes.

---

## 2. Technical Scope

- Engine: Godot 4.x.
- Game mode: 2D.
- Terrain rendering: TileMap.
- Root nodes: Node2D.
- Movement: scripted movement using _process; no physics required.
- Platform: desktop for development; later exportable to Android/iOS.

---

## 3. Folder Structure

Expected folder layout under project root:

/scenes  
- Main.tscn  
- Map.tscn  
- Enemy.tscn  
- AmmoCrate.tscn  
- Shell.tscn  

/scripts  
- Main.gd  
- Map.gd  
- Enemy.gd  
- AmmoCrate.gd  
- Shell.gd  
- GameConfig.gd  

/assets/placeholders  
- enemy_placeholder.png  
- enemy_placeholder_large.png  
- ammo_crate_placeholder.png  
- shell_placeholder.png  
- tile_placeholder.png  

/data  
- terrain_tileset.tres  

The exact names and locations should be used consistently so they can be referenced by scripts and by future automation.

---

## 4. GameConfig.gd

Create a global config script `GameConfig.gd` to centralize constants used by other scripts.

Key constants:
- TILE_SIZE: 64 (pixels).
- MAP_WIDTH: 20 (tiles).
- MAP_HEIGHT: 30 (tiles).
- ENEMY_SPEED: 40.0 (pixels per second).
- ENEMY_SPAWN_INTERVAL: 2.0 (seconds).
- MAX_ENEMIES: 50.
- CRATE_SPAWN_INTERVAL: 12.0 (seconds).
- AMMO_PER_CRATE: 5.
- MAX_CRATES: 3.
- INITIAL_AMMO: 20.
- LAYER_TERRAIN: 0 (TileMap layer index).

All other scripts should reference these values via GameConfig instead of hardcoding.

---

## 5. Map System

Scene file: Map.tscn  
Script: Map.gd attached to root node.

### 5.1 Scene Structure

- Root node: Node2D named "Map".
- Child node: TileMap named "TerrainTileMap".
- TerrainTileMap uses tile size 64×64 pixels.
- Initial tileset can be a single placeholder tile (tile_placeholder.png) assembled into terrain_tileset.tres.

### 5.2 Map Data

Store two 2D arrays:
- elevation_map[y][x]: int elevation in meters, range 0–200.
- terrain_map[y][x]: String terrain type; initial values can be "grass", "forest", or "road".

Map dimensions:
- Width: MAP_WIDTH (20).
- Height: MAP_HEIGHT (30).

### 5.3 Procedural Generation

At _ready(), Map.gd should:
- Initialize elevation_map and terrain_map as 2D arrays sized [MAP_HEIGHT][MAP_WIDTH].
- Start with a baseline elevation (e.g., 50).
- For each tile (x,y) row by row:
  - Modify current elevation by a random delta between −20 and +20.
  - Clamp elevation between 0 and 200.
  - Assign a random terrain type from ["grass", "forest", "road"].
  - Draw a tile into TerrainTileMap on LAYER_TERRAIN using the placeholder tile from terrain_tileset.tres.

The visual tile can be the same for all terrain types in this milestone; terrain type values are mainly for future use.

### 5.4 Public API

Map.gd must expose:

- world_to_grid(world_pos: Vector2) -> Vector2i  
  Converts a point in global coordinates into map (x,y) tile coordinates.

- grid_to_world(tile: Vector2i) -> Vector2  
  Converts tile (x,y) coordinates into a world position suitable for placing Node2D instances.

- get_elevation(tile: Vector2i) -> int  
  Returns elevation for given tile; out-of-bounds can return 0.

- is_inside_map(tile: Vector2i) -> bool  
  Returns true if 0 ≤ x < MAP_WIDTH and 0 ≤ y < MAP_HEIGHT.

---

## 6. Enemy System

Scene file: Enemy.tscn  
Script: Enemy.gd attached to root node.

### 6.1 Scene Structure

- Root node: Node2D named "Enemy".
- Child: Sprite2D named "Sprite".
- Sprite.texture: assets/placeholders/enemy_placeholder.png (32×32).

### 6.2 Behavior

Enemy.gd should:

- Define signal: reached_bottom(enemy: Node2D).
- Expose export var speed: float = GameConfig.ENEMY_SPEED.
- On _ready(), compute bottom_y = MAP_HEIGHT * TILE_SIZE (world Y coordinate of player line).
- On _process(delta), move downward:
  - position.y += speed * delta.
- When position.y >= bottom_y:
  - Emit reached_bottom(self).
  - queue_free().

Enemies do not need complex collision; they will be hit by tile-based logic.

---

## 7. Ammo Crate System

Scene file: AmmoCrate.tscn  
Script: AmmoCrate.gd attached.

### 7.1 Scene Structure

- Root node: Node2D named "AmmoCrate".
- Child: Sprite2D named "Sprite".
- Sprite.texture: assets/placeholders/ammo_crate_placeholder.png (32×32).

### 7.2 Behavior

AmmoCrate.gd should:

- Define signal: crate_destroyed(crate: Node2D).
- Provide function destroy() that:
  - Emits crate_destroyed(self).
  - Calls queue_free().

Main.gd will call destroy() when a shell hits the crate’s tile.

---

## 8. Shell System (Player Fire)

Scene file: Shell.tscn  
Script: Shell.gd attached.

### 8.1 Scene Structure

- Root node: Node2D named "Shell".
- Child: Sprite2D named "Sprite".
- Sprite.texture: assets/placeholders/shell_placeholder.png (16×16).

### 8.2 Behavior

Shell.gd should:

- Have variables:
  - target_tile: Vector2i (tile coordinates to hit).
  - main_ref: Node (reference to Main controller).
- On _ready():
  - If main_ref is valid and has a method resolve_shell_hit(tile), call main_ref.resolve_shell_hit(target_tile).
  - Immediately queue_free().

In this milestone, the shell does not animate; it is effectively instant-fire.

---

## 9. Main Scene / Game Controller

Scene file: Main.tscn  
Script: Main.gd attached.

### 9.1 Scene Structure

Main.tscn should contain:

- Root: Node2D named "Main".
- Children:
  - Map (instance of Map.tscn) named "Map".
  - Node2D named "EnemyContainer".
  - Node2D named "CrateContainer".
  - CanvasLayer named "UI" with:
    - Label named "AmmoLabel".
    - Label named "ScoreLabel".
    - Control named "GameOverPanel" with:
      - Label named "GameOverLabel".
  - Timer named "EnemySpawnTimer".
  - Timer named "CrateSpawnTimer".

Initial UI settings:
- GameOverPanel.visible = false.

Timers:
- EnemySpawnTimer:
  - wait_time set from GameConfig.ENEMY_SPAWN_INTERVAL.
  - one_shot = false.
  - autostart = true.
- CrateSpawnTimer:
  - wait_time set from GameConfig.CRATE_SPAWN_INTERVAL.
  - one_shot = false.
  - autostart = true.

Main node can optionally be added to a group "MainController" for reference.

### 9.2 Main State

Main.gd should manage:

- ammo: int, initialized to GameConfig.INITIAL_AMMO.
- score: int, initialized to 0.
- is_game_over: bool, default false.
- PackedScene references:
  - enemy_scene: PackedScene (Enemy.tscn).
  - ammo_crate_scene: PackedScene (AmmoCrate.tscn).
  - shell_scene: PackedScene (Shell.tscn).

If export vars are not set via editor, load the default scenes in _ready().

### 9.3 Input Handling

In _input(event):

- If is_game_over is true, ignore input.
- On left mouse button pressed:
  - Call _handle_shot(event.position).

_handle_shot(screen_pos: Vector2) should:

- If ammo <= 0, do nothing.
- Use map.world_to_grid(screen_pos) to get tile.
- If tile is outside map bounds (map.is_inside_map(tile) is false), do nothing.
- Decrement ammo by 1.
- Update UI.
- Instantiate a Shell:
  - Set shell.target_tile = tile.
  - Set shell.main_ref = self.
  - Optionally set shell.position = map.grid_to_world(tile).
  - Add shell as child of Main.

### 9.4 Enemy Spawning

EnemySpawnTimer.timeout should call _on_enemy_spawn_timer_timeout().

Behavior:
- If is_game_over is true, return.
- If EnemyContainer has MAX_ENEMIES children, return.
- Choose random x in [0, MAP_WIDTH−1], tile = (x, 0).
- world_pos = map.grid_to_world(tile).
- Instantiate Enemy:
  - enemy.position = world_pos.
  - Add as child of EnemyContainer.
  - Connect enemy.reached_bottom to _on_enemy_reached_bottom(enemy).

### 9.5 Crate Spawning

CrateSpawnTimer.timeout should call _on_crate_spawn_timer_timeout().

Behavior:
- If is_game_over is true, return.
- If CrateContainer has MAX_CRATES children, return.
- Choose random x in [0, MAP_WIDTH−1].
- Choose random y in [1, MAP_HEIGHT−2] (to avoid top and bottom rows).
- tile = (x, y).
- world_pos = map.grid_to_world(tile).
- Instantiate AmmoCrate:
  - crate.position = world_pos.
  - Add as child of CrateContainer.

No collision checks needed beyond tile overlap logic.

### 9.6 Shell Resolution

Main.gd must implement resolve_shell_hit(tile: Vector2i).

Logic:

- Initialize lists enemies_to_destroy and crates_to_destroy.
- Iterate over EnemyContainer children:
  - Convert enemy.position to tile via map.world_to_grid(enemy.position).
  - If equal to target tile, add enemy to enemies_to_destroy.
- Iterate over CrateContainer children:
  - Convert crate.position similarly.
  - If equal to target tile, add crate to crates_to_destroy.
- For each enemy in enemies_to_destroy:
  - Increase score by 1.
  - queue_free() the enemy.
- For each crate in crates_to_destroy:
  - Add AMMO_PER_CRATE to ammo.
  - queue_free() the crate.
- After modifications, call UI update.

### 9.7 Game Over

Game over is triggered when _on_enemy_reached_bottom(enemy: Node2D) is called.

_on_enemy_reached_bottom should:
- Call _trigger_game_over with a reason string such as "Enemy reached your position!".

_trigger_game_over(reason: String) should:
- If is_game_over is already true, return.
- Set is_game_over = true.
- Stop EnemySpawnTimer and CrateSpawnTimer.
- Set GameOverLabel.text to a message containing reason and final score.
- Set GameOverPanel.visible = true.

No restart logic required in Milestone 1 (optional).

### 9.8 UI Updates

Main.gd should provide _update_ui(), which:
- Sets AmmoLabel.text to "Ammo: X".
- Sets ScoreLabel.text to "Score: Y".

Call this after:
- Initial setup.
- Firing a shot (ammo changes).
- Destroying enemies (score changes).
- Destroying crates (ammo changes).

---

## 10. Interaction Rules Summary

- Shell vs Enemy: if a shell targets a tile containing enemies, all in that tile are destroyed; each destroyed enemy gives +1 score.
- Shell vs AmmoCrate: if a shell targets a tile with one or more crates, all those crates are destroyed; each destroyed crate adds AMMO_PER_CRATE ammo.
- Enemy vs Bottom: when an enemy’s y-position passes the bottom line (MAP_HEIGHT * TILE_SIZE), it emits reached_bottom and is removed; this triggers game over via Main.gd.

---

## 11. Placeholder Assets

All assets for Milestone 1 can be simple solid-color or minimal-shape sprites.

Required placeholder files under assets/placeholders:
- enemy_placeholder.png: 32×32, red square or simple enemy icon.
- enemy_placeholder_large.png: 64×64, optional variant for future use.
- ammo_crate_placeholder.png: 32×32, brown square (crate).
- shell_placeholder.png: 16×16, small grey or white circle.
- tile_placeholder.png: 64×64, green square for terrain.

---

## 12. Future-Proof Asset Naming

To prepare for later visuals, define naming pattern:
- {entity_type}_{variant}_{size}.png.

Examples:
- enemy_basic_32.png.
- enemy_tank_32.png.
- crate_wood_32.png.
- terrain_grass_64.png.
- terrain_forest_64.png.
- terrain_road_64.png.
- shell_he_16.png.

Future replacement pipeline:
- Place new art in /assets/generated.
- Update Sprite2D.texture fields in the relevant scenes.
- Adjust Sprite2D.scale if resolution differs, or introduce metadata in future milestones.

---

## 13. Performance Requirements

- Target device: mobile-capable performance, but PC dev first.
- Maximum active enemies: 50.
- Maximum active crates: 3.
- Minimal CPU usage: no physics bodies required, simple per-frame movement and checks.

---

## 14. Milestone 1 Completion Criteria

Milestone 1 is complete when:
- Running Main.tscn produces a playable prototype where:
  - A procedural map appears using the TileMap.
  - Enemies periodically spawn at the top and move downward.
  - The player can click/tap anywhere on the map to fire a shell, consuming ammo (unless ammo is 0).
  - Hitting enemies increases the score and removes them.
  - Ammo crates spawn periodically at random tiles; hitting them increases ammo.
  - If any enemy reaches the bottom, game over is displayed via GameOverPanel including final score.
  - UI correctly displays current ammo and score at all times.
- All scenes and scripts exist and are named and wired exactly as described in this document.