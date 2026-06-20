extends Control

# Nodos de Información
@onready var record_label: Label = $MarginContainer/HBoxContainer/ColLeft/RecordLabel
@onready var gold_label: Label = $MarginContainer/HBoxContainer/ColLeft/GoldLabel

# Botones Principales
@onready var btn_start: Button = $MarginContainer/HBoxContainer/ColCenter/BtnStart
@onready var btn_exit: Button = $MarginContainer/HBoxContainer/ColCenter/BtnExit

# Botones de Navegación (Derecha)
@onready var btn_shop: Button = $MarginContainer/HBoxContainer/ColRight/BtnShop
@onready var btn_upgrades: Button = $MarginContainer/HBoxContainer/ColRight/BtnUpgrades
@onready var btn_bestiary: Button = $MarginContainer/HBoxContainer/ColRight/BtnBestiary
@onready var btn_cards: Button = $MarginContainer/HBoxContainer/ColRight/BtnCards

# Botones de Utilidad (Izquierda)
@onready var btn_settings: Button = $MarginContainer/HBoxContainer/ColLeft/HBoxButtons/BtnSettings
@onready var btn_achievements: Button = $MarginContainer/HBoxContainer/ColLeft/HBoxButtons/BtnAchievements

var label_font = preload("res://scenes/Font.tres")
var button_font = preload("res://assets/fuentes/BoldPixels.ttf")

var deck_panel: Button

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Crear panel del mazo
	deck_panel = Button.new()
	deck_panel.name = "BtnDeckEditor"
	deck_panel.custom_minimum_size = Vector2(0, 75)
	
	# Estilo
	var deck_style = StyleBoxFlat.new()
	deck_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	deck_style.border_width_left = 2
	deck_style.border_width_top = 2
	deck_style.border_width_right = 2
	deck_style.border_width_bottom = 2
	deck_style.border_color = Color(0.2, 0.5, 0.8, 1)
	deck_style.corner_radius_top_left = 8
	deck_style.corner_radius_top_right = 8
	deck_style.corner_radius_bottom_right = 8
	deck_style.corner_radius_bottom_left = 8
	
	deck_panel.add_theme_stylebox_override("normal", deck_style)
	deck_panel.add_theme_stylebox_override("hover", deck_style)
	deck_panel.add_theme_stylebox_override("pressed", deck_style)
	deck_panel.add_theme_font_override("font", button_font)
	deck_panel.add_theme_font_size_override("font_size", 15)
	
	deck_panel.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MazoEditorMenu.tscn")
	)
	
	var col_center = $MarginContainer/HBoxContainer/ColCenter
	col_center.add_child(deck_panel)
	col_center.move_child(deck_panel, 2) # Justo debajo de BtnStart (BtnStart es el índice 1)
	
	update_ui()
	
	# Conexiones
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_exit.pressed.connect(_on_btn_exit_pressed)
	
	btn_upgrades.pressed.connect(_on_btn_upgrades_pressed)
	btn_cards.pressed.connect(_on_btn_cards_pressed)
	btn_bestiary.pressed.connect(_on_btn_bestiary_pressed)
	
	# Botones nuevos (Placeholders o futuras escenas)
	btn_shop.pressed.connect(_on_btn_shop_pressed)
	btn_settings.pressed.connect(show_settings_dialog)
	btn_achievements.pressed.connect(show_rank_dialog)
	
	check_daily_login()

func _on_btn_shop_pressed() -> void:
	var shop_scene = load("res://scenes/ShopMenu.tscn")
	if shop_scene:
		var shop_instance = shop_scene.instantiate()
		add_child(shop_instance)
	else:
		print("Error: No se pudo cargar ShopMenu.tscn")

func update_ui() -> void:
	if record_label:
		record_label.text = "Récord: Oleada " + str(GameManager.best_wave)
		
	if gold_label:
		gold_label.text = "Banco: " + str(GameManager.total_gold) + " Oro"
		
	if is_instance_valid(deck_panel):
		var deck_text = "MAZO: NIVEL " + str(GameManager.deck_level) + "   |   "
		var cards_names = []
		for card_id in GameManager.deck_equipped_cards:
			if card_id != "":
				var name = GameManager.skills_data.get(card_id, {}).get("name", card_id)
				cards_names.append("[" + name.to_upper() + "]")
			else:
				cards_names.append("[VACIO]")
		deck_text += "   ".join(cards_names)
		deck_panel.text = deck_text

