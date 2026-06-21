extends Area2D

@export var max_health: int = 100
var current_health: int = 100
var current_level_val: Variant = 1 # Pasado a Variant contra crashes
var is_invulnerable: bool = false
var original_scale: Vector2
var aggro_timer: Timer
var health_bar: ProgressBar

func _ready() -> void:
	add_to_group("BaseRabanito") # Funciona, pero lo manejaremos con cuidado
	original_scale = scale
	
	# Barra de salud dinámica del nodo de la escena
	health_bar = get_node("ProgressBar")
	if health_bar:
		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.6)
		bg.set_corner_radius_all(3)
		
		var fill = StyleBoxFlat.new()
		fill.bg_color = Color(0.8, 0.2, 0.2) # Rojo
		fill.set_corner_radius_all(3)
		
		health_bar.add_theme_stylebox_override("background", bg)
		health_bar.add_theme_stylebox_override("fill", fill)
		
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	# Reemplazamos el physics_process por un Timer súper ligero
	aggro_timer = Timer.new()
	aggro_timer.wait_time = 0.5
	aggro_timer.timeout.connect(_attract_enemies)
	add_child(aggro_timer)
	aggro_timer.start()
	
	# Restaurar target original a los enemigos cuando esto muera
	tree_exiting.connect(_restore_enemy_targets)
	
	# Conectar señal para detectar cuando los enemigos entran en su área
	area_entered.connect(_on_area_entered)

func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val
	var lvl = 4 if typeof(lvl_val) == TYPE_STRING else lvl_val
	
	max_health = 100 + (lvl * 50) 
	current_health = max_health
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		
	# Sinergia Fortaleza Viviente: Hojas orbitan alrededor del espantapájaros
	if GameManager.has_living_fortress:
		var shield_scene = load("res://scenes/orbital_shield.tscn")
		var active_shield = shield_scene.instantiate()
		active_shield.z_index = 5
		call_deferred("add_child", active_shield)
		
	# Sinergia Papa Infectada: Emite nube tóxica permanente
	if GameManager.has_infected_potato:
		var toxic_script = load("res://scripts/ToxicAuraComponent.gd")
		var toxic_node = Area2D.new()
		toxic_node.name = "ToxicAuraComponent"
		toxic_node.set_script(toxic_script)
		
		var col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape = CircleShape2D.new()
		shape.radius = 120.0
		col.shape = shape
		toxic_node.add_child(col)
		
		call_deferred("add_child", toxic_node)
		
	# Efecto 4_spec o Nivel 5: Provocación global e invulnerabilidad
	var is_spec_or_lvl5 = (typeof(lvl_val) == TYPE_STRING and lvl_val == "4_spec") or (typeof(lvl_val) == TYPE_INT and lvl_val >= 5)
	if is_spec_or_lvl5:
		is_invulnerable = true
		modulate = Color.YELLOW
		
		# Timer seguro contra destrucción prematura
		var t = get_tree().create_timer(5.0)
		t.timeout.connect(_remove_invulnerability)

func _remove_invulnerability() -> void:
	if is_instance_valid(self):
		is_invulnerable = false
		modulate = Color.WHITE

func _attract_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	# Rango global si es 4_spec o nivel 5, si no, rango normal
	var is_spec_or_lvl5 = (typeof(current_level_val) == TYPE_STRING and current_level_val == "4_spec") or (typeof(current_level_val) == TYPE_INT and current_level_val >= 5)
	var attr_range = 2000.0 if is_spec_or_lvl5 else 150.0 
	var attr_range_sq = attr_range * attr_range # Raíz cuadrada optimizada
	
	for e in enemies:
		if is_instance_valid(e) and "target_base" in e:
			if global_position.distance_squared_to(e.global_position) < attr_range_sq:
				if e.target_base != self:
					e.target_base = self
					if e.has_method("interrupt_attack"):
						e.interrupt_attack()

func _restore_enemy_targets() -> void:
	# Búsqueda segura de la base real
	var real_base = null
	for node in get_tree().get_nodes_in_group("BaseRabanito"):
		if node != self: # Ignoramos a este mismo espantapájaros u otros
			real_base = node
			break
			
	if not real_base: return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and "target_base" in e and e.target_base == self:
			e.target_base = real_base
			if e.has_method("interrupt_attack"):
				e.interrupt_attack()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("kamikaze_attack"):
			area.kamikaze_attack()

func take_damage(amount: int, type: String = "normal") -> void:
	if is_invulnerable: return
	
	current_health -= amount
	if health_bar:
		health_bar.value = current_health
		
	var t = create_tween()
	t.tween_property(self, "scale", original_scale * 1.2, 0.05)
	t.tween_property(self, "scale", original_scale, 0.1)
	
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	# Nivel 3: Refleja daño
	if lvl >= 3:
		_apply_reflection(amount)
	
	if current_health <= 0:
		call_deferred("die")

func _apply_reflection(amount: int) -> void:
	for area in get_overlapping_areas():
		if area.is_in_group("enemies") and area.has_method("take_damage"):
			area.take_damage(int(amount * 0.5))

func die() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	# Nivel 4: Explota al morir
	if lvl >= 4:
		var b = load("res://scenes/seed_bomb.tscn").instantiate()
		get_parent().call_deferred("add_child", b)
		b.global_position = global_position
		if b.has_method("setup_level"): b.setup_level(3)
		
	# Iniciar cooldown de 8 segundos en GameManager
	if GameManager.has_method("start_scarecrow_cooldown"):
		GameManager.start_scarecrow_cooldown()
		
	queue_free()
