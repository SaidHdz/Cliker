extends Control

@onready var btn_sayonara: Button = $HBoxContainer/BtnSayonara
@onready var btn_steroids: Button = $HBoxContainer/BtnSteroids
@onready var btn_aura: Button = $HBoxContainer/BtnAura

var tex_epica = preload("res://assets/img/carta_epica.png")
var button_font = preload("res://assets/fuentes/BoldPixels.ttf")

var cards_pool: Array = [
	{
		"id": "sayonara",
		"title": "DISCO SAYONARA",
		"desc": "Detiene el tiempo y explota a todos.\n\nDuración:\n1 Uso\n\nEfecto:\nLimpia la pantalla."
	},
	{
		"id": "steroids",
		"title": "ABONO MÁGICO",
		"desc": "Gigante (x2), Daño x3 y Doble XP.\n\nDuración:\n2 oleadas\n\nEfecto:\n5s Activo / 12s CD."
	},
	{
		"id": "conqueror_aura",
		"title": "AURA CONQUISTADOR",
		"desc": "Pulso de limpieza de área automática.\n\nDuración:\n1 oleada\n\nEfecto:\nPulso cada 8 segundos."
	},
	{
		"id": "campesino_extremo",
		"title": "CAMPESINO EXTREMO",
		"desc": "\"El rábano recuerda sus raíces.\"\n\nDuración:\n2 oleadas\n\nEfecto:\n- Duplica el XP obtenido.\n- El Carro Minero aparece gratis.\n- Recoge todo automáticamente."
	},
	{
		"id": "reactor_nuclear",
		"title": "REACTOR NUCLEAR",
		"desc": "\"Probablemente esto sea ilegal.\"\n\nDuración:\n2 oleadas\n\nEfecto:\n- Cada 8 segundos una explosión nuclear masiva limpia enemigos y sacude la pantalla."
	},
	{
		"id": "sobrecarga_cuantica",
		"title": "SOBRECARGA CUÁNTICA",
		"desc": "\"Demasiada energía para un vegetal.\"\n\nDuración:\n2 oleadas\n\nEfecto:\n- Cooldowns de auras, torretas y mascotas son 3 veces más rápidos (x3)."
	},
	{
		"id": "lluvia_rabanos",
		"title": "LLUVIA DE RÁBANOS",
		"desc": "\"Los cielos nos bendicen.\"\n\nDuración:\n1 oleada\n\nEfecto:\n- Caen rábanos gigantes del cielo que aplastan enemigos y dejan XP."
	},
	{
		"id": "senal_pirata",
		"title": "SEÑAL PIRATA",
		"desc": "\"Interceptamos sus comunicaciones.\"\n\nDuración:\n2 oleadas\n\nEfecto:\n- Una nave alienígena orbital dispara láseres sobre los propios invasores."
	},
	{
		"id": "sindicato_alien",
		"title": "SINDICATO ALIENÍGENA",
		"desc": "\"Exigimos mejores condiciones laborales.\"\n\nDuración:\n2 oleadas\n\nEfecto:\n- La mitad de los alienígenas se niegan a trabajar (caminan lento o se sientan)."
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	var style = StyleBoxTexture.new()
	style.texture = tex_epica
	
	# Autowrap, tamaño y estilos estéticos de cartas para los botones
	for btn in [btn_sayonara, btn_steroids, btn_aura]:
		btn.add_theme_font_override("font", button_font)
		btn.add_theme_font_size_override("font_size", 20) # Ajustado al tamaño de habilidades normales (20)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(320, 480)

func show_menu() -> void:
	# Mezclar y elegir exactamente 2 cartas aleatorias
	var temp_pool = cards_pool.duplicate()
	temp_pool.shuffle()
	var selected_cards = [temp_pool[0], temp_pool[1]]
	
	var buttons = [btn_sayonara, btn_steroids]
	var hidden_button = btn_aura
	
	hidden_button.hide()
	
	for i in range(2):
		var card = selected_cards[i]
		var btn = buttons[i]
		btn.show()
		
		# Limpiar conexiones previas para evitar llamadas duplicadas o acumuladas
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
			
		btn.text = card["title"] + "\n\n" + card["desc"]
		btn.pressed.connect(_on_reward_selected.bind(card["id"]))
	
	get_tree().paused = true
	show()

func _on_reward_selected(id: String) -> void:
	var scene = get_tree().current_scene
	match id:
		"sayonara":
			GameManager.sayonara_uses += 1
			if scene.has_method("activate_sayonara"): scene.activate_sayonara()
		"steroids":
			GameManager.steroids_rounds = 2
			if scene.has_method("activate_steroids"): scene.activate_steroids()
		"conqueror_aura":
			GameManager.conqueror_aura_rounds = 1
		"campesino_extremo":
			GameManager.campesino_extremo_rounds = 2
			if scene.has_method("force_update_skills"): scene.force_update_skills()
		"reactor_nuclear":
			GameManager.reactor_nuclear_rounds = 2
		"sobrecarga_cuantica":
			GameManager.sobrecarga_cuantica_rounds = 2
			if scene.has_method("force_update_skills"): scene.force_update_skills()
		"lluvia_rabanos":
			GameManager.lluvia_rabanos_rounds = 1
		"senal_pirata":
			GameManager.senal_pirata_rounds = 2
		"sindicato_alien":
			GameManager.sindicato_alien_rounds = 2
	
	hide()
	get_tree().paused = false
