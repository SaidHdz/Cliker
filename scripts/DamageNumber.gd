extends Label

var start_pos: Vector2

func set_values(amount: int, is_crit: bool, _start_pos: Vector2) -> void:
	text = str(amount)
	start_pos = _start_pos
	position = start_pos
	
	if is_crit:
		add_theme_color_override("font_color", Color(1, 0.84, 0)) # Dorado
		add_theme_font_size_override("font_size", 36) # Más grande
	else:
		add_theme_color_override("font_color", Color(1, 1, 1)) # Blanco
		add_theme_font_size_override("font_size", 24) # Tamaño normal
		
	animate()

func animate() -> void:
	var tween = create_tween()
	
	# Valores aleatorios para la dirección del arco
	var random_x_offset = randf_range(-60.0, 60.0)
	var peak_y_offset = -80.0
	var final_y_offset = 20.0
	
	# Punto más alto del arco
	var peak_pos = start_pos + Vector2(random_x_offset * 0.5, peak_y_offset)
	# Punto de caída final
	var end_pos = start_pos + Vector2(random_x_offset, final_y_offset)
	
	# Fase 1: Sube rápido al punto máximo
	tween.tween_property(self, "position", peak_pos, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Fase 2: Cae mientras se desvanece
	tween.tween_property(self, "position", end_pos, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	
	# Borrar al terminar
	tween.finished.connect(queue_free)
