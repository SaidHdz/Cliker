extends Node2D

var current_level_val: Variant = 1
var attack_timer: Timer
var orbital_ray_timer: Timer
var locked_target: Node2D # Variable para guardar al enemigo si tenemos "Objetivo Fijado"

func _ready() -> void:
	pass

func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val
	var lvl = 4 if typeof(lvl_val) == TYPE_STRING else lvl_val
	
	if not attack_timer:
		attack_timer = Timer.new()
		add_child(attack_timer)
		attack_timer.timeout.connect(_fire_lasers)
	
	# Nivel 4 de carta: Sobrecarga de sistemas (Mitad de tiempo de recarga)
	var fire_rate = 2.0
	if lvl >= 4: fire_rate = 1.0 
	
	attack_timer.wait_time = fire_rate
	if attack_timer.is_stopped(): attack_timer.start() # Previene que se reinicie el contador si ya estaba andando
	
	if lvl >= 5 and not orbital_ray_timer:
		orbital_ray_timer = Timer.new()
		orbital_ray_timer.wait_time = 10.0
		orbital_ray_timer.timeout.connect(_fire_orbital_ray)
		add_child(orbital_ray_timer)
		orbital_ray_timer.start()

func _fire_lasers() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	var meta_upgrade = GameManager.card_upgrade_levels.get("satellite", 0)
	var is_locked_on = (typeof(meta_upgrade) == TYPE_STRING and meta_upgrade == "4_spec")
	
	var num_lasers = 1
	if lvl >= 3: num_lasers = 2 # Nivel 3 de carta: Mira dual (dos disparos a la vez)
	
	var damage = 20
	if lvl >= 2: damage = 40 # Nivel 2 de carta: Láseres concentrados
	
	for i in range(num_lasers):
		var target = null
		
		# Lógica de la mejora 4_spec: Objetivo Fijado
		if is_locked_on:
			if not is_instance_valid(locked_target) or locked_target.current_health <= 0:
				locked_target = _get_random_enemy() # Buscar uno nuevo si el viejo murió
			target = locked_target
		else:
			target = _get_random_enemy() # Comportamiento normal errático
			
		if target:
			_draw_laser(target.global_position, lvl)
			if target.has_method("take_damage"):
				target.take_damage(damage)
			
			if GameManager.has_orbital_satellite:
				_fire_orbital_turret_bullets(target)

func _fire_orbital_turret_bullets(target: Node2D) -> void:
	if not is_instance_valid(target): return
	var seed_scene = preload("res://scenes/seed_projectile.tscn")
	var count = 6
	for i in range(count):
		var bullet = seed_scene.instantiate()
		bullet.z_index = 10
		get_parent().add_child(bullet)
		bullet.global_position = target.global_position
		bullet.direction = Vector2.RIGHT.rotated((PI * 2 / count) * i)
		bullet.damage = 8
		bullet.modulate = Color(0.2, 0.8, 1.2)
		if bullet.has_method("setup_projectile"):
			bullet.setup_projectile(1, false)

func _fire_orbital_ray() -> void:
	var target = _get_random_enemy()
	if target:
		var ray_pos = target.global_position
		await _draw_giant_laser(ray_pos)
		
		var sq_radius = 22500.0 # 150 * 150 (Optimizado)
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e.global_position.distance_squared_to(ray_pos) < sq_radius:
				if e.has_method("take_damage"):
					e.take_damage(100)

func _get_random_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_enemies = []
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
			valid_enemies.append(e)
	
	if valid_enemies.size() > 0:
		return valid_enemies.pick_random()
	return null

func _draw_laser(target_pos: Vector2, lvl: int) -> void:
	var width = 4.0 + (lvl * 2.0)
	
	var outer = Line2D.new()
	outer.default_color = Color(1.0, 0.1, 0.1, 0.5)
	outer.width = width * 2.0
	outer.add_point(target_pos + Vector2(0, -600))
	outer.add_point(target_pos)
	get_tree().current_scene.add_child(outer)
	
	var core = Line2D.new()
	core.default_color = Color(1.0, 1.0, 1.0, 1.0)
	core.width = width * 0.4
	core.add_point(target_pos + Vector2(0, -600))
	core.add_point(target_pos)
	get_tree().current_scene.add_child(core)
	
	var t = create_tween()
	t.parallel().tween_property(outer, "modulate:a", 0.0, 0.3)
	t.parallel().tween_property(core, "modulate:a", 0.0, 0.2)
	t.finished.connect(func():
		outer.queue_free()
		core.queue_free()
	)

func _draw_giant_laser(target_pos: Vector2) -> void:
	var start_pos = target_pos + Vector2(0, -800)
	var scene = get_tree().current_scene
	
	var reticle = Line2D.new()
	reticle.default_color = Color(1.0, 0.1, 0.1, 1.0)
	reticle.width = 2.0
	reticle.z_index = 10
	scene.add_child(reticle)
	var steps = 16
	for i in range(steps + 1):
		var angle = (PI * 2 / steps) * i
		reticle.add_point(target_pos + Vector2.RIGHT.rotated(angle) * 40.0)
		
	reticle.scale = Vector2(2.0, 2.0)
	var t_ret = create_tween()
	t_ret.tween_property(reticle, "scale", Vector2(1.0, 1.0), 0.7)
	t_ret.parallel().tween_property(reticle, "modulate:a", 0.5, 0.7)
	
	await get_tree().create_timer(0.8).timeout
	
	var laser = Line2D.new()
	laser.default_color = Color(1.0, 0.1, 0.1, 0.5)
	laser.width = 120.0 
	laser.z_index = 11
	scene.add_child(laser)
	laser.add_point(start_pos)
	laser.add_point(target_pos)

	var laser_core = Line2D.new()
	laser_core.default_color = Color(1.0, 1.0, 1.0, 1.0)
	laser_core.width = 30.0
	laser_core.z_index = 12
	scene.add_child(laser_core)
	laser_core.add_point(start_pos)
	laser_core.add_point(target_pos)

	var t_flicker = create_tween().set_loops(4)
	t_flicker.tween_property(laser, "width", 90.0, 0.05)
	t_flicker.tween_property(laser, "width", 120.0, 0.05)
	
	if AudioManager.has_method("play"): AudioManager.play("crit")
	if scene.has_method("shake_camera"): scene.shake_camera(0.6, 15)
	
	var t_fade = create_tween()
	t_fade.set_parallel(true)
	t_fade.tween_property(laser, "width", 0.0, 0.4)
	t_fade.tween_property(laser, "modulate:a", 0.0, 0.4)
	t_fade.tween_property(laser_core, "width", 0.0, 0.3)
	t_fade.tween_property(laser_core, "modulate:a", 0.0, 0.3)
	t_fade.tween_property(reticle, "modulate:a", 0.0, 0.4)
		
	t_fade.finished.connect(func():
		laser.queue_free()
		laser_core.queue_free()
		reticle.queue_free()
	)
