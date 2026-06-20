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
var next_unlock_panel: PanelContainer
var next_unlock_lbl: Label

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
	
	# Conexiones
	btn_start.pressed.connect(_on_btn_start_pressed)
	
	# Ocultar botón de salir original ya que se movió a Ajustes
	if btn_exit:
		btn_exit.visible = false
		
	# Personalizar nombres de los botones de la derecha
	if btn_cards:
		btn_cards.text = "CARTAS\nColección"
	if btn_upgrades:
		btn_upgrades.text = "LABORATORIO\nMejoras"
	
	btn_upgrades.pressed.connect(_on_btn_upgrades_pressed)
	btn_cards.pressed.connect(_on_btn_cards_pressed)
	btn_bestiary.pressed.connect(_on_btn_bestiary_pressed)
	
	# Botones nuevos (Placeholders o futuras escenas)
	btn_shop.pressed.connect(_on_btn_shop_pressed)
	btn_settings.pressed.connect(show_settings_dialog)
	btn_achievements.pressed.connect(show_rank_dialog)
	
	check_daily_login()
	
	# Botón de Perfil dinámico arriba del Récord
	var profile_btn = Button.new()
	profile_btn.name = "BtnProfile"
	profile_btn.custom_minimum_size = Vector2(0, 80)
	
	var prof_style = StyleBoxFlat.new()
	prof_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	prof_style.border_width_left = 2
	prof_style.border_width_top = 2
	prof_style.border_width_right = 2
	prof_style.border_width_bottom = 2
	prof_style.border_color = Color(0.8, 0.6, 0.2, 1) # Borde dorado
	prof_style.corner_radius_top_left = 8
	prof_style.corner_radius_top_right = 8
	prof_style.corner_radius_bottom_right = 8
	prof_style.corner_radius_bottom_left = 8
	profile_btn.add_theme_stylebox_override("normal", prof_style)
	profile_btn.add_theme_stylebox_override("hover", prof_style)
	profile_btn.add_theme_stylebox_override("pressed", prof_style)
	profile_btn.pressed.connect(show_profile_dialog)
	
	var prof_hbox = HBoxContainer.new()
	prof_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prof_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prof_hbox.add_theme_constant_override("separation", 15)
	profile_btn.add_child(prof_hbox)
	
	var prof_margin = MarginContainer.new()
	prof_margin.add_theme_constant_override("margin_left", 15)
	prof_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prof_hbox.add_child(prof_margin)
	
	var btn_avatar_rect = TextureRect.new()
	btn_avatar_rect.name = "AvatarRect"
	btn_avatar_rect.custom_minimum_size = Vector2(48, 48)
	btn_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	btn_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	btn_avatar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prof_margin.add_child(btn_avatar_rect)
	
	var btn_labels_vb = VBoxContainer.new()
	btn_labels_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_labels_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prof_hbox.add_child(btn_labels_vb)
	
	var btn_name_lbl = Label.new()
	btn_name_lbl.name = "NameLabel"
	btn_name_lbl.add_theme_font_override("font", button_font)
	btn_name_lbl.add_theme_font_size_override("font_size", 16)
	btn_labels_vb.add_child(btn_name_lbl)
	
	var btn_title_lbl = Label.new()
	btn_title_lbl.name = "TitleLabel"
	btn_title_lbl.add_theme_font_override("font", button_font)
	btn_title_lbl.add_theme_font_size_override("font_size", 12)
	btn_title_lbl.modulate = Color(0.9, 0.8, 0.4)
	btn_labels_vb.add_child(btn_title_lbl)
	
	var col_left = $MarginContainer/HBoxContainer/ColLeft
	col_left.add_child(profile_btn)
	col_left.move_child(profile_btn, 0) # Colocar arriba del récord
	
	# Panel del próximo desbloqueo dinámico
	next_unlock_panel = PanelContainer.new()
	var unlock_style = StyleBoxFlat.new()
	unlock_style.bg_color = Color(0.06, 0.06, 0.08, 0.8)
	unlock_style.border_width_left = 2; unlock_style.border_width_top = 2
	unlock_style.border_width_right = 2; unlock_style.border_width_bottom = 2
	unlock_style.border_color = Color(0.3, 0.3, 0.4, 0.8)
	unlock_style.corner_radius_top_left = 8
	unlock_style.corner_radius_top_right = 8
	unlock_style.corner_radius_bottom_right = 8
	unlock_style.corner_radius_bottom_left = 8
	next_unlock_panel.add_theme_stylebox_override("panel", unlock_style)
	
	var unlock_margin = MarginContainer.new()
	unlock_margin.add_theme_constant_override("margin_left", 12)
	unlock_margin.add_theme_constant_override("margin_top", 12)
	unlock_margin.add_theme_constant_override("margin_right", 12)
	unlock_margin.add_theme_constant_override("margin_bottom", 12)
	next_unlock_panel.add_child(unlock_margin)
	
	next_unlock_lbl = Label.new()
	next_unlock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_unlock_lbl.add_theme_font_override("font", button_font)
	next_unlock_lbl.add_theme_font_size_override("font_size", 15)
	unlock_margin.add_child(next_unlock_lbl)
	col_left.add_child(next_unlock_panel)
	
	update_ui()

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
		
	# Actualizar botón de perfil
	var prof_btn = $MarginContainer/HBoxContainer/ColLeft.get_node_or_null("BtnProfile")
	if is_instance_valid(prof_btn):
		var avatar = GameManager.profile_stats.get("equipped_avatar", "Alien Normal")
		var tex_path = "res://assets/img/alien_normal.png"
		var mod_color = Color.WHITE
		if avatar == "Alien Normal": tex_path = "res://assets/img/alien_normal.png"
		elif avatar == "Alien Curador": tex_path = "res://assets/img/alien_curandero.png"
		elif avatar == "Alien Kamikaze": tex_path = "res://assets/img/alien_kamikaze.png"
		elif avatar == "Devorarábanos": tex_path = "res://assets/img/rabanito_diablo.png"
		elif avatar == "Chayanne": tex_path = "res://assets/img/alien_amigo.png"
		elif avatar == "Papa Espantapájaros": tex_path = "res://assets/img/alien_minero.png"
		elif avatar == "Rábano Dorado":
			tex_path = "res://assets/img/rabanito.png"
			mod_color = Color(1.0, 0.8, 0.1)
		elif avatar == "Rábano Cósmico":
			tex_path = "res://assets/img/rabanito.png"
			mod_color = Color(0.6, 0.3, 1.0)
			
		var rect = prof_btn.find_child("AvatarRect", true, false)
		if is_instance_valid(rect):
			rect.texture = load(tex_path)
			rect.modulate = mod_color
			
		var name_lbl = prof_btn.find_child("NameLabel", true, false)
		if is_instance_valid(name_lbl):
			name_lbl.text = GameManager.profile_stats.get("player_name", "Said")
			
		var title_lbl = prof_btn.find_child("TitleLabel", true, false)
		if is_instance_valid(title_lbl):
			title_lbl.text = GameManager.profile_stats.get("equipped_title", "Novato del Huerto")
		
	# Actualizar próximo desbloqueo
	if is_instance_valid(next_unlock_lbl):
		var record = GameManager.best_wave
		var is_es = GameManager.language == "es"
		if record < 25:
			next_unlock_lbl.text = ("PRÓXIMO\nSlot de Mazo 2\nOleada 25\n" if is_es else "NEXT\nDeck Slot 2\nWave 25\n") + str(record) + " / 25"
		elif record < 50:
			next_unlock_lbl.text = ("PRÓXIMO\nPrestigio\nOleada 50\n" if is_es else "NEXT\nPrestige\nWave 50\n") + str(record) + " / 50"
		else:
			next_unlock_lbl.text = "PRÓXIMO\n¡Todo Desbloqueado!" if is_es else "NEXT\nEverything Unlocked!"

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
	
	# Contar TODAS las cartas excluyendo sinergias (legendarias)
	var total_cards = 0
	var unlocked_count = 0
	for k in GameManager.skills_data.keys():
		var info = GameManager.skills_data[k]
		if info.get("rarity", "") != "legendaria":
			total_cards += 1
			if GameManager.unlocked_skills.has(k):
				unlocked_count += 1
	for k in GameManager.flat_upgrades.keys():
		var info = GameManager.flat_upgrades[k]
		if info.get("rarity", "") != "legendaria":
			total_cards += 1
			if GameManager.unlocked_skills.has(k):
				unlocked_count += 1
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
	_center_panel(panel, 660, 480)
	
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
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# TITLE
	var title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.label_settings = label_font
	title_lbl.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title_lbl)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# ScrollContainer for settings controls
	var settings_scroll = ScrollContainer.new()
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(settings_scroll)
	_setup_drag_scroll(settings_scroll)
	
	var settings_vbox = VBoxContainer.new()
	settings_vbox.add_theme_constant_override("separation", 18)
	settings_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.add_child(settings_vbox)
	
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
	var btn_exit_game = Button.new()
	
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
		credits_lbl.text = "Dev.Diablo - Obra original respaldada por Dev.Diablo." if is_es else "Dev.Diablo - Original work backed by Dev.Diablo."
		
		# Close / Reset / Exit
		btn_reset.text = "BORRAR PARTIDA (RESET)" if is_es else "HARD RESET (DELETE SAVE)"
		btn_exit_game.text = "SALIR DEL JUEGO" if is_es else "EXIT GAME"
		btn_close_settings.text = "CERRAR Y GUARDAR" if is_es else "CLOSE & SAVE"
	
	# Add Music UI
	var hb_music = HBoxContainer.new()
	hb_music.alignment = BoxContainer.ALIGNMENT_CENTER
	settings_vbox.add_child(hb_music)
	
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
	settings_vbox.add_child(hb_sfx)
	
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
	settings_vbox.add_child(hb_dmg)
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
	settings_vbox.add_child(hb_shad)
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
	settings_vbox.add_child(hb_shk)
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
	settings_vbox.add_child(hb_l)
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
	settings_vbox.add_child(cred_sep)
	credits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credits_lbl.add_theme_font_override("font", button_font)
	credits_lbl.add_theme_font_size_override("font_size", 16)
	credits_lbl.modulate = Color(0.6, 0.6, 0.6, 1)
	settings_vbox.add_child(credits_lbl)
	
	# Add Hard Reset and Exit Buttons inside settings side-by-side
	var reset_sep = HSeparator.new()
	settings_vbox.add_child(reset_sep)
	
	var style_reset = StyleBoxFlat.new()
	style_reset.bg_color = Color(0.7, 0.1, 0.1, 1.0)
	style_reset.border_width_left = 2; style_reset.border_width_top = 2
	style_reset.border_width_right = 2; style_reset.border_width_bottom = 2
	style_reset.border_color = Color(0.9, 0.3, 0.3, 1.0)
	style_reset.corner_radius_top_left = 8; style_reset.corner_radius_top_right = 8
	style_reset.corner_radius_bottom_right = 8; style_reset.corner_radius_bottom_left = 8
	
	btn_reset.add_theme_stylebox_override("normal", style_reset)
	btn_reset.add_theme_stylebox_override("hover", style_reset)
	btn_reset.add_theme_stylebox_override("pressed", style_reset)
	btn_reset.add_theme_font_override("font", button_font)
	btn_reset.add_theme_font_size_override("font_size", 20)
	btn_reset.custom_minimum_size = Vector2(0, 60)
	btn_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style_exit = StyleBoxFlat.new()
	style_exit.bg_color = Color(0.35, 0.1, 0.1, 1.0)
	style_exit.border_width_left = 2; style_exit.border_width_top = 2
	style_exit.border_width_right = 2; style_exit.border_width_bottom = 2
	style_exit.border_color = Color(0.55, 0.2, 0.2, 1.0)
	style_exit.corner_radius_top_left = 8; style_exit.corner_radius_top_right = 8
	style_exit.corner_radius_bottom_right = 8; style_exit.corner_radius_bottom_left = 8
	
	btn_exit_game.add_theme_stylebox_override("normal", style_exit)
	btn_exit_game.add_theme_stylebox_override("hover", style_exit)
	btn_exit_game.add_theme_stylebox_override("pressed", style_exit)
	btn_exit_game.add_theme_font_override("font", button_font)
	btn_exit_game.add_theme_font_size_override("font_size", 20)
	btn_exit_game.custom_minimum_size = Vector2(0, 60)
	btn_exit_game.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hb_reset_exit = HBoxContainer.new()
	hb_reset_exit.add_theme_constant_override("separation", 15)
	hb_reset_exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_vbox.add_child(hb_reset_exit)
	
	hb_reset_exit.add_child(btn_reset)
	hb_reset_exit.add_child(btn_exit_game)
	
	# Add Close Button (pinned to bottom of vbox)
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
	
	btn_exit_game.pressed.connect(func():
		GameManager.save_game()
		get_tree().quit()
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
		reward_lbl.text = str(reward_val) + "M"
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

func _get_prestige_roman(num: int) -> String:
	if num <= 0: return ""
	var romans = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	if num <= romans.size():
		return "Prestigio " + romans[num - 1]
	return "Prestigio " + str(num)

func _format_time(seconds: float) -> String:
	var hrs = int(seconds / 3600)
	var mins = int((int(seconds) % 3600) / 60)
	var secs = int(seconds) % 60
	if hrs > 0:
		return "%dh %dm %ds" % [hrs, mins, secs]
	elif mins > 0:
		return "%dm %ds" % [mins, secs]
	else:
		return "%ds" % [secs]

func show_profile_dialog() -> void:
	var is_es = GameManager.language == "es"
	var overlay = ColorRect.new()
	overlay.color = Color(0.05, 0.05, 0.08, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var panel = PanelContainer.new()
	overlay.add_child(panel)
	_center_panel(panel, 860, 540)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.8, 0.6, 0.2, 1.0)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Botón de cerrar en la esquina superior derecha del panel (fuera de márgenes)
	var btn_close_top = Button.new()
	btn_close_top.text = " X "
	btn_close_top.custom_minimum_size = Vector2(36, 36)
	btn_close_top.add_theme_font_override("font", button_font)
	btn_close_top.add_theme_font_size_override("font_size", 14)
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.35, 0.1, 0.1, 1.0)
	close_style.set_corner_radius_all(6)
	btn_close_top.add_theme_stylebox_override("normal", close_style)
	btn_close_top.add_theme_stylebox_override("hover", close_style)
	btn_close_top.add_theme_stylebox_override("pressed", close_style)
	
	panel.add_child(btn_close_top)
	btn_close_top.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_close_top.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	btn_close_top.grow_vertical = Control.GROW_DIRECTION_END
	btn_close_top.offset_left = -46
	btn_close_top.offset_top = 10
	btn_close_top.offset_right = -10
	btn_close_top.offset_bottom = 46
	
	btn_close_top.pressed.connect(func():
		update_ui()
		overlay.queue_free()
	)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	var header_vb = VBoxContainer.new()
	header_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	header_vb.add_theme_constant_override("separation", 10)
	vbox.add_child(header_vb)
	
	var title_lbl = Label.new()
	title_lbl.text = "PERFIL" if is_es else "PROFILE"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.label_settings = label_font
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_vb.add_child(title_lbl)
	
	# HBox para foto + nombre + boton guardar
	var name_hbox = HBoxContainer.new()
	name_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	name_hbox.add_theme_constant_override("separation", 15)
	header_vb.add_child(name_hbox)
	
	var avatar_rect = TextureRect.new()
	avatar_rect.custom_minimum_size = Vector2(64, 64)
	avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	name_hbox.add_child(avatar_rect)
	
	var name_edit = LineEdit.new()
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.add_theme_font_override("font", button_font)
	name_edit.add_theme_font_size_override("font_size", 16)
	name_edit.custom_minimum_size = Vector2(240, 42)
	name_edit.max_length = 15
	name_hbox.add_child(name_edit)
	
	var btn_save_name = Button.new()
	btn_save_name.text = "GUARDAR" if is_es else "SAVE"
	btn_save_name.custom_minimum_size = Vector2(110, 42)
	btn_save_name.add_theme_font_override("font", button_font)
	btn_save_name.add_theme_font_size_override("font_size", 12)
	
	var save_style = StyleBoxFlat.new()
	save_style.bg_color = Color(0.12, 0.45, 0.22, 1.0)
	save_style.set_corner_radius_all(6)
	btn_save_name.add_theme_stylebox_override("normal", save_style)
	btn_save_name.add_theme_stylebox_override("hover", save_style)
	btn_save_name.add_theme_stylebox_override("pressed", save_style)
	name_hbox.add_child(btn_save_name)
	
	btn_save_name.pressed.connect(func():
		var new_name = name_edit.text.strip_edges()
		if new_name == "":
			new_name = "Said"
		GameManager.profile_stats["player_name"] = new_name
		GameManager.save_game()
		name_edit.text = new_name
		btn_save_name.text = "OK!"
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(btn_save_name):
			btn_save_name.text = "GUARDAR" if is_es else "SAVE"
	)
	
	var title_equip_lbl = Label.new()
	title_equip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_equip_lbl.add_theme_font_override("font", button_font)
	title_equip_lbl.add_theme_font_size_override("font_size", 14)
	title_equip_lbl.modulate = Color(0.9, 0.8, 0.4)
	header_vb.add_child(title_equip_lbl)
	
	var prestige_lbl = Label.new()
	prestige_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prestige_lbl.add_theme_font_override("font", button_font)
	prestige_lbl.add_theme_font_size_override("font_size", 14)
	prestige_lbl.modulate = Color(0.3, 0.7, 1.0)
	header_vb.add_child(prestige_lbl)
	
	var update_header = func():
		var avatar = GameManager.profile_stats.get("equipped_avatar", "Alien Normal")
		var tex_path = "res://assets/img/alien_normal.png"
		var mod_color = Color.WHITE
		if avatar == "Alien Normal": tex_path = "res://assets/img/alien_normal.png"
		elif avatar == "Alien Curador": tex_path = "res://assets/img/alien_curandero.png"
		elif avatar == "Alien Kamikaze": tex_path = "res://assets/img/alien_kamikaze.png"
		elif avatar == "Devorarábanos": tex_path = "res://assets/img/rabanito_diablo.png"
		elif avatar == "Chayanne": tex_path = "res://assets/img/alien_amigo.png"
		elif avatar == "Papa Espantapájaros": tex_path = "res://assets/img/alien_minero.png"
		elif avatar == "Rábano Dorado":
			tex_path = "res://assets/img/rabanito.png"
			mod_color = Color(1.0, 0.8, 0.1)
		elif avatar == "Rábano Cósmico":
			tex_path = "res://assets/img/rabanito.png"
			mod_color = Color(0.6, 0.3, 1.0)
			
		avatar_rect.texture = load(tex_path)
		avatar_rect.modulate = mod_color
		name_edit.text = GameManager.profile_stats.get("player_name", "Said")
		title_equip_lbl.text = GameManager.profile_stats.get("equipped_title", "Novato del Huerto")
		
		var prestige_val = GameManager.profile_stats.get("prestige", 0)
		if prestige_val > 0:
			prestige_lbl.text = _get_prestige_roman(prestige_val)
			prestige_lbl.visible = true
		else:
			prestige_lbl.visible = false
	
	update_header.call()
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# HBox inferior dividido en 20% y 80%
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 20)
	bottom_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(bottom_hbox)
	
	# Left: nav_scroll (20%)
	var nav_scroll = ScrollContainer.new()
	nav_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_scroll.size_flags_stretch_ratio = 1.0
	bottom_hbox.add_child(nav_scroll)
	_setup_drag_scroll(nav_scroll)
	
	var nav_vbox = VBoxContainer.new()
	nav_vbox.add_theme_constant_override("separation", 10)
	nav_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_scroll.add_child(nav_vbox)
	
	# Right: detail_scroll (80%)
	var detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_stretch_ratio = 4.0
	bottom_hbox.add_child(detail_scroll)
	_setup_drag_scroll(detail_scroll)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 8)
	detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(detail_vbox)
	
	var cats = [
		"Estadísticas" if is_es else "Stats",
		"Récords" if is_es else "Records",
		"Títulos" if is_es else "Titles",
		"Avatares" if is_es else "Avatars",
		"Colección" if is_es else "Collection",
		"Curiosidades" if is_es else "Trivia"
	]
	
	var cat_buttons = []
	for cat in cats:
		var btn = Button.new()
		btn.text = cat.to_upper()
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_override("font", button_font)
		btn.add_theme_font_size_override("font_size", 12)
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.12, 0.12, 0.16, 0.9)
		btn_style.border_width_left = 2; btn_style.border_width_top = 2
		btn_style.border_width_right = 2; btn_style.border_width_bottom = 2
		btn_style.border_color = Color(0.25, 0.25, 0.35, 1.0)
		btn_style.corner_radius_top_left = 8; btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_right = 8; btn_style.corner_radius_bottom_left = 8
		
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("hover", btn_style)
		btn.add_theme_stylebox_override("pressed", btn_style)
		
		nav_vbox.add_child(btn)
		cat_buttons.append({"btn": btn, "style": btn_style, "cat": cat})
		
	var update_active_button = func(active_cat: String):
		for item in cat_buttons:
			if item.cat == active_cat:
				item.style.border_color = Color(0.8, 0.6, 0.2, 1.0) # Gold border for selected
				item.style.bg_color = Color(0.16, 0.16, 0.22, 1.0)
			else:
				item.style.border_color = Color(0.25, 0.25, 0.35, 1.0) # Normal border
				item.style.bg_color = Color(0.12, 0.12, 0.16, 0.9)
				
	for item in cat_buttons:
		var current_cat = item.cat
		_connect_button_with_drag_protection(item.btn, func():
			update_active_button.call(current_cat)
			_populate_profile_category(current_cat, detail_vbox, avatar_rect, title_equip_lbl)
		)
		
	# Populate by default with the first category (Stats)
	var default_cat = "Estadísticas" if is_es else "Stats"
	update_active_button.call(default_cat)
	_populate_profile_category(default_cat, detail_vbox, avatar_rect, title_equip_lbl)

