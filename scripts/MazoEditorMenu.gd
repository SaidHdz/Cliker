extends Control

@onready var grid: GridContainer = $VBoxContainer/ScrollContainer/GridContainer
@onready var gold_label: Label = $VBoxContainer/HBoxHeader/GoldLabel
@onready var badges_label: Label = $VBoxContainer/HBoxHeader/BadgesLabel
@onready var deck_level_label: Label = $VBoxContainer/HBoxHeader/DeckLevelLabel
@onready var btn_upgrade_deck: Button = $VBoxContainer/HBoxHeader/BtnUpgradeDeck
@onready var slots_container: HBoxContainer = $VBoxContainer/HBoxSlots
@onready var afinity_label: Label = $VBoxContainer/AfinityLabel
@onready var btn_prestige: Button = $VBoxContainer/HBoxPrestige/BtnPrestige

var label_font = preload("res://scenes/Font.tres")
var button_font = preload("res://assets/fuentes/BoldPixels.ttf")

var tex_comun = preload("res://assets/img/carta_comun.png")
var tex_rara = preload("res://assets/img/carta_rara.png")
var tex_epica = preload("res://assets/img/carta_epica.png")
var tex_legendaria = preload("res://assets/img/carta_legendaria.png")

var selected_slot_index: int = 0
var modal_instance: Control = null

var skills_list = [
	# Habilidades estándar (5 niveles)
	"fire_slice", "lightning_slice", "explosive_slice", "fire_wall",
	"shield", "seed_nova", "mining_cart", "thorns", "toxic_aura",
	"pet_chayanne", "black_hole", "aura", "turret", "pet_minigun",
	"tornado", "axe_thrower", "satellite", "tamed_alien", "scarecrow",
	"cosmic_magnet", "boomerang",

	# Mejoras Planas (Flat Upgrades)
	"heal", "damage_boost", "crit_boost", "auto_speed",
	"mirror_slice", "double_slice", "wind_gust", "toxic_compost",
	"energy_shield", "sword_craft", "frost_avalanche", "earthquake"
]

func _ready() -> void:
	# Ocultar el scroll container original para que las ranuras ocupen toda la pantalla
	if has_node("VBoxContainer/ScrollContainer"):
		$VBoxContainer/ScrollContainer.visible = false
		
	# Asegurarse de que el mazo tenga al menos slot 1 desbloqueado por defecto si cumple la condición
	if GameManager.best_wave >= 10 and GameManager.deck_unlocked_slots == 0:
		GameManager.deck_unlocked_slots = 1
		GameManager.save_game()
		
	var btn_back = get_node_or_null("VBoxContainer/BtnBack")
	if btn_back:
		btn_back.get_parent().remove_child(btn_back)
		add_child(btn_back)
		
		btn_back.text = " X "
		btn_back.custom_minimum_size = Vector2(55, 55)
		btn_back.add_theme_font_override("font", button_font)
		btn_back.add_theme_font_size_override("font_size", 22)
		
		var back_style = StyleBoxFlat.new()
		back_style.bg_color = Color(0.35, 0.1, 0.1, 1.0)
		back_style.set_corner_radius_all(6)
		btn_back.add_theme_stylebox_override("normal", back_style)
		btn_back.add_theme_stylebox_override("hover", back_style)
		btn_back.add_theme_stylebox_override("pressed", back_style)
		
		btn_back.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		btn_back.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		btn_back.grow_vertical = Control.GROW_DIRECTION_END
		btn_back.offset_left = -59
		btn_back.offset_top = 4
		btn_back.offset_right = -4
		btn_back.offset_bottom = 59
		
	update_ui()

