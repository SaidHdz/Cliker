extends Area2D

@export var duration: float = 4.0
@export var pull_force: float = 400.0

var current_level_val: Variant = 1
var damage_timer: Timer

func _ready() -> void:
	current_level_val = GameManager.get_skill_level("black_hole")
	
	scale = Vector2(0.1, 0.1)
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3).set_trans(Tween.TRANS_BACK)
	
	var t_rot = create_tween().bind_node(self).set_loops(20)
	t_rot.tween_property(self, "rotation", PI * 2, 1.0).as_relative()
	
	# Sinergia Agujero Infernal: Cambiar color y aumentar fuerza de atracción
	if GameManager.has_infernal_hole:
		if has_node("Sprite2D"):
			$Sprite2D.modulate = Color(2.5, 0.4, 0.0) # Rojo/naranja fuego brillante
		pull_force = 700.0 # Succiona más fuerte (base es 400)
	
	# Timer para daño constante y justo (cada 0.25s = 4 golpes por segundo)
	damage_timer = Timer.new()
	damage_timer.wait_time = 0.25
	damage_timer.timeout.connect(_deal_damage_tick)
	add_child(damage_timer)
	damage_timer.start()
	
	get_tree().create_timer(duration).timeout.connect(_on_collapse)

# Agregamos setup_level por coherencia con tu arquitectura
func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val

func _physics_process(delta: float) -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	for area in get_overlapping_areas():
		# Succionar Enemigos
		if area.is_in_group("enemies") and not area.get("is_boss"):
			if area.get("is_underground"): continue
			
			var dir = global_position.direction_to(area.global_position)
			area.position -= dir * pull_force * delta
			if area.has_method("interrupt_attack"): area.interrupt_attack()
		
		# Nivel 3 y 4_spec: Absorb XP y Monedas (Redirigidos al Rábano de forma segura)
		var has_suction = (lvl >= 3) or (typeof(current_level_val) == TYPE_STRING and current_level_val == "4_spec")
		if has_suction:
			if (area.is_in_group("orbs") or area.is_in_group("coins")) and area.has_method("magnetize_to"):
				var base = get_tree().get_first_node_in_group("BaseRabanito")
				if base:
					area.magnetize_to(base.global_position)
		
		# Nivel 4: Absorbe Proyectiles
		if lvl >= 4:
			if area.is_in_group("projectiles"): 
				area.queue_free()

func _deal_damage_tick() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	var tick_damage = 2 + (lvl * 2)
	
	# Nivel 2: +Daño
	if lvl >= 2: tick_damage *= 2
	
	# Sinergia Agujero Infernal: +50% Daño base
	if GameManager.has_infernal_hole:
		tick_damage = int(tick_damage * 1.5)
	
	for area in get_overlapping_areas():
		if area.is_in_group("enemies") and area.has_method("take_damage"):
			var dmg_type = "fire" if GameManager.has_infernal_hole else "normal"
			area.take_damage(tick_damage, false, dmg_type)
			if GameManager.has_infernal_hole and area.has_method("apply_fire"):
				area.apply_fire()

func _on_collapse() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	# Nivel 5 o Sinergia Agujero Infernal: Explosión al colapsar
	if lvl >= 5 or GameManager.has_infernal_hole:
		var nuke = load("res://scenes/seed_bomb.tscn").instantiate()
		get_parent().call_deferred("add_child", nuke)
		nuke.global_position = global_position
		var expl_lvl = 5 if lvl >= 5 else 3
		if nuke.has_method("setup_level"): nuke.setup_level(expl_lvl)
		
	var t2 = create_tween()
	t2.tween_property(self, "scale", Vector2.ZERO, 0.3)
	t2.finished.connect(queue_free)