func _on_btn_start_pressed() -> void:
	# Si califica para algún salto (oleada récord >= 20), mostramos el diálogo
	if GameManager.best_wave >= 20:
		show_wave_skip_dialog()
	else:
		_start_game_at_wave(1, 0)

func show_wave_skip_dialog() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0.05, 0.05, 0.08, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var panel = PanelContainer.new()
	overlay.add_child(panel)
	_center_panel(panel, 420, 300)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.08, 1.0)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.2, 0.5, 0.8, 1.0)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "¿DESDE DÓNDE INICIAR?"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.label_settings = label_font
	title_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_lbl)
	
	# Botón Oleada 1 (Gratis)
	var btn_w1 = Button.new()
	btn_w1.text = "OLEADA 1 (GRATIS)"
	btn_w1.custom_minimum_size = Vector2(0, 45)
	btn_w1.add_theme_font_override("font", button_font)
	btn_w1.add_theme_font_size_override("font_size", 14)
	btn_w1.pressed.connect(func():
		overlay.queue_free()
		_start_game_at_wave(1, 0)
	)
	vbox.add_child(btn_w1)
	
	# Calcular saltos disponibles en múltiplos de 10
	var w = 10
	var available_skips = []
	while GameManager.best_wave >= w * 2:
		var cost = int(500 * pow(4, (w / 10) - 1))
		available_skips.append({"wave": w, "cost": cost})
		w += 10
		
	for skip in available_skips:
		var w_val = skip["wave"]
		var cost_val = skip["cost"]
		var btn = Button.new()
		btn.text = "OLEADA " + str(w_val) + " (" + str(cost_val) + " ORO)"
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_override("font", button_font)
		btn.add_theme_font_size_override("font_size", 14)
		
		if GameManager.total_gold < cost_val:
			btn.disabled = true
			btn.text += " - ORO INSUFICIENTE"
			
		btn.pressed.connect(func():
			overlay.queue_free()
			GameManager.total_gold -= cost_val
			GameManager.save_game()
			_start_game_at_wave(w_val, cost_val)
		)
		vbox.add_child(btn)
		
	var btn_cancel = Button.new()
	btn_cancel.text = "CANCELAR"
	btn_cancel.custom_minimum_size = Vector2(0, 40)
	btn_cancel.add_theme_font_override("font", button_font)
	btn_cancel.add_theme_font_size_override("font_size", 12)
	btn_cancel.pressed.connect(func():
		overlay.queue_free()
	)
	vbox.add_child(btn_cancel)

func _start_game_at_wave(start_wave: int, cost: int) -> void:
	get_tree().paused = false
	GameManager.reset_run()
	
	if start_wave > 1:
		var accumulated_gold = 0
		for w in range(1, start_wave):
			accumulated_gold += 50 + w * 10
		GameManager.total_coins = accumulated_gold
		
		GameManager.current_level = start_wave
		GameManager.pending_level_ups = start_wave - 1
		
		var xp_req = 10
		for i in range(1, start_wave):
			xp_req = int(xp_req * 1.15)
		GameManager.xp_to_next_level = xp_req
		GameManager.current_xp = 0
		
		GameManager.current_wave = start_wave
		GameManager.is_boss_wave = (start_wave % 5 == 0)
		
		# Emitir actualizaciones para notificar al juego y componentes
		GameManager.xp_updated.emit(0, GameManager.xp_to_next_level)
		GameManager.level_up.emit(GameManager.current_level)
		GameManager.wave_updated.emit(GameManager.current_wave)
		GameManager.coins_updated.emit(GameManager.total_coins)
		
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_btn_upgrades_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UpgradeMenu.tscn")

func _on_btn_cards_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CardGalleryMenu.tscn")

func _on_btn_bestiary_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BestiaryMenu.tscn")

func _on_btn_exit_pressed() -> void:
	GameManager.save_game()
	get_tree().quit()

