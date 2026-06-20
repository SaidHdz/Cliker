extends Area2D

@export var speed: float = 600.0
@export var damage: int = 5
var direction: Vector2 = Vector2.RIGHT

var pierce_count: int = 0
var is_explosive: bool = false
var current_level_val: Variant = 1
var is_nova_type: bool = false
var locked_target: Node2D

var life_timer: Timer = Timer.new()
var hit_enemies: Array = []

var is_orbiting: bool = false
var orbit_angle: float = 0.0
var orbit_radius: float = 120.0
var base_node: Node2D
var is_sub_bullet: bool = false

func _ready() -> void:
	if life_timer.wait_time == 1.0:
		life_timer.wait_time = 3.0
	life_timer.timeout.connect(queue_free)
	if life_timer.get_parent() == null:
		add_child(life_timer)
	life_timer.start()
	
	area_entered.connect(_on_area_entered)

func _init_orbit() -> void:
	var tree = get_tree()
	if tree:
		base_node = tree.get_first_node_in_group("BaseRabanito")
	
	# Asegurar que no duplicamos el Timer
	for child in get_children():
		if child.name == "OrbitShootTimer":
			return
			
	var shoot_timer = Timer.new()
	shoot_timer.name = "OrbitShootTimer"
	shoot_timer.wait_time = 0.8
	shoot_timer.timeout.connect(_orbit_shoot)
	add_child(shoot_timer)
	shoot_timer.start()

func setup_projectile(lvl_val: Variant, is_nova: bool = false) -> void:
	current_level_val = lvl_val
	is_nova_type = is_nova
	var lvl = 4 if typeof(lvl_val) == TYPE_STRING else lvl_val
	
	if is_nova:
		# Aura de Hojas
		if lvl >= 3: pierce_count = 3 # ¡ESTO FALTABA!
		if lvl >= 4: is_explosive = true
	else:
		# Hojas Metralleta
		if lvl >= 2:
			life_timer.wait_time = 4.5
			life_timer.start()
		if lvl >= 4: pierce_count = 2 
		
	# Sinergia Jardín de Guerra: Semilla orbita e invoca disparos
	if GameManager.has_war_garden and not is_sub_bullet:
		is_orbiting = true
		orbit_angle = randf() * PI * 2
		life_timer.wait_time = 6.0
		life_timer.start()
		_init_orbit()

func _physics_process(delta: float) -> void:
	if is_orbiting and is_instance_valid(base_node):
		orbit_angle += delta * 2.5
		global_position = base_node.global_position + Vector2.RIGHT.rotated(orbit_angle) * orbit_radius
		rotation = orbit_angle + PI/2.0
	else:
		var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
		
		if is_nova_type and lvl >= 3:
			if not is_instance_valid(locked_target) or locked_target.current_health <= 0:
				locked_target = _get_closest_enemy_for_homing()
				
			if is_instance_valid(locked_target):
				var target_dir = global_position.direction_to(locked_target.global_position)
				direction = direction.lerp(target_dir, delta * 3.0).normalized()
				
		global_position += direction * speed * delta
		rotation = direction.angle()

func _orbit_shoot() -> void:
	if not is_instance_valid(self): return
	var target = _get_closest_enemy_for_homing()
	if target:
		var sub_bullet = load("res://scenes/seed_projectile.tscn").instantiate()
		sub_bullet.z_index = 10
		get_parent().add_child(sub_bullet)
		sub_bullet.global_position = global_position
		sub_bullet.direction = global_position.direction_to(target.global_position)
		sub_bullet.damage = int(damage * 0.5)
		sub_bullet.is_sub_bullet = true
		if sub_bullet.has_method("setup_projectile"):
			sub_bullet.setup_projectile(current_level_val, false)

func _get_closest_enemy_for_homing() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest = null
	var min_dist_sq = 160000.0 
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	if lvl >= 2: min_dist_sq = 193600.0 
	
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
			var d_sq = global_position.distance_squared_to(e.global_position)
			if d_sq < min_dist_sq: 
				min_dist_sq = d_sq
				closest = e
	return closest

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		# BLINDAJE ANTI MULTI-HIT
		if area in hit_enemies: return 
		hit_enemies.append(area)

		if area.has_method("take_damage"):
			area.take_damage(damage)
			
		if is_nova_type and typeof(current_level_val) == TYPE_STRING and current_level_val == "4_spec":
			if "move_speed" in area and "original_move_speed" in area:
				area.move_speed = area.original_move_speed * 0.95
		
		if is_explosive and pierce_count <= 0:
			_explode()
		
		if pierce_count > 0:
			pierce_count -= 1
		else:
			call_deferred("queue_free") 

func _explode() -> void:
	var b_scene = load("res://scenes/seed_bomb.tscn")
	if is_instance_valid(b_scene):
		var b = b_scene.instantiate()
		get_parent().call_deferred("add_child", b)
		b.global_position = global_position
		if b.has_method("setup_level"): b.setup_level(2)
