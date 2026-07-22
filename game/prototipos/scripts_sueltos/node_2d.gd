extends Area2D

var speed = 1000
var direction = Vector2.RIGHT

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		body.take_damage(1) # función que deberías tener en tu enemigo
		queue_free()
	else:
		# si choca con cualquier otra cosa, se destruye
		queue_free()
