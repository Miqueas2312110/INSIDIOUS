extends Area2D

var player_inside = false

# Se ejecuta cuando el jugador entra en el área de la puerta
func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"): # tu jugador debe estar en el grupo "Player"
		player_inside = true

# Se ejecuta cuando el jugador sale del área de la puerta
func _on_Area2D_body_exited(body):
	if body.is_in_group("Player"):
		player_inside = false

# Se ejecuta cada frame
func _process(delta):
	# Si el jugador está dentro del área y presiona F
	if player_inside and Input.is_action_just_pressed("ui_e"):
		get_tree().change_scene_to_file("res://game/escenarios/escenario_2/escena/exterior.tscn")