func show_rank_dialog() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0.05, 0.05, 0.08, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var panel = PanelContainer.new()
	overlay.add_child(panel)
	_center_panel(panel, 620, 600)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.08, 1.0)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.2, 0.5, 0.8, 1.0)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_top", 35)
	margin.add_theme_constant_override("margin_right", 35)
	margin.add_theme_constant_override("margin_bottom", 35)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 22)
	margin.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "RANGO Y ESTADÍSTICAS"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.label_settings = label_font
	title_lbl.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title_lbl)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Contar TODAS las cartas (skills + flat_upgrades)
	var total_cards = GameManager.skills_data.size() + GameManager.flat_upgrades.size()
	var unlocked_count = GameManager.unlocked_skills.size()
	var pct = 0.0
	if total_cards > 0:
		pct = (float(unlocked_count) / total_cards) * 100.0
	
	# Recalcular maestrías desde los datos reales
	var real_mastery = 0
	for k in GameManager.card_upgrade_levels:
		var val = GameManager.card_upgrade_levels[k]
		if typeof(val) == TYPE_STRING: # "4_fav" o "4_spec"
			real_mastery += 1
			
	# Sumar total de enemigos derrotados desde el bestiario
	var total_killed = 0
	for k in GameManager.bestiary.keys():
		total_killed += GameManager.bestiary[k]
	
	var stats = [
		{"name": "Récord Máximo", "val": "Oleada " + str(GameManager.best_wave), "color": Color(0.2, 0.8, 1.0)},
		{"name": "El Carnicero (Combo)", "val": str(GameManager.best_combo) + " Golpes", "color": Color(1.0, 0.4, 0.4)},
		{"name": "Exterminador (Total)", "val": str(total_killed) + " Aliens", "color": Color(0.5, 0.9, 0.5)},
		{"name": "Coleccionista (Mazo)", "val": str(unlocked_count) + "/" + str(total_cards) + " (" + ("%.1f" % pct) + "%)", "color": Color(1.0, 0.8, 0.2)},
		{"name": "Maestrías (Nivel 4)", "val": str(real_mastery) + " Cartas", "color": Color(0.8, 0.4, 1.0)}
	]
	
	for stat in stats:
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		
		var name_lbl = Label.new()
		name_lbl.text = stat["name"] + ":"
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_override("font", button_font)
		name_lbl.add_theme_font_size_override("font_size", 22)
		hbox.add_child(name_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = stat["val"]
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_override("font", button_font)
		val_lbl.add_theme_font_size_override("font_size", 22)
		val_lbl.modulate = stat["color"]
		hbox.add_child(val_lbl)
		
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	var btn_close = Button.new()
	btn_close.text = "CERRAR"
	btn_close.custom_minimum_size = Vector2(0, 70)
	btn_close.add_theme_font_override("font", button_font)
	btn_close.add_theme_font_size_override("font_size", 22)
	btn_close.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(btn_close)

func show_settings_dialog() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0.05, 0.05, 0.08, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var panel = PanelContainer.new()
	overlay.add_child(panel)
	_center_panel(panel, 660, 840)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.08, 1.0)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.2, 0.5, 0.8, 1.0)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)
	
	# TITLE
	var title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.label_settings = label_font
	title_lbl.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title_lbl)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# References for updating labels dynamically
	var lbl_music = Label.new()
	var slider_music = HSlider.new()
	var lbl_music_val = Label.new()
	
	var lbl_sfx = Label.new()
	var slider_sfx = HSlider.new()
	var lbl_sfx_val = Label.new()
	
	var lbl_damage_nums = Label.new()
	var btn_damage_nums = Button.new()
	
	var lbl_shaders = Label.new()
	var btn_shaders = Button.new()
	
	var lbl_shake = Label.new()
	var btn_shake = Button.new()
	
	var lbl_lang = Label.new()
	var btn_lang = Button.new()
	
	var credits_lbl = Label.new()
	var btn_reset = Button.new()
	var btn_close_settings = Button.new()
	
	# Helper to update texts based on current language
	var update_texts = func():
		var is_es = GameManager.language == "es"
		
		# Title
		title_lbl.text = "AJUSTES" if is_es else "SETTINGS"
		
		# Music Slider
		lbl_music.text = "Música:" if is_es else "Music:"
		lbl_music_val.text = str(int(slider_music.value * 100)) + "%"
		
		# SFX Slider
		lbl_sfx.text = "Efectos (SFX):" if is_es else "SFX Effects:"
		lbl_sfx_val.text = str(int(slider_sfx.value * 100)) + "%"
		
		# Damage Numbers Toggle
		lbl_damage_nums.text = "Números de Daño:" if is_es else "Damage Numbers:"
		if is_es:
			btn_damage_nums.text = "ACTIVADO" if GameManager.damage_numbers_enabled else "DESACTIVADO"
		else:
			btn_damage_nums.text = "ENABLED" if GameManager.damage_numbers_enabled else "DISABLED"
		
		# Shaders Toggle
		lbl_shaders.text = "Efectos / Shaders:" if is_es else "VFX / Shaders:"
		if is_es:
			btn_shaders.text = "COMPLEJOS" if GameManager.shaders_enabled else "SIMPLES"
		else:
			btn_shaders.text = "COMPLEX" if GameManager.shaders_enabled else "SIMPLE"
		
		# Screen Shake Toggle
		lbl_shake.text = "Sacudida Pantalla:" if is_es else "Screen Shake:"
		if is_es:
			btn_shake.text = "ACTIVADA" if GameManager.screen_shake_enabled else "DESACTIVADA"
		else:
			btn_shake.text = "ENABLED" if GameManager.screen_shake_enabled else "DISABLED"
			
		# Language
		lbl_lang.text = "Idioma / Language:" if is_es else "Language / Idioma:"
		btn_lang.text = "ESPAÑOL" if is_es else "ENGLISH"
		
		# Credits
		credits_lbl.text = "Ravyn Studio - Obra original respaldada por Ravyn Studio." if is_es else "Ravyn Studio - Original work backed by Ravyn Studio."
		
		# Close / Reset
		btn_reset.text = "BORRAR PARTIDA (RESET)" if is_es else "HARD RESET (DELETE SAVE)"
		btn_close_settings.text = "CERRAR Y GUARDAR" if is_es else "CLOSE & SAVE"
	
	# Add Music UI
	var hb_music = HBoxContainer.new()
	hb_music.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hb_music)
	
	lbl_music.custom_minimum_size = Vector2(250, 0)
	lbl_music.add_theme_font_override("font", button_font)
	lbl_music.add_theme_font_size_override("font_size", 22)
	hb_music.add_child(lbl_music)
	
	slider_music.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_music.custom_minimum_size = Vector2(0, 36)
	slider_music.min_value = 0.0
	slider_music.max_value = 1.0
	slider_music.step = 0.05
	slider_music.value = GameManager.music_volume
	hb_music.add_child(slider_music)
	
	lbl_music_val.custom_minimum_size = Vector2(75, 0)
	lbl_music_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_music_val.add_theme_font_override("font", button_font)
	lbl_music_val.add_theme_font_size_override("font_size", 22)
	hb_music.add_child(lbl_music_val)
	
	# Add SFX UI
	var hb_sfx = HBoxContainer.new()
	hb_sfx.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hb_sfx)
	
	lbl_sfx.custom_minimum_size = Vector2(250, 0)
	lbl_sfx.add_theme_font_override("font", button_font)
	lbl_sfx.add_theme_font_size_override("font_size", 22)
	hb_sfx.add_child(lbl_sfx)
	
	slider_sfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_sfx.custom_minimum_size = Vector2(0, 36)
	slider_sfx.min_value = 0.0
	slider_sfx.max_value = 1.0
	slider_sfx.step = 0.05
	slider_sfx.value = GameManager.sfx_volume
	hb_sfx.add_child(slider_sfx)
	
	lbl_sfx_val.custom_minimum_size = Vector2(75, 0)
	lbl_sfx_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_sfx_val.add_theme_font_override("font", button_font)
	lbl_sfx_val.add_theme_font_size_override("font_size", 22)
	hb_sfx.add_child(lbl_sfx_val)
	
	# Add Damage Numbers Toggle Row
	var hb_dmg = HBoxContainer.new()
	vbox.add_child(hb_dmg)
	lbl_damage_nums.custom_minimum_size = Vector2(300, 0)
	lbl_damage_nums.add_theme_font_override("font", button_font)
	lbl_damage_nums.add_theme_font_size_override("font_size", 22)
	hb_dmg.add_child(lbl_damage_nums)
	btn_damage_nums.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_damage_nums.custom_minimum_size = Vector2(0, 60)
	btn_damage_nums.add_theme_font_override("font", button_font)
	btn_damage_nums.add_theme_font_size_override("font_size", 20)
	hb_dmg.add_child(btn_damage_nums)
	
	# Add Shaders Toggle Row
	var hb_shad = HBoxContainer.new()
	vbox.add_child(hb_shad)
	lbl_shaders.custom_minimum_size = Vector2(300, 0)
	lbl_shaders.add_theme_font_override("font", button_font)
	lbl_shaders.add_theme_font_size_override("font_size", 22)
	hb_shad.add_child(lbl_shaders)
	btn_shaders.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_shaders.custom_minimum_size = Vector2(0, 60)
	btn_shaders.add_theme_font_override("font", button_font)
	btn_shaders.add_theme_font_size_override("font_size", 20)
	hb_shad.add_child(btn_shaders)
	
	# Add Screen Shake Toggle Row
	var hb_shk = HBoxContainer.new()
	vbox.add_child(hb_shk)
	lbl_shake.custom_minimum_size = Vector2(300, 0)
	lbl_shake.add_theme_font_override("font", button_font)
	lbl_shake.add_theme_font_size_override("font_size", 22)
	hb_shk.add_child(lbl_shake)
	btn_shake.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_shake.custom_minimum_size = Vector2(0, 60)
	btn_shake.add_theme_font_override("font", button_font)
	btn_shake.add_theme_font_size_override("font_size", 20)
	hb_shk.add_child(btn_shake)
	
	# Add Language Row
	var hb_l = HBoxContainer.new()
	vbox.add_child(hb_l)
	lbl_lang.custom_minimum_size = Vector2(300, 0)
	lbl_lang.add_theme_font_override("font", button_font)
	lbl_lang.add_theme_font_size_override("font_size", 22)
	hb_l.add_child(lbl_lang)
	btn_lang.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_lang.custom_minimum_size = Vector2(0, 60)
	btn_lang.add_theme_font_override("font", button_font)
	btn_lang.add_theme_font_size_override("font_size", 20)
	hb_l.add_child(btn_lang)
	
	# Add Credits Box
	var cred_sep = HSeparator.new()
	vbox.add_child(cred_sep)
	credits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credits_lbl.add_theme_font_override("font", button_font)
	credits_lbl.add_theme_font_size_override("font_size", 16)
	credits_lbl.modulate = Color(0.6, 0.6, 0.6, 1)
	vbox.add_child(credits_lbl)
	
	# Add Hard Reset (Red Button)
	var reset_sep = HSeparator.new()
	vbox.add_child(reset_sep)
	
	var style_reset = StyleBoxFlat.new()
	style_reset.bg_color = Color(0.7, 0.1, 0.1, 1.0)
	style_reset.border_width_left = 2
	style_reset.border_width_top = 2
	style_reset.border_width_right = 2
	style_reset.border_width_bottom = 2
	style_reset.border_color = Color(0.9, 0.3, 0.3, 1.0)
	style_reset.corner_radius_top_left = 8
	style_reset.corner_radius_top_right = 8
	style_reset.corner_radius_bottom_right = 8
	style_reset.corner_radius_bottom_left = 8
	
	btn_reset.add_theme_stylebox_override("normal", style_reset)
	btn_reset.add_theme_stylebox_override("hover", style_reset)
	btn_reset.add_theme_stylebox_override("pressed", style_reset)
	btn_reset.add_theme_font_override("font", button_font)
	btn_reset.add_theme_font_size_override("font_size", 22)
	btn_reset.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(btn_reset)
	
	# Add Close Button
	btn_close_settings.add_theme_font_override("font", button_font)
	btn_close_settings.add_theme_font_size_override("font_size", 24)
	btn_close_settings.custom_minimum_size = Vector2(0, 75)
	vbox.add_child(btn_close_settings)
	
	# Setup initial text bindings
	slider_music.value_changed.connect(func(val):
		GameManager.music_volume = val
		var music_bus_idx = AudioServer.get_bus_index("Music")
		if music_bus_idx != -1:
			AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(val))
			AudioServer.set_bus_mute(music_bus_idx, val <= 0.0)
		update_texts.call()
	)
	
	slider_sfx.value_changed.connect(func(val):
		GameManager.sfx_volume = val
		var sfx_bus_idx = AudioServer.get_bus_index("SFX")
		if sfx_bus_idx != -1:
			AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(val))
			AudioServer.set_bus_mute(sfx_bus_idx, val <= 0.0)
		update_texts.call()
	)
	
	btn_damage_nums.pressed.connect(func():
		GameManager.damage_numbers_enabled = not GameManager.damage_numbers_enabled
		update_texts.call()
	)
	
	btn_shaders.pressed.connect(func():
		GameManager.shaders_enabled = not GameManager.shaders_enabled
		update_texts.call()
	)
	
	btn_shake.pressed.connect(func():
		GameManager.screen_shake_enabled = not GameManager.screen_shake_enabled
		update_texts.call()
	)
	
	btn_lang.pressed.connect(func():
		if GameManager.language == "es":
			GameManager.language = "en"
		else:
			GameManager.language = "es"
		update_texts.call()
		update_ui() # Update main menu language too!
	)
	
	btn_reset.pressed.connect(func():
		var is_es = GameManager.language == "es"
		# Confirmación 1
		var conf1 = ColorRect.new()
		conf1.color = Color(0.1, 0.05, 0.05, 0.95)
		conf1.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.add_child(conf1)
		
		var p1 = PanelContainer.new()
		conf1.add_child(p1)
		_center_panel(p1, 560, 360)
		p1.add_theme_stylebox_override("panel", panel_style)
		
		var m1 = MarginContainer.new()
		m1.add_theme_constant_override("margin_left", 25)
		m1.add_theme_constant_override("margin_top", 25)
		m1.add_theme_constant_override("margin_right", 25)
		m1.add_theme_constant_override("margin_bottom", 25)
		p1.add_child(m1)
		
		var vb1 = VBoxContainer.new()
		vb1.add_theme_constant_override("separation", 18)
		m1.add_child(vb1)
		
		var title1 = Label.new()
		title1.text = "CONFIRMACIÓN" if is_es else "CONFIRMATION"
		title1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title1.add_theme_font_override("font", button_font)
		title1.add_theme_font_size_override("font_size", 26)
		title1.modulate = Color(1.0, 0.3, 0.3, 1.0)
		vb1.add_child(title1)
		
		var msg1 = Label.new()
		msg1.text = "¿Estás seguro de borrar todo tu progreso permanente?" if is_es else "Are you sure you want to delete all permanent progress?"
		msg1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg1.add_theme_font_override("font", button_font)
		msg1.add_theme_font_size_override("font_size", 20)
		vb1.add_child(msg1)
		
		var btn_yes1 = Button.new()
		btn_yes1.text = "SÍ, CONTINUAR" if is_es else "YES, CONTINUE"
		btn_yes1.add_theme_stylebox_override("normal", style_reset)
		btn_yes1.add_theme_stylebox_override("hover", style_reset)
		btn_yes1.add_theme_stylebox_override("pressed", style_reset)
		btn_yes1.add_theme_font_override("font", button_font)
		btn_yes1.add_theme_font_size_override("font_size", 20)
		btn_yes1.custom_minimum_size = Vector2(0, 60)
		vb1.add_child(btn_yes1)
		
		var btn_no1 = Button.new()
		btn_no1.text = "CANCELAR" if is_es else "CANCEL"
		btn_no1.add_theme_font_override("font", button_font)
		btn_no1.add_theme_font_size_override("font_size", 20)
		btn_no1.custom_minimum_size = Vector2(0, 60)
		btn_no1.pressed.connect(func(): conf1.queue_free())
		vb1.add_child(btn_no1)
		
		btn_yes1.pressed.connect(func():
			var conf2 = ColorRect.new()
			conf2.color = Color(0.0, 0.0, 0.0, 0.95)
			conf2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			conf1.add_child(conf2)
			
			var p2 = PanelContainer.new()
			conf2.add_child(p2)
			_center_panel(p2, 560, 360)
			p2.add_theme_stylebox_override("panel", panel_style)
			
			var m2 = MarginContainer.new()
			m2.add_theme_constant_override("margin_left", 25)
			m2.add_theme_constant_override("margin_top", 25)
			m2.add_theme_constant_override("margin_right", 25)
			m2.add_theme_constant_override("margin_bottom", 25)
			p2.add_child(m2)
			
			var vb2 = VBoxContainer.new()
			vb2.add_theme_constant_override("separation", 18)
			m2.add_child(vb2)
			
			var title2 = Label.new()
			title2.text = "¡ADVERTENCIA FINAL!" if is_es else "FINAL WARNING!"
			title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title2.add_theme_font_override("font", button_font)
			title2.add_theme_font_size_override("font_size", 26)
			title2.modulate = Color(1.0, 0.1, 0.1, 1.0)
			vb2.add_child(title2)
			
			var msg2 = Label.new()
			msg2.text = "¿ESTÁS COMPLETAMENTE SEGURO? Esta acción es irreversible." if is_es else "ARE YOU ABSOLUTELY SURE? This action cannot be undone."
			msg2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			msg2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			msg2.add_theme_font_override("font", button_font)
			msg2.add_theme_font_size_override("font_size", 20)
			vb2.add_child(msg2)
			
			var btn_yes2 = Button.new()
			btn_yes2.text = "SÍ, BORRAR TODO" if is_es else "YES, DELETE ALL"
			btn_yes2.add_theme_stylebox_override("normal", style_reset)
			btn_yes2.add_theme_stylebox_override("hover", style_reset)
			btn_yes2.add_theme_stylebox_override("pressed", style_reset)
			btn_yes2.add_theme_font_override("font", button_font)
			btn_yes2.add_theme_font_size_override("font_size", 20)
			btn_yes2.custom_minimum_size = Vector2(0, 60)
			vb2.add_child(btn_yes2)
			
			var btn_no2 = Button.new()
			btn_no2.text = "CANCELAR" if is_es else "CANCEL"
			btn_no2.add_theme_font_override("font", button_font)
			btn_no2.add_theme_font_size_override("font_size", 20)
			btn_no2.custom_minimum_size = Vector2(0, 60)
			btn_no2.pressed.connect(func(): conf2.queue_free())
			vb2.add_child(btn_no2)
			
			btn_yes2.pressed.connect(func():
				GameManager.hard_reset()
				update_ui()
				overlay.queue_free()
			)
		)
	)
	
	btn_close_settings.pressed.connect(func():
		GameManager.save_game()
		overlay.queue_free()
	)
	
	update_texts.call()

