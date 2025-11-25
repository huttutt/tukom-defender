extends Node2D

## Shell.gd
## Artillery shell fired by the player.
## Immediately resolves hit detection on creation (instant-fire for Milestone 1).

# Target tile coordinates to hit
var target_tile: Vector2i = Vector2i.ZERO

# Reference to Main controller for hit resolution
var main_ref: Node = null


func _ready() -> void:
	# Resolve the shell hit immediately
	if main_ref != null and main_ref.has_method("resolve_shell_hit"):
		main_ref.resolve_shell_hit(target_tile)

	# Remove shell immediately (instant-fire, no animation)
	queue_free()
