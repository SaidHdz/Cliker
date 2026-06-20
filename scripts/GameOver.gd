extends Control

@onready var stats_label = get_node_or_null("VBoxContainer/StatsLabel")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup Blur
	var blur_bg = ColorRect.new()
	blur_bg.color = Color(0,0,0,0.5)
	blur_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(blur_bg)
	move_child(blur_bg, 0)
	
	var shader = Shader.new()
	shader.code = "shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, 4.0);
		COLOR.rgb *= 0.5;
	}"
	var mat = ShaderMaterial.new(); mat.shader = shader
	blur_bg.material = mat
	
	# Buscar los botones e intentar conectarlos automáticamente por si acaso
	var btn_restart = get_node_or_null("VBoxContainer/BtnRestart")
	if btn_restart and not btn_restart.pressed.is_connected(_on_btn_restart_pressed):
		btn_restart.pressed.connect(_on_btn_restart_pressed)
		
	var btn_menu = get_node_or_null("VBoxContainer/BtnMenu")
	if btn_menu and not btn_menu.pressed.is_connected(_on_btn_menu_pressed):
		btn_menu.pressed.connect(_on_btn_menu_pressed)
		
	# Búsqueda alternativa del StatsLabel si no está en el VBox
	if not stats_label:
		stats_label = get_node_or_null("StatsLabel")

func show_game_over() -> void:
	visible = true
	get_tree().paused = true
	
	# Calcular oro: 1 moneda por enemigo + bono por oleada
	var gold_earned = GameManager.enemies_defeated + (GameManager.current_wave * 2)
	GameManager.total_gold += gold_earned
	GameManager.increment_stat("losses", 1)
	GameManager.increment_stat("radishes_lost", 1)
	GameManager.increment_stat("gold_earned", gold_earned)
	
	# Actualizar records en profile_stats
	if GameManager.enemies_defeated > GameManager.profile_stats.get("max_kills_in_match", 0):
		GameManager.profile_stats["max_kills_in_match"] = GameManager.enemies_defeated
	if gold_earned > GameManager.profile_stats.get("max_gold_in_match", 0):
		GameManager.profile_stats["max_gold_in_match"] = gold_earned
	if GameManager.current_level > GameManager.profile_stats.get("max_level_reached", 1):
		GameManager.profile_stats["max_level_reached"] = GameManager.current_level
		
	GameManager.save_game() # Guardar el oro ganado y récords
	
	# Mostrar las estadísticas si el Label existe
	if stats_label:
		stats_label.text = "Oleada Alcanzada: %d\nEnemigos Eliminados: %d\nNivel Final: %d\nOro Ganado: %d" % [GameManager.current_wave, GameManager.enemies_defeated, GameManager.current_level, gold_earned]

func _on_btn_restart_pressed() -> void:
	print("DEBUG: Reiniciando partida desde GameOver...")
	# Quitamos la pausa DE MANERA EXPLÍCITA antes de cualquier otra cosa
	get_tree().paused = false
	
	# Reiniciamos datos
	GameManager.reset_run()
	
	# Recargamos la escena principal
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_btn_menu_pressed() -> void:
	# Quitamos la pausa y volvemos al inicio
	get_tree().paused = false
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://scenes/MenuInicio.tscn")
