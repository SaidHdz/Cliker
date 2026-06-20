extends Area2D

# --- VARIABLES DE ESTADÍSTICAS ---
enum EnemyVariant { NORMAL, TANK, RUNNER, KAMIKAZE, TROJAN, HEALER, SNIPER, MINER }
@export var current_variant: EnemyVariant = EnemyVariant.NORMAL
@export var base_hp_mult: float = 1.0
@export var base_speed_mult: float = 1.0
@export var custom_texture: Texture2D # <-- Para asignar sprites únicos fácilmente

@export var max_health: int = 10
var current_health: int = 0
@export var is_boss: bool = false
var coin_multiplier: int = 1

# --- VARIABLES DE MOVIMIENTO ---
var velocity: Vector2 = Vector2.ZERO
@export var move_speed: float = 50.0
var target_base: Node2D
var dispersion_velocity: Vector2 = Vector2.ZERO
var is_underground: bool = false
var is_lazy: bool = false

# --- COMPONENTES ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var coin_scene = preload("res://scenes/coin.tscn")
@onready var damage_number_scene = preload("res://scenes/damage_number.tscn")
@onready var toxic_shot_scene = preload("res://scenes/toxic_shot.tscn")

var original_sprite_scale: Vector2
var hit_tween: Tween
var attack_timer: Timer
var shot_timer: Timer
var is_attacking: bool = false
var damage_to_base: int = 1
var lightning_overlay: ColorRect

# --- VARIABLES DE ESTADOS (ROGUELITE) ---
var is_stunned: bool = false
var stun_timer: Timer
var is_invulnerable: bool = false 
var fire_timer: Timer
var fire_ticks: int = 0
var is_frozen: bool = false
var frost_timer: Timer
var original_move_speed: float
var is_poisoned: bool = false
var poison_timer: Timer
var poison_ticks: int = 0
var bleed_timer: Timer
var bleed_ticks: int = 0
var has_shield: bool = false
var is_enraged: bool = false
var is_electrified: bool = false

@onready var estados_container: HBoxContainer = get_node_or_null("estados")

# Caching de iconos de estados para mejorar el rendimiento
var icon_fuego: TextureRect
var icon_hielo: TextureRect
var icon_rayo: TextureRect
var icon_veneno: TextureRect
var icon_enojo: TextureRect
var icon_escudo: TextureRect

func _ready() -> void:
	is_lazy = randf() < 0.50
	z_index = 10 
	original_sprite_scale = anim.scale
	
	# Ocultar todos los estados al inicio y guardar referencias en caché
	if estados_container:
		icon_fuego = estados_container.get_node_or_null("fuego")
		icon_hielo = estados_container.get_node_or_null("hielo")
		icon_rayo = estados_container.get_node_or_null("rayo")
		icon_veneno = estados_container.get_node_or_null("veneno")
		icon_enojo = estados_container.get_node_or_null("enojo")
		icon_escudo = estados_container.get_node_or_null("escudo")
		
		for child in estados_container.get_children():
			child.visible = false
			
	# --- APLICAR TEXTURA PERSONALIZADA ---
	if custom_texture and is_instance_valid(anim):
		var new_frames = anim.sprite_frames.duplicate(true)
		if new_frames.has_animation("run"):
			new_frames.clear("run")
		else:
			new_frames.add_animation("run")
		new_frames.add_frame("run", custom_texture)
		anim.sprite_frames = new_frames
	
	# Setup Lightning Overlay (SHADER) - Mantenemos esto como efecto visual extra si quieres
	lightning_overlay = ColorRect.new()
	lightning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lightning_overlay.visible = false
	add_child(lightning_overlay)
	
	var sh = Shader.new()
	sh.code = "shader_type canvas_item;
	void fragment() {
		COLOR = vec4(0.5, 0.9, 1.0, 0.7 * (0.5 + 0.5 * sin(TIME * 20.0)));
	}"
	var mat = ShaderMaterial.new(); mat.shader = sh
	lightning_overlay.material = mat
	lightning_overlay.size = Vector2(80, 80)
	lightning_overlay.position = -lightning_overlay.size / 2.0
	
	# ESCALADO POR OLEADA
	var wave = GameManager.current_wave
	var scaled_hp = int(20 * pow(1.25, wave - 1)) # Nuevo base scaling 1.25
	if is_boss:
		max_health = scaled_hp * 8 # Jefe es x8 de la vida normal de la oleada
	else:
		max_health = int(scaled_hp * base_hp_mult)
	
	move_speed = move_speed * base_speed_mult
	original_move_speed = move_speed
	
	# Inicializar timer de Stun
	stun_timer = Timer.new()
	stun_timer.one_shot = true
	stun_timer.timeout.connect(func(): is_stunned = false)
	add_child(stun_timer)
	
	add_to_group("enemies")
	z_index = 4
	current_health = max_health
	health_bar.max_value = max_health; health_bar.value = current_health
	target_base = get_tree().get_first_node_in_group("BaseRabanito")
	
	attack_timer = Timer.new(); attack_timer.wait_time = 1.0; attack_timer.timeout.connect(_on_attack_timer_timeout); add_child(attack_timer)
	fire_timer = Timer.new(); fire_timer.wait_time = 1.0; fire_timer.timeout.connect(_on_fire_tick); add_child(fire_timer)
	frost_timer = Timer.new(); frost_timer.wait_time = 3.0; frost_timer.one_shot = true; frost_timer.timeout.connect(_on_frost_timeout); add_child(frost_timer)
	poison_timer = Timer.new(); poison_timer.wait_time = 1.0; poison_timer.timeout.connect(_on_poison_tick); add_child(poison_timer)
	bleed_timer = Timer.new(); bleed_timer.wait_time = 1.0; bleed_timer.timeout.connect(_on_bleed_tick); add_child(bleed_timer)
	shot_timer = Timer.new(); shot_timer.wait_time = 3.0; shot_timer.timeout.connect(_on_special_timer_timeout); add_child(shot_timer)
	
	if current_variant == EnemyVariant.SNIPER or current_variant == EnemyVariant.HEALER: shot_timer.start()
	if current_variant == EnemyVariant.MINER:
		enter_underground()
		var spawn_area = get_node_or_null("area_spawn")
		if is_instance_valid(spawn_area):
			spawn_area.area_entered.connect(_on_spawn_area_entered)

	input_event.connect(_on_input_event)

