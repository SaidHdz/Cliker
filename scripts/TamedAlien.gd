extends CharacterBody2D

@export var move_speed: float = 120.0
@export var damage: int = 15

var max_health: int = 100
var current_health: int = 100

var target: Node2D
var current_level_val: Variant = 1
var attack_timer: Timer
var shoot_timer: Timer

func _ready() -> void:
	z_index = 4
	collision_layer = 0
	collision_mask = 0
	
	current_level_val = GameManager.get_skill_level("tamed_alien")
	add_to_group("allies")
	
	if GameManager.shaders_enabled:
		var shader = preload("res://shaders/outline.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("outline_color", Color(1.0, 1.0, 1.0, 1.0))
		mat.set_shader_parameter("outline_width", 1.5)
		for child in get_children():
			if child is Sprite2D or child is AnimatedSprite2D:
				child.material = mat
	
	attack_timer = Timer.new()
	attack_timer.wait_time = 1.0
	attack_timer.timeout.connect(_melee_attack)
	add_child(attack_timer)
	attack_timer.start()

func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val
	var lvl = 4 if typeof(lvl_val) == TYPE_STRING else lvl_val
	
	# Integra el daño del Rábano y las mejoras permanentes
	var base_dmg = damage + GameManager.meta_base_damage
	var meta_bonus = GameManager.get_card_upgrade_int_level("tamed_alien") * 3
	damage = base_dmg + meta_bonus
	
	if lvl >= 2: damage = int(damage * 1.5)
	if lvl >= 3: move_speed *= 1.5
	
	# Sinergia Escuadrón del Campo
	if GameManager.has_field_squad:
		damage = int(damage * 1.5)
		move_speed *= 1.5
		scale = Vector2(1.3, 1.3)
		modulate = Color(1.3, 1.1, 0.4)
	else:
		scale = Vector2(1.0, 1.0)
		modulate = Color.WHITE
		
	# Afinidad Mascotas: +10% salud máxima y +10% velocidad de ataque
	max_health = 100
	if GameManager.get_deck_affinity() == "Mascotas":
		max_health = int(max_health * 1.10)
	current_health = max_health
	
	var base_attack_time = 1.0 * (0.90 if GameManager.get_deck_affinity() == "Mascotas" else 1.0)
	if GameManager.sobrecarga_cuantica_rounds > 0:
		base_attack_time /= 3.0
	if is_instance_valid(attack_timer):
		attack_timer.wait_time = base_attack_time
	
	if lvl >= 4:
		if not is_instance_valid(shoot_timer):
			shoot_timer = Timer.new()
			shoot_timer.timeout.connect(_shoot_acid)
			add_child(shoot_timer)
		var base_shoot_time = 2.0 * (0.90 if GameManager.get_deck_affinity() == "Mascotas" else 1.0)
		if GameManager.sobrecarga_cuantica_rounds > 0:
			base_shoot_time /= 3.0
		shoot_timer.wait_time = base_shoot_time
		if shoot_timer.is_stopped():
			shoot_timer.start()
		
	if lvl >= 5:
		_summon_minis()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.current_health <= 0:
		target = _get_closest_enemy()
	
	if is_instance_valid(target):
		var direction = global_position.direction_to(target.global_position)
		var dist_sq = global_position.distance_squared_to(target.global_position)
		
		# Se detiene solo si está a rango de ataque cuerpo a cuerpo (50x50 = 2500)
		if dist_sq < 2500.0:
			velocity = Vector2.ZERO
		else:
			velocity = direction * move_speed
		
		move_and_slide()

func _get_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_normal = null
	var closest_special = null
	var min_dist_normal = 999999.0
	var min_dist_special = 999999.0
	
	# Verificamos si tiene la mejora de la tienda (Nivel 4 Especial)
	var meta_upgrade = GameManager.card_upgrade_levels.get("tamed_alien", 0)
	var prioritizes_specials = (typeof(meta_upgrade) == TYPE_STRING and meta_upgrade == "4_spec")
	
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
			var d_sq = global_position.distance_squared_to(e.global_position)
			
			# ¡Aquí está la corrección!
			var is_special = ("current_variant" in e and e.current_variant != 0) or ("is_boss" in e and e.is_boss)
			
			if is_special:
				if d_sq < min_dist_special:
					min_dist_special = d_sq
					closest_special = e
			else:
				if d_sq < min_dist_normal:
					min_dist_normal = d_sq
					closest_normal = e

	if prioritizes_specials and closest_special != null:
		return closest_special
	elif closest_normal != null:
		return closest_normal
	else:
		return closest_special # Por si solo quedan especiales en pantalla

func _melee_attack() -> void:
	if is_instance_valid(target) and global_position.distance_squared_to(target.global_position) < 3600.0: # Rango de 60
		target.take_damage(damage)
		
		var t = create_tween()
		t.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		t.tween_property(self, "scale", Vector2(1, 1), 0.1)

func _shoot_acid() -> void:
	if is_instance_valid(target):
		var bullet = load("res://scenes/seed_projectile.tscn").instantiate()
		get_parent().call_deferred("add_child", bullet)
		bullet.global_position = global_position
		bullet.direction = global_position.direction_to(target.global_position)
		bullet.damage = int(damage * 0.8) # Que el disparo haga un poco menos de daño que el puñetazo
		bullet.modulate = Color.GREEN
		
		if bullet.has_method("setup_projectile"): 
			# Simulamos un nivel para que sepa cómo comportarse
			bullet.setup_projectile(1, false) 

func _summon_minis() -> void:
	for i in range(2):
		var mini = load("res://scenes/allies/tamed_alien.tscn").instantiate()
		get_parent().call_deferred("add_child", mini)
		mini.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		
		# Precaución de Godot: Escalar CharacterBody2D puede causar bugs de colisión en móviles.
		# Lo mejor es que la escala se aplique al nodo visual si ves que se atoran.
		mini.scale = Vector2(0.6, 0.6) 
		
		if mini.has_method("setup_level"): 
			# Le pasamos Nivel 1 para que no sigan invocando minis infinitamente
			mini.setup_level(1)
