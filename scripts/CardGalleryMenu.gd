extends Control

@onready var grid: GridContainer = $VBoxContainer/ScrollContainer/GridContainer
@onready var gold_label: Label = $VBoxContainer/GoldLabel

var label_font = preload("res://scenes/Font.tres")
var button_font = preload("res://assets/fuentes/BoldPixels.ttf")

var tex_comun = preload("res://assets/img/carta_comun.png")
var tex_rara = preload("res://assets/img/carta_rara.png")
var tex_epica = preload("res://assets/img/carta_epica.png")
var tex_legendaria = preload("res://assets/img/carta_legendaria.png")

func _ready() -> void:
	# 1. Fondo Negro Sólido
	$ColorRect.color = Color(0.05, 0.05, 0.05, 1.0)
	
	# 2. Header Uniforme
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 50)
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	gold_label.get_parent().remove_child(gold_label)
	header_hbox.add_child(gold_label)
	
	var title_node = $VBoxContainer/Title
	title_node.get_parent().remove_child(title_node)
	header_hbox.add_child(title_node)
	
	var progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.label_settings = label_font
	progress_label.add_theme_font_size_override("font_size", 24)
	header_hbox.add_child(progress_label)
	
	$VBoxContainer.add_child(header_hbox)
	$VBoxContainer.move_child(header_hbox, 0)
	
	# 3. Estilo Grid para 4 Columnas y Scroll Móvil
	var scroll = $VBoxContainer/ScrollContainer
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	
	$VBoxContainer/BtnBack.add_theme_font_override("font", button_font)
	
	update_ui()
	
	var total_skills = GameManager.skills_data.size() + GameManager.flat_upgrades.size()
	var unlocked_count = GameManager.unlocked_skills.size()
	progress_label.text = "CARTAS: " + str(unlocked_count) + " / " + str(total_skills)

func update_ui() -> void:
	gold_label.text = "BANCO: " + str(GameManager.total_gold) + " ORO"
	for child in grid.get_children(): child.queue_free()
	
	var all_skills = []
	all_skills.append_array(GameManager.skills_data.keys())
	all_skills.append_array(GameManager.flat_upgrades.keys())
	
	for skill_id in all_skills:
		create_card_entry(skill_id)

