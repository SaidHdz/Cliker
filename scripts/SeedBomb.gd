extends Area2D

@export var explosion_damage: int = 20
@export var explosion_radius: float = 150.0

var current_level_val: Variant = 1

func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val
	var lvl = 4 if typeof(lvl_val) == TYPE_STRING else lvl_val
	
	if lvl >= 2: explosion_damage = int(explosion_damage * 1.8)
	if lvl >= 3: explosion_radius *= 1.5
	if lvl >= 5: 
		explosion_radius *= 2.0
		explosion_damage *= 3
		modulate = Color.YELLOW_GREEN # Color radiactivo

func _ready() -> void:
	var tween = create_tween().set_loops(4)
	tween.tween_property(self, "modulate", Color.RED, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	get_tree().create_timer(1.5).timeout.connect(explode)

func explode() -> void:
	var meta_upgrade = GameManager.card_upgrade_levels.get("explosive_slice", 0)
	
	# Extraemos el bonus de forma segura, sea número o texto
	var bonus_damage = 0
	if typeof(meta_upgrade) == TYPE_INT:
		bonus_damage = meta_upgrade * 5
	else:
		bonus_damage = 4 * 5 # Asumimos Nivel 4 base para el cálculo si es texto
		
	var final_damage = explosion_damage + bonus_damage
	
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	var sq_radius = explosion_radius * explosion_radius # Optimización
	
	# Revisamos si tiene la mejora de la tienda para empujar
	var is_demolitionist = (typeof(meta_upgrade) == TYPE_STRING and meta_upgrade == "4_spec")
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and global_position.distance_squared_to(enemy.global_position) < sq_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(final_damage, lvl >= 5, "fire")
				
				# Aplicar Knockback si es Demolicionista
				if is_demolitionist and enemy.has_method("apply_knockback"):
					var push_dir = global_position.direction_to(enemy.global_position)
					enemy.apply_knockback(push_dir * 300.0) # Fuerza del empuje
				
				# Nivel 4: Explosiones encadenadas
				if lvl >= 4 and randf() < 0.15:
					_spawn_chain_bomb(enemy.global_position, lvl)
	
	_play_visual_effect()

func _spawn_chain_bomb(pos: Vector2, parent_lvl: int) -> void:
	if parent_lvl <= 1: return # Evitar bombas de nivel 0 o infinito
	
	var b = load("res://scenes/seed_bomb.tscn").instantiate()
	get_parent().call_deferred("add_child", b)
	b.global_position = pos
	
	if b.has_method("setup_level"): 
		b.setup_level(parent_lvl - 1) # Pasamos el nivel entero y limpio

func _play_visual_effect() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	var effect = create_tween()
	scale = Vector2(0.1, 0.1)
	
	var target_scale = Vector2(3, 3)
	if lvl >= 5: target_scale = Vector2(8, 8)
	
	effect.tween_property(self, "scale", target_scale, 0.1)
	effect.parallel().tween_property(self, "modulate:a", 0, 0.1)
	
	if AudioManager.has_method("play"):
		AudioManager.play("crit")
		if lvl >= 5: AudioManager.play("crit") # Doble sonido para la nuke
		
	effect.finished.connect(queue_free)
