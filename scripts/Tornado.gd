extends Area2D

@export var speed: float = 100.0
@export var damage: int = 5
@export var duration: float = 5.0

var direction: Vector2 = Vector2.ZERO
var current_level_val: Variant = 1 # Pasado a Variant para evitar crashes
var tick_timer: Timer
var change_dir_timer: Timer

func _ready() -> void:
	# Elegir una dirección inicial aleatoria
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	tick_timer = Timer.new()
	tick_timer.wait_time = 0.5
	tick_timer.timeout.connect(_on_tick)
	add_child(tick_timer)
	tick_timer.start()
	
	change_dir_timer = Timer.new()
	change_dir_timer.wait_time = 1.0
	change_dir_timer.timeout.connect(_change_direction)
	add_child(change_dir_timer)
	change_dir_timer.start()

func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val
	var lvl = 4 if typeof(lvl_val) == TYPE_STRING else lvl_val
	
	if lvl >= 2: damage = int(damage * 1.5)
	if lvl >= 3: duration += 3.0
	if lvl >= 4: speed *= 1.5
	
	get_tree().create_timer(duration).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
	# Rotación visual
	rotation += 10.0 * delta
	
	# Rebote Inteligente: Previene que el tornado se atasque en los bordes
	var screen_rect = get_viewport_rect()
	if global_position.x < screen_rect.position.x or global_position.x > screen_rect.end.x:
		direction.x *= -1
		global_position.x = clamp(global_position.x, screen_rect.position.x, screen_rect.end.x)
	
	if global_position.y < screen_rect.position.y or global_position.y > screen_rect.end.y:
		direction.y *= -1
		global_position.y = clamp(global_position.y, screen_rect.position.y, screen_rect.end.y)
		
	# Efecto "4_spec": Aspiradora Natural
	if typeof(current_level_val) == TYPE_STRING and current_level_val == "4_spec":
		_vacuum_coins()

func _vacuum_coins() -> void:
	var coins = get_tree().get_nodes_in_group("coins")
	var pull_radius_squared = 150.0 * 150.0 
	
	for coin in coins:
		if is_instance_valid(coin) and global_position.distance_squared_to(coin.global_position) < pull_radius_squared:
			if coin.has_method("magnetize_to"):
				coin.magnetize_to(global_position)

func _change_direction() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var target = null
	var min_dist_sq = 90000.0 # 300 * 300 (Mejor rendimiento que sacar la raíz cuadrada)
	
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0:
			if e.get("is_underground"): continue # Que el tornado no persiga a los topos
			
			var d_sq = global_position.distance_squared_to(e.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				target = e
	
	if target:
		direction = direction.lerp(global_position.direction_to(target.global_position), 0.5).normalized()
	else:
		direction = direction.rotated(randf_range(-PI/4, PI/4))

func _on_tick() -> void:
	for area in get_overlapping_areas():
		if area.is_in_group("enemies") and area.has_method("take_damage"):
			area.take_damage(damage)
