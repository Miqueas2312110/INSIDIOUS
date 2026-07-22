extends CharacterBody2D
class_name ManiquiEnemigo

## Vida del enemigo — muere al recibir 4 balas
var health: int = 4
var max_health: int = 4

## Si ya está muerto (para evitar múltiples procesamientos)
var is_dead: bool = false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("Enemy")


## Recibe daño de una bala. Si la vida llega a 0 o menos, muere.
func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	health -= amount
	print("Maniquí recibió daño. Vida: ", health, "/", max_health)
	
	if health <= 0:
		die()


## El enemigo muere: animación, desactivar colisión, y desaparecer
func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	# Desactivar colisión para que las balas no sigan chocando
	collision_shape.disabled = true
	
	# Efecto visual: parpadeo rápido y desaparecer
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(anim_sprite, "modulate", Color(1, 0, 0, 0.8), 0.15)
	tween.tween_property(anim_sprite, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_callback(queue_free).set_delay(0.4)
	
	print("¡Maniquí eliminado!")
