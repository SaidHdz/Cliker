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
