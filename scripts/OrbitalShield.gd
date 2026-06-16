extends Node2D

@export var rotation_speed: float = 3.0

func _physics_process(delta: float) -> void:
	# Rotación constante por código (asegura que gire aunque no haya animación)
	rotate(rotation_speed * delta)
	
	# Escalar visualmente según el daño/nivel (opcional)
	var target_scale = 1.0 + (GameManager.shield_level * 0.1)
	scale = lerp(scale, Vector2(target_scale, target_scale), 0.1)

func _on_leaf_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(GameManager.shield_damage)
			# Pequeño efecto visual al chocar
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.05)
			tween.tween_property(self, "modulate", Color.WHITE, 0.1)


func _on_hoja_1_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(GameManager.shield_damage)
			# Pequeño efecto visual al chocar
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.05)
			tween.tween_property(self, "modulate", Color.WHITE, 0.1)


func _on_hoja_2_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(GameManager.shield_damage)
			# Pequeño efecto visual al chocar
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.05)
			tween.tween_property(self, "modulate", Color.WHITE, 0.1)
