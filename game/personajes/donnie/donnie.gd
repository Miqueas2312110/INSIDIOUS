extends CharacterBody2D

# --- Variables de movimiento ---
var speed: float = 72.0
var jump: float = -400.0
var gravity: float = 980.0

# --- Variables del arma ---
var has_shotgun: bool = false
var equipped_shotgun: Escopeta = null
var near_shotgun: Escopeta = null
var facing_right: bool = true

# --- Variables de cartuchos ---
var cartuchos: int = 0  # Cartuchos de 3 balas que lleva el jugador
var near_cartucho: Cartucho = null  # Cartucho más cercano para recoger

# --- Variables de escena ---
var near_door: bool = false
var door_scene_path: String = "res://game/escenarios/escenario_2/escena/exterior.tscn"


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	var move_player: float = Input.get_axis("ui_left", "ui_right")
	velocity.x = move_player * speed

	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump

	move_and_slide()

	# --- RECOGER ESCOPETA (F) ---
	if Input.is_action_just_pressed("pickup_shotgun") and near_shotgun != null:
		pickup_shotgun()

	# --- DISPARAR (T) ---
	if Input.is_action_just_pressed("shoot_shotgun") and equipped_shotgun != null:
		_aim_toward_mouse()  # Girar al jugador hacia el mouse antes de disparar
		_update_shotgun_direction()
		equipped_shotgun.shoot()

	# --- RECARGAR (R) ---
	if Input.is_action_just_pressed("reload_shotgun") and equipped_shotgun != null:
		equipped_shotgun.reload(self)

	# --- RECOGER CARTUCHO (E) ---
	if Input.is_action_just_pressed("interacción") and near_cartucho != null:
		pickup_cartucho(near_cartucho)

# --- CAMBIAR DE ESCENA (Y) junto a la puerta ---
	if Input.is_action_just_pressed("change_scene") and near_door:
		_change_scene()

	animated()
	_update_shotgun_direction()  # Sincronizar el arma cada frame


func pickup_shotgun() -> void:
	if near_shotgun == null:
		return
	var shotgun: Escopeta = near_shotgun
	near_shotgun = null
	shotgun.pick_up(self)
	equipped_shotgun = shotgun
	has_shotgun = true
	print("¡Escopeta recogida! Balas: ", shotgun.bullet_count, "/", shotgun.max_bullets)





## Recoge un cartucho del suelo (llamado al presionar E)
func pickup_cartucho(cartucho: Cartucho) -> void:
	if not is_instance_valid(cartucho):
		return
	cartuchos += 1
	near_cartucho = null
	cartucho.queue_free()
	print("Cartucho recogido. Total: ", cartuchos)
	
	# Feedback visual simple (sin await para que el print sea inmediato)
	var feedback: Label = Label.new()
	feedback.text = "+1 Cartucho"
	feedback.add_theme_color_override("font_color", Color.ORANGE)
	feedback.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback.add_theme_constant_override("shadow_offset_x", 1)
	feedback.add_theme_constant_override("shadow_offset_y", 1)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.position = Vector2(-60, -70)
	feedback.z_index = 100
	add_child(feedback)
	
	var fb_tween: Tween = create_tween()
	fb_tween.set_parallel(true)
	fb_tween.tween_property(feedback, "position:y", -95, 0.8).set_ease(Tween.EASE_OUT)
	fb_tween.tween_property(feedback, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	await fb_tween.finished
	if is_instance_valid(feedback):
		feedback.queue_free()


## Consume un cartucho y devuelve cuántas balas otorga (3).
## Retorna 0 si no hay cartuchos disponibles.
func use_cartucho() -> int:
	if cartuchos <= 0:
		return 0
	
	cartuchos -= 1
	print("Cartucho consumido. Restantes: ", cartuchos)
	return 3


## Añade balas a la escopeta (llamado por pickups de munición)
func add_ammo(amount: int) -> void:
	if equipped_shotgun != null:
		equipped_shotgun.add_ammo(amount)


## Cambia a la escena exterior
func _change_scene() -> void:
	print("Cambiando a: ", door_scene_path)
	get_tree().change_scene_to_file(door_scene_path)


## Gira al personaje hacia donde está el mouse
func _aim_toward_mouse() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var mouse_dir: Vector2 = (mouse_pos - global_position).normalized()
	
	# Si el mouse está a la izquierda y el jugador mira a la derecha, o viceversa
	if mouse_dir.x < 0 and facing_right:
		facing_right = false
	elif mouse_dir.x > 0 and not facing_right:
		facing_right = true


## Sincroniza la rotación/inversión del arma con la dirección del personaje
func _update_shotgun_direction() -> void:
	if not equipped_shotgun or not is_instance_valid(equipped_shotgun):
		return
	
	var pivot: Node2D = equipped_shotgun.get_node_or_null("SpritePivot")
	if not pivot:
		return
	
	if not facing_right:
		pivot.scale.x = -abs(pivot.scale.x)
	else:
		pivot.scale.x = abs(pivot.scale.x)
	
	# (sin brazo)


func animated() -> void:
	if is_on_floor():
		if velocity.x == 0:
			$AnimatedSprite2D.play("quieto")
		else:
			$AnimatedSprite2D.play("caminata")
			if velocity.x < 0:
				$AnimatedSprite2D.flip_h = true
				facing_right = false
			else:
				$AnimatedSprite2D.flip_h = false
				facing_right = true
			# Al caminar, también sincronizar el arma
			_update_shotgun_direction()


# --- Señales: detectar escopeta en el suelo ---
func _on_pickup_area_body_entered(body: Node) -> void:
	if body.is_in_group("Escopeta") and not body.is_picked_up:
		near_shotgun = body

func _on_pickup_area_body_exited(body: Node) -> void:
	if body == near_shotgun:
		near_shotgun = null

# --- Señales: detectar cartuchos en el suelo (son Area2D) ---
func _on_pickup_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("Cartucho"):
		near_cartucho = area as Cartucho

func _on_pickup_area_area_exited(area: Area2D) -> void:
	if area == near_cartucho:
		near_cartucho = null

# --- Señales: detectar puerta de cambio de escena ---
func _on_door_area_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		near_door = true
		# Mostrar indicador visual
		var hint: Label = Label.new()
		hint.name = "DoorHint"
		hint.text = "Presiona Y para salir"
		hint.add_theme_color_override("font_color", Color.WHITE)
		hint.add_theme_color_override("font_shadow_color", Color.BLACK)
		hint.add_theme_constant_override("shadow_offset_x", 1)
		hint.add_theme_constant_override("shadow_offset_y", 1)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.position = Vector2(-80, -120)
		hint.z_index = 100
		add_child(hint)

func _on_door_area_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		near_door = false
		var hint: Label = get_node_or_null("DoorHint")
		if hint:
			hint.queue_free()
