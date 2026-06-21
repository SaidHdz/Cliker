extends CharacterBody2D

@export var move_speed: float = 150.0
@export var damage: int = 5

var max_health: int = 100
var current_health: int = 100

var target: Node2D
var current_level_val: Variant = 1
var shoot_timer: Timer
var retarget_timer: float = 0.0
var speed_boost_timer: float = 0.0

func apply_compadres_boost() -> void:
	speed_boost_timer = 1.0

func _ready() -> void:
	z_index = 4
	collision_layer = 0
	collision_mask = 0
	
	current_level_val = GameManager.get_skill_level("pet_minigun")
	add_to_group("allies")
	
	shoot_timer = Timer.new()
	shoot_timer.timeout.connect(_shoot)
	add_child(shoot_timer)
	
	_apply_stats()

# Agregamos setup_level para que coincida con tu arquitectura
func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val
	_apply_stats()

func _apply_stats() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	# Daño Base = Daño de la mascota + Daño comprado en la Tienda Permanente del Rábano
	damage = 5 + GameManager.meta_base_damage
	
	# Sumamos el bono pasivo de la Meta-Tienda de Cartas (Nivel permanente de Pet Minigun)
	var meta_bonus = GameManager.get_card_upgrade_int_level("pet_minigun") * 2
	damage += meta_bonus
	
	# Nivel 2 de la partida: Munición explosiva (Daño masivo)
	if lvl >= 2: damage = int(damage * 1.5) 
	
	# Sinergia Escuadrón del Campo
	if GameManager.has_field_squad:
		damage = int(damage * 1.5)
		move_speed = 225.0
		scale = Vector2(1.3, 1.3)
		modulate = Color(1.3, 1.1, 0.4)
	else:
		move_speed = 150.0
		scale = Vector2(1.0, 1.0)
		modulate = Color.WHITE
	
	# Afinidad Mascotas: +10% salud máxima
	max_health = 100
	if GameManager.get_deck_affinity() == "Mascotas":
		max_health = int(max_health * 1.10)
	current_health = max_health
	
	# Nivel 3 de la partida: Gatillo fácil (más cadencia)
	var fire_rate = 0.5
	if lvl >= 3: fire_rate = 0.25 
	if lvl >= 5: fire_rate = 0.08 # Nivel 5: Modo Rambo (frenesí de disparo)
	if GameManager.get_deck_affinity() == "Mascotas":
		fire_rate *= 0.90 # +10% attack speed (10% shorter wait time)
		
	if GameManager.sobrecarga_cuantica_rounds > 0:
		fire_rate /= 3.0
	
	shoot_timer.wait_time = fire_rate
	if shoot_timer.is_stopped(): shoot_timer.start()

func _physics_process(delta: float) -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	# Reloj interno a prueba de lag para re-evaluar objetivo
	retarget_timer += delta
	var time_to_retarget = 1.0
	if lvl >= 3: time_to_retarget = 0.5 # Nivel 3: Cambia de objetivo el doble de rápido
	
	if retarget_timer >= time_to_retarget:
		target = null # Forzar re-búsqueda
		retarget_timer = 0.0
		
	if not is_instance_valid(target) or target.current_health <= 0:
		target = _get_closest_enemy()
	
	if is_instance_valid(target):
		var dist_sq = global_position.distance_squared_to(target.global_position)
		var optimal_dist_max_sq = 40000.0 # 200 * 200
		var optimal_dist_min_sq = 10000.0 # 100 * 100
		
		# Nivel 2: Mayor rango
		if lvl >= 2:
			optimal_dist_max_sq = 90000.0 # 300 * 300
			optimal_dist_min_sq = 40000.0 # 200 * 200
			
		var dir = global_position.direction_to(target.global_position)
		
		# Sinergia Los Compadres: Aplicar velocidad de boost
		var actual_speed = move_speed
		if speed_boost_timer > 0.0:
			speed_boost_timer -= delta
			actual_speed *= 1.8
			
		if dist_sq > optimal_dist_max_sq:
			velocity = dir * actual_speed
			move_and_slide()
		elif dist_sq < optimal_dist_min_sq:
			velocity = -dir * actual_speed
			move_and_slide()

func _get_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	var prioritize_boss = (typeof(current_level_val) == TYPE_STRING and current_level_val == "4_spec")
	
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

func _shoot() -> void:
	if not is_instance_valid(target): return
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	var bullet = load("res://scenes/seed_projectile.tscn").instantiate()
	get_parent().call_deferred("add_child", bullet)
	bullet.global_position = global_position
	bullet.direction = global_position.direction_to(target.global_position)
	bullet.damage = damage
	bullet.modulate = Color(0.8, 0.8, 0.8) # Gris metálico
	
	# Nivel 4: Disparos atraviesan
	if lvl >= 4 and bullet.has_method("setup_projectile"):
		bullet.setup_projectile(current_level_val, true) # true es el flag de pierce en tu arquitectura
		
	# Sinergia Los Compadres: Dar velocidad al otro aliado
	if GameManager.has_los_compadres:
		for ally in get_tree().get_nodes_in_group("allies"):
			if ally != self and ally.has_method("apply_compadres_boost"):
				ally.apply_compadres_boost()
	
	if AudioManager.has_method("play"): AudioManager.play("pop")
	
	# Retroceso visual
	var t = create_tween()
	t.tween_property(self, "position", position - (bullet.direction * 5), 0.05)
	t.tween_property(self, "position", position, 0.05)