func update_ui() -> void:
	# 1. Actualizar textos de cabecera
	gold_label.text = "BANCO: " + str(GameManager.total_gold) + " ORO"
	badges_label.text = "VETERANO: " + str(GameManager.veteran_badges)
	deck_level_label.text = "MAZO: NV " + str(GameManager.deck_level)
	
	# 2. Configurar botón de mejora de nivel de mazo
	if GameManager.deck_level == 1:
		btn_upgrade_deck.text = "MEJORAR NV 2 (10,000 ORO)"
		btn_upgrade_deck.disabled = GameManager.total_gold < 10000
	elif GameManager.deck_level == 2:
		btn_upgrade_deck.text = "MEJORAR NV 3 (30,000 ORO)"
		btn_upgrade_deck.disabled = GameManager.total_gold < 30000
	else:
		btn_upgrade_deck.text = "MAZO AL MÁXIMO"
		btn_upgrade_deck.disabled = true
		
	# 3. Configurar botón de prestigio
	if GameManager.best_wave >= 50:
		btn_prestige.text = "PRESTIGIO (+1 INSIGNIA DE VETERANO)"
		btn_prestige.disabled = false
	else:
		btn_prestige.text = "PRESTIGIO (REQUIERE OLEADA RÉCORD 50)"
		btn_prestige.disabled = true
		
	# 4. Actualizar Ranuras y Afinidad
	update_slots()
	update_affinity()

func update_slots() -> void:
	for c in slots_container.get_children():
		c.queue_free()
		
	for i in range(3):
		var slot_panel = PanelContainer.new()
		# Hacer las ranuras más grandes ya que no tenemos el grid principal
		slot_panel.custom_minimum_size = Vector2(280, 200)
		
		var style = StyleBoxFlat.new()
		if i == selected_slot_index and i < GameManager.deck_unlocked_slots:
			style.bg_color = Color(0.12, 0.22, 0.35, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
			style.border_color = Color(0.0, 0.7, 1.0, 1.0)
		else:
			style.bg_color = Color(0.06, 0.06, 0.08, 1.0)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.25, 0.25, 0.25, 1.0)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		slot_panel.add_theme_stylebox_override("panel", style)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_panel.add_child(vbox)
		
		var title_lbl = Label.new()
		title_lbl.text = "ESPACIO " + str(i + 1)
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.label_settings = label_font
		title_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(title_lbl)
		
		if i < GameManager.deck_unlocked_slots:
			# Ranura desbloqueada
			var card_id = GameManager.deck_equipped_cards[i]
			if card_id == "":
				var info_lbl = Label.new()
				info_lbl.text = "[ VACÍO ]\nClick para seleccionar"
				info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				info_lbl.label_settings = label_font
				info_lbl.add_theme_font_size_override("font_size", 12)
				vbox.add_child(info_lbl)
				
				var btn = Button.new()
				btn.flat = true
				btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				btn.pressed.connect(func():
					selected_slot_index = i
					update_slots()
					_open_card_selector_modal()
				)
				slot_panel.add_child(btn)
			else:
				var card_data = {}
				if GameManager.skills_data.has(card_id):
					card_data = GameManager.skills_data[card_id]
				elif GameManager.flat_upgrades.has(card_id):
					card_data = GameManager.flat_upgrades[card_id]
				
				var name_lbl = Label.new()
				name_lbl.text = card_data["name"].to_upper()
				name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				name_lbl.label_settings = label_font
				name_lbl.add_theme_font_size_override("font_size", 16)
				
				var rarity = card_data.get("rarity", "comun")
				var r_color = Color(1.0, 1.0, 1.0)
				if rarity == "legendaria": r_color = Color(1.0, 0.35, 0.35)
				elif rarity == "epica": r_color = Color(0.85, 0.4, 1.0)
				elif rarity == "rara": r_color = Color(0.35, 0.65, 1.0)
				name_lbl.add_theme_color_override("font_color", r_color)
				vbox.add_child(name_lbl)
				
				var clear_btn = Button.new()
				clear_btn.text = "VACIAR"
				clear_btn.custom_minimum_size = Vector2(90, 26)
				clear_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				clear_btn.add_theme_font_override("font", button_font)
				clear_btn.add_theme_font_size_override("font_size", 10)
				
				var current_i = i
				clear_btn.pressed.connect(func():
					GameManager.deck_equipped_cards[current_i] = ""
					GameManager.save_game()
					selected_slot_index = current_i
					update_ui()
				)
				vbox.add_child(clear_btn)
				
				var select_btn = Button.new()
				select_btn.flat = true
				select_btn.custom_minimum_size = Vector2(280, 130)
				select_btn.pressed.connect(func():
					selected_slot_index = current_i
					update_slots()
					_open_card_selector_modal()
				)
				slot_panel.add_child(select_btn)
				slot_panel.move_child(select_btn, 0)
		else:
			# Ranura bloqueada
			var req_wave = 20 if i == 1 else 30
			var req_cost = 5000 if i == 1 else 15000
			
			var lock_lbl = Label.new()
			lock_lbl.text = "BLOQUEADO\nOleada Récord: " + str(req_wave)
			lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_lbl.label_settings = label_font
			lock_lbl.add_theme_font_size_override("font_size", 10)
			lock_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			vbox.add_child(lock_lbl)
			
			var buy_btn = Button.new()
			buy_btn.text = "DESBLOQUEAR (" + str(req_cost) + ")"
			buy_btn.custom_minimum_size = Vector2(150, 26)
			buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			buy_btn.add_theme_font_override("font", button_font)
			buy_btn.add_theme_font_size_override("font_size", 10)
			
			var can_buy = GameManager.best_wave >= req_wave and GameManager.total_gold >= req_cost
			buy_btn.disabled = not can_buy
			
			var current_i = i
			buy_btn.pressed.connect(func():
				if GameManager.unlock_deck_slot(current_i):
					selected_slot_index = current_i
					update_ui()
			)
			vbox.add_child(buy_btn)
			
		slots_container.add_child(slot_panel)

