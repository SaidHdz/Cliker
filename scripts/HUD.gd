extends CanvasLayer

@onready var coins_label: Label = $CoinsLabel
@onready var wave_label: Label = $WaveLabel
@onready var btn_pause: Button = $BtnPause

# --- NUEVO: Barra de Nivel ---
@onready var xp_bar: ProgressBar = $XPBar
@onready var level_label: Label = $XPBar/LevelLabel 
@onready var combo_label: Label = get_node_or_null("ComboLabel")

signal pause_requested

func _ready() -> void:
	# Nos suscribimos a las señales de XP, oleadas y combo
	GameManager.xp_updated.connect(_on_xp_updated)
	GameManager.level_up.connect(_on_level_up)
	GameManager.wave_updated.connect(_on_wave_updated)
	GameManager.combo_updated.connect(_on_combo_updated)
	
	# Inicializar la interfaz
	_on_xp_updated(GameManager.current_xp, GameManager.xp_to_next_level)
	_on_level_up(GameManager.current_level)
	_on_wave_updated(GameManager.current_wave)
	_on_combo_updated(0)

func _on_xp_updated(current_xp: int, max_xp: int) -> void:
	if xp_bar:
		xp_bar.max_value = max_xp
		xp_bar.value = current_xp

func _on_level_up(new_level: int) -> void:
	if level_label:
		level_label.text = "Nivel " + str(new_level)

func _on_wave_updated(new_wave: int) -> void:
	wave_label.text = "Oleada: " + str(new_wave)

func _on_combo_updated(count: int) -> void:
	if not combo_label: return
	
	if count <= 1:
		combo_label.hide()
		return
	
	combo_label.show()
	combo_label.text = "COMBO X" + str(count)
	
	# Efecto visual (Tween)
	var tween = create_tween()
	combo_label.pivot_offset = combo_label.size / 2.0
	
	# Latido y Rotación loca
	tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.05)
	tween.parallel().tween_property(combo_label, "rotation_degrees", randf_range(-15, 15), 0.05)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.parallel().tween_property(combo_label, "rotation_degrees", 0.0, 0.1)

func _on_btn_pause_pressed() -> void:
	pause_requested.emit()

func _on_btn_prestige_pressed() -> void:
	pass 
