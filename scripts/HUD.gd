extends CanvasLayer

@onready var coins_label: Label = $CoinsLabel
@onready var wave_label: Label = $WaveLabel
@onready var btn_pause: Button = $BtnPause

# --- NUEVO: Barra de Nivel ---
@onready var xp_bar: ProgressBar = $XPBar
@onready var level_label: Label = $XPBar/LevelLabel 
@onready var combo_label: Label = get_node_or_null("ComboLabel")

# --- NUEVO: Info de Recompensas ---
@onready var reward_label: Label = get_node_or_null("RewardLabel") # Añade este label en Godot

signal pause_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Nos suscribimos a las señales
	GameManager.xp_updated.connect(_on_xp_updated)
	GameManager.level_up.connect(_on_level_up)
	GameManager.wave_updated.connect(_on_wave_updated)
	GameManager.combo_updated.connect(_on_combo_updated)
	GameManager.chest_reward_activated.connect(_on_chest_reward)
	
	# Inicializar la interfaz
	_on_xp_updated(GameManager.current_xp, GameManager.xp_to_next_level)
	_on_level_up(GameManager.current_level)
	_on_wave_updated(GameManager.current_wave)
	_on_combo_updated(0)
	if reward_label: reward_label.hide()

func _on_xp_updated(current_xp: int, max_xp: int) -> void:
	if xp_bar:
		xp_bar.max_value = max_xp
		xp_bar.value = current_xp

func _on_level_up(new_level: int) -> void:
	if level_label:
		level_label.text = "Nivel " + str(new_level)

func _on_wave_updated(new_wave: int) -> void:
	wave_label.text = "Oleada: " + str(new_wave)

func _on_chest_reward(reward_name: String) -> void:
	if reward_label:
		reward_label.text = "¡" + reward_name.to_upper() + " ACTIVADO!"
		reward_label.show()
		
		# Animación de aviso
		var t = create_tween()
		t.tween_property(reward_label, "scale", Vector2(1.5, 1.5), 0.2)
		t.tween_property(reward_label, "scale", Vector2(1.0, 1.0), 0.2)
		
		# Ocultar tras 3 segundos
		await get_tree().create_timer(3.0).timeout
		reward_label.hide()

func _on_combo_updated(count: int) -> void:
	if not combo_label: return
	if count <= 1:
		combo_label.hide()
		return
	
	combo_label.show()
	combo_label.text = "COMBO X" + str(count)
	
	# --- CAMBIO DE COLOR DINÁMICO ---
	# Interpolamos de Amarillo (0) a Azul Fuego (500+)
	var fire_blue = Color(0.0, 0.8, 1.0) # Azul fuego brillante
	var progress = clamp(float(count) / 500.0, 0.0, 1.0)
	combo_label.modulate = Color.YELLOW.lerp(fire_blue, progress)
	
	var tween = create_tween()
	combo_label.pivot_offset = combo_label.size / 2.0
	tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.05)
	tween.parallel().tween_property(combo_label, "rotation_degrees", randf_range(-15, 15), 0.05)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.parallel().tween_property(combo_label, "rotation_degrees", 0.0, 0.1)

func _on_btn_pause_pressed() -> void:
	pause_requested.emit()
