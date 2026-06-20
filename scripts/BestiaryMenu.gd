extends Control

@onready var grid: GridContainer = $VBoxContainer/ScrollContainer/GridContainer

var label_font = preload("res://scenes/Font.tres")
var button_font = preload("res://assets/fuentes/BoldPixels.ttf")

# --- MODAL ---
var modal_bg: ColorRect
var modal_panel: PanelContainer
var modal_title: Label
var modal_desc: Label
var modal_milestone_lbl: Label
var modal_claim_btn: Button
var gold_label_ref: Label

func _ready() -> void:
	# 1. Fondo Negro Sólido
	$ColorRect.color = Color(0.05, 0.05, 0.05, 1.0)
	
	# 2. Header Uniforme
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 50)
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var gold_info = Label.new()
	gold_info.text = "BANCO: " + str(GameManager.total_gold) + " ORO"
	gold_info.label_settings = label_font
	gold_label_ref = gold_info
	header_hbox.add_child(gold_info)
	
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
	
	# 3. Estilo Grid para 5 Columnas y Scroll Móvil
	var scroll = $VBoxContainer/ScrollContainer
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	
	_setup_modal()
	for child in grid.get_children(): child.queue_free()
	
	var discovered = 0
	for id in GameManager.bestiary.keys():
		if GameManager.bestiary[id] > 0: discovered += 1
		create_entry(id, GameManager.bestiary[id])
	
	progress_label.text = "ALIENS: " + str(discovered) + " / " + str(GameManager.bestiary.size())
	
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

func _setup_modal() -> void:
	modal_bg = ColorRect.new()
	modal_bg.color = Color(0, 0, 0, 0.7)
	modal_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_bg.visible = false
	
	var shader = Shader.new()
	shader.code = "shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, 3.0);
		COLOR.rgb *= 0.4;
	}"
	var mat = ShaderMaterial.new(); mat.shader = shader
	modal_bg.material = mat
	add_child(modal_bg)
	
	modal_panel = PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(650, 500)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 1.0)
	style.border_width_left = 4; style.border_width_top = 4
	style.border_width_right = 4; style.border_width_bottom = 4
	style.border_color = Color(0.8, 0.6, 0.2, 1.0)
	style.set_corner_radius_all(15)
	modal_panel.add_theme_stylebox_override("panel", style)
	
	modal_panel.anchors_preset = Control.PRESET_CENTER
	modal_panel.anchor_left = 0.5; modal_panel.anchor_top = 0.5
	modal_panel.anchor_right = 0.5; modal_panel.anchor_bottom = 0.5
	modal_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	modal_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	modal_bg.add_child(modal_panel)
	
	# Botón de cerrar en la esquina
	var close_btn_wrapper = Control.new()
	modal_panel.add_child(close_btn_wrapper)
	
	var btn_close_top = Button.new()
	btn_close_top.text = " X "
	btn_close_top.custom_minimum_size = Vector2(55, 55)
	btn_close_top.add_theme_font_override("font", button_font)
	btn_close_top.add_theme_font_size_override("font_size", 22)
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.35, 0.1, 0.1, 1.0)
	close_style.set_corner_radius_all(6)
	btn_close_top.add_theme_stylebox_override("normal", close_style)
	btn_close_top.add_theme_stylebox_override("hover", close_style)
	btn_close_top.add_theme_stylebox_override("pressed", close_style)
	
	close_btn_wrapper.add_child(btn_close_top)
	btn_close_top.position = Vector2(650 - 65, 10)
	
	btn_close_top.pressed.connect(func(): modal_bg.visible = false)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_panel.add_child(vbox)
	
	modal_title = Label.new()
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.label_settings = label_font
	modal_title.add_theme_font_size_override("font_size", 44)
	vbox.add_child(modal_title)
	
	modal_desc = Label.new()
	modal_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modal_desc.label_settings = label_font
	modal_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_desc.add_theme_font_size_override("font_size", 24)
	vbox.add_child(modal_desc)
	
	modal_milestone_lbl = Label.new()
	modal_milestone_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_milestone_lbl.label_settings = label_font
	modal_milestone_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(modal_milestone_lbl)
	
	modal_claim_btn = Button.new()
	modal_claim_btn.custom_minimum_size = Vector2(250, 60)
	modal_claim_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	modal_claim_btn.add_theme_font_override("font", button_font)
	vbox.add_child(modal_claim_btn)

	var btn_close = Button.new()
	btn_close.text = "VOLVER"
	btn_close.custom_minimum_size = Vector2(200, 70)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_close.add_theme_font_override("font", button_font)
	btn_close.pressed.connect(func(): modal_bg.visible = false)
	vbox.add_child(btn_close)

