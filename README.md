# TUKOM Defender

A 2D top-down artillery defense game built with Godot 4.x.

## Overview

TUKOM Defender is a procedurally-generated tactical defense game where players command artillery to defend against waves of enemies. The game features procedural terrain generation, tap-to-fire mechanics, and resource management through limited ammunition.

## Project Structure

```
/scenes         - Godot scene files (.tscn)
/scripts        - GDScript files (.gd)
/assets         - Game assets (sprites, textures, etc.)
  /placeholders - Placeholder art for development
/data           - Game data files (tilesets, etc.)
```

## Development

This project follows strict **GitFlow** conventions. Please read [CLAUDE.md](CLAUDE.md) for complete branching and workflow guidelines.

### Current Milestone

**Milestone 1**: Core gameplay loop
- Procedural map generation with elevation
- Enemy spawning and movement
- Tap-to-fire artillery mechanics
- Ammo management with supply crates
- Game over conditions

## Requirements

- Godot 4.x
- Target platforms: Desktop (development), Android/iOS (future)

## GitFlow Branch Model

- `main` - Production-ready releases only
- `develop` - Integration branch for ongoing work
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Critical production fixes
- `release/*` - Release preparation

**Never commit directly to `main` or `develop`.** All changes must go through pull requests.

## Getting Started

1. Clone the repository
2. Open the project in Godot 4.x
3. Run `Main.tscn` from the scenes folder

## License

[To be determined]
