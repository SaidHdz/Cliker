extends Node2D

var conqueror_pulse_timer: Timer

func _ready() -> void:
	conqueror_pulse_timer = Timer.new()
	conqueror_pulse_timer.wait_time = 8.0
	conqueror_pulse_timer.timeout.connect(_on_conqueror_pulse)
	add_child(conqueror_pulse_timer)
	
	update_component()

func update_component() -> void:
	var base_time = 8.0
	if GameManager.sobrecarga_cuantica_rounds > 0:
		base_time /= 3.0
	conqueror_pulse_timer.wait_time = base_time

	if GameManager.conqueror_aura_rounds > 0:
		if conqueror_pulse_timer.is_stopped():
			conqueror_pulse_timer.start()
			_on_conqueror_pulse() # Pulso inicial
	else:
		conqueror_pulse_timer.stop()

func _on_conqueror_pulse() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var range_dist = 500.0
	
	# Sacudir cámara
	var scene = get_tree().current_scene
	if scene and scene.has_method("shake_camera"):
		scene.shake_camera(0.4, 20)
		
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < range_dist:
			var variant = e.get("current_variant")
			if not e.get("is_boss") and variant == 0:
				# Alien Normal: Muere
				if e.has_method("die"): e.die()
			else:
				# Otros: Gran empuje
				var dir = global_position.direction_to(e.global_position)
				if e.has_method("apply_knockback"):
					e.apply_knockback(dir * 800.0)
				elif "dispersion_velocity" in e:
					e.dispersion_velocity = dir * 800.0