func create_card_entry(skill_id: String) -> void:
	var data = {}
	if GameManager.skills_data.has(skill_id):
		data = GameManager.skills_data[skill_id]
	elif GameManager.flat_upgrades.has(skill_id):
		data = GameManager.flat_upgrades[skill_id]
	else:
		return
	var is_unlocked = GameManager.unlocked_skills.has(skill_id)
	var level = GameManager.card_upgrade_levels.get(skill_id, 0)
	var level_int = GameManager.get_card_upgrade_int_level(skill_id)
	var cost = 100 + (level_int * 200)
	
	var card_bg = PanelContainer.new()
	card_bg.custom_minimum_size = Vector2(180, 320) # Más compactas
	card_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var rarity = data.get("rarity", "comun")
	var style = StyleBoxTexture.new()
	if is_unlocked:
		if rarity == "legendaria": style.texture = tex_legendaria
		elif rarity == "epica": style.texture = tex_epica
		elif rarity == "rara": style.texture = tex_rara
		else: style.texture = tex_comun
	else:
		# Carta oculta, usamos la común pero la teñimos de oscuro
		style.texture = tex_comun
		style.modulate_color = Color(0.2, 0.2, 0.2, 1.0)
		
	card_bg.add_theme_stylebox_override("panel", style)
	
	var vbox = BoxContainer.new()
	vbox.vertical = true
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	card_bg.add_child(vbox)
	
	if is_unlocked:
		var label_name = Label.new()
		label_name.text = data.name.to_upper()
		label_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label_name.label_settings = label_font
		label_name.add_theme_font_size_override("font_size", 18)
		label_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(label_name)
		
		var label_lv = Label.new()
		var is_maxed = false
		var branch_id = ""
		
		# Determinar nivel meta
		if typeof(level) == TYPE_STRING:
			is_maxed = true
			branch_id = level
			label_lv.text = "[ MAESTRÍA ]"
		elif level >= 3:
			label_lv.text = "LV META: " + str(level) + " (MAX)"
			# Aún no ha elegido maestría en partida, o el diseño indica que la compra en tienda llega hasta el 3
		else:
			label_lv.text = "LV META: " + str(level)
			
		label_lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_lv.label_settings = label_font
		label_lv.modulate = Color(1, 0.9, 0.4)
		label_lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(label_lv)
		
		var label_desc = Label.new()
		# Mostrar la descripción META
		if GameManager.meta_upgrades_data.has(skill_id):
			if is_maxed:
				var prefix = "FAVORITA:\n" if branch_id == "4_fav" else "ESPECIALIDAD:\n"
				label_desc.text = prefix + GameManager.meta_upgrades_data[skill_id].get(branch_id, "")
			elif level == 3:
				var fav_desc = GameManager.meta_upgrades_data[skill_id].get("4_fav", "Favorita")
				var spec_desc = GameManager.meta_upgrades_data[skill_id].get("4_spec", "Especialización")
				label_desc.text = "FAV: " + fav_desc + "\n\nSPEC: " + spec_desc
				label_desc.add_theme_font_size_override("font_size", 11) # Tamaño más chico para que quepa todo
			else:
				var next_lvl = level + 1
				label_desc.text = "Siguiente: " + GameManager.meta_upgrades_data[skill_id].get(next_lvl, "")
		else:
			label_desc.text = data.get("desc", "")
			
		label_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label_desc.label_settings = label_font
		label_desc.add_theme_font_size_override("font_size", 14)
		label_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(label_desc)
		
		# Solo permitir BUY si es una habilidad con niveles meta y no está al máximo
		if GameManager.card_upgrade_levels.has(skill_id) and not is_maxed:
			if typeof(level) == TYPE_INT and level < 3:
				var btn_upgrade = Button.new()
				btn_upgrade.text = "BUY LV (" + str(cost) + ")"
				btn_upgrade.custom_minimum_size = Vector2(0, 50)
				btn_upgrade.disabled = GameManager.total_gold < cost
				btn_upgrade.add_theme_font_override("font", button_font)
				btn_upgrade.mouse_filter = Control.MOUSE_FILTER_PASS
				btn_upgrade.pressed.connect(_on_upgrade_clicked.bind(skill_id, cost))
				vbox.add_child(btn_upgrade)
			elif typeof(level) == TYPE_INT and level == 3:
				# Mostrar opciones de maestría (Nivel 4)
				var btn_fav = Button.new()
				btn_fav.text = "FAV (" + str(cost) + ")"
				btn_fav.custom_minimum_size = Vector2(0, 40)
				btn_fav.disabled = GameManager.total_gold < cost
				btn_fav.add_theme_font_override("font", button_font)
				btn_fav.add_theme_font_size_override("font_size", 14)
				btn_fav.pressed.connect(_on_maestria_clicked.bind(skill_id, "4_fav", cost))
				vbox.add_child(btn_fav)
				
				var btn_spec = Button.new()
				btn_spec.text = "SPEC (" + str(cost) + ")"
				btn_spec.custom_minimum_size = Vector2(0, 40)
				btn_spec.disabled = GameManager.total_gold < cost
				btn_spec.add_theme_font_override("font", button_font)
				btn_spec.add_theme_font_size_override("font_size", 14)
				btn_spec.pressed.connect(_on_maestria_clicked.bind(skill_id, "4_spec", cost))
				vbox.add_child(btn_spec)
		else:
			var label_info = Label.new()
			if is_maxed:
				label_info.text = "[MAESTRÍA]"
			elif typeof(level) == TYPE_INT and level >= 3:
				label_info.text = "[MAXED]"
			else:
				label_info.text = "[INMEJORABLE]"
			label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label_info.label_settings = label_font
			label_info.modulate = Color(0.6, 0.6, 0.6)
			label_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(label_info)
	else:
		var label_q = Label.new()
		label_q.text = "?"
		label_q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_q.label_settings = label_font
		label_q.add_theme_font_size_override("font_size", 60)
		label_q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(label_q)

	grid.add_child(card_bg)

func _on_upgrade_clicked(skill_id: String, cost: int) -> void:
	if GameManager.total_gold >= cost:
		GameManager.total_gold -= cost
		GameManager.card_upgrade_levels[skill_id] += 1
		GameManager.save_game()
		if AudioManager.has_method("play"): AudioManager.play("coin_pickup")
		update_ui()

func _on_maestria_clicked(skill_id: String, type: String, cost: int) -> void:
	if GameManager.total_gold >= cost:
		GameManager.total_gold -= cost
		GameManager.card_upgrade_levels[skill_id] = type
		GameManager.register_mastery(skill_id)
		GameManager.save_game()
		if AudioManager.has_method("play"): AudioManager.play("coin_pickup")
		update_ui()

func _on_btn_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MenuInicio.tscn")
