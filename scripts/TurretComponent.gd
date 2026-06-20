extends Node2D

var turret_timer: Timer
var seed_scene = preload("res://scenes/seed_projectile.tscn")

func _ready() -> void:
	turret_timer = Timer.new()
	turret_timer.wait_time = 1.5
	turret_timer.timeout.connect(_on_turret_timeout)
	add_child(turret_timer)
	
	update_component()

func update_component() -> void:
	var turret_lvl_val = GameManager.get_skill_level("turret")
	var turret_lvl = 4 if typeof(turret_lvl_val) == TYPE_STRING else turret_lvl_val
	
	var nova_lvl_val = GameManager.get_skill_level("seed_nova")
	var nova_lvl = 4 if typeof(nova_lvl_val) == TYPE_STRING else nova_lvl_val
	
	if turret_lvl <= 0 and nova_lvl <= 0:
		turret_timer.stop()
		return
		
	# Calcular la cadencia según las habilidades
	var wait_time = 1.5
	if turret_lvl >= 3:
		wait_time = 0.8
	if turret_lvl >= 5:
		wait_time = 0.3 # Evolución: Modo Gatling
		
	if nova_lvl >= 5:
		wait_time = min(wait_time, 0.5) # Evolución: Tormenta constante
		
	if GameManager.sobrecarga_cuantica_rounds > 0:
		wait_time /= 3.0
		
	turret_timer.wait_time = wait_time
	if turret_timer.is_stopped():
		turret_timer.start()

func _on_turret_timeout() -> void:
	var nova_lvl_val = GameManager.get_skill_level("seed_nova")
	var nova_lvl = 4 if typeof(nova_lvl_val) == TYPE_STRING else nova_lvl_val
	if nova_lvl > 0:
		_fire_seed_nova(nova_lvl_val)
		
	var turret_lvl_val = GameManager.get_skill_level("turret")
	var turret_lvl = 4 if typeof(turret_lvl_val) == TYPE_STRING else turret_lvl_val
	if turret_lvl > 0:
		_fire_turret(turret_lvl_val, turret_lvl)

func _fire_turret(lvl_val: Variant, lvl: int) -> void:
	var prioritize_low_hp = (typeof(lvl_val) == TYPE_STRING and lvl_val == "4_spec")
	var target = get_closest_enemy(prioritize_low_hp)
	if not target: return
	
	var bullet_count = 3
	if lvl >= 2:
		bullet_count = 5
		
	var base_dir = global_position.direction_to(target.global_position)
	var turret_damage = 5 + (lvl * 5)
	
	# Si es nivel 5 o más, potenciamos más el daño
	if lvl >= 5:
		turret_damage = int(turret_damage * 1.3)
		
	for i in range(bullet_count):
		var bullet = seed_scene.instantiate()
		bullet.z_index = 10
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.direction = base_dir.rotated((i - (bullet_count - 1) / 2.0) * 0.2)
		bullet.damage = turret_damage
		if bullet.has_method("setup_projectile"):
			bullet.setup_projectile(lvl_val, false)

func _fire_seed_nova(lvl_val: Variant) -> void:
	var lvl = 4 if typeof(lvl_val) == TYPE_STRING else lvl_val
	var count = 4
	if lvl >= 2:
		count = 6
		
	var nova_damage = 5 + (lvl * 5)
	for i in range(count):
		var bullet = seed_scene.instantiate()
		bullet.z_index = 10
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.direction = Vector2.RIGHT.rotated((PI * 2 / count) * i)
		bullet.damage = nova_damage
		if bullet.has_method("setup_projectile"):
			bullet.setup_projectile(lvl_val, true) # true para perforar

func get_closest_enemy(prioritize_low_hp: bool = false) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_target = null
	var min_val = 99999.0
	
	for enemy in enemies:
		if is_instance_valid(enemy) and "current_health" in enemy and enemy.current_health > 0:
			if enemy.get("is_underground"): continue
			
			if prioritize_low_hp:
				if enemy.current_health < min_val:
					min_val = enemy.current_health
					best_target = enemy
			else:
				var dist = global_position.distance_to(enemy.global_position)
				if dist < min_val:
					min_val = dist
					best_target = enemy
					
	return best_target