func create_entry(id: int, count: int) -> void:
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(180, 160)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 1.0)
	style.border_width_left = 3; style.border_width_top = 3
	style.border_width_right = 3; style.border_width_bottom = 3
	style.border_color = Color(0.8, 0.6, 0.2, 1.0)
	style.set_corner_radius_all(10)
	card_panel.add_theme_stylebox_override("panel", style)
	
	var btn = Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	card_panel.add_child(btn)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_panel.add_child(vbox)
	
	var data = GameManager.alien_data.get(id, {"name": "???", "desc": ""})
	var is_discovered = count > 0
	
	var label_name = Label.new()
	label_name.text = data.name.to_upper() if is_discovered else "???"
	label_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_name.label_settings = label_font
	label_name.add_theme_font_size_override("font_size", 16)
	vbox.add_child(label_name)
	
	var label_count = Label.new()
	label_count.text = "KILLS: " + str(count)
	label_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_count.label_settings = label_font
	label_count.modulate = Color(0.7, 0.7, 0.7)
	label_count.add_theme_font_size_override("font_size", 14)
	vbox.add_child(label_count)
	
	if is_discovered:
		btn.pressed.connect(_on_alien_clicked.bind(id))
	else:
		style.bg_color = Color(0.04, 0.04, 0.04, 1.0)
		style.border_color = Color(0.3, 0.3, 0.3, 1.0)
		
	grid.add_child(card_panel)

func _on_alien_clicked(id: int) -> void:
	var data = GameManager.alien_data.get(id, {"name": "???", "desc": "Sin datos."})
	modal_title.text = data.name.to_upper()
	modal_desc.text = data.desc + "\n\nDERROTADOS: " + str(GameManager.bestiary[id])
	modal_bg.visible = true
	
	modal_panel.pivot_offset = Vector2(325, 250)
	modal_panel.scale = Vector2(0.8, 0.8)
	var t = create_tween()
	t.tween_property(modal_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	# Desconectar señales de reclamo previas
	for connection in modal_claim_btn.pressed.get_connections():
		modal_claim_btn.pressed.disconnect(connection.callable)
		
	_update_milestone_ui(id)

func _update_milestone_ui(id: int) -> void:
	var m_lvl = GameManager.bestiary_milestones.get(id, 1)
	var target = _get_milestone_target(id, m_lvl)
	var reward = _get_milestone_reward(id, m_lvl)
	var count = GameManager.bestiary[id]
	
	modal_milestone_lbl.text = "META ACTUAL: " + str(count) + " / " + str(target) + " KILLS\nRecompensa: " + str(reward) + " ORO"
	
	if count >= target:
		modal_claim_btn.disabled = false
		modal_claim_btn.text = "RECLAMAR ORO"
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.6, 0.2)
		style.set_corner_radius_all(8)
		modal_claim_btn.add_theme_stylebox_override("normal", style)
		modal_claim_btn.add_theme_stylebox_override("hover", style)
		modal_claim_btn.add_theme_stylebox_override("pressed", style)
		
		modal_claim_btn.pressed.connect(_claim_reward.bind(id))
	else:
		modal_claim_btn.disabled = true
		modal_claim_btn.text = "BLOQUEADO"
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.3)
		style.set_corner_radius_all(8)
		modal_claim_btn.add_theme_stylebox_override("normal", style)
		modal_claim_btn.add_theme_stylebox_override("hover", style)
		modal_claim_btn.add_theme_stylebox_override("pressed", style)

func _get_milestone_target(id: int, m_lvl: int) -> int:
	var base = 50
	if id == 0:
		base = 100
	elif id == 8:
		base = 5
	else:
		base = 25
	return base * int(pow(2, m_lvl))

func _get_milestone_reward(id: int, m_lvl: int) -> int:
	var base_reward = 25
	if id == 8:
		base_reward = 75
	elif id == 0:
		base_reward = 25
	else:
		base_reward = 37
	return base_reward * int(pow(2, m_lvl))

func _claim_reward(id: int) -> void:
	var m_lvl = GameManager.bestiary_milestones.get(id, 1)
	var reward = _get_milestone_reward(id, m_lvl)
	
	GameManager.total_gold += reward
	GameManager.bestiary_milestones[id] = m_lvl + 1
	GameManager.save_game()
	
	if gold_label_ref:
		gold_label_ref.text = "BANCO: " + str(GameManager.total_gold) + " ORO"
		
	if AudioManager.has_method("play"):
		AudioManager.play("coin_pickup")
		
	# Desconectar para evitar doble llamada en el próximo click
	for connection in modal_claim_btn.pressed.get_connections():
		modal_claim_btn.pressed.disconnect(connection.callable)
		
	_update_milestone_ui(id)

func _on_btn_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MenuInicio.tscn")
