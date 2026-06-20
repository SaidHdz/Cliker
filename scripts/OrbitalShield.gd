extends Node2D

@export var base_rotation_speed: float = 3.0
var current_speed: float = 3.0
var actual_damage: int = 2

# Variables para separar la tienda de la partida
var in_match_lvl: int = 1
var meta_lvl_val: Variant = 1

func _ready() -> void:
	# 1. Obtenemos el nivel de la carta en esta partida (1 a 5)
	in_match_lvl = GameManager.get_skill_level("shield")
	
	# 2. Obtenemos las mejoras compradas en la tienda principal
	meta_lvl_val = GameManager.card_upgrade_levels.get("shield", 0)
	var meta_lvl = 4 if typeof(meta_lvl_val) == TYPE_STRING else meta_lvl_val
	
	# --- APLICAR MEJORAS PERMANENTES (TIENDA) ---
	if meta_lvl >= 2:
		for child in get_children():
			if child is Area2D: child.position *= 1.1 # Radio +10%
			
	if meta_lvl >= 3:
		base_rotation_speed *= 1.5 # Giran más rápido desde el inicio
		
	if typeof(meta_lvl_val) == TYPE_STRING and meta_lvl_val == "4_spec":
		for child in get_children():
			if child is Area2D:
				for coll in child.get_children():
					if coll is CollisionShape2D: coll.scale *= 2.0 # Guardián Verde

	# --- APLICAR MEJORAS DE CARTA (EN PARTIDA) ---
	actual_damage = GameManager.shield_damage
	if in_match_lvl >= 2: 
		actual_damage *= 2 # Nivel 2: Daño doble
		
	# Nota para ti: En Nivel 3 dice que añade 2 hojas. Si tienes 4 en la escena, 
	# asumo que empiezan 2 invisibles/desactivadas y aquí las enciendes.
	if in_match_lvl >= 3:
		pass # Aquí activarías hoja 3 y 4 (ej. $Hoja3.process_mode = Node.PROCESS_MODE_INHERIT)
		
	current_speed = base_rotation_speed
	if in_match_lvl >= 5:
		current_speed *= 3.0 # Nivel 5: Torbellino extremo
		
	# Conectar automáticamente todas las hojas sin hacerlo a mano en el editor
	for child in get_children():
		if child is Area2D and not child.area_entered.is_connected(_on_leaf_impact):
			child.area_entered.connect(_on_leaf_impact.bind(child))

func _physics_process(delta: float) -> void:
	rotate(current_speed * delta)

# Le pasamos también qué hoja golpeó por si ocupamos calcular empuje desde esa hoja
func _on_leaf_impact(area: Area2D, leaf: Area2D = null) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(actual_damage)
			
		# Nivel 4 de Partida: Empuje violento (Knockback)
		if in_match_lvl >= 4 and leaf != null and area.has_method("apply_knockback"):
			# Calculamos la dirección desde el centro de la base hacia el enemigo
			var push_dir = global_position.direction_to(area.global_position)
			area.apply_knockback(push_dir * 400.0)
			
	elif area.is_in_group("projectiles"):
		if area.has_method("take_damage"): area.take_damage(1)
		else: area.queue_free()
