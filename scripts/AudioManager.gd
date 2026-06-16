extends Node

# Cargamos los archivos directamente por su ruta para evitar errores en móviles
# NOTA: Revisa que estas rutas coincidan exactamente (mayúsculas/minúsculas)
var streams = {
	"crit": preload("res://assets/sounds/crit.wav"),
	"pop": preload("res://assets/sounds/pop.wav"),
	"drop_xp": preload("res://assets/sounds/drop_xp.wav"),
	"take_xp": preload("res://assets/sounds/take_xp.wav")
}

var players = {}

func _ready() -> void:
	# Creamos los reproductores y les asignamos el audio cargado
	for key in streams:
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.stream = streams[key]
		
		# Ajuste de volumen para el crítico
		if key == "crit":
			p.volume_db = -12.0
		
		players[key] = p
		print("DEBUG AudioManager: Cargado nodo para ", key)

func play(sound_name: String) -> void:
	# Compatibilidad con nombres viejos
	var final_name = sound_name
	if sound_name == "critico": final_name = "crit"
	
	if players.has(final_name):
		var p = players[final_name]
		if p.playing:
			p.stop()
		p.play()
	else:
		# Fallback silencioso por si intentas tocar algo no listo aún
		pass
