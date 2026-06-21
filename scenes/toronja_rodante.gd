extends Area2D

var speed: float = 450.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Destruir la toronja después de 5 segundos para que no viaje al infinito
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _process(delta: float) -> void:
	# Rotación visual para que parezca que va rodando
	rotation += 10.0 * delta 
	# Movimiento lineal
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemigos"):
		if body.has_method("is_boss") and body.is_boss():
			# A los jefes no los insta-mata, pero les duele
			body.take_damage(500) 
		else:
			# Instakill al enemigo
			body.die() 
			
			# Robar vida para el Rabanito
			var base = get_tree().get_first_node_in_group("base_rabanito")
			if base and base.has_method("heal"):
				# Ajusta este número según qué tan roto quieras que esté
				base.heal(1)
