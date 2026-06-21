extends Label

const COLORS = {
	"normal": Color.WHITE,
	"crit": Color.YELLOW,
	"fire": Color.INDIAN_RED,
	"electric": Color.ROYAL_BLUE,
	"poison": Color.LIME_GREEN,
	"bleed": Color(0.85, 0.1, 0.1)
}

var active_tween: Tween
var total_amount: int = 0
var is_critical: bool = false
var damage_type: String = "normal"

func _ready() -> void:
	GameManager.active_damage_numbers += 1
	tree_exiting.connect(func(): GameManager.active_damage_numbers -= 1)

func set_values(amount: int, is_crit: bool, pos: Vector2, type: String = "normal") -> void:
	global_position = pos
	total_amount = amount
	is_critical = is_crit
	damage_type = type
	_update_text_and_tween()

func refresh_damage(amount: int, is_crit: bool, type: String = "normal") -> void:
	total_amount += amount
	if is_crit:
		is_critical = true
	if type != "normal":
		damage_type = type
	_update_text_and_tween()

func _update_text_and_tween() -> void:
	text = str(total_amount)
	reset_size()
	pivot_offset = size / 2.0
	
	if is_critical:
		modulate = COLORS["crit"]
	else:
		modulate = COLORS.get(damage_type, COLORS["normal"])
		
	scale = Vector2.ZERO
	modulate.a = 1.0
	
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	active_tween = create_tween()
	active_tween.set_parallel(true)
	
	var target_scale = Vector2(1.4, 1.4) if is_critical else Vector2.ONE
	var pop_scale = target_scale * 1.5
	
	# Elevación vertical y desvanecimiento
	active_tween.tween_property(self, "position:y", position.y - 70, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.3)
	
	# Escala elástica (Efecto Pop / Salto)
	active_tween.tween_property(self, "scale", pop_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "scale", target_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.15)
	
	# Retorno al Object Pooling al finalizar la animación
	active_tween.chain().tween_callback(func(): GameManager.return_damage_number(self))