func check_daily_login() -> void:
	var current_day = int(Time.get_unix_time_from_system() / 86400)
	var last_day = GameManager.last_login_day_num
	
	# Si ya reclamó hoy, no hacer nada
	if last_day == current_day:
		return
		
	var streak = GameManager.consecutive_logins
	if last_day == 0:
		# Primer inicio de sesión
		streak = 1
	elif current_day == last_day + 1:
		# Día consecutivo
		streak += 1
		if streak > 7:
			streak = 1
	else:
		# Se rompió la racha (pasó más de un día)
		streak = 1
		
	GameManager.consecutive_logins = streak
	show_daily_login_dialog(streak)

func show_daily_login_dialog(active_day: int) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0.05, 0.05, 0.08, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var panel = PanelContainer.new()
	overlay.add_child(panel)
	_center_panel(panel, 650, 600)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 1.0)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(1.0, 0.8, 0.2, 1.0) # Borde dorado
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# TITLE
	var is_es = GameManager.language == "es"
	var title_lbl = Label.new()
	title_lbl.text = "RECOMPENSA DIARIA" if is_es else "DAILY REWARD"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.label_settings = label_font
	title_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = "¡Inicia sesión todos los días para obtener monedas!" if is_es else "Log in daily to earn coins!"
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_override("font", button_font)
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(desc_lbl)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Grid de 7 días
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid)
	
	for i in range(1, 8):
		var card = PanelContainer.new()
		grid.add_child(card)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var card_style = StyleBoxFlat.new()
		card_style.corner_radius_top_left = 10
		card_style.corner_radius_top_right = 10
		card_style.corner_radius_bottom_right = 10
		card_style.corner_radius_bottom_left = 10
		
		# Determinar estado visual del día
		if i < active_day:
			# Día ya reclamado o pasado
			card_style.bg_color = Color(0.04, 0.04, 0.06, 0.8)
			card_style.border_width_left = 2
			card_style.border_width_top = 2
			card_style.border_width_right = 2
			card_style.border_width_bottom = 2
			card_style.border_color = Color(0.2, 0.2, 0.2, 0.8)
			card.modulate = Color(0.5, 0.5, 0.5, 0.8)
		elif i == active_day:
			# Día actual a reclamar (brillante / dorado)
			card_style.bg_color = Color(0.15, 0.12, 0.05, 1.0)
			card_style.border_width_left = 3
			card_style.border_width_top = 3
			card_style.border_width_right = 3
			card_style.border_width_bottom = 3
			card_style.border_color = Color(1.0, 0.8, 0.2, 1.0)
		else:
			# Días futuros bloqueados
			card_style.bg_color = Color(0.06, 0.06, 0.09, 1.0)
			card_style.border_width_left = 2
			card_style.border_width_top = 2
			card_style.border_width_right = 2
			card_style.border_width_bottom = 2
			card_style.border_color = Color(0.15, 0.15, 0.2, 0.8)
			
		card.add_theme_stylebox_override("panel", card_style)
		
		var card_margin = MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 10)
		card_margin.add_theme_constant_override("margin_top", 10)
		card_margin.add_theme_constant_override("margin_right", 10)
		card_margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(card_margin)
		
		var card_vb = VBoxContainer.new()
		card_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		card_margin.add_child(card_vb)
		
		# Label Día
		var day_lbl = Label.new()
		day_lbl.text = ("DÍA " if is_es else "DAY ") + str(i)
		day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_lbl.add_theme_font_override("font", button_font)
		day_lbl.add_theme_font_size_override("font_size", 14)
		if i == active_day:
			day_lbl.modulate = Color(1.0, 0.8, 0.2)
		card_vb.add_child(day_lbl)
		
		# Label Recompensa
		var reward_val = i * 100
		var reward_lbl = Label.new()
		reward_lbl.text = str(reward_val) + " 🪙"
		reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_lbl.add_theme_font_override("font", button_font)
		reward_lbl.add_theme_font_size_override("font_size", 16)
		card_vb.add_child(reward_lbl)
		
		if i == active_day:
			var act_lbl = Label.new()
			act_lbl.text = "¡HOY!" if is_es else "TODAY!"
			act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			act_lbl.add_theme_font_override("font", button_font)
			act_lbl.add_theme_font_size_override("font_size", 11)
			act_lbl.modulate = Color(0.2, 1.0, 0.2)
			card_vb.add_child(act_lbl)
			
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	# Botón de Reclamar
	var btn_claim = Button.new()
	btn_claim.text = "RECLAMAR " + str(active_day * 100) + " MONEDAS" if is_es else "CLAIM " + str(active_day * 100) + " COINS"
	btn_claim.custom_minimum_size = Vector2(0, 65)
	
	var claim_style = StyleBoxFlat.new()
	claim_style.bg_color = Color(0.1, 0.7, 0.1, 1.0)
	claim_style.border_width_left = 3
	claim_style.border_width_top = 3
	claim_style.border_width_right = 3
	claim_style.border_width_bottom = 3
	claim_style.border_color = Color(0.3, 0.9, 0.3, 1.0)
	claim_style.corner_radius_top_left = 10
	claim_style.corner_radius_top_right = 10
	claim_style.corner_radius_bottom_right = 10
	claim_style.corner_radius_bottom_left = 10
	
	btn_claim.add_theme_stylebox_override("normal", claim_style)
	btn_claim.add_theme_stylebox_override("hover", claim_style)
	btn_claim.add_theme_stylebox_override("pressed", claim_style)
	btn_claim.add_theme_font_override("font", button_font)
	btn_claim.add_theme_font_size_override("font_size", 22)
	vbox.add_child(btn_claim)
	
	btn_claim.pressed.connect(func():
		var reward = active_day * 100
		GameManager.total_gold += reward
		GameManager.last_login_day_num = int(Time.get_unix_time_from_system() / 86400)
		GameManager.save_game()
		update_ui()
		overlay.queue_free()
	)

func _center_panel(panel: Control, width: float, height: float) -> void:
	panel.custom_minimum_size = Vector2(width, height)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -width / 2.0
	panel.offset_right = width / 2.0
	panel.offset_top = -height / 2.0
	panel.offset_bottom = height / 2.0
