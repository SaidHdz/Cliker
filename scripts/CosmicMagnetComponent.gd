extends Area2D

var magnet_timer: Timer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Asegurar que el recurso de colisión sea único para este componente
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
	
	magnet_timer = Timer.new()
	magnet_timer.wait_time = 15.0
	magnet_timer.timeout.connect(_on_magnet_timeout)
	add_child(magnet_timer)
	
	# Desactivar colisiones si el nivel es 0 al iniciar
	update_component()

func update_component() -> void:
	var magnet_lvl = GameManager.get_skill_level("cosmic_magnet")
	if magnet_lvl <= 0:
		set_physics_process(false)
		monitoring = false
		return
		
	set_physics_process(true)
	monitoring = true
	
	# Actualizar rango de colisión
	var magnet_range = 150.0 + (magnet_lvl * 50.0)
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = magnet_range

func _physics_process(_delta: float) -> void:
	var magnet_lvl = GameManager.get_skill_level("cosmic_magnet")
	if magnet_lvl <= 0: return
	
	if magnet_lvl >= 5 and magnet_timer.is_stopped():
		magnet_timer.start()
		
	# Atraer cuerpos (Monedas/Orbes que son RigidBody2D)
	for body in get_overlapping_bodies():
		_try_magnetize(body, magnet_lvl)
		
	# Atraer áreas (Cofres y otros elementos Area2D)
	for area in get_overlapping_areas():
		_try_magnetize(area, magnet_lvl)

func _try_magnetize(node: Node, lvl: int) -> void:
	if not is_instance_valid(node): return
	
	var is_valid_target = false
	if node.is_in_group("coins"):
		is_valid_target = true
	elif node.is_in_group("orbs") and lvl >= 3:
		is_valid_target = true
	elif node.is_in_group("chests") and lvl >= 4:
		is_valid_target = true
		
	if is_valid_target and node.has_method("magnetize_to"):
		node.magnetize_to(global_position)

func _on_magnet_timeout() -> void:
	var magnet_lvl = GameManager.get_skill_level("cosmic_magnet")
	if magnet_lvl >= 5:
		# Nivel 5: Atrae instantáneamente todo lo que hay en pantalla
		for node in get_tree().get_nodes_in_group("coins") + get_tree().get_nodes_in_group("orbs"):
			if is_instance_valid(node) and node.has_method("magnetize_to"):
				node.magnetize_to(global_position)
