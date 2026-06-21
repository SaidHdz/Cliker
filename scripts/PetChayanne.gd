extends CharacterBody2D

@export var move_speed: float = 250.0
@export var damage: int = 15

var max_health: int = 100
var current_health: int = 100

var target: Node2D
var current_level_val: Variant = 1
var attack_timer: Timer

func _ready() -> void:
	z_index = 4
	collision_layer = 0
	collision_mask = 0
	
	current_level_val = GameManager.get_skill_level("pet_chayanne")
	add_to_group("allies")
	
	attack_timer = Timer.new()
	attack_timer.timeout.connect(_on_attack_timer)
	add_child(attack_timer)
	
	_apply_stats()

func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val
	_apply_stats()

var speed_boost_timer: float = 0.0

func apply_compadres_boost() -> void:
	speed_boost_timer = 1.0

func _apply_stats() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	# Afinidad Mascotas: +10% salud máxima
	max_health = 100
	if GameManager.get_deck_affinity() == "Mascotas":
		max_health = int(max_health * 1.10)
	current_health = max_health
	
	var base_time = 0.8
	if lvl >= 5: base_time = 0.4 # Nivel 5: Berserk (Doble cadencia)
	if GameManager.get_deck_affinity() == "Mascotas":
		base_time *= 0.90 # +10% attack speed (10% shorter wait time)
		
	if GameManager.sobrecarga_cuantica_rounds > 0:
		base_time /= 3.0
		
	attack_timer.wait_time = base_time
	if attack_timer.is_stopped(): 
		attack_timer.start()
		
	# Sinergia Escuadrón del Campo: +50% velocidad, tamaño grande y brillo dorado
	if GameManager.has_field_squad:
		move_speed = 375.0
		scale = Vector2(1.3, 1.3)
		modulate = Color(1.3, 1.1, 0.4)
	else:
		move_speed = 250.0
		scale = Vector2(1.0, 1.0)
		modulate = Color.WHITE

func _physics_process(delta: float) -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	var final_speed = move_speed
	
	if lvl >= 5: final_speed *= 2.0
	
	# Sinergia Los Compadres: Incrementar velocidad bajo efecto de boost
	var actual_speed = final_speed
	if speed_boost_timer > 0.0:
		speed_boost_timer -= delta
		actual_speed *= 1.8
	
	if not is_instance_valid(target) or target.current_health <= 0:
		target = _get_closest_enemy()
	
	if is_instance_valid(target):
		var direction = global_position.direction_to(target.global_position)
		var dist_sq = global_position.distance_squared_to(target.global_position)
		
		# Se detiene solo si está a rango de ataque cuerpo a cuerpo (50x50 = 2500)
		if dist_sq < 2500.0:
			velocity = Vector2.ZERO
		elif lvl >= 4 and dist_sq > 10000.0:
			velocity = direction * actual_speed * 3.0
		else:
			velocity = direction * actual_speed
			
		move_and_slide()

func _get_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	# Leemos la meta-tienda para ver si tiene "Manager Profesional"
	var meta_upgrade = GameManager.card_upgrade_levels.get("pet_chayanne", 0)
	var prioritize_boss = (typeof(meta_upgrade) == TYPE_STRING and meta_upgrade == "4_spec")
	
	var closest_normal = null
	var closest_boss = null
	var min_dist_normal = 999999.0
	var min_dist_boss = 999999.0
	
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
			var d_sq = global_position.distance_squared_to(e.global_position)
			var is_boss = ("is_boss" in e and e.is_boss)
			
			if is_boss:
				if d_sq < min_dist_boss:
					min_dist_boss = d_sq
					closest_boss = e
			else:
				if d_sq < min_dist_normal:
					min_dist_normal = d_sq
					closest_normal = e

	if prioritize_boss and closest_boss != null:
		return closest_boss
	elif closest_normal != null:
		return closest_normal
	else:
		return closest_boss

func _on_attack_timer() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	if is_instance_valid(target) and global_position.distance_squared_to(target.global_position) < 6400.0:
		
		# Cálculo de Daño: Daño Base de Chayanne + Daño del Rábano
		var base_dmg = damage + GameManager.meta_base_damage
		
		# Bono pasivo de la Meta-Tienda
		var meta_bonus = GameManager.get_card_upgrade_int_level("pet_chayanne") * 3
		var final_damage = base_dmg + meta_bonus + (lvl * 10)
		
		# Nivel 2 en partida: Entrenamiento de Combate (+50% Daño)
		if lvl >= 2: final_damage = int(final_damage * 1.5)
		
		# Sinergia Escuadrón del Campo: +50% Daño
		if GameManager.has_field_squad:
			final_damage = int(final_damage * 1.5)
		
		target.take_damage(int(final_damage))
		
		# Sinergia Los Compadres: Dar velocidad al otro aliado
		if GameManager.has_los_compadres:
			for ally in get_tree().get_nodes_in_group("allies"):
				if ally != self and ally.has_method("apply_compadres_boost"):
					ally.apply_compadres_boost()
		
		# Nivel 3: Ataque en área
		if lvl >= 3:
			_aoe_attack(int(final_damage * 0.5))
			
		# Animación de ataque (Escalar)
		var t = create_tween()
		var target_scale = Vector2(1.8, 1.8) if GameManager.has_field_squad else Vector2(1.4, 1.4)
		var orig_scale = Vector2(1.3, 1.3) if GameManager.has_field_squad else Vector2(1.0, 1.0)
		t.tween_property(self, "scale", target_scale, 0.1)
		t.tween_property(self, "scale", orig_scale, 0.1)

func _aoe_attack(dmg: int) -> void:
	# Rango de área de 100 (100 * 100 = 10000)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e != target and global_position.distance_squared_to(e.global_position) < 10000.0:
			e.take_damage(dmg)
