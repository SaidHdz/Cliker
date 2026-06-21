extends Control

var grid: GridContainer
@onready var gold_label: Label = $VBoxContainer/GoldLabel

var label_font = preload("res://scenes/Font.tres")
var button_font = preload("res://assets/fuentes/BoldPixels.ttf")

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
	
	var progress_info = Label.new()
	progress_info.text = "ESTADÍSTICAS"
	progress_info.label_settings = label_font
	progress_info.add_theme_font_size_override("font_size", 24)
	header_hbox.add_child(progress_info)
	
	$VBoxContainer.add_child(header_hbox)
	$VBoxContainer.move_child(header_hbox, 0)
	
	# 3. Ajustar Grid para 5 Columnas y Scroll Móvil
	var scroll = $VBoxContainer/ScrollContainer
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var old_list = $VBoxContainer/ScrollContainer/UpgradeList
	if old_list: old_list.queue_free()
	
	grid = GridContainer.new()
	grid.columns = 5 # 5 Columnas solicitadas
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_PASS # Dejar pasar el scroll
	scroll.add_child(grid)
	
	var btn_back = $VBoxContainer/BtnBack
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
		btn_back.offset_left = -63
		btn_back.offset_top = 8
		btn_back.offset_right = -8
		btn_back.offset_bottom = 63
	
	update_ui()

func update_ui() -> void:
	gold_label.text = "BANCO: " + str(GameManager.total_gold) + " ORO"
	if not is_instance_valid(grid): return
	for child in grid.get_children(): child.queue_free()
		
	add_upgrade_card("damage", "FUERZA CLICK", GameManager.meta_base_damage, GameManager.cost_meta_damage, "+1 Daño")
	add_upgrade_card("health", "SALUD ISLA", GameManager.meta_base_health, GameManager.cost_meta_health, "+50 Salud")
	add_upgrade_card("crit", "OJO CRÍTICO", int(GameManager.meta_crit_chance * 100), GameManager.cost_meta_crit, "+5% Crítico")

func add_upgrade_card(id: String, title: String, current_val: int, cost: int, desc: String) -> void:
	var card_bg = PanelContainer.new()
	card_bg.custom_minimum_size = Vector2(180, 320) # Más compactas
	card_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 1.0)
	style.border_width_left = 3; style.border_width_top = 3
	style.border_width_right = 3; style.border_width_bottom = 3
	style.border_color = Color(0.8, 0.6, 0.2, 1.0)
	style.set_corner_radius_all(10)
	card_bg.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	card_bg.add_child(vbox)
	
	var label_title = Label.new()
	label_title.text = title
	label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_title.label_settings = label_font
	label_title.add_theme_font_size_override("font_size", 20)
	label_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label_title)
	
	var label_val = Label.new()
	label_val.text = "LV: " + str(current_val)
	label_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_val.label_settings = label_font
	label_val.modulate = Color(1, 0.9, 0.4)
	label_val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label_val)
	
	var label_desc = Label.new()
	label_desc.text = desc
	label_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_desc.label_settings = label_font
	label_desc.add_theme_font_size_override("font_size", 16)
	label_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label_desc)
	
	var btn = Button.new()
	btn.text = "BUY (" + str(cost) + ")"
	btn.custom_minimum_size = Vector2(0, 60)
	btn.disabled = GameManager.total_gold < cost
	btn.add_theme_font_override("font", button_font)
	btn.mouse_filter = Control.MOUSE_FILTER_PASS # IMPORTANTE: PASS para permitir drag
	btn.pressed.connect(_on_buy_pressed.bind(id, cost))
	vbox.add_child(btn)
	
	grid.add_child(card_bg)

func _on_buy_pressed(id: String, cost: int) -> void:
	# Verificamos si es un click real y no un drag (opcional pero recomendado)
	if GameManager.total_gold >= cost:
		GameManager.total_gold -= cost
		GameManager.increment_stat("gold_spent", cost)
		if cost > GameManager.profile_stats.get("most_expensive_upgrade", 0):
			GameManager.profile_stats["most_expensive_upgrade"] = cost
		if id == "damage":
			GameManager.meta_base_damage += 1
			GameManager.cost_meta_damage = int(GameManager.cost_meta_damage * 1.5)
		elif id == "health":
			GameManager.meta_base_health += 50
			GameManager.cost_meta_health = int(GameManager.cost_meta_health * 1.5)
		elif id == "crit" and GameManager.meta_crit_chance < 0.2:
			GameManager.meta_crit_chance += 0.05
			GameManager.cost_meta_crit = int(GameManager.cost_meta_crit * 2.0)
		
		GameManager.save_game()
		if AudioManager.has_method("play"): AudioManager.play("coin_pickup")
		update_ui()

func _on_btn_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MenuInicio.tscn")
