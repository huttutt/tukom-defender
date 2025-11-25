extends Node2D

## AmmoCrate.gd
## Ammo crate with HP system that can be destroyed by shells to replenish player ammunition.

# Signal emitted when crate is destroyed
signal crate_destroyed(crate: Node2D)

# Hit points
@export var hp: int = 1


## Takes damage and destroys if HP reaches 0
func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		crate_destroyed.emit(self)
		queue_free()
