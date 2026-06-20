extends Node2D

var aura_timer: Timer

func _ready() -> void:
	aura_timer = Timer.new()
	aura_timer.wait_time = 5.0
	aura_timer.timeout.connect(_on_aura_timeout)
	add_child(aura_timer)
	
	update_component()

func update_component() -> void:
	var lvl = GameManager.get_skill_level("aura")
	if lvl <= 0:
		aura_timer.stop()
		return
		
	var base_time = 5.0
	if GameManager.sobrecarga_cuantica_rounds > 0:
		base_time /= 3.0
	aura_timer.wait_time = base_time
		
	if aura_timer.is_stopped():
		aura_timer.start()

func _on_aura_timeout() -> void:
	var current_lvl = GameManager.get_skill_level("aura")
	if current_lvl <= 0: return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	var range_dist = 200.0
	if current_lvl >= 2: range_dist *= 2.0 # Nivel 2: Radio doble
	
	var force = 400.0
	if current_lvl >= 3: force *= 2.0 # Nivel 3: Más empuje
	
	var damage = 0
	if current_lvl >= 4: damage = 25 # Nivel 4: Daño
	
	# Sacudir cámara
	var scene = get_tree().current_scene
	if scene and scene.has_method("shake_camera"):
		scene.shake_camera(0.1, 5)
		
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < range_dist:
			var dir = global_position.direction_to(e.global_position)
			
			# Empujar siempre
			if e.has_method("apply_knockback"):
				e.apply_knockback(dir * force)
			elif "dispersion_velocity" in e:
				e.dispersion_velocity = dir * force
				
			# Daño (L4+)
			if damage > 0 and e.has_method("take_damage"):
				e.take_damage(damage, false)
				
			# Daño Elemental (L5)
			if current_lvl >= 5:
				if e.has_method("apply_fire"): e.apply_fire()
				if e.has_method("apply_poison"): e.apply_poison()
