extends Area2D

@export var duration: float = 3.0
@export var damage: int = 3

func _ready() -> void:
	modulate.a = 0
	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.2)
	
	get_tree().create_timer(duration).timeout.connect(func():
		var t2 = create_tween()
		t2.tween_property(self, "modulate:a", 0.0, 0.5)
		t2.finished.connect(queue_free)
	)

func _on_timer_timeout() -> void:
	for area in get_overlapping_areas():
		if area.is_in_group("enemies") and area.has_method("apply_fire"):
			area.apply_fire() # Aplica el estado quemado
			area.take_damage(damage)
