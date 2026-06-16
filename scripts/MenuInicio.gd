extends Control

# Nodos de Información
@onready var record_label: Label = $VBoxContainer/RecordLabel
@onready var gold_label: Label = $VBoxContainer/GoldLabel

# Nodos de Tienda (Asegúrate de crearlos en la escena MenuInicio.tscn)
@onready var btn_buy_damage: Button = $ShopContainer/BtnBuyDamage
@onready var btn_buy_health: Button = $ShopContainer/BtnBuyHealth
@onready var btn_buy_crit: Button = $ShopContainer/BtnBuyCrit

func _ready() -> void:
	# FORZAR DESPAUSA: A veces el cambio de escena desde un estado pausado puede heredar el bloqueo.
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	update_ui()
	
	# Conectar botones de la tienda si existen
	if btn_buy_damage: btn_buy_damage.pressed.connect(_on_buy_damage)
	if btn_buy_health: btn_buy_health.pressed.connect(_on_buy_health)
	if btn_buy_crit: btn_buy_crit.pressed.connect(_on_buy_crit)

func update_ui() -> void:
	# Actualizar Récord
	if record_label:
		record_label.text = "Récord: Oleada " + str(GameManager.best_wave)
		
	# Actualizar Oro Total
	if gold_label:
		gold_label.text = "Banco: " + str(GameManager.total_gold) + " Oro"
		
	# Actualizar Textos de la Tienda (Usando saltos de línea para evitar superposición)
	if btn_buy_damage:
		btn_buy_damage.text = "+1 Daño Base\nNivel: " + str(GameManager.meta_base_damage) + "\nCoste: " + str(GameManager.cost_meta_damage)
	if btn_buy_health:
		btn_buy_health.text = "+50 Salud Base\nNivel: " + str(GameManager.meta_base_health) + "\nCoste: " + str(GameManager.cost_meta_health)
	if btn_buy_crit:
		btn_buy_crit.text = "+5% Crítico Base\nNivel: +" + str(int(GameManager.meta_crit_chance * 100)) + "%\nCoste: " + str(GameManager.cost_meta_crit)

func _on_btn_start_pressed() -> void:
	print("DEBUG: Botón JUGAR presionado. Despausando y cambiando a Main...")
	get_tree().paused = false # Forzar de nuevo justo antes del cambio
	# Reset run forces the new meta stats to apply
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_btn_exit_pressed() -> void:
	get_tree().quit()

# --- LÓGICA DE LA TIENDA PERMANENTE ---

func _on_buy_damage() -> void:
	if GameManager.total_gold >= GameManager.cost_meta_damage:
		GameManager.total_gold -= GameManager.cost_meta_damage
		GameManager.meta_base_damage += 1
		GameManager.cost_meta_damage = int(GameManager.cost_meta_damage * 1.5)
		GameManager.save_game() # Guardar progreso
		play_buy_sound()
		update_ui()

func _on_buy_health() -> void:
	if GameManager.total_gold >= GameManager.cost_meta_health:
		GameManager.total_gold -= GameManager.cost_meta_health
		GameManager.meta_base_health += 50
		GameManager.cost_meta_health = int(GameManager.cost_meta_health * 1.5)
		GameManager.save_game() # Guardar progreso
		play_buy_sound()
		update_ui()

func _on_buy_crit() -> void:
	# Límite máximo de crítico base: 50%
	if GameManager.total_gold >= GameManager.cost_meta_crit and GameManager.meta_crit_chance < 0.5:
		GameManager.total_gold -= GameManager.cost_meta_crit
		GameManager.meta_crit_chance += 0.05
		GameManager.cost_meta_crit = int(GameManager.cost_meta_crit * 2.0)
		GameManager.save_game() # Guardar progreso
		play_buy_sound()
		update_ui()

func play_buy_sound() -> void:
	if AudioManager.has_method("play"):
		AudioManager.play("coin_pickup") # Sonido de caja registradora
