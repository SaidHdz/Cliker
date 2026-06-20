extends Area2D

var seed_scene = preload("res://scenes/seed_projectile.tscn")
var bomb_scene = preload("res://scenes/seed_bomb.tscn")

func _ready() -> void:
	# Conectarse a la señal de daño del padre (BaseRabanito)
	var parent = get_parent()
	if parent:
		if not parent.has_signal("damaged"):
			# En caso de que se intente conectar antes de definir la señal en el padre
			parent.add_user_signal("damaged", [{"name": "amount", "type": TYPE_INT}])
		parent.connect("damaged", _on_parent_damaged)
		
	# Conectar señal de área para interceptar proyectiles
	area_entered.connect(_on_area_entered)

func _on_parent_damaged(amount: int) -> void:
	var thorns_lvl_val = GameManager.get_skill_level("thorns")
	var thorns_lvl = 4 if typeof(thorns_lvl_val) == TYPE_STRING else thorns_lvl_val
	if thorns_lvl <= 0: return
	
	# Calcular reflejo
	_apply_thorns_reflection(amount, thorns_lvl_val)

func _apply_thorns_reflection(incoming_damage: int, lvl_val: Variant) -> void:
	var lvl = 4 if typeof(lvl_val) == TYPE_STRING else lvl_val
	var reflect_percent = 0.2 + (lvl * 0.1)
	
	# Nivel 3: Activa reflejo más rápido (Aumento del daño reflejado)
	if lvl >= 3:
		reflect_percent *= 1.2
		
	var reflect_damage = int(incoming_damage * reflect_percent)
	
	# Rango de activación de reflejo melee
	var search_radius = 80.0
	if lvl >= 2:
		search_radius = 120.0
		
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < search_radius:
			if e.has_method("take_damage"):
				e.take_damage(reflect_damage, false)
				
				# Nivel 3: Aplica sangrado al atacante (usamos veneno como bypass)
				if lvl >= 3 and e.has_method("apply_poison"):
					e.apply_poison(true)
					
				# Nivel 4 Especial (Meta-Mejora): Dolor Compartido (Mini retroceso)
				if typeof(lvl_val) == TYPE_STRING and lvl_val == "4_spec":
					if e.has_method("apply_knockback"):
						var dir = global_position.direction_to(e.global_position)
						e.apply_knockback(dir * 150.0)
						
	# Nivel 5: Contraataque explosivo
	if lvl >= 5 and randf() < 0.35:
		_spawn_counter_explosion()

func _spawn_counter_explosion() -> void:
	var bomb = bomb_scene.instantiate()
	get_parent().get_parent().call_deferred("add_child", bomb)
	bomb.global_position = global_position
	if bomb.has_method("setup_level"):
		bomb.setup_level(3) # Nivel de potencia de la explosión

func _on_area_entered(area: Area2D) -> void:
	var thorns_lvl_val = GameManager.get_skill_level("thorns")
	var thorns_lvl = 4 if typeof(thorns_lvl_val) == TYPE_STRING else thorns_lvl_val
	
	# Nivel 4: Reflejar proyectiles
	if thorns_lvl >= 4 and area.is_in_group("projectiles"):
		_reflect_projectile(area, thorns_lvl_val)

func _reflect_projectile(proj: Area2D, lvl_val: Variant) -> void:
	var lvl = 4 if typeof(lvl_val) == TYPE_STRING else lvl_val
	var reflected = seed_scene.instantiate()
	
	# Añadir a la escena principal
	get_parent().get_parent().call_deferred("add_child", reflected)
	reflected.global_position = proj.global_position
	
	# Invertir dirección
	var dir = -proj.direction if "direction" in proj else Vector2.UP
	reflected.direction = dir
	reflected.damage = 15 + (lvl * 5)
	
	if reflected.has_method("setup_projectile"):
		reflected.setup_projectile(lvl_val, true) # true para que perfore enemigos
		
	# Sonido visual y borrar proyectil original
	if AudioManager.has_method("play"):
		AudioManager.play("pop")
		
	proj.queue_free()
