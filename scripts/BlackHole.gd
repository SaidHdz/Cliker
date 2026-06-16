extends Area2D

@export var duration: float = 4.0
@export var pull_force: float = 300.0

func _ready() -> void:
	scale = Vector2.ZERO
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_BACK)
	
	var t_rot = create_tween().set_loops()
	t_rot.tween_property(self, "rotation", PI * 2, 1.0).as_relative()
	
	get_tree().create_timer(duration).timeout.connect(func():
		var t2 = create_tween()
		t2.tween_property(self, "scale", Vector2.ZERO, 0.3)
		t2.finished.connect(queue_free)
	)

func _physics_process(delta: float) -> void:
	# Succionar enemigos en el área
	for area in get_overlapping_areas():
		if area.is_in_group("enemies") and not area.get("is_boss"):
			var dir = global_position.direction_to(area.global_position)
			var dist = global_position.distance_to(area.global_position)
			if dist > 10:
				area.position -= dir * pull_force * delta
				# Daño leve por succión
				if area.has_method("take_damage") and randf() < 0.1:
					area.take_damage(1)
