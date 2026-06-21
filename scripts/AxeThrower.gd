extends Node2D

var current_level: int = 1
var attack_timer: Timer

func _ready() -> void:
	pass

func setup_level(lvl: int) -> void:
	current_level = lvl
	
	if not attack_timer:
		attack_timer = Timer.new()
		add_child(attack_timer)
		attack_timer.timeout.connect(_throw_axes)
	
	attack_timer.wait_time = 1.5
	if lvl >= 5: attack_timer.wait_time = 0.8 # Nivel 5: Tormenta (más rápido)
	attack_timer.start()

func _throw_axes() -> void:
	var num_axes = 1
	if current_level >= 3: num_axes = 2
	if current_level >= 5: num_axes = 4 # Nivel 5: Tormenta de hachas
	
	for i in range(num_axes):
		var target = _get_random_enemy()
		if target:
			_spawn_axe(target)

func _get_random_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_enemies = []
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
			valid_enemies.append(e)
	
	if valid_enemies.size() > 0:
		return valid_enemies.pick_random()
	return null

func _spawn_axe(target: Node2D) -> void:
	var base = get_tree().get_first_node_in_group("BaseRabanito")
	if not base: return
	
	var damage = 10
	if current_level >= 2: damage = 20 # Nivel 2: Más daño
	
	# Spawn de la hacha normal (se mantiene siempre)
	var axe = load("res://scenes/seed_projectile.tscn").instantiate()
	get_parent().add_child(axe)
	axe.global_position = base.global_position
	axe.direction = base.global_position.direction_to(target.global_position)
	axe.damage = damage
	axe.modulate = Color(0.6, 0.4, 0.2) # Color madera/hacha
	
	var t_rot = create_tween().bind_node(axe).set_loops(50)
	t_rot.tween_property(axe, "rotation", PI * 2, 0.5).as_relative()
	
	if current_level >= 4:
		if axe.has_method("setup_projectile"):
			axe.setup_projectile(4, true)
			
	# Spawn de la sinergia deforestador (hacha + búmeran)
	var has_synergy = GameManager.has_deforesador
	if has_synergy:
		var boom = load("res://scenes/boomerang_projectile.tscn").instantiate()
		boom.global_position = base.global_position
		get_parent().add_child(boom)
		
		boom.scale = Vector2(3.0, 3.0)
		boom.modulate = Color(1.5, 0.5, 0.0) # Naranja orbital brillante
		
		var t_rot_b = create_tween().bind_node(boom).set_loops(100)
		t_rot_b.tween_property(boom, "rotation", PI * 2, 0.1).as_relative()
		
		var shred_timer = Timer.new()
		shred_timer.wait_time = 0.2
		shred_timer.timeout.connect(func():
			if is_instance_valid(boom):
				var sq_dist = 80.0 * 80.0
				for e in get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e) and "current_health" in e and e.current_health > 0:
						if boom.global_position.distance_squared_to(e.global_position) < sq_dist:
							e.take_damage(int(damage * 0.4), false, "normal")
		)
		boom.add_child(shred_timer)
		shred_timer.start()
		
		var reach = 300.0
		if current_level >= 3: reach = 500.0
		var dir = base.global_position.direction_to(target.global_position)
		var target_pos = base.global_position + (dir * reach)
		var travel_time = 0.8
		
		var move_t = create_tween()
		move_t.tween_property(boom, "global_position", target_pos, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		move_t.tween_interval(2.0)
		move_t.tween_property(boom, "global_position", base.global_position, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		move_t.finished.connect(boom.queue_free)
