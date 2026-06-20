extends Area2D

var toxic_timer: Timer
var overlay: TextureRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Asegurar que el recurso de colisión sea único
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
		
	# Crear overlay visual dinámicamente
	overlay = TextureRect.new()
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	add_child(overlay)
	
	# Timer para aplicar daño de veneno cada segundo
	toxic_timer = Timer.new()
	toxic_timer.wait_time = 1.0
	toxic_timer.timeout.connect(_on_toxic_tick)
	add_child(toxic_timer)
	
	update_component()

func update_component() -> void:
	var toxic_lvl_val = GameManager.get_skill_level("toxic_aura")
	var toxic_lvl = 4 if typeof(toxic_lvl_val) == TYPE_STRING else toxic_lvl_val
	
	if toxic_lvl <= 0:
		overlay.visible = false
		monitoring = false
		toxic_timer.stop()
		return
		
	overlay.visible = true
	monitoring = true
	
	if GameManager.shaders_enabled:
		var shader = preload("res://shaders/toxic_aura.gdshader")
		if not overlay.material or (overlay.material as ShaderMaterial).shader != shader:
			var mat = ShaderMaterial.new()
			mat.shader = shader
			overlay.material = mat
		overlay.texture = null
		overlay.modulate = Color.WHITE
	else:
		overlay.material = null
		overlay.texture = preload("res://assets/img/vortice.png")
		overlay.modulate = Color(0.2, 0.8, 0.2, 0.45)
	
	var base_time = 1.0
	if GameManager.sobrecarga_cuantica_rounds > 0:
		base_time /= 3.0
	toxic_timer.wait_time = base_time
	
	if toxic_timer.is_stopped():
		toxic_timer.start()
		
	# Calcular radio del área
	var radius = 100.0
	if toxic_lvl >= 2: radius *= 1.1
	if toxic_lvl >= 3: radius *= 1.2
	if toxic_lvl >= 5: radius *= 2.0 # Nube tóxica gigante
	
	# Actualizar colisión
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius
		
	# Actualizar tamaño y posición del ColorRect visual
	overlay.size = Vector2(radius * 2, radius * 2)
	overlay.position = -overlay.size / 2.0

func _on_toxic_tick() -> void:
	var toxic_lvl_val = GameManager.get_skill_level("toxic_aura")
	var toxic_lvl = 4 if typeof(toxic_lvl_val) == TYPE_STRING else toxic_lvl_val
	if toxic_lvl <= 0: return
	
	var damage = 5 + (toxic_lvl * 5)
	
	# Nivel 2: Veneno letal (+50% daño)
	if toxic_lvl >= 2:
		damage = int(damage * 1.5)
		
	for area in get_overlapping_areas():
		if area.is_in_group("enemies") and area.has_method("take_damage"):
			# Aplicar daño de veneno
			area.take_damage(damage, false, "poison")
			
			if area.has_method("apply_poison"):
				# Nivel 3: Duración de venenos +10%
				area.apply_poison(toxic_lvl >= 3)
				
			# Nivel 4 Especial: Bioquímico (Ralentiza)
			var meta_upgrade = GameManager.card_upgrade_levels.get("toxic_aura", 0)
			if typeof(meta_upgrade) == TYPE_STRING and meta_upgrade == "4_spec":
				if "move_speed" in area and "original_move_speed" in area:
					area.move_speed = area.original_move_speed * 0.7 # 30% de ralentización