func update_affinity() -> void:
	var affinity = GameManager.get_deck_affinity()
	if affinity == "Tecnológica":
		afinity_label.text = "Afinidad Activa: Tecnológica (+5% aparición de cartas Épicas)"
		afinity_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	elif affinity == "Mascotas":
		afinity_label.text = "Afinidad Activa: Mascotas (+10% salud y velocidad de ataque para invocaciones)"
		afinity_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	elif affinity == "Elemental":
		afinity_label.text = "Afinidad Activa: Elemental (+10% de duración de veneno y quemadura)"
		afinity_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	else:
		afinity_label.text = "Afinidad Activa: Ninguna (Equipa 3 cartas de la misma categoría)"
		afinity_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

func _open_card_selector_modal() -> void:
	if is_instance_valid(modal_instance):
		modal_instance.queue_free()
		
	# 1. Crear el fondo del modal (bloquea clicks externos)
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	modal_instance = bg
	
	# CenterContainer para centrar perfectamente el panel en cualquier pantalla
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_PASS
	bg.add_child(center_container)
	
	# 2. Panel central (860x480)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 480)
	center_container.add_child(panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.0, 0.7, 1.0, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	
	# MarginContainer para dar espacio a los bordes
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	# 3. Contenedor vertical principal del modal
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(main_vbox)
	
	# Cabecera: Título + Botón de Cerrar
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(header)
	
	# Espacio a la izquierda
	var spacing_left = Control.new()
	spacing_left.custom_minimum_size = Vector2(12, 10)
	header.add_child(spacing_left)
	
	var title = Label.new()
	title.text = "SELECCIONAR CARTA PARA ESPACIO " + str(selected_slot_index + 1)
	title.label_settings = label_font
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = " X "
	close_btn.add_theme_font_override("font", button_font)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(bg.queue_free)
	header.add_child(close_btn)
	
	# Espacio a la derecha
	var spacing_right = Control.new()
	spacing_right.custom_minimum_size = Vector2(12, 10)
	header.add_child(spacing_right)
	
	# 4. ScrollContainer para las cartas
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	main_vbox.add_child(scroll)
	
	# Configurar drag-scroll
	_setup_drag_scroll(scroll)
	
	# 5. GridContainer de 4 columnas
	var modal_grid = GridContainer.new()
	modal_grid.columns = 4
	modal_grid.add_theme_constant_override("h_separation", 24)
	modal_grid.add_theme_constant_override("v_separation", 24)
	modal_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(modal_grid)
	
	# 6. Generar las cartas
	for skill_id in skills_list:
		var data = {}
		if GameManager.skills_data.has(skill_id):
			data = GameManager.skills_data[skill_id]
		elif GameManager.flat_upgrades.has(skill_id):
			data = GameManager.flat_upgrades[skill_id]
		var is_unlocked = GameManager.unlocked_skills.has(skill_id)
		
		# Crear contenedor de carta (hacerlas más pequeñas y darles espacio)
		var card_panel = PanelContainer.new()
		card_panel.custom_minimum_size = Vector2(150, 190)
		card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		
		var card_style = StyleBoxTexture.new()
		var rarity = data.get("rarity", "comun")
		if is_unlocked:
			if rarity == "legendaria": card_style.texture = tex_legendaria
			elif rarity == "epica": card_style.texture = tex_epica
			elif rarity == "rara": card_style.texture = tex_rara
			else: card_style.texture = tex_comun
		else:
			card_style.texture = tex_comun
			card_style.modulate_color = Color(0.15, 0.15, 0.2, 1.0)
			
		card_panel.add_theme_stylebox_override("panel", card_style)
		
		# VBox dentro de la carta
		var card_vbox = VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 6)
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		card_panel.add_child(card_vbox)
		
		# Nombre de la carta
		var name_lbl = Label.new()
		name_lbl.text = data["name"].to_upper()
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.label_settings = label_font
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		if not is_unlocked:
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		card_vbox.add_child(name_lbl)
		
		# Estado/Rareza
		var status_lbl = Label.new()
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_lbl.label_settings = label_font
		status_lbl.add_theme_font_size_override("font_size", 9)
		status_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		
		if not is_unlocked:
			status_lbl.text = "BLOQUEADA"
			status_lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		else:
			status_lbl.text = rarity.to_upper()
			var r_color = Color(1.0, 1.0, 1.0)
			if rarity == "legendaria": r_color = Color(1.0, 0.35, 0.35)
			elif rarity == "epica": r_color = Color(0.85, 0.4, 1.0)
			elif rarity == "rara": r_color = Color(0.35, 0.65, 1.0)
			status_lbl.add_theme_color_override("font_color", r_color)
			
			var eq_idx = GameManager.deck_equipped_cards.find(skill_id)
			if eq_idx != -1:
				status_lbl.text = "EQUIPADA (" + str(eq_idx + 1) + ")"
				status_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
				
		card_vbox.add_child(status_lbl)
		
		# Botón transparente para interactuar
		var select_btn = Button.new()
		select_btn.flat = true
		card_panel.add_child(select_btn)
		
		if is_unlocked:
			select_btn.pressed.connect(func():
				_equip_card(skill_id)
				bg.queue_free()
			)
		else:
			select_btn.disabled = true
			select_btn.focus_mode = Control.FOCUS_NONE
			
		modal_grid.add_child(card_panel)

func _equip_card(skill_id: String) -> void:
	if selected_slot_index < GameManager.deck_unlocked_slots:
		for i in range(3):
			if GameManager.deck_equipped_cards[i] == skill_id:
				GameManager.deck_equipped_cards[i] = ""
		GameManager.deck_equipped_cards[selected_slot_index] = skill_id
		GameManager.save_game()
		
		var next_slot = (selected_slot_index + 1) % GameManager.deck_unlocked_slots
		selected_slot_index = next_slot
		update_ui()

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

func _on_btn_upgrade_deck_pressed() -> void:
	if GameManager.upgrade_deck_level():
		update_ui()

func _on_btn_prestige_pressed() -> void:
	if GameManager.prestige_deck():
		selected_slot_index = 0
		update_ui()

func _on_btn_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MenuInicio.tscn")
