extends Area2D

@export var damage_per_tick: int = 2

func _ready() -> void:
	# El charco dura 5 segundos en el suelo
	get_tree().create_timer(5.0).timeout.connect(queue_free)
	
	# Temporizador para dañar a los que estén encima
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_on_tick)
	add_child(timer)
	timer.start()

func _on_tick() -> void:
	for body in get_overlapping_areas():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage_per_tick, false, "poison")
			if body.has_method("apply_poison"):
				body.apply_poison()
