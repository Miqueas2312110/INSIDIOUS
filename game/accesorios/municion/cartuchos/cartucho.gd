extends Area2D
class_name Cartucho

## Cantidad de balas que otorga este cartucho al recargar
var ammo_amount: int = 3

## Referencia al sprite
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("Cartucho")
	
	# Pequeña animación de flotación
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "position:y", -3, 0.6).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", 3, 0.6).set_ease(Tween.EASE_IN_OUT)