func _physics_process(delta: float) -> void:
	_update_states_visibility()
	if current_health <= 0 or is_attacking or is_frozen: 
		velocity = Vector2.ZERO
		move_with_dispersion(delta)
		return
	
	if is_instance_valid(target_base):
		var move_target = target_base.global_position
		var move_to_base = true
		
		if current_variant == EnemyVariant.HEALER:
			var closest_ally = null
			var min_dist_sq = 999999.0
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e != self and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
					var dist_sq = global_position.distance_squared_to(e.global_position)
					if dist_sq < min_dist_sq:
						min_dist_sq = dist_sq
						closest_ally = e
			if closest_ally != null:
				var dist_sq = global_position.distance_squared_to(closest_ally.global_position)
				if dist_sq < 6400.0: # 80 * 80
					velocity = Vector2.ZERO
					move_to_base = false
				else:
					move_target = closest_ally.global_position
		
		elif current_variant == EnemyVariant.SNIPER:
			var dist = global_position.distance_to(target_base.global_position)
			if dist <= 290.0:
				velocity = Vector2.ZERO
				move_to_base = false
				
		var current_speed = move_speed
		if GameManager.sindicato_alien_rounds > 0 and is_lazy:
			current_speed *= 0.10
			# La mitad de los flojos se quedan quietos y se sientan/paran (idle)
			if int(global_position.x) % 2 == 0:
				current_speed = 0.0
				anim.play("idle")
				
		if move_to_base:
			var direction = global_position.direction_to(move_target)
			velocity = direction * current_speed
			
		# Flip sprite
		var flip_dir = global_position.direction_to(target_base.global_position)
		if flip_dir.x < 0: anim.flip_h = true
		else: anim.flip_h = false
		
		global_position += velocity * delta
	
	move_with_dispersion(delta)

func _update_states_visibility() -> void:
	if not estados_container: return
	if icon_fuego: icon_fuego.visible = fire_ticks > 0
	if icon_hielo: icon_hielo.visible = is_frozen
	if icon_rayo: icon_rayo.visible = (lightning_overlay.visible if is_instance_valid(lightning_overlay) else false)
	if icon_veneno: icon_veneno.visible = poison_ticks > 0
	if icon_enojo: icon_enojo.visible = is_enraged
	if icon_escudo: icon_escudo.visible = has_shield

