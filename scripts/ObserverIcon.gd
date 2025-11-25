extends Node2D

## ObserverIcon.gd
## Represents the observer's position on the map.
## Acts as the anchor point for bearing line calculations.

# Visual representation (circle sprite placeholder)
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# Icon is positioned by Main.gd based on map and UI layout
	pass
