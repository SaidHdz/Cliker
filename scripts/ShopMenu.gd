extends CanvasLayer

@onready var gold_label: Label = $Modal/VBox/Header/HBox/GoldDisplay/GoldLabel
@onready var btn_close: Button = $Modal/VBox/Header/HBox/BtnClose
@onready var btn_equip_beta: Button = $"Modal/VBox/Tabs/COSMÉTICOS/Margin/SkinGrid/SkinCard_Beta/VBox/BtnEquip"
@onready var btn_ad: Button = $"Modal/VBox/Tabs/ORO GRATIS/VBox/Card/VBox/BtnAd"

func _ready() -> void:
	update_ui()
	btn_close.pressed.connect(_on_close_pressed)
	btn_equip_beta.pressed.connect(_on_equip_beta_pressed)
	# El botón de anuncio está deshabilitado en el TSCN, pero por seguridad:
	btn_ad.disabled = true
	
	var scroll = get_node_or_null("Modal/VBox/Tabs/COSMÉTICOS")
	if scroll:
		_setup_drag_scroll(scroll)
		
	var tabs = get_node_or_null("Modal/VBox/Tabs")
	if tabs:
		tabs.tab_changed.connect(func(tab_idx):
			print("Tab de tienda cambiada a: ", tab_idx)
		)

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
