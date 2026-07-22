extends CharacterBody2D
class_name Escopeta

## Contador de balas de la escopeta
var bullet_count: int = 0
var max_bullets: int = 6

## Cooldown entre disparos
var can_shoot: bool = true
var shoot_cooldown: float = 0.8

## Indica si ya fue recogida por el jugador
var is_picked_up: bool = false

## Referencia a la escena de la bala
var bullet_scene: PackedScene = preload("res://game/accesorios/municion/balas/bala.tscn")

## Escala proporcional calculada para las balas
var bullet_scale: float = 0.35

## Referencia al Sprite2D del arma (para animación de retroceso)
var weapon_pivot: Node2D
var weapon_sprite: Sprite2D
var weapon_marker: Marker2D

## Cargar la textura del fogonazo
var muzzle_texture: Texture2D = preload("res://game/accesorios/armas/escopeta/muzzle_flash_frame_0.png")


func _ready() -> void:
	add_to_group("Escopeta")
	weapon_pivot = $SpritePivot if has_node("SpritePivot") else null
	weapon_sprite = $SpritePivot/Sprite2D if has_node("SpritePivot/Sprite2D") else null
	weapon_marker = $SpritePivot/Marker2D if has_node("SpritePivot/Marker2D") else null


## Dispara una bala desde el Marker2D hacia la posición del mouse.
func shoot() -> bool:
	if not is_picked_up or not can_shoot:
		return false
	
	if bullet_count <= 0:
		_show_no_ammo_feedback()
		return false
	
	# Consumir una bala
	bullet_count -= 1
	can_shoot = false
	
	# --- ANIMACIÓN DE DISPARO ---
	_play_shoot_animation()
	
	# Instanciar la bala
	var bullet: CharacterBody2D = bullet_scene.instantiate()
	bullet.bullet_scale = bullet_scale
	
	# Dirección desde la escopeta hacia el mouse
	var mouse_pos: Vector2 = get_global_mouse_position()
	var bullet_dir: Vector2 = (mouse_pos - global_position).normalized()
	bullet.direction = bullet_dir
	
	# Posición de salida: desde el cañón (calculado correctamente incluso con pivot invertido)
	bullet.global_position = _get_muzzle_global_position()
	
	get_tree().current_scene.add_child(bullet)
	
	# Esperar el cooldown
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true
	return true


## Obtiene la posición global de la punta del cañón.
## Usa la dirección en X del pivot (invertido si mira izquierda) para calcular 
## dónde está la punta del cañón, independientemente de la rotación del sprite.
func _get_muzzle_global_position() -> Vector2:
	if not weapon_pivot:
		return global_position
	
	# Dirección del cañón: si el pivot está invertido, el cañón apunta a la izquierda
	var barrel_dir: float = -1.0 if weapon_pivot.scale.x < 0 else 1.0
	
	# Distancia desde el centro del pivot hasta la punta del cañón (según Marker2D)
	var barrel_distance: float = abs(weapon_marker.position.x) if weapon_marker else 22.0
	
	# Posición de la punta: desde el pivot, hacia la dirección del cañón
	return weapon_pivot.global_position + Vector2(barrel_dir * barrel_distance, 0.0)


func _play_shoot_animation() -> void:
	# 1. Fogonazo (muzzle flash) en la posición del cañón
	var flash: Sprite2D = Sprite2D.new()
	flash.texture = muzzle_texture
	flash.global_position = _get_muzzle_global_position()
	flash.scale = Vector2(bullet_scale * 2, bullet_scale * 2)
	flash.z_index = 50
	get_tree().current_scene.add_child(flash)
	
	# Desaparecer el fogonazo rápidamente
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.1)
	flash_tween.tween_callback(flash.queue_free)
	
	# 2. Retroceso visual del arma (si tiene sprite)
	if weapon_sprite:
		var original_pos: Vector2 = weapon_sprite.position
		var recoil_tween: Tween = create_tween()
		recoil_tween.tween_property(weapon_sprite, "position:x", original_pos.x - 3, 0.05)
		recoil_tween.tween_property(weapon_sprite, "position:x", original_pos.x, 0.1).set_ease(Tween.EASE_OUT)


## Recargar: consume un cartucho del jugador para llenar el cargador
func reload(player: Node) -> bool:
	if not is_picked_up:
		return false
	
	if bullet_count >= max_bullets:
		# Ya está lleno
		return false
	
	# Pedir un cartucho al jugador (3 balas)
	if not player.has_method("use_cartucho"):
		return false
	
	var ammo_gained: int = player.use_cartucho()
	if ammo_gained <= 0:
		# No hay cartuchos disponibles
		_show_no_cartucho_feedback()
		return false
	
	bullet_count = clampi(bullet_count + ammo_gained, 0, max_bullets)
	print("Escopeta recargada: ", bullet_count, "/", max_bullets)
	
	# Feedback visual de recarga
	var feedback: Label = Label.new()
	feedback.text = "+" + str(ammo_gained)
	feedback.add_theme_color_override("font_color", Color.YELLOW)
	feedback.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback.add_theme_constant_override("shadow_offset_x", 1)
	feedback.add_theme_constant_override("shadow_offset_y", 1)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.position = Vector2(-40, -80)
	feedback.z_index = 100
	get_parent().add_child(feedback)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback, "position:y", -110, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	await tween.finished
	feedback.queue_free()
	return true


