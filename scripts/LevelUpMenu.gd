extends Control

# Debes tener 3 botones en tu escena llamados Card1, Card2, Card3 dentro de un HBoxContainer
@onready var cards: Array = [$HBoxContainer/Card1, $HBoxContainer/Card2, $HBoxContainer/Card3]

var upgrades_pool = [
	{"id": "heal", "title": "Reparar Base", "desc": "Cura 50 puntos de salud a la isla."},
	{"id": "damage_boost", "title": "Filo Afilado", "desc": "Aumenta el daño de tu corte en +1."},
	{"id": "crit_boost", "title": "Ojo Crítico", "desc": "Ganas +15% de probabilidad de crítico."},
	{"id": "auto_speed", "title": "Dedo Fantasma", "desc": "El auto-clicker ataca más rápido."},
	{"id": "fire_slice", "title": "Corte Picante", "desc": "Tus tajos prenden fuego a los enemigos (Daño por segundo)."},
	{"id": "mirror_slice", "title": "Corte Espejo", "desc": "Crea un tajo fantasma en el lado opuesto de la pantalla."},
	{"id": "frost_avalanche", "title": "Avalancha de Nieve", "desc": "INSTANTÁNEO: Congela a todos los enemigos actuales (50% velocidad) por unos segundos."},
	{"id": "turret", "title": "Semillas de Metralleta", "desc": "El rabanito dispara semillas al enemigo más cercano automáticamente."},
	{"id": "shield", "title": "Escudo de Hojas", "desc": "Hojas afiladas giran a tu alrededor dañando enemigos."},
	{"id": "explosive_slice", "title": "Tajo Explosivo", "desc": "Tu estela tiene un 5% de probabilidad de soltar bombas al golpear."},
	{"id": "toxic_compost", "title": "Abono Tóxico", "desc": "Los enemigos tienen 20% de probabilidad de soltar ácido al morir."},
	# --- NUEVAS FASE 2 ---
	{"id": "lightning_slice", "title": "Tajo Relámpago", "desc": "Tus cortes lanzan rayos. Escala: +rango, +objetivos y +daño."},
	{"id": "double_slice", "title": "Tajo Doble", "desc": "Crea un corte paralelo extra. (Límite: 1)"},
	{"id": "wind_gust", "title": "Ráfaga de Viento", "desc": "Lanza proyectiles de aire. Añade +1 proyectil (Máximo 3)."},
	{"id": "black_hole", "title": "Agujero Negro", "desc": "Tus cortes tienen probabilidad de crear un vórtice que succiona enemigos."},
	{"id": "fire_wall", "title": "Tajo Pintor", "desc": "Tus tajos dejan un muro de fuego persistente en el suelo."},
	{"id": "knockback_aura", "title": "Aura de Voluntad", "desc": "Cada 5s emites un pulso que empuja a todos los enemigos cercanos."}
]

var current_options = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Funciona en pausa
	hide()
	for i in range(cards.size()):
		var btn = cards[i] as Button
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(250, 400)
		btn.pressed.connect(_on_card_pressed.bind(i))

func show_menu() -> void:
	get_tree().paused = true
	show()
	generate_options()

func generate_options() -> void:
	current_options.clear()
	# Filtramos la pool para no ofrecer habilidades ya maximizadas
	var available_pool = []
	for u in upgrades_pool:
		var can_add = true
		if u.id == "double_slice" and GameManager.has_double_slice: can_add = false
		if u.id == "wind_gust" and GameManager.wind_gust_count >= 3: can_add = false
		if can_add: available_pool.append(u)
	
	available_pool.shuffle()
	for i in range(3):
		if i < available_pool.size():
			var upgrade = available_pool[i]
			current_options.append(upgrade)
			cards[i].text = upgrade.title + "\n\n" + upgrade.desc
			cards[i].visible = true
		else:
			cards[i].visible = false

func _on_card_pressed(index: int) -> void:
	if index >= current_options.size(): return
	apply_upgrade(current_options[index].id)
	hide()
	get_tree().paused = false

func apply_upgrade(id: String) -> void:
	match id:
		"heal":
			var base = get_tree().get_first_node_in_group("BaseRabanito")
			if base:
				base.current_health = min(base.current_health + 50, base.max_health)
				base.health_bar.value = base.current_health
		"damage_boost":
			GameManager.click_damage += 1
		"crit_boost":
			GameManager.crit_chance += 0.15
		"auto_speed":
			if GameManager.auto_damage == 0:
				GameManager.auto_damage = 1; GameManager.auto_timer.wait_time = 1.0
			else:
				GameManager.auto_damage += 1; GameManager.auto_timer.wait_time = max(0.2, GameManager.auto_timer.wait_time - 0.1)
		"fire_slice":
			GameManager.has_fire_slice = true; GameManager.fire_slice_level += 1
		"mirror_slice":
			GameManager.has_mirror_slice = true; GameManager.mirror_slice_level += 1
		"frost_avalanche":
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(enemy) and enemy.has_method("apply_frost"): enemy.apply_frost()
		"turret":
			GameManager.turret_level += 1
		"shield":
			GameManager.shield_level += 1; GameManager.shield_damage += 2
		"explosive_slice":
			GameManager.has_explosive_slice = true
		"toxic_compost":
			GameManager.has_toxic_compost = true
		# --- NUEVAS LÓGICAS FASE 2 ---
		"lightning_slice":
			GameManager.has_lightning_slice = true; GameManager.lightning_level += 1
		"double_slice":
			GameManager.has_double_slice = true
		"wind_gust":
			GameManager.has_wind_gust = true
			GameManager.wind_gust_count = min(3, GameManager.wind_gust_count + 1)
		"black_hole":
			GameManager.has_black_hole = true; GameManager.black_hole_level += 1
		"fire_wall":
			GameManager.has_fire_wall = true
		"knockback_aura":
			GameManager.has_knockback_aura = true; GameManager.aura_level += 1