func take_damage(amount: int, is_crit: bool = false, type: String = "normal") -> void:
	if current_health <= 0 or is_underground or is_invulnerable: return
	
	if has_shield and type != "electric": # Ejemplo: rayo rompe escudo
		amount = int(amount * 0.2)
	
	# Track stats
	GameManager.increment_stat("total_damage", amount)
	if is_crit:
		GameManager.increment_stat("total_crit_damage", amount)
		if amount > GameManager.profile_stats.get("max_crit_damage", 0):
			GameManager.profile_stats["max_crit_damage"] = amount
			GameManager.save_game()
			
	current_health -= amount
	health_bar.value = current_health
	
	# --- EFECTO DE REBOTE (VISUAL) ---
	var bounce_tween = create_tween()
	bounce_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	bounce_tween.tween_property(anim, "scale", original_sprite_scale * 1.2, 0.1)
	bounce_tween.tween_property(anim, "scale", original_sprite_scale, 0.2)

	if GameManager.has_fire_slice: apply_fire()
	spawn_damage_number(amount, is_crit, type)
	
	if not is_boss: anim.play("idle")
	
	if hit_tween and hit_tween.is_valid(): hit_tween.kill()
	hit_tween = create_tween()
	# Solo modulamos el Sprite, no todo el nodo (asi los iconos de estados no parpadean)
	hit_tween.tween_property(anim, "modulate", Color(5, 5, 5, 1), 0.05)
	hit_tween.tween_property(anim, "modulate", Color.WHITE, 0.1)
	
	if current_health <= 0: call_deferred("die")

func apply_fire() -> void:
	if is_frozen: return
	if fire_ticks <= 0: fire_timer.start()
	var ticks = 3
	if GameManager.get_deck_affinity() == "Elemental":
		ticks += 1
	fire_ticks = ticks

func _on_fire_tick() -> void:
	if current_health > 0:
		var current_lvl = GameManager.get_skill_level("fire_slice")
		var meta_bonus = GameManager.get_card_upgrade_int_level("fire_slice") * 1
		var burn_damage = int(max_health * 0.05) + (current_lvl * 2) + meta_bonus
		
		# Nivel 2: +50% daño de quemadura
		if current_lvl >= 2: burn_damage = int(burn_damage * 1.5)
		
		take_damage(burn_damage, false, "fire")
		
		# Nivel 4: El fuego se propaga
		if current_lvl >= 4:
			for e in get_tree().get_nodes_in_group("enemies"):
				if e != self and is_instance_valid(e) and global_position.distance_to(e.global_position) < 80:
					if e.has_method("apply_fire"): e.apply_fire()
		
		fire_ticks -= 1
		if fire_ticks <= 0: fire_timer.stop()

func apply_frost() -> void:
	is_frozen = true
	frost_timer.start()

func _on_frost_timeout() -> void:
	is_frozen = false

func apply_poison(extra_duration: bool = false) -> void:
	if poison_ticks <= 0: poison_timer.start()
	var ticks = 6 if extra_duration else 5
	if GameManager.has_radioactive_swamp:
		ticks += 4
	if GameManager.get_deck_affinity() == "Elemental":
		ticks += 1
	poison_ticks = ticks

func _on_poison_tick() -> void:
	if current_health > 0:
		take_damage(int(max_health * 0.03), false, "poison")
		
		# Sinergia Pantano Radioactivo: Contagiar a enemigos cercanos
		if GameManager.has_radioactive_swamp:
			for e in get_tree().get_nodes_in_group("enemies"):
				if e != self and is_instance_valid(e) and "current_health" in e and e.current_health > 0:
					if global_position.distance_squared_to(e.global_position) < 14400.0:
						if e.has_method("apply_poison") and randf() < 0.40:
							e.apply_poison()
							
		poison_ticks -= 1
		if poison_ticks <= 0: poison_timer.stop()

func apply_bleed() -> void:
	var is_spec = (GameManager.card_upgrade_levels.get("damage_boost", 0) == "4_spec")
	var ticks = 5 if is_spec else 3
	if bleed_ticks <= 0: bleed_timer.start()
	bleed_ticks = ticks

func _on_bleed_tick() -> void:
	if current_health > 0:
		var lvl = GameManager.get_skill_level("damage_boost")
		var meta_lvl = GameManager.get_card_upgrade_int_level("damage_boost")
		var is_spec = (GameManager.card_upgrade_levels.get("damage_boost", 0) == "4_spec")
		
		# Daño escala con nivel de run, meta nivel y maestría
		var multiplier = 1.0 + (lvl - 1) * 0.2 + meta_lvl * 0.2
		if is_spec: multiplier += 0.4
		
		var base_damage = int((5 + int(GameManager.click_damage * 0.2)) * multiplier)
		var is_moving = velocity.length_squared() > 100.0
		if is_moving:
			base_damage *= 2
		take_damage(base_damage, false, "normal")
		
		bleed_ticks -= 1
		if bleed_ticks <= 0: bleed_timer.stop()

