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
	"energy_shield", "sword_craft", "frost_avalanche", "earthquake",

	# Sinergias (Legendarias)
	"infernal_hole", "orbital_satellite", "radioactive_swamp", "field_squad",
	"living_fortress", "ajo_negativo", "los_compadres", "war_garden", "infected_potato",
	"excalibur_vegetal", "deforesador",

	# Cartas de Cofre
	"sayonara", "steroids", "conqueror_aura", "campesino_extremo",
	"reactor_nuclear", "sobrecarga_cuantica", "lluvia_rabanos", "senal_pirata", "sindicato_alien"
]

func _ready() -> void:
	# Asegurarse de que el mazo tenga al menos slot 1 desbloqueado por defecto si cumple la condición
	if GameManager.best_wave >= 10 and GameManager.deck_unlocked_slots == 0:
		GameManager.deck_unlocked_slots = 1
		GameManager.save_game()
		
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
	
	# 5. Generar Grid de Cartas
	update_grid()

func update_slots() -> void:
	for c in slots_container.get_children():
		c.queue_free()
		
	for i in range(3):
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(240, 150)
		
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
				
				# El truco para capturar el índice actual "i" de forma segura en Godot 4 es usar bind o una variable local
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
				select_btn.custom_minimum_size = Vector2(240, 90)
				select_btn.pressed.connect(func():
					selected_slot_index = current_i
					update_slots()
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

func update_grid() -> void:
	for c in grid.get_children():
		c.queue_free()
		
	for skill_id in skills_list:
		var data = {}
		if GameManager.skills_data.has(skill_id):
			data = GameManager.skills_data[skill_id]
		elif GameManager.flat_upgrades.has(skill_id):
			data = GameManager.flat_upgrades[skill_id]
		var is_unlocked = GameManager.unlocked_skills.has(skill_id)
		
		var card_btn = Button.new()
		card_btn.custom_minimum_size = Vector2(190, 240)
		card_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var style = StyleBoxTexture.new()
		var rarity = data.get("rarity", "comun")
		if is_unlocked:
			if rarity == "legendaria": style.texture = tex_legendaria
			elif rarity == "epica": style.texture = tex_epica
			elif rarity == "rara": style.texture = tex_rara
			else: style.texture = tex_comun
		else:
			style.texture = tex_comun
			style.modulate_color = Color(0.15, 0.15, 0.2, 1.0)
			
		card_btn.add_theme_stylebox_override("normal", style)
		card_btn.add_theme_stylebox_override("hover", style)
		card_btn.add_theme_stylebox_override("pressed", style)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		card_btn.add_child(vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = data["name"].to_upper()
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.label_settings = label_font
		name_lbl.add_theme_font_size_override("font_size", 13)
		if not is_unlocked:
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(name_lbl)
		
		var status_lbl = Label.new()
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_lbl.label_settings = label_font
		status_lbl.add_theme_font_size_override("font_size", 10)
		
		if not is_unlocked:
			status_lbl.text = "BLOQUEADA\n(Juega para obtenerla)"
			status_lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
			card_btn.disabled = true
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
				
			var current_skill_id = skill_id
			card_btn.pressed.connect(func():
				if selected_slot_index < GameManager.deck_unlocked_slots:
					for i in range(3):
						if GameManager.deck_equipped_cards[i] == current_skill_id:
							GameManager.deck_equipped_cards[i] = ""
					GameManager.deck_equipped_cards[selected_slot_index] = current_skill_id
					GameManager.save_game()
					
					var next_slot = (selected_slot_index + 1) % GameManager.deck_unlocked_slots
					selected_slot_index = next_slot
					update_ui()
			)
		vbox.add_child(status_lbl)
		grid.add_child(card_btn)

func _on_btn_upgrade_deck_pressed() -> void:
	if GameManager.upgrade_deck_level():
		update_ui()

func _on_btn_prestige_pressed() -> void:
	if GameManager.prestige_deck():
		selected_slot_index = 0
		update_ui()

func _on_btn_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MenuInicio.tscn")
