extends Area2D

@export var explosion_damage: int = 20
@export var explosion_radius: float = 150.0

func _ready() -> void:
	# Animación de parpadeo
	var tween = create_tween().set_loops(4)
	tween.tween_property(self, "modulate", Color.RED, 0.25)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
	
	# Explotar tras 2 segundos
	get_tree().create_timer(2.0).timeout.connect(explode)

func explode() -> void:
	# Buscar enemigos en el área
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < explosion_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(explosion_damage)
	
	# Efecto visual simple
	var effect = create_tween()
	scale = Vector2.ZERO
	show()
	effect.tween_property(self, "scale", Vector2(3, 3), 0.1)
	effect.parallel().tween_property(self, "modulate:a", 0, 0.1)
	
	if AudioManager.has_method("play"):
		AudioManager.play("crit") # Sonido temporal de explosión
		
	effect.finished.connect(queue_free)
