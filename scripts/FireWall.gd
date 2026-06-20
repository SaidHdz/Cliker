extends Area2D

@export var duration: float = 3.0
@export var damage: int = 5

var current_level_val: Variant = 1
var tick_timer: Timer

func _ready() -> void:
	# Intentamos leer de GameManager primero, pero permitimos que setup_level lo sobrescriba
	current_level_val = GameManager.get_skill_level("fire_wall")
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	# Nivel 2: Más duración
	if lvl >= 2: duration += 3.0
	# Nivel 4: Más daño
	if lvl >= 4: damage *= 2
	
	modulate.a = 0
	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.2)
	
	tick_timer = Timer.new()
	tick_timer.wait_time = 0.5
	tick_timer.timeout.connect(_on_tick)
	add_child(tick_timer)
	tick_timer.start()
	
	# Fundamental: Conectamos la salida para devolver la velocidad
	area_exited.connect(_on_area_exited)
	
	get_tree().create_timer(duration).timeout.connect(_on_expire)

# Añadimos setup_level por si se instancia directamente por código (como en los aliens)
func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val

func _on_tick() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	var meta_upgrade = GameManager.card_upgrade_levels.get("fire_wall", 0)
	var is_architect = (typeof(meta_upgrade) == TYPE_STRING and meta_upgrade == "4_spec")

	for area in get_overlapping_areas():
		if area.is_in_group("enemies"):
			if area.has_method("take_damage"):
				area.take_damage(damage, false, "fire")
				if area.has_method("apply_fire"): area.apply_fire()
			
			if "move_speed" in area and "original_move_speed" in area:
				if is_architect:
					# Efecto 4_spec: Bloqueo casi total (atrapados en el muro)
					area.move_speed = area.original_move_speed * 0.05 
				elif lvl >= 3:
					# Nivel 3: Ralentización normal
					area.move_speed = area.original_move_speed * 0.5

func _on_area_exited(area: Area2D) -> void:
	# ¡Curamos el bug! Les devolvemos su velocidad al salir del fuego
	if area.is_in_group("enemies") and "move_speed" in area and "original_move_speed" in area:
		area.move_speed = area.original_move_speed

func _on_expire() -> void:
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	# Nivel 5: Explota al desaparecer
	if lvl >= 5:
		_explode()
		
	var t2 = create_tween()
	t2.tween_property(self, "modulate:a", 0.0, 0.3)
	t2.finished.connect(queue_free)

func _explode() -> void:
	var b_scene = load("res://scenes/seed_bomb.tscn")
	if is_instance_valid(b_scene):
		var b = b_scene.instantiate()
		get_parent().call_deferred("add_child", b)
		b.global_position = global_position
		if b.has_method("setup_level"): b.setup_level(3)