func _populate_profile_category(cat_name: String, detail_vbox: VBoxContainer, header_avatar_rect: TextureRect, header_title_equip_lbl: Label) -> void:
	var is_es = GameManager.language == "es"
	
	for child in detail_vbox.get_children():
		child.queue_free()
		
	# Calcular cartas (comunes, raras, épicas, cofre) excluyendo sinergias (legendarias)
	var cards_total = 0
	var cards_unlocked = 0
	for k in GameManager.skills_data.keys():
		var info = GameManager.skills_data[k]
		if info.get("rarity", "") != "legendaria":
			cards_total += 1
			if GameManager.unlocked_skills.has(k):
				cards_unlocked += 1
	for k in GameManager.flat_upgrades.keys():
		var info = GameManager.flat_upgrades[k]
		if info.get("rarity", "") != "legendaria":
			cards_total += 1
			if GameManager.unlocked_skills.has(k):
				cards_unlocked += 1
		
	if cat_name.contains("Estadísticas") or cat_name.contains("Stats"):
		var add_lbl = func(txt: String, size = 15):
			var lbl = Label.new()
			lbl.text = txt
			lbl.add_theme_font_override("font", button_font)
			lbl.add_theme_font_size_override("font_size", size)
			detail_vbox.add_child(lbl)
			
		var add_header = func(txt: String):
			var sep_line = HSeparator.new()
			detail_vbox.add_child(sep_line)
			var lbl = Label.new()
			lbl.text = txt
			lbl.add_theme_font_override("font", button_font)
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.modulate = Color(0.4, 0.8, 1.0)
			detail_vbox.add_child(lbl)
			
		add_header.call("ESTADISTICAS GENERALES" if is_es else "GENERAL STATS")
		add_lbl.call(("Tiempo Jugado: " if is_es else "Time Played: ") + _format_time(GameManager.profile_stats.get("time_played", 0.0)))
		add_lbl.call(("Partidas Jugadas: " if is_es else "Matches Played: ") + str(GameManager.profile_stats.get("matches_played", 0)))
		add_lbl.call(("Victorias: " if is_es else "Wins: ") + str(GameManager.profile_stats.get("wins", 0)))
		add_lbl.call(("Derrotas: " if is_es else "Losses: ") + str(GameManager.profile_stats.get("losses", 0)))
		add_lbl.call(("Oleada Maxima: " if is_es else "Max Wave: ") + str(GameManager.best_wave))
		add_lbl.call(("Prestigios: " if is_es else "Prestiges: ") + str(GameManager.profile_stats.get("prestige", 0)))
		add_lbl.call(("Cofres Abiertos: " if is_es else "Chests Opened: ") + str(GameManager.profile_stats.get("chests_opened", 0)))
		
		add_header.call("ESTADISTICAS DE COMBATE" if is_es else "COMBAT STATS")
		add_lbl.call(("Aliens Eliminados: " if is_es else "Aliens Defeated: ") + str(GameManager.total_enemies_defeated))
		add_lbl.call(("Jefes Derrotados: " if is_es else "Bosses Defeated: ") + str(GameManager.profile_stats.get("bosses_killed", GameManager.bestiary.get(8, 0))))
		add_lbl.call(("Dano Total: " if is_es else "Total Damage: ") + str(GameManager.profile_stats.get("total_damage", 0)))
		add_lbl.call(("Dano Critico Total: " if is_es else "Total Crit Damage: ") + str(GameManager.profile_stats.get("total_crit_damage", 0)))
		add_lbl.call(("Mayor Combo: " if is_es else "Max Combo: ") + str(GameManager.best_combo))
		add_lbl.call(("Cortes Realizados: " if is_es else "Cuts Made: ") + str(GameManager.profile_stats.get("finger_cuts", 0)))
		add_lbl.call(("Enemigos Quemados: " if is_es else "Enemies Burned: ") + str(GameManager.profile_stats.get("enemies_burned", 0)))
		add_lbl.call(("Enemigos Electrocutados: " if is_es else "Enemies Electrocuted: ") + str(GameManager.profile_stats.get("enemies_electrocuted", 0)))
		add_lbl.call(("Enemigos Absorbidos: " if is_es else "Enemies Absorbed: ") + str(GameManager.profile_stats.get("enemies_absorbed", 0)))
		
		add_header.call("ESTADISTICAS ECONOMICAS" if is_es else "ECONOMIC STATS")
		add_lbl.call(("Oro Ganado: " if is_es else "Gold Earned: ") + str(GameManager.profile_stats.get("gold_earned", 0)))
		add_lbl.call(("Oro Gastado: " if is_es else "Gold Spent: ") + str(GameManager.profile_stats.get("gold_spent", 0)))
		add_lbl.call(("Monedas Recogidas: " if is_es else "Coins Collected: ") + str(GameManager.profile_stats.get("coins_collected", 0)))
		add_lbl.call(("XP Total Obtenida: " if is_es else "Total XP Earned: ") + str(GameManager.profile_stats.get("total_xp_earned", 0)))
		add_lbl.call(("Mejora Mas Cara Comprada: " if is_es else "Most Expensive Upgrade: ") + str(GameManager.profile_stats.get("most_expensive_upgrade", 0)))
		
		add_header.call("ESTADISTICAS DE CARTAS" if is_es else "CARD STATS")
		var card_choices = GameManager.profile_stats.get("card_choices", {})
		var fav_card = "Ninguna" if is_es else "None"
		var fav_count = 0
		for k in card_choices.keys():
			if card_choices[k] > fav_count:
				fav_count = card_choices[k]
				fav_card = GameManager.skills_data.get(k, {}).get("name", k)
		add_lbl.call(("Carta Favorita:\n   " if is_es else "Favorite Card:\n   ") + fav_card + "\n   " + ("Elegida: " if is_es else "Chosen: ") + str(fav_count) + (" veces" if is_es else " times"))
		
		var max_upgraded = "Ninguna" if is_es else "None"
		var max_lvl = 0
		for k in GameManager.card_upgrade_levels.keys():
			var val = GameManager.card_upgrade_levels[k]
			if val is int and val > max_lvl:
				max_lvl = val
				max_upgraded = GameManager.skills_data.get(k, {}).get("name", k)
		if max_lvl > 0:
			add_lbl.call(("Carta Mas Mejorada: " if is_es else "Most Upgraded Card: ") + max_upgraded + " (Nivel " + str(max_lvl) + ")")
		else:
			add_lbl.call("Carta Mas Mejorada: Ninguna" if is_es else "Most Upgraded Card: None")
		add_lbl.call(("Sinergias Descubiertas: " if is_es else "Synergies Discovered: ") + str(GameManager.profile_stats.get("sinergias_discovered", []).size()) + " / 11")
		add_lbl.call(("Cartas Desbloqueadas: " if is_es else "Cards Unlocked: ") + str(cards_unlocked) + " / " + str(cards_total))
		
	elif cat_name.contains("Récords") or cat_name.contains("Records"):
		var add_lbl = func(txt: String):
			var lbl = Label.new()
			lbl.text = txt
			lbl.add_theme_font_override("font", button_font)
			lbl.add_theme_font_size_override("font_size", 16)
			detail_vbox.add_child(lbl)
			
		var cards_lvl_5 = 0
		for k in GameManager.card_upgrade_levels.keys():
			var val = GameManager.card_upgrade_levels[k]
			if val is int and val >= 5:
				cards_lvl_5 += 1
				
		add_lbl.call(("Mayor Dano Critico:\n   " if is_es else "Max Crit Damage:\n   ") + str(GameManager.profile_stats.get("max_crit_damage", 0)))
		var spacer = Control.new(); spacer.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer)
		add_lbl.call(("Mas Aliens Eliminados en una Partida:\n   " if is_es else "Most Kills in a Single Match:\n   ") + str(GameManager.profile_stats.get("max_kills_in_match", 0)))
		var spacer2 = Control.new(); spacer2.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer2)
		add_lbl.call(("Mas Oro en una Partida:\n   " if is_es else "Most Gold in a Single Match:\n   ") + str(GameManager.profile_stats.get("max_gold_in_match", 0)))
		var spacer3 = Control.new(); spacer3.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer3)
		add_lbl.call(("Mayor Nivel Alcanzado:\n   Oleada " if is_es else "Max Level Reached:\n   Wave ") + str(GameManager.profile_stats.get("max_level_reached", 1)))
		var spacer4 = Control.new(); spacer4.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer4)
		add_lbl.call(("Mayor Cantidad de Cartas Nivel 5:\n   " if is_es else "Max Cards at Level 5:\n   ") + str(cards_lvl_5))
		
	elif cat_name.contains("Títulos") or cat_name.contains("Titles"):
		var titles_data = [
			{"name": "Novato del Huerto", "desc": "Jugar 1 partida" if is_es else "Play 1 match"},
			{"name": "Defensor", "desc": "Oleada 10" if is_es else "Wave 10"},
			{"name": "Jardinero de Guerra", "desc": "Oleada 20" if is_es else "Wave 20"},
			{"name": "Exterminador", "desc": "10,000 aliens" if is_es else "10,000 aliens"},
			{"name": "Cazajefes", "desc": "100 bosses" if is_es else "100 bosses"},
			{"name": "El Elegido del Rábano", "desc": "Oleada 50" if is_es else "Wave 50"},
			{"name": "El Dorado", "desc": "Prestigio 1" if is_es else "Prestige 1"},
			{"name": "Devorador de Invasores", "desc": "50,000 aliens" if is_es else "50,000 aliens"}
		]
		var ut = GameManager.profile_stats.get("unlocked_titles", ["Novato del Huerto"])
		var equipped = GameManager.profile_stats.get("equipped_title", "Novato del Huerto")
		
		for t_info in titles_data:
			var row = PanelContainer.new()
			detail_vbox.add_child(row)
			
			var row_style = StyleBoxFlat.new()
			row_style.bg_color = Color(0.06, 0.06, 0.08, 0.8)
			row_style.border_width_left = 2; row_style.border_width_top = 2
			row_style.border_width_right = 2; row_style.border_width_bottom = 2
			row_style.corner_radius_top_left = 6; row_style.corner_radius_top_right = 6
			row_style.corner_radius_bottom_right = 6; row_style.corner_radius_bottom_left = 6
			
			var is_unlocked = ut.has(t_info.name)
			var is_equipped = equipped == t_info.name
			
			if is_equipped:
				row_style.border_color = Color(0.8, 0.6, 0.2, 1.0)
			else:
				row_style.border_color = Color(0.2, 0.2, 0.25, 0.8)
			row.add_theme_stylebox_override("panel", row_style)
			
			var margin_row = MarginContainer.new()
			margin_row.add_theme_constant_override("margin_left", 12)
			margin_row.add_theme_constant_override("margin_top", 10)
			margin_row.add_theme_constant_override("margin_right", 12)
			margin_row.add_theme_constant_override("margin_bottom", 10)
			row.add_child(margin_row)
			
			var hbox = HBoxContainer.new()
			margin_row.add_child(hbox)
			
			var vb_text = VBoxContainer.new()
			vb_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(vb_text)
			
			var t_name_lbl = Label.new()
			t_name_lbl.text = (t_info.name if is_unlocked else "[BLOQUEADO] " + t_info.name if is_es else "[LOCKED] " + t_info.name)
			t_name_lbl.add_theme_font_override("font", button_font)
			t_name_lbl.add_theme_font_size_override("font_size", 15)
			if is_equipped:
				t_name_lbl.modulate = Color(1.0, 0.8, 0.2)
			elif not is_unlocked:
				t_name_lbl.modulate = Color(0.5, 0.5, 0.5)
			vb_text.add_child(t_name_lbl)
			
			var desc_lbl = Label.new()
			desc_lbl.text = t_info.desc
			desc_lbl.add_theme_font_override("font", button_font)
			desc_lbl.add_theme_font_size_override("font_size", 12)
			desc_lbl.modulate = Color(0.6, 0.6, 0.6)
			vb_text.add_child(desc_lbl)
			
			if is_equipped:
				var eq_lbl = Label.new()
				eq_lbl.text = "EQUIPADO" if is_es else "EQUIPPED"
				eq_lbl.add_theme_font_override("font", button_font)
				eq_lbl.add_theme_font_size_override("font_size", 14)
				eq_lbl.modulate = Color(0.2, 1.0, 0.2)
				hbox.add_child(eq_lbl)
			elif is_unlocked:
				var btn_equip = Button.new()
				btn_equip.text = "EQUIPAR" if is_es else "EQUIP"
				btn_equip.custom_minimum_size = Vector2(90, 40)
				btn_equip.add_theme_font_override("font", button_font)
				btn_equip.add_theme_font_size_override("font_size", 12)
				
				var eq_style = StyleBoxFlat.new()
				eq_style.bg_color = Color(0.15, 0.35, 0.15, 1.0)
				eq_style.corner_radius_top_left = 6; eq_style.corner_radius_top_right = 6
				eq_style.corner_radius_bottom_right = 6; eq_style.corner_radius_bottom_left = 6
				btn_equip.add_theme_stylebox_override("normal", eq_style)
				btn_equip.add_theme_stylebox_override("hover", eq_style)
				btn_equip.add_theme_stylebox_override("pressed", eq_style)
				hbox.add_child(btn_equip)
				
				_connect_button_with_drag_protection(btn_equip, func():
					GameManager.profile_stats["equipped_title"] = t_info.name
					GameManager.save_game()
					header_title_equip_lbl.text = t_info.name
					_populate_profile_category(cat_name, detail_vbox, header_avatar_rect, header_title_equip_lbl)
				)
			else:
				var lock_lbl = Label.new()
				lock_lbl.text = "BLOQUEADO" if is_es else "LOCKED"
				lock_lbl.add_theme_font_override("font", button_font)
				lock_lbl.add_theme_font_size_override("font_size", 13)
				lock_lbl.modulate = Color(0.5, 0.5, 0.5)
				hbox.add_child(lock_lbl)
				
	elif cat_name.contains("Avatares") or cat_name.contains("Avatars"):
		var avatars_data = [
			{"name": "Alien Normal", "desc": "Inicial" if is_es else "Initial"},
			{"name": "Alien Curador", "desc": "Derrotar 50 aliens curadores" if is_es else "Defeat 50 healer aliens"},
			{"name": "Alien Kamikaze", "desc": "Derrotar 50 aliens kamikaze" if is_es else "Defeat 50 kamikaze aliens"},
			{"name": "Devorarábanos", "desc": "Alcanzar Oleada 15" if is_es else "Reach Wave 15"},
			{"name": "Chayanne", "desc": "Llevar 3 cartas a Nivel Máximo" if is_es else "Get 3 cards to Max Level"},
			{"name": "Papa Espantapájaros", "desc": "Gastar 5,000 de oro" if is_es else "Spend 5,000 gold"},
			{"name": "Rábano Dorado", "desc": "Alcanzar Oleada 30" if is_es else "Reach Wave 30"},
			{"name": "Rábano Cósmico", "desc": "Alcanzar Oleada 50" if is_es else "Reach Wave 50"}
		]
		var ua = GameManager.profile_stats.get("unlocked_avatars", ["Alien Normal"])
		var equipped = GameManager.profile_stats.get("equipped_avatar", "Alien Normal")
		
		for a_info in avatars_data:
			var row = PanelContainer.new()
			detail_vbox.add_child(row)
			
			var row_style = StyleBoxFlat.new()
			row_style.bg_color = Color(0.06, 0.06, 0.08, 0.8)
			row_style.border_width_left = 2; row_style.border_width_top = 2
			row_style.border_width_right = 2; row_style.border_width_bottom = 2
			row_style.corner_radius_top_left = 6; row_style.corner_radius_top_right = 6
			row_style.corner_radius_bottom_right = 6; row_style.corner_radius_bottom_left = 6
			
			var is_unlocked = ua.has(a_info.name)
			var is_equipped = equipped == a_info.name
			
			if is_equipped:
				row_style.border_color = Color(0.8, 0.6, 0.2, 1.0)
			else:
				row_style.border_color = Color(0.2, 0.2, 0.25, 0.8)
			row.add_theme_stylebox_override("panel", row_style)
			
			var margin_row = MarginContainer.new()
			margin_row.add_theme_constant_override("margin_left", 12)
			margin_row.add_theme_constant_override("margin_top", 10)
			margin_row.add_theme_constant_override("margin_right", 12)
			margin_row.add_theme_constant_override("margin_bottom", 10)
			row.add_child(margin_row)
			
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 15)
			margin_row.add_child(hbox)
			
			var tex_path = "res://assets/img/alien_normal.png"
			var mod_color = Color.WHITE
			if a_info.name == "Alien Normal": tex_path = "res://assets/img/alien_normal.png"
			elif a_info.name == "Alien Curador": tex_path = "res://assets/img/alien_curandero.png"
			elif a_info.name == "Alien Kamikaze": tex_path = "res://assets/img/alien_kamikaze.png"
			elif a_info.name == "Devorarábanos": tex_path = "res://assets/img/rabanito_diablo.png"
			elif a_info.name == "Chayanne": tex_path = "res://assets/img/alien_amigo.png"
			elif a_info.name == "Papa Espantapájaros": tex_path = "res://assets/img/alien_minero.png"
			elif a_info.name == "Rábano Dorado":
				tex_path = "res://assets/img/rabanito.png"
				mod_color = Color(1.0, 0.8, 0.1)
			elif a_info.name == "Rábano Cósmico":
				tex_path = "res://assets/img/rabanito.png"
				mod_color = Color(0.6, 0.3, 1.0)
				
			var tr = TextureRect.new()
			tr.custom_minimum_size = Vector2(48, 48)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			if is_unlocked:
				tr.texture = load(tex_path)
				tr.modulate = mod_color
			else:
				tr.texture = load("res://assets/img/alien_normal.png")
				tr.modulate = Color(0.1, 0.1, 0.1, 0.6)
				
			hbox.add_child(tr)
			
			var vb_text = VBoxContainer.new()
			vb_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(vb_text)
			
			var a_name_lbl = Label.new()
			a_name_lbl.text = (a_info.name if is_unlocked else "[BLOQUEADO] " + a_info.name if is_es else "[LOCKED] " + a_info.name)
			a_name_lbl.add_theme_font_override("font", button_font)
			a_name_lbl.add_theme_font_size_override("font_size", 15)
			if is_equipped:
				a_name_lbl.modulate = Color(1.0, 0.8, 0.2)
			elif not is_unlocked:
				a_name_lbl.modulate = Color(0.5, 0.5, 0.5)
			vb_text.add_child(a_name_lbl)
			
			var desc_lbl = Label.new()
			desc_lbl.text = a_info.desc
			desc_lbl.add_theme_font_override("font", button_font)
			desc_lbl.add_theme_font_size_override("font_size", 12)
			desc_lbl.modulate = Color(0.6, 0.6, 0.6)
			vb_text.add_child(desc_lbl)
			
			if is_equipped:
				var eq_lbl = Label.new()
				eq_lbl.text = "EQUIPADO" if is_es else "EQUIPPED"
				eq_lbl.add_theme_font_override("font", button_font)
				eq_lbl.add_theme_font_size_override("font_size", 14)
				eq_lbl.modulate = Color(0.2, 1.0, 0.2)
				hbox.add_child(eq_lbl)
			elif is_unlocked:
				var btn_equip = Button.new()
				btn_equip.text = "EQUIPAR" if is_es else "EQUIP"
				btn_equip.custom_minimum_size = Vector2(90, 40)
				btn_equip.add_theme_font_override("font", button_font)
				btn_equip.add_theme_font_size_override("font_size", 12)
				
				var eq_style = StyleBoxFlat.new()
				eq_style.bg_color = Color(0.15, 0.35, 0.15, 1.0)
				eq_style.corner_radius_top_left = 6; eq_style.corner_radius_top_right = 6
				eq_style.corner_radius_bottom_right = 6; eq_style.corner_radius_bottom_left = 6
				btn_equip.add_theme_stylebox_override("normal", eq_style)
				btn_equip.add_theme_stylebox_override("hover", eq_style)
				btn_equip.add_theme_stylebox_override("pressed", eq_style)
				hbox.add_child(btn_equip)
				
				_connect_button_with_drag_protection(btn_equip, func():
					GameManager.profile_stats["equipped_avatar"] = a_info.name
					GameManager.save_game()
					header_avatar_rect.texture = load(tex_path)
					header_avatar_rect.modulate = mod_color
					_populate_profile_category(cat_name, detail_vbox, header_avatar_rect, header_title_equip_lbl)
				)
			else:
				var lock_lbl = Label.new()
				lock_lbl.text = "BLOQUEADO" if is_es else "LOCKED"
				lock_lbl.add_theme_font_override("font", button_font)
				lock_lbl.add_theme_font_size_override("font_size", 13)
				lock_lbl.modulate = Color(0.5, 0.5, 0.5)
				hbox.add_child(lock_lbl)
				
	elif cat_name.contains("Colección") or cat_name.contains("Collection"):
		var add_lbl = func(txt: String):
			var lbl = Label.new()
			lbl.text = txt
			lbl.add_theme_font_override("font", button_font)
			lbl.add_theme_font_size_override("font_size", 16)
			detail_vbox.add_child(lbl)
			
		var bestiary_unlocked = 0
		for k in GameManager.bestiary.keys():
			if GameManager.bestiary[k] > 0:
				bestiary_unlocked += 1
				
		var sy_total = GameManager.profile_stats.get("sinergias_discovered", []).size()
		var av_total = GameManager.profile_stats.get("unlocked_avatars", []).size()
		var ti_total = GameManager.profile_stats.get("unlocked_titles", []).size()
		
		add_lbl.call("RESUMEN DE COLECCION\n" if is_es else "COLLECTION SUMMARY\n")
		add_lbl.call(("Cartas: " if is_es else "Cards: ") + str(cards_unlocked) + " / " + str(cards_total))
		var spacer1 = Control.new(); spacer1.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer1)
		add_lbl.call(("Bestiario: " if is_es else "Bestiary: ") + str(bestiary_unlocked) + " / 9")
		var spacer2 = Control.new(); spacer2.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer2)
		add_lbl.call(("Sinergias: " if is_es else "Synergies: ") + str(sy_total) + " / 11")
		var spacer3 = Control.new(); spacer3.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer3)
		add_lbl.call(("Avatares: " if is_es else "Avatars: ") + str(av_total) + " / 8")
		var spacer4 = Control.new(); spacer4.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer4)
		add_lbl.call(("Titulos: " if is_es else "Titles: ") + str(ti_total) + " / 8")
		
	elif cat_name.contains("Curiosidades") or cat_name.contains("Trivia"):
		var add_lbl = func(txt: String):
			var lbl = Label.new()
			lbl.text = txt
			lbl.add_theme_font_override("font", button_font)
			lbl.add_theme_font_size_override("font_size", 16)
			detail_vbox.add_child(lbl)
			
		add_lbl.call(("Rabanos Protegidos: " if is_es else "Radishes Protected: ") + str(GameManager.profile_stats.get("radishes_protected", 1)))
		var spacer1 = Control.new(); spacer1.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer1)
		add_lbl.call(("Rabanos Perdidos: " if is_es else "Radishes Lost: ") + str(GameManager.profile_stats.get("radishes_lost", 0)))
		var spacer2 = Control.new(); spacer2.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer2)
		add_lbl.call(("Aliens Enviados a Terapia: " if is_es else "Aliens Sent to Therapy: ") + str(GameManager.profile_stats.get("aliens_in_therapy", 0)))
		var spacer3 = Control.new(); spacer3.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer3)
		add_lbl.call(("Pantallas Sacudidas: " if is_es else "Screens Shaken: ") + str(GameManager.profile_stats.get("screens_shaken", 0)))
		var spacer4 = Control.new(); spacer4.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer4)
		add_lbl.call(("Explosiones Provocadas: " if is_es else "Explosions Caused: ") + str(GameManager.profile_stats.get("explosions_caused", 0)))
		var spacer5 = Control.new(); spacer5.custom_minimum_size = Vector2(0, 10); detail_vbox.add_child(spacer5)
		add_lbl.call(("Kilometros Cortados: " if is_es else "Kilometers Cut: ") + ("%.1f" % GameManager.profile_stats.get("kilometers_cut", 0.0)) + " km")

