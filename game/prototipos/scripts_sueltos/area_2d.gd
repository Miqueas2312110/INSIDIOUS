extends Area2D

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if Input.is_action_just_pressed("ui_accept"):
			body.pick_shotgun()
			queue_free() # elimina la escopeta del suelo
