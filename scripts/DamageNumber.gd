extends Label

const COLORS = {
	"normal": Color.WHITE,
	"crit": Color.YELLOW,
	"fire": Color.INDIAN_RED,
	"electric": Color.ROYAL_BLUE,
	"poison": Color.LIME_GREEN
}

func _ready() -> void:
	GameManager.active_damage_numbers += 1
	tree_exiting.connect(func(): GameManager.active_damage_numbers -= 1)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Movimiento hacia arriba
	tween.tween_property(self, "position:y", position.y - 60, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Desvanecimiento
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	
	# La forma más segura de borrarlo tras los tweens paralelos
	tween.chain().tween_callback(queue_free)

func set_values(amount: int, is_crit: bool, pos: Vector2, type: String = "normal") -> void:
	global_position = pos
	text = str(amount)
	
	# Truco: Forzar actualización del tamaño para que el pivote sea exacto
	reset_size()
	pivot_offset = size / 2.0 
	
	if is_crit:
		modulate = COLORS["crit"]
		# Animación de "Pop" para críticos (crece a 1.6 y baja a 1.3 rápidamente)
		scale = Vector2(1.6, 1.6)
		var pop_tween = create_tween()
		pop_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BOUNCE)
	else:
		modulate = COLORS.get(type, COLORS["normal"])
