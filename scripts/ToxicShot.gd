extends Area2D

@export var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
var current_health: int = 1 # Para evitar errores de acceso desde aliados
var extra_damage: int = 0

func _ready() -> void:
	add_to_group("projectiles")
	# Autodestrucción por si sale de pantalla
	get_tree().create_timer(5.0).timeout.connect(queue_free)
	area_entered.connect(_on_area_entered)

func set_target(pos: Vector2) -> void:
	direction = global_position.direction_to(pos)
	look_at(pos)

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("BaseRabanito"):
		if area.has_method("take_damage"):
			area.take_damage(5 + extra_damage, "poison")
		queue_free()

func take_damage(_amount: int, _is_crit: bool = false, _type: String = "normal") -> void:
	# El jugador puede rebanar las balas en el aire
	AudioManager.play("pop")
	queue_free()
