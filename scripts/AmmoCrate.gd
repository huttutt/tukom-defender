extends Node2D

## AmmoCrate.gd
## Ammo crate that can be destroyed by shells to replenish player ammunition.

# Signal emitted when crate is destroyed
signal crate_destroyed(crate: Node2D)


## Destroys this crate, emitting signal and removing from scene
func destroy() -> void:
	crate_destroyed.emit(self)
	queue_free()
