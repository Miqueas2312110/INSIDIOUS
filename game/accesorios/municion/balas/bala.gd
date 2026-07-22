extends CharacterBody2D
class_name Bala

## Velocidad de la bala en píxeles por segundo
var speed: float = 700.0

## Dirección normalizada hacia donde debe moverse la bala
var direction: Vector2 = Vector2.ZERO

## Escala proporcional al arma que la disparó
var bullet_scale: float = 1.0

## Tiempo de vida máximo antes de autodestruirse (en segundos)
var lifetime: float = 3.0

## Flag para ignorar colisiones en el primer frame (evita chocar con el jugador al spawnear)
var _first_frame: bool = true


func _ready() -> void:
	# Aplicar la escala proporcional al arma
	scale = Vector2(bullet_scale, bullet_scale)
	
	# Rotar el sprite para que apunte en la dirección de movimiento
	if direction.length() > 0:
		rotation = direction.angle()
	
	
	
	# Destruir la bala después de su tiempo de vida máximo
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	velocity = direction * speed
	move_and_slide()
	
	# Ignorar colisiones en el primer frame (la bala acaba de spawnear)
	if _first_frame:
		_first_frame = false
		return
	
	# Revisar todas las colisiones del frame
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Node = collision.get_collider()
		
		# Si chocó con el jugador o la escopeta, ignorarlos (la bala atraviesa)
		if collider.is_in_group("Player") or collider.is_in_group("Escopeta"):
			continue
		
		# Si chocó con un enemigo, aplicarle daño
		if collider.is_in_group("Enemy") and collider.has_method("take_damage"):
			print("Bala impactó enemigo: ", collider.name)
			collider.take_damage(1)
		
		# Destruir la bala al chocar con cualquier otra cosa
		queue_free()
		return
