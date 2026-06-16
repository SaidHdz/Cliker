extends Area2D

@export var speed: float = 600.0
@export var damage: int = 5
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Autodestrucción si no golpea nada en 5 segundos
	get_tree().create_timer(5.0).timeout.connect(queue_free)
	
	# Conectamos la colisión
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	# Moverse en la dirección asignada
	global_position += direction * speed * delta
	# Mirar hacia donde vuela
	rotation = direction.angle()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
			# print("DEBUG: Semilla golpeó a ", area.name)
		
		queue_free() # Se destruye al impactar

# Fallback por si tus enemigos son Body en lugar de Area
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
