extends CanvasLayer

@onready var gold_label: Label = $Modal/VBox/Header/HBox/GoldDisplay/GoldLabel
@onready var btn_close: Button = $Modal/VBox/Header/HBox/BtnClose
@onready var btn_equip_beta: Button = $"Modal/VBox/Tabs/COSMÉTICOS/Margin/SkinGrid/SkinCard_Beta/VBox/BtnEquip"
@onready var btn_ad: Button = $"Modal/VBox/Tabs/ORO GRATIS/VBox/Card/VBox/BtnAd"

func _ready() -> void:
	update_ui()
	btn_close.pressed.connect(_on_close_pressed)
	
	# Asegurar que el TabContainer reciba clics para cambiar de pestaña
	var tabs = get_node_or_null("Modal/VBox/Tabs")
	if tabs:
		tabs.mouse_filter = Control.MOUSE_FILTER_STOP
		tabs.tab_changed.connect(func(tab_idx):
			print("Tab de tienda cambiada a: ", tab_idx)
		)
	
	var scroll = get_node_or_null("Modal/VBox/Tabs/COSMÉTICOS")
	if scroll:
		scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		_setup_drag_scroll(scroll)
		_set_mouse_filter_pass_recursive(scroll)
		
	# Conectar botón de equipar con protección de arrastre
	_connect_button_with_drag_protection(btn_equip_beta, _on_equip_beta_pressed)
	
	# El botón de anuncio está deshabilitado en el TSCN, pero por seguridad:
	btn_ad.disabled = true

func _set_mouse_filter_pass_recursive(node: Node) -> void:
	if node is Control:
		if not node is Button and not node is ScrollContainer:
			node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in node.get_children():
		_set_mouse_filter_pass_recursive(child)

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

func update_ui() -> void:
	gold_label.text = str(GameManager.total_gold)
	
	# Logica Skin Rabanito Diablo
	if GameManager.is_beta_tester:
		if GameManager.current_skin == "rabanito_diablo":
			btn_equip_beta.text = "EQUIPADO"
			btn_equip_beta.disabled = true
		else:
			btn_equip_beta.text = "EQUIPAR"
			btn_equip_beta.disabled = false
	else:
		btn_equip_beta.text = "BLOQUEADA"
		btn_equip_beta.disabled = true

func _on_close_pressed() -> void:
	queue_free()

func _on_equip_beta_pressed() -> void:
	GameManager.current_skin = "rabanito_diablo"
	GameManager.save_game()
	update_ui()
	print("Skin Rabanito Diablo equipada")
