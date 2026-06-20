extends Area2D

@onready var path: PathFollow2D = get_parent()
@export var base_speed: float = 0.3

var current_level_val: Variant = 1
var speed_mult: float = 1.0 # Variable para guardar la velocidad final

func _ready() -> void:
	z_index = 4
	add_to_group("allies")
	setup_level(GameManager.get_skill_level("mining_cart"))

func setup_level(lvl_val: Variant) -> void:
	current_level_val = lvl_val
	var lvl = 4 if typeof(current_level_val) == TYPE_STRING else current_level_val
	
	# Calculamos el multiplicador de velocidad (L2: +20%, L3: +30%)
	speed_mult = 1.0
	if lvl >= 2: speed_mult = 1.2
	if lvl >= 3: speed_mult = 1.3
	
	# Restauramos la escala original del CollisionShape2D antes de re-escalar
	for child in get_children():
		if child is CollisionShape2D:
			child.scale = Vector2.ONE
			if lvl >= 3:
				child.scale = Vector2(1.15, 1.15)

func _physics_process(delta: float) -> void:
	# Ahora esta línea es puramente matemática y ultraligera
	path.progress_ratio += base_speed * speed_mult * delta
	
	for body in get_overlapping_bodies(): _check_and_collect(body)
	for area in get_overlapping_areas(): _check_and_collect(area)

func _check_and_collect(node: Node) -> void:
	if not is_instance_valid(node): return
	
	var is_coin = node.is_in_group("coins")
	var is_xp = node.is_in_group("orbs")
	
	var can_collect = false
	if is_coin: can_collect = true 
	if is_xp: can_collect = true 
	
	if can_collect and node.has_method("magnetize_to"):
		if is_xp and typeof(current_level_val) == TYPE_STRING and current_level_val == "4_spec" and randf() < 0.1:
			if "xp_value" in node: node.xp_value *= 10
			if "modulate" in node: node.modulate = Color(0.5, 0.8, 1.0) 
			
		var base = get_tree().get_first_node_in_group("BaseRabanito")
		if base:
			node.magnetize_to(base.global_position)