func spawn_damage_number(amount: int, is_crit: bool = false, type: String = "normal") -> void:
	if not GameManager.damage_numbers_enabled:
		return
	# Si hay demasiados números en pantalla, descartar golpes normales para ahorrar CPU
	if not is_crit and GameManager.active_damage_numbers > 40:
		return
		
	var l = damage_number_scene.instantiate(); get_tree().current_scene.add_child(l)
	if l.has_method("set_values"): l.set_values(amount, is_crit, global_position + Vector2(randf_range(-20, 20), -40), type)

func apply_lightning_effect() -> void:
	is_electrified = true
	if GameManager.has_ajo_negativo and has_method("apply_fire"):
		apply_fire()
	if is_instance_valid(lightning_overlay):
		lightning_overlay.visible = true
		var t = create_tween()
		t.tween_property(lightning_overlay, "modulate:a", 1.0, 0.05)
		t.tween_property(lightning_overlay, "modulate:a", 0.0, 0.2)
		t.finished.connect(func(): if is_instance_valid(lightning_overlay): lightning_overlay.visible = false)

func kamikaze_attack() -> void:
	if current_variant == EnemyVariant.KAMIKAZE:
		if is_instance_valid(target_base): target_base.take_damage(30)
		die()
		return
	if not is_attacking and current_health > 0:
		is_attacking = true
		anim.play("idle")
		attack_timer.start()

func interrupt_attack() -> void:
	if is_attacking:
		is_attacking = false
		attack_timer.stop()
		if current_health > 0: anim.play("run")

func _on_attack_timer_timeout() -> void:
	if current_health <= 0: attack_timer.stop(); return
	
	# Verificar si está atrapado en un agujero negro
	var in_black_hole = false
	for area in get_overlapping_areas():
		if area.name.begins_with("BlackHole"):
			in_black_hole = true
			break
			
	if in_black_hole:
		interrupt_attack()
		return
		
	if is_instance_valid(target_base) and target_base.has_method("take_damage"):
		target_base.take_damage(damage_to_base)
		var t = create_tween()
		var d = (target_base.global_position - global_position).normalized()
		t.tween_property(anim, "position", d * 15, 0.1)
		t.tween_property(anim, "position", Vector2.ZERO, 0.2)
	else:
		attack_timer.stop(); is_attacking = false; anim.play("run")

func apply_knockback(force_vector: Vector2) -> void:
	if is_boss:
		dispersion_velocity += force_vector * 0.2 # Resistencia al empuje (80% menos)
	else:
		dispersion_velocity += force_vector

func die() -> void:
	var current_fire_lvl = GameManager.get_skill_level("fire_slice")
	
	# Nivel 3 Corte Hot: Explosión al morir si está quemado
	if (current_fire_lvl >= 3 and fire_ticks > 0) or (GameManager.has_ajo_negativo and is_electrified):
		_spawn_fire_explosion()
	
	# Nivel 5 Corte Hot: Brasas permanentes
	if current_fire_lvl >= 5 and fire_ticks > 0:
		_spawn_embers()
		
	# Abono Tóxico: Soltar charco de ácido al morir (por probabilidad de 40%)
	if GameManager.has_toxic_compost and randf() < 0.40:
		_spawn_acid_puddle()

	if is_boss:
		GameManager.notify_enemy_defeated(8)
	else:
		GameManager.notify_enemy_defeated(current_variant)
	
	# El Minero suelta el doble de loot
	if current_variant == EnemyVariant.MINER:
		coin_multiplier = 2
		spawn_loot(10) # 10 monedas extra fijas
	
	if current_variant == EnemyVariant.TROJAN:
		spawn_mini_aliens()

	spawn_loot()
	queue_free()

func _spawn_fire_explosion() -> void:
	var explosion_range = 100.0
	var explosion_damage = int(max_health * 0.2)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e != self and global_position.distance_to(e.global_position) < explosion_range:
			if e.has_method("take_damage"): e.take_damage(explosion_damage, true, "fire")

func _spawn_embers() -> void:
	var fw_scene = load("res://scenes/fire_wall.tscn")
	if is_instance_valid(fw_scene):
		var fw = fw_scene.instantiate()
		get_parent().call_deferred("add_child", fw)
		fw.global_position = global_position
		if "duration" in fw: fw.duration = 5.0

func spawn_mini_aliens() -> void:
	# Usamos un bucle para delegar el spawn de forma segura
	for i in range(4):
		call_deferred("_spawn_single_mini")

func _spawn_acid_puddle() -> void:
	var acid = load("res://scenes/acid_puddle.tscn").instantiate()
	acid.z_index = 2
	get_parent().call_deferred("add_child", acid)
	acid.global_position = global_position