## Añade balas al cargador (llamado por los pickups de munición)
func add_ammo(amount: int) -> void:
	if not is_picked_up:
		return
	
	var old_count: int = bullet_count
	bullet_count = clampi(bullet_count + amount, 0, max_bullets)
	var added: int = bullet_count - old_count
	
	if added > 0:
		var feedback: Label = Label.new()
		feedback.text = "+" + str(added) + " balas"
		feedback.add_theme_color_override("font_color", Color.ORANGE)
		feedback.add_theme_color_override("font_shadow_color", Color.BLACK)
		feedback.add_theme_constant_override("shadow_offset_x", 1)
		feedback.add_theme_constant_override("shadow_offset_y", 1)
		feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		feedback.position = Vector2(-40, -70)
		feedback.z_index = 100
		get_parent().add_child(feedback)
		
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(feedback, "position:y", -95, 0.8).set_ease(Tween.EASE_OUT)
		tween.tween_property(feedback, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
		await tween.finished
		feedback.queue_free()


## Feedback visual de "Sin balas"
func _show_no_ammo_feedback() -> void:
	if not is_inside_tree():
		return
	
	var feedback: Label = Label.new()
	feedback.text = "¡Sin balas!"
	feedback.add_theme_color_override("font_color", Color.RED)
	feedback.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback.add_theme_constant_override("shadow_offset_x", 1)
	feedback.add_theme_constant_override("shadow_offset_y", 1)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback.position = Vector2(-50, -60)
	feedback.z_index = 100
	get_parent().add_child(feedback)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback, "position:y", -90, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback, "modulate:a", 0.0, 1.2).set_ease(Tween.EASE_IN)
	await tween.finished
	feedback.queue_free()


## El jugador recoge esta escopeta del suelo
func pick_up(player: Node) -> void:
	is_picked_up = true
	reparent(player)
	_calculate_proportional_scale(player)
	position = Vector2(25, -40)
	$CollisionShape2D.disabled = true
	if has_node("PickupZone/CollisionShape2D"):
		$PickupZone/CollisionShape2D.disabled = true


func _calculate_proportional_scale(player: Node) -> void:
	var player_sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if not player_sprite:
		return
	var sprite_frames: SpriteFrames = player_sprite.sprite_frames
	if not sprite_frames:
		return
	var anim: String = player_sprite.animation
	var frame_idx: int = player_sprite.frame
	var frame_tex: Texture2D = sprite_frames.get_frame_texture(anim, frame_idx)
	if not frame_tex:
		return
	var player_frame_size: Vector2 = frame_tex.get_size()
	var player_scale: Vector2 = player_sprite.scale * player.scale
	var player_visual_width: float = player_frame_size.x * player_scale.x
	var target_gun_length: float = player_visual_width * 0.65
	const TEXTURE_LENGTH: float = 44.0
	var new_scale_x: float = target_gun_length / TEXTURE_LENGTH
	var new_scale_y: float = new_scale_x * (33.0 / 44.0)
	if weapon_sprite:
		weapon_sprite.scale = Vector2(new_scale_x, new_scale_y)
	var bullet_texture_size: float = 32.0
	var target_bullet_size: float = target_gun_length * 0.18
	bullet_scale = target_bullet_size / bullet_texture_size


## Feedback visual de "No tienes cartuchos"
func _show_no_cartucho_feedback() -> void:
	if not is_inside_tree():
		return
	
	var feedback: Label = Label.new()
	feedback.text = "¡Sin cartuchos!"
	feedback.add_theme_color_override("font_color", Color.ORANGE_RED)
	feedback.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback.add_theme_constant_override("shadow_offset_x", 1)
	feedback.add_theme_constant_override("shadow_offset_y", 1)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback.position = Vector2(-50, -60)
	feedback.z_index = 100
	get_parent().add_child(feedback)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback, "position:y", -90, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback, "modulate:a", 0.0, 1.2).set_ease(Tween.EASE_IN)
	await tween.finished
	feedback.queue_free()


func _on_pickup_zone_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and not is_picked_up:
		body.near_shotgun = self

func _on_pickup_zone_body_exited(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("near_shotgun"):
		if body.near_shotgun == self:
			body.near_shotgun = null
