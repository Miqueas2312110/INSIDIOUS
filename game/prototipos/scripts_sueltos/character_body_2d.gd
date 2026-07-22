extends CharacterBody2D

var bullet_scene = preload("res://game/accesorios/municion/balas/bala.tscn")

func _physics_process(delta):
	# La escopeta apunta siempre al mouse
	look_at(get_global_mouse_position())

	if Input.is_action_just_pressed("ui_accept"):
		fire()

func fire():
	var bullet = bullet_scene.instantiate()
	# La bala sale exactamente desde el Marker2D
	bullet.global_position = $Marker2D.global_position
	# Le pasamos la dirección hacia el mouse
	bullet.direction = (get_global_mouse_position() - $Marker2D.global_position).normalized()
	get_tree().current_scene.add_child(bullet)