func _spawn_single_mini() -> void:
	var main = get_tree().current_scene
	if main.has_method("spawn_variant_at"):
		var mini = main.spawn_variant_at(EnemyVariant.NORMAL, global_position)
		if is_instance_valid(mini):
			# 1. Empuje violento (Se esparcen)
			if "dispersion_velocity" in mini:
				var push_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				mini.dispersion_velocity = push_dir * 800.0
				
			# 2. I-Frames (Invulnerables por 0.3s para que tu dedo no los mate al instante)
			if "is_invulnerable" in mini:
				mini.is_invulnerable = true
				mini.modulate = Color(1, 1, 1, 0.5) # Se ven semi-transparentes al nacer
				var t = mini.get_tree().create_timer(0.3)
				t.timeout.connect(func():
					if is_instance_valid(mini):
						mini.is_invulnerable = false
						mini.modulate = Color.WHITE
				)

func spawn_loot(extra_coins: int = 0) -> void:
	var coin_count = (randi() % 3 + 1) * coin_multiplier + extra_coins
	
	# Agrupación de botín para reducir drásticamente los RigidBody2D simultáneos
	var coins_to_spawn = 1
	var value_per_coin = coin_count
	
	if coin_count > 6:
		coins_to_spawn = 2
		value_per_coin = int(coin_count / 2)
	elif coin_count > 3:
		coins_to_spawn = 1
		value_per_coin = coin_count
		
	for i in range(coins_to_spawn):
		var c = coin_scene.instantiate()
		c.value = value_per_coin
		# Escalar un poco la moneda si representa un valor más alto
		if value_per_coin > 1:
			c.scale = Vector2(2.0, 2.0) * min(2.0, 1.0 + (value_per_coin * 0.05))
		get_parent().call_deferred("add_child", c)
		c.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))

func enter_underground() -> void:
	is_underground = true
	modulate.a = 0.3 # Visual semi-transparente
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	# Timer desactivado: ahora solo sale por colisión con area_spawn

func exit_underground() -> void:
	is_underground = false
	modulate.a = 1.0
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

func _on_special_timer_timeout() -> void:
	if current_health <= 0: return
	
	# Si está atrapado en un agujero negro, no dispara ni cura
	var in_black_hole = false
	for area in get_overlapping_areas():
		if area.name.begins_with("BlackHole"):
			in_black_hole = true
			break
			
	if in_black_hole: return
	
	if current_variant == EnemyVariant.SNIPER and is_instance_valid(target_base):
		var dist = global_position.distance_to(target_base.global_position)
		if dist > 290.0:
			return # No disparar si está fuera de rango (ej. fue empujado)
			
		var s = toxic_shot_scene.instantiate()
		get_parent().add_child(s)
		s.global_position = global_position
		if s.has_method("set_target"): s.set_target(target_base.global_position)
		s.add_to_group("enemies")
		
	elif current_variant == EnemyVariant.HEALER:
		var heal_range_sq = 40000.0 # 200 * 200 (Mejor rendimiento)
		
		for e in get_tree().get_nodes_in_group("enemies"):
			# Blindaje anti-crashes: Verificamos que tenga vida actual, vida máxima y barra de salud
			if is_instance_valid(e) and e != self and "current_health" in e and "max_health" in e and "health_bar" in e:
				if global_position.distance_squared_to(e.global_position) < heal_range_sq:
					e.current_health = min(e.current_health + 10, e.max_health)
					e.health_bar.value = e.current_health

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_underground: return # No se puede clickear bajo tierra
	
	var is_click = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var is_touch = (event is InputEventScreenTouch and event.pressed)
	
	if is_click or is_touch:
		var final_damage = int(GameManager.click_damage * GameManager.prestige_multiplier)
		take_damage(final_damage)

func move_with_dispersion(delta: float) -> void:
	if dispersion_velocity.length_squared() > 25.0: # Optimización que evita calcular raíz cuadrada
		global_position += dispersion_velocity * delta
		dispersion_velocity = dispersion_velocity.lerp(Vector2.ZERO, delta * 4.0)
	else:
		dispersion_velocity = Vector2.ZERO

func apply_stun(duration: float = 2.0) -> void:
	if current_health <= 0 or is_underground: return
	is_stunned = true
	stun_timer.wait_time = duration
	stun_timer.start()
	anim.play("idle")

func _on_spawn_area_entered(area: Area2D) -> void:
	if is_underground:
		if is_instance_valid(target_base) and (area == target_base or area.get_parent() == target_base):
			exit_underground()
