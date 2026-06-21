extends Node2D

var current_level_val: Variant = 1
var attack_timer: Timer

func _ready() -> void:
	pass

func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val
	
	if not attack_timer:
		attack_timer = Timer.new()
		add_child(attack_timer)
		attack_timer.timeout.connect(_throw_boomerang)
	
	attack_timer.wait_time = 2.0
	attack_timer.start()

func _throw_boomerang() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	var num_boomerangs = 1
	if lvl >= 4: num_boomerangs = 2 # Nivel 4: Dos búmeranes
	
	for i in range(num_boomerangs):
		var target = _get_random_enemy()
		if target:
			_spawn_boomerang(target)

func _get_random_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_enemies = []
	
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
			valid_enemies.append(e)
	
	if valid_enemies.size() > 0:
		return valid_enemies.pick_random()
	return null

func _spawn_boomerang(target: Node2D) -> void:
	var base = get_tree().get_first_node_in_group("BaseRabanito")
	if not base: return
	
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	var meta_upgrade = GameManager.get_card_upgrade_int_level("boomerang")
	
	var damage = 15 + (meta_upgrade * 3)
	if lvl >= 2: damage = int(damage * 1.6)
	
	var reach = 300.0
	if lvl >= 3: reach = 500.0
	if meta_upgrade >= 3: reach *= 1.15
	
	# 1. Siempre lanzar el búmeran normal
	var boom = load("res://scenes/boomerang_projectile.tscn").instantiate()
	boom.global_position = base.global_position
	get_parent().add_child(boom)
	
	var travel_time = 0.8
	if meta_upgrade >= 2: travel_time = 0.72
	
	var dir = base.global_position.direction_to(target.global_position)
	var target_pos = base.global_position + (dir * reach)
	
	if lvl >= 5: boom.modulate = Color.CYAN
	
	var t_rot = create_tween().bind_node(boom).set_loops(50)
	t_rot.tween_property(boom, "rotation", PI * 2, 0.3).as_relative()
	
	var move_t = create_tween()
	move_t.tween_property(boom, "global_position", target_pos, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	move_t.tween_property(boom, "global_position", base.global_position, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	move_t.finished.connect(boom.queue_free)
	
	if boom.has_signal("area_entered"):
		boom.area_entered.connect(func(area):
			if area.is_in_group("enemies") and area.has_method("take_damage"):
				var dmg_type = "electric" if lvl >= 5 else "normal"
				var is_crit = false
				var meta_val = GameManager.card_upgrade_levels.get("boomerang", 0)
				if typeof(meta_val) == TYPE_STRING and meta_val == "4_spec":
					is_crit = randf() < 0.25
				var final_damage = int(damage * 2.0) if is_crit else damage
				area.take_damage(final_damage, is_crit, dmg_type)
		)
		
	# 2. Si tiene la sinergia deforestador, lanzar adicionalmente el súper búmeran naranja
	var has_synergy = GameManager.has_deforesador
	if has_synergy:
		var s_boom = load("res://scenes/boomerang_projectile.tscn").instantiate()
		s_boom.global_position = base.global_position
		get_parent().add_child(s_boom)
		
		s_boom.scale = Vector2(3.0, 3.0)
		s_boom.modulate = Color(1.5, 0.5, 0.0) # Naranja orbital brillante
		
		var s_t_rot = create_tween().bind_node(s_boom).set_loops(100)
		s_t_rot.tween_property(s_boom, "rotation", PI * 2, 0.1).as_relative()
		
		var shred_timer = Timer.new()
		shred_timer.wait_time = 0.2
		shred_timer.timeout.connect(func():
			if is_instance_valid(s_boom):
				var sq_dist = 80.0 * 80.0
				for e in get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e) and "current_health" in e and e.current_health > 0:
						if s_boom.global_position.distance_squared_to(e.global_position) < sq_dist:
							e.take_damage(int(damage * 0.4), false, "normal")
		)
		s_boom.add_child(shred_timer)
		shred_timer.start()
		
		var s_move_t = create_tween()
		s_move_t.tween_property(s_boom, "global_position", target_pos, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		s_move_t.tween_interval(2.0)
		s_move_t.tween_property(s_boom, "global_position", base.global_position, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		s_move_t.finished.connect(s_boom.queue_free)
