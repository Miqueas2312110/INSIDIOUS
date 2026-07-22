extends Area2D
class_name AmmoPickup

## Cantidad de balas que otorga este pickup
var ammo_amount: int = 2

@onready var sprite: Sprite2D = $Sprite2D
var float_tween: Tween


func _ready() -> void:
	# Animación de flotación suave
	float_tween = create_tween().set_loops()
	float_tween.tween_property(sprite, "position:y", 3, 0.6).as_relative().set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(sprite, "position:y", -3, 0.6).as_relative().set_ease(Tween.EASE_IN_OUT)


## Se recoge automáticamente al detectar al jugador
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		# Dar balas al jugador (a través de la escopeta)
		if body.has_method("add_ammo"):
			body.add_ammo(ammo_amount)
		
		# Feedback visual y desaparecer
		set_deferred("monitoring", false)
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.2)
		await tween.finished
		queue_free()