func _setup_drag_scroll(scroll_container: ScrollContainer) -> void:
	var drag_data = {
		"is_dragging": false,
		"drag_start": Vector2.ZERO,
		"scroll_start": Vector2.ZERO
	}
	scroll_container.gui_input.connect(func(event):
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.pressed:
				drag_data.is_dragging = true
				drag_data.drag_start = event.position
				drag_data.scroll_start = Vector2(scroll_container.scroll_horizontal, scroll_container.scroll_vertical)
			else:
				drag_data.is_dragging = false
		elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and drag_data.is_dragging:
			var diff = event.position - drag_data.drag_start
			scroll_container.scroll_horizontal = drag_data.scroll_start.x - diff.x
			scroll_container.scroll_vertical = drag_data.scroll_start.y - diff.y
	)

func _connect_button_with_drag_protection(btn: Button, callback: Callable) -> void:
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	var drag_threshold = 10.0
	var press_pos = Vector2.ZERO
	var was_dragged = false
	btn.gui_input.connect(func(event):
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.pressed:
				press_pos = event.position
				was_dragged = false
			else:
				if not was_dragged and event.position.distance_to(press_pos) < drag_threshold:
					callback.call()
		elif event is InputEventMouseMotion or event is InputEventScreenDrag:
			if event.position.distance_to(press_pos) > drag_threshold:
				was_dragged = true
	)
