extends Area2D

@export var speed: float = 300.0
var target_pos: Vector2 = Vector2.ZERO

func set_target(pos: Vector2) -> void:
	target_pos = pos
	look_at(target_pos)

func _physics_process(delta: float) -> void:
	var direction = global_position.direction_to(target_pos)
	global_position += direction * speed * delta
	
	if global_position.distance_to(target_pos) < 10:
		# Al llegar a la base, explota
		var base = get_tree().get_first_node_in_group("BaseRabanito")
		if base and base.has_method("take_damage"):
			base.take_damage(5)
		queue_free()

func take_damage(_amount: int, _is_crit: bool = false) -> void:
	# El jugador puede rebanar las balas en el aire
	AudioManager.play("pop")
	queue_free()
