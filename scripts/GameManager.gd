##--- GameManager --- 
extends Node

# --- SEÑALES ---
signal coins_updated(total_coins)
signal enemy_defeated(total_defeated)
signal wave_updated(new_wave)
signal shop_updated
signal gems_updated(total_gems)
signal xp_updated(current_xp, max_xp)
signal level_up(new_level)
signal combo_updated(combo_count)
signal chest_reward_activated(reward_name)
signal chest_opened

# --- VARIABLES DE PROGRESO ---
var total_coins: int = 0
var enemies_defeated: int = 0
var skill_levels: Dictionary = {} # ID -> Nivel (1, 2, 3, "4_fav", "4_spec")
var mastered_skills: Array = [] # Lista de IDs que alcanzaron Nivel 4
var active_damage_numbers: int = 0

# --- META-PROGRESIÓN ---
var total_gold: int = 0 
var best_wave: int = 1
var best_combo: int = 0
var total_enemies_defeated: int = 0 # Acumulador histórico persistente
var is_beta_tester: bool = true
var current_skin: String = "default"
var mastery_total_count: int = 0 # Cuántas cartas al máximo se han logrado históricamente
var tutorial_completed: bool = false
var last_login_day_num: int = 0
var consecutive_logins: int = 0

var profile_stats: Dictionary = {
	"player_name": "Said",
	"equipped_title": "Novato del Huerto",
	"prestige": 0,
	"unlocked_titles": ["Novato del Huerto"],
	"equipped_avatar": "Alien Normal",
	"unlocked_avatars": ["Alien Normal"],
	
	"time_played": 0.0,
	"matches_played": 0,
	"wins": 0,
	"losses": 0,
	"chests_opened": 0,
	
	"aliens_killed": 0,
	"bosses_killed": 0,
	"total_damage": 0,
	"total_crit_damage": 0,
	"finger_cuts": 0,
	"enemies_burned": 0,
	"enemies_electrocuted": 0,
	"enemies_absorbed": 0,
	
	"gold_earned": 0,
	"gold_spent": 0,
	"coins_collected": 0,
	"total_xp_earned": 0,
	"most_expensive_upgrade": 0,
	
	"card_choices": {},
	"sinergias_discovered": [],
	
	"max_crit_damage": 0,
	"max_kills_in_match": 0,
	"max_gold_in_match": 0,
	"max_level_reached": 1,
	"max_cards_level_5": 0,
	
	"radishes_protected": 1,
	"radishes_lost": 0,
	"aliens_in_therapy": 0,
	"screens_shaken": 0,
	"explosions_caused": 0,
	"kilometers_cut": 0.0
}

# --- AJUSTES ---
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var damage_numbers_enabled: bool = true
var shaders_enabled: bool = true
var screen_shake_enabled: bool = true
var language: String = "es"

# --- VARIABLES DE MAZO INICIAL ---
var deck_level: int = 1
var deck_unlocked_slots: int = 0
var deck_equipped_cards: Array = ["", "", ""]
var veteran_badges: int = 0

# Datos de Cartas/Habilidades (En Partida - 5 Niveles)
var skills_data = {
	"fire_slice": {
		"name": "Corte Hot",
		"rarity": "comun",
		"levels": {
			1: "Tus tajos imbuyen a los enemigos en llamas, causando daño constante a lo largo del tiempo.",
			2: "El fuego arde con más intensidad. Aumenta un 50% el daño de tus quemaduras.",
			3: "Reacción volátil. Los enemigos que mueran mientras están incendiados explotarán.",
			4: "Fuego incontrolable. Las llamas ahora se propagan a los enemigos que caminen muy cerca.",
			5: "Evolución: El suelo queda marcado. Tus tajos dejan brasas candentes permanentes."
		}
	},
	"explosive_slice": {
		"name": "Tajo Explosivo",
		"rarity": "comun",
		"levels": {
			1: "Tus cortes tienen un 5% de probabilidad de generar una explosión donde mueren los enemigos.",
			2: "Pólvora mejorada. Aumenta considerablemente el daño de todas las explosiones.",
			3: "Onda expansiva. El radio de daño de las explosiones es mucho mayor.",
			4: "Reacción en cadena. Las explosiones tienen probabilidad de causar explosiones secundarias.",
			5: "Evolución: Devastación total. Probabilidad de invocar una mini bomba nuclear."
		}
	},
	"fire_wall": {
		"name": "Tajo Pintor",
		"rarity": "comun",
		"levels": {
			1: "Dibuja el peligro. Tus tajos dejan un muro de fuego persistente en el campo de batalla.",
			2: "Llamas eternas. Aumenta la duración de los muros de fuego antes de que se apaguen.",
			3: "Calor sofocante. Los enemigos que cruzan el muro ven su velocidad de movimiento reducida.",
			4: "Infierno concentrado. Duplica el daño que infligen los muros de fuego.",
			5: "Evolución: Final explosivo. El muro detona causando gran daño al terminar su duración."
		}
	},
	"lightning_slice": {
		"name": "Tajo Relámpago",
		"rarity": "rara",
		"levels": {
			1: "Tus cortes desatan un rayo eléctrico que rebota entre 2 enemigos cercanos.",
			2: "Alto voltaje. El rayo inflige mucho más daño al impactar.",
			3: "Conducción superior. El rayo ahora puede rebotar hacia 2 objetivos adicionales.",
			4: "Carga acumulativa. Cada vez que el rayo rebota, su daño se multiplica.",
			5: "Evolución: Ira divina. Invoca devastadores rayos desde el cielo aleatoriamente."
		}
	},
	"shield": {
		"name": "Escudo de Hojas",
		"rarity": "rara",
		"levels": {
			1: "Hojas afiladas orbitan tu base, dañando a los enemigos que se atrevan a acercarse.",
			2: "Filo natural. El daño por contacto del escudo se duplica.",
			3: "Defensa espesa. Añade dos hojas adicionales a la órbita de tu escudo.",
			4: "Barrera repulsora. Las hojas ahora empujan violentamente a los enemigos al impactar.",
			5: "Evolución: Torbellino protector. Las hojas giran a una velocidad extrema e imparable."
		}
	},
	"seed_nova": {
		"name": "Aura de Hojas",
		"rarity": "rara",
		"levels": {
			1: "La base dispara ráfagas de 4 hojas afiladas en forma de estrella periódicamente.",
			2: "Follaje denso. Añade 2 hojas extra a cada ráfaga disparada.",
			3: "Hojas imparables. Los proyectiles ahora atraviesan a múltiples enemigos.",
			4: "Naturaleza volátil. Las hojas explotan al impactar contra su objetivo final.",
			5: "Evolución: Tormenta constante. La cadencia de disparo aumenta drásticamente."
		}
	},
	"mining_cart": {
		"name": "Carro Minero",
		"rarity": "rara",
		"levels": {
			1: "Despliega un carrito minero que viaja recogiendo orbes de experiencia (XP) de forma automática.",
			2: "Ejes engrasados. El carrito se mueve un 20% más rápido por la pantalla.",
			3: "Turbinas de vapor. Aumenta la velocidad del carrito en un 10% adicional y el radio en un 15%.",
			4: "Minero afortunado. Tienes probabilidad de obtener el doble de experiencia al recogerlas.",
			5: "Evolución: Economía autónoma. El carro genera XP pasivamente y atropella enemigos."
		}
	},
	"thorns": {
		"name": "Espinas del Rábano",
		"rarity": "rara",
		"levels": {
			1: "Defensa espinosa. Refleja un porcentaje del daño cuerpo a cuerpo de vuelta al atacante.",
			2: "Piel gruesa. Aumenta significativamente la cantidad de daño que reflejas.",
			3: "Heridas profundas. Los enemigos que atacan la base sufren un efecto de sangrado.",
			4: "Reflejo absoluto. Tu base ahora puede reflejar proyectiles enemigos.",
			5: "Evolución: Venganza explosiva. Posibilidad de lanzar un contraataque explosivo al recibir daño."
		}
	},
	"toxic_aura": {
		"name": "Veneno Radiactivo",
		"rarity": "rara",
		"levels": {
			1: "Emana un aura tóxica que envenena lentamente a los enemigos cercanos a tu base.",
			2: "Veneno letal. Aumenta el daño por segundo que inflige el aura.",
			3: "Contaminación masiva. El radio de efecto del aura tóxica se expande.",
			4: "Gases debilitantes. Los enemigos dentro del aura ven reducido su poder de ataque.",
			5: "Evolución: Zona muerta. El aura se convierte en una nube tóxica enorme y letal."
		}
	},
	"pet_chayanne": {
		"name": "Chayanne Chiquito",
		"rarity": "rara",
		"levels": {
			1: "Invoca a un valiente aliado rábano que perseguirá y golpeará a los enemigos.",
			2: "Entrenamiento de combate. Los golpes de tu aliado causan un 50% más de daño.",
			3: "Impactos contundentes. Sus ataques ahora dañan a todos los enemigos en un área pequeña.",
			4: "Movilidad táctica. Chayanne realiza embestidas rápidas (dashes) para alcanzar objetivos lejanos.",
			5: "Evolución: Modo Berserk. Se vuelve el doble de rápido y ataca sin piedad."
		}
	},
	"black_hole": {
		"name": "Agujero Negro",
		"rarity": "epica",
		"levels": {
			1: "Genera un vórtice gravitacional que atrapa a los enemigos y les causa daño constante.",
			2: "Gravedad aplastante. Duplica el daño que sufren los enemigos atrapados en el centro.",
			3: "Aspiradora cósmica. El vórtice ahora atrae monedas y orbes de XP lejanos.",
			4: "Horizonte de sucesos. El agujero negro absorbe y destruye proyectiles enemigos.",
			5: "Evolución: Colapso estelar. Termina en una explosión masiva que borra la pantalla."
		}
	},
	"aura": {
		"name": "Aura Rabanesca",
		"rarity": "rara",
		"levels": {
			1: "Un pulso de energía que empuja a los enemigos lejos de tu base.",
			2: "Radio expandido. El alcance del pulso de empuje se duplica.",
			3: "Presión crítica. La fuerza del retroceso es significativamente mayor.",
			4: "Onda de choque. El pulso ahora inflige daño al impactar.",
			5: "Evolución: Aura Elemental. El pulso aplica quemadura y veneno a los afectados."
		}
	},
	"turret": {
		"name": "Hojas Metralleta",
		"rarity": "epica",
		"levels": {
			1: "Instala una torreta defensiva que dispara ráfagas de 3 hojas al enemigo más cercano.",
			2: "Calibre pesado. El daño de cada proyectil aumenta considerablemente.",
			3: "Cargador ampliado. La torreta ahora dispara ráfagas continuas de 5 hojas.",
			4: "Balas de punta hueca. Los proyectiles de la torreta atraviesan a múltiples objetivos.",
			5: "Evolución: Modo Gatling. La cadencia de disparo se vuelve increíblemente rápida."
		}
	},
	"pet_minigun": {
		"name": "Chalan con Minigun",
		"rarity": "epica",
		"levels": {
			1: "Un rábano armado con armamento pesado se une a ti, disparando a distancia.",
			2: "Munición explosiva. Aumenta el daño base de todas sus balas.",
			3: "Gatillo fácil. La velocidad de disparo de su ametralladora se incrementa.",
			4: "Fuego cruzado. Sus disparos ahora pueden atravesar las defensas enemigas.",
			5: "Evolución: Modo Rambo. Entra en un frenesí temporal disparando a una cadencia absurda."
		}
	},
	"tornado": {
		"name": "Mini Tornado",
		"rarity": "epica",
		"levels": {
			1: "Invoca un tornado errático que recorre el mapa causando daño a lo que toque.",
			2: "Vientos huracanados. El daño base infligido por el tornado aumenta un 50%.",
			3: "Ciclón persistente. El tornado dura mucho más tiempo antes de disiparse.",
			4: "Corrientes rápidas. La velocidad a la que se mueve por el mapa aumenta.",
			5: "Evolución: Desastre natural. Ahora se invocan dos tornados simultáneos."
		}
	},
	"axe_thrower": {
		"name": "Leñador Furioso",
		"rarity": "epica",
		"levels": {
			1: "Desde las sombras, un aliado lanza hachas mortales a enemigos aleatorios.",
			2: "Hachas pesadas. El daño de impacto de cada hacha se duplica.",
			3: "Doble filo. Ahora lanza dos hachas simultáneamente en cada ataque.",
			4: "Técnica de rebote. Las hachas atraviesan a los enemigos dañando a los que estén detrás.",
			5: "Evolución: Tormenta de hachas. Lanza una ráfaga masiva de hachas que arrasan la zona."
		}
	},
	"satellite": {
		"name": "Satélite Agrícola",
		"rarity": "epica",
		"levels": {
			1: "Un satélite en órbita asiste disparando precisos láseres rojos a los enemigos.",
			2: "Láseres concentrados. El rayo se vuelve más grueso y causa el doble de daño.",
			3: "Mira dual. El satélite adquiere la capacidad de disparar a dos objetivos a la vez.",
			4: "Sobrecarga de sistemas. El tiempo de recarga entre ataques láser se reduce a la mitad.",
			5: "Evolución: Juicio orbital. Dispara un pilar de luz gigante que incinera un área masiva."
		}
	},
	"tamed_alien": {
		"name": "Alien Domesticado",
		"rarity": "epica",
		"levels": {
			1: "Un alienígena rebelde lucha a tu lado, atacando cuerpo a cuerpo a los suyos.",
			2: "Fuerza alienígena. Sus golpes cuerpo a cuerpo son mucho más letales.",
			3: "Agilidad extraterrestre. Se desplaza a mayor velocidad por el campo de batalla.",
			4: "Adaptación bélica. Gana la habilidad de escupir peligrosos proyectiles de ácido.",
			5: "Evolución: Líder de manada. Invoca pequeñas copias aliadas para asistirlo en combate."
		}
	},
	"scarecrow": {
		"name": "Papa Espantapájaros",
		"rarity": "epica",
		"levels": {
			1: "Planta un señuelo que provoca a los enemigos, obligándolos a atacarlo en vez de a ti.",
			2: "Relleno resistente. La vida base del espantapájaros se duplica.",
			3: "Venganza pasiva. Refleja la mitad del daño que recibe de los atacantes cuerpo a cuerpo.",
			4: "Trampa explosiva. Detona violentamente cuando su salud llega a cero.",
			5: "Evolución: Provocación global. Atrae a todos en pantalla y es temporalmente invulnerable."
		}
	},
	"cosmic_magnet": {
		"name": "Imán Cósmico",
		"rarity": "rara",
		"levels": {
			1: "Atrae monedas de forma pasiva en un radio corto alrededor del rábano.",
			2: "Fuerza de atracción aumentada. Incrementa un 20% el radio del imán.",
			3: "Aspiradora de botín. El imán ahora también puede atraer orbes de experiencia (XP).",
			4: "Magneto afortunado. El imán adquiere la capacidad de atraer cofres de recompensa.",
			5: "Evolución: Magnetismo absoluto. Atrae instantáneamente todo el botín en pantalla cada 15 segundos."
		}
	},
	"boomerang": {
		"name": "Búmeran",
		"rarity": "rara",
		"levels": {
			1: "Lanza un búmeran a un enemigo aleatorio que causa daño y regresa a la base.",
			2: "Filo afilado. Aumenta el daño de impacto del búmeran.",
			3: "Vuelo de larga distancia. Incrementa el alcance máximo de vuelo.",
			4: "Corte doble. Ahora lanza dos búmeranes simultáneamente en cada ataque.",
			5: "Evolución: Tormenta eléctrica. Aplica daño eléctrico y paraliza brevemente al golpear."
		}
	}
}

# Datos de Mejoras Permanentes (Galería - Mis Cartas - 4 Niveles)
var meta_upgrades_data = {
	"fire_slice": {
		1: "+Daño Base.", # Nivel 1 siempre es el base que ya tiene
		2: "+10% duración de quemaduras.",
		3: "Los enemigos incendiados son más visibles.",
		"4_fav": "Favorita: +15% prob. de aparecer.",
		"4_spec": "Pirómano: Brasas duran 1s más."
	},
	"explosive_slice": {
		1: "+Daño Base.",
		2: "+10% radio de explosión.",
		3: "Explosiones generan más partículas visuales.",
		"4_fav": "Favorita: +15% aparición.",
		"4_spec": "Demolicionista: Las explosiones empujan."
	},
	"fire_wall": {
		1: "+Daño Base.",
		2: "+15% duración del muro.",
		3: "Muros más anchos.",
		"4_fav": "Favorita.",
		"4_spec": "Arquitecto del Caos: Bloquean enemigos."
	},
	"lightning_slice": {
		1: "+Daño Base.",
		2: "Buscan desde más lejos.",
		3: "Velocidad de rebote +20%.",
		"4_fav": "Favorita.",
		"4_spec": "Conductor Perfecto: Prioriza especiales."
	},
	"shield": {
		1: "+Daño Base.",
		2: "Radio orbital +10%.",
		3: "Giran más rápido.",
		"4_fav": "Favorita.",
		"4_spec": "Guardián Verde: Interceptan proyectiles."
	},
	"seed_nova": {
		1: "+Daño Base.",
		2: "Radio de búsqueda +10%.",
		3: "Mejor seguimiento.",
		"4_fav": "Favorita.",
		"4_spec": "Jardinero Supremo: Ralentizan un 5%."
	},
	"mining_cart": {
		1: "Mejora Base.",
		2: "+15% velocidad.",
		3: "+15% radio de recolección.",
		"4_fav": "Favorita.",
		"4_spec": "Carro Agrícola: Prob. de diamantes (XP x10)."
	},
	"thorns": {
		1: "+Daño Base.",
		2: "Mayor rango de activación.",
		3: "Activa reflejo más rápido.",
		"4_fav": "Favorita.",
		"4_spec": "Dolor Compartido: Mini retroceso."
	},
	"toxic_aura": {
		1: "+Daño Base.",
		2: "+10% área de la nube.",
		3: "Duración de venenos +10%.",
		"4_fav": "Favorita.",
		"4_spec": "Bioquímico: Más ralentización."
	},
	"pet_chayanne": {
		1: "+Daño Base.",
		2: "+10% velocidad de movimiento.",
		3: "Detecta enemigos más lejos.",
		"4_fav": "Favorita.",
		"4_spec": "Manager Profesional: Prioriza jefes."
	},
	"black_hole": {
		1: "+Daño Base.",
		2: "+10% radio de atracción.",
		3: "+15% duración.",
		"4_fav": "Favorita.",
		"4_spec": "Recolector Cósmico: Atrae XP y monedas."
	},
	"aura": {
		1: "Mejora Base.",
		2: "+10% alcance.",
		3: "Cooldown ligeramente menor.",
		"4_fav": "Favorita.",
		"4_spec": "Presencia Imperial: Afecta a jefes."
	},
	"turret": {
		1: "+Daño Base.",
		2: "Mayor alcance.",
		3: "Apunta más rápido.",
		"4_fav": "Favorita.",
		"4_spec": "Munición Inteligente: Prioriza poca vida."
	},
	"pet_minigun": {
		1: "+Daño Base.",
		2: "Mayor rango.",
		3: "Cambio de objetivo más rápido.",
		"4_fav": "Favorita.",
		"4_spec": "Cazador de Jefes: Prioriza jefes."
	},
	"tornado": {
		1: "+Daño Base.",
		2: "+10% tamaño.",
		3: "+10% velocidad.",
		"4_fav": "Favorita.",
		"4_spec": "Aspiradora Natural: Recoge monedas."
	},
	"axe_thrower": {
		1: "+Daño Base.",
		2: "Mayor alcance de lanzamiento.",
		3: "Mejor puntería.",
		"4_fav": "Favorita.",
		"4_spec": "Experto Forestal: Prioriza grupos."
	},
	"satellite": {
		1: "+Daño Base.",
		2: "Mayor velocidad de giro.",
		3: "Mayor rango de detección.",
		"4_fav": "Favorita.",
		"4_spec": "Objetivo Fijado: No cambia objetivo."
	},
	"tamed_alien": {
		1: "+Daño Base.",
		2: "Más velocidad.",
		3: "Mayor rango de detección.",
		"4_fav": "Favorita.",
		"4_spec": "Instinto Asesino: Prioriza especiales."
	},
	"scarecrow": {
		1: "+Vida Base.",
		2: "+20% vida base.",
		3: "+20% duración.",
		"4_fav": "Favorita.",
		"4_spec": "Señuelo Perfecto: Genera más amenaza."
	},
	"cosmic_magnet": {
		1: "+Daño Base.",
		2: "+10% radio de atracción.",
		3: "Velocidad de atracción +15%.",
		"4_fav": "Favorita.",
		"4_spec": "Atracción Gravitacional: Atrae proyectiles."
	},
	"boomerang": {
		1: "+Daño Base.",
		2: "+10% velocidad de retorno.",
		3: "+15% rango de búsqueda.",
		"4_fav": "Favorita.",
		"4_spec": "Conducción Metálica: Inflige daño crítico."
	},
	"heal": {
		1: "Cura 5 HP cada 100 de combo.",
		2: "Cura 7 HP cada 100 de combo.",
		3: "Cura 9 HP cada 100 de combo.",
		"4_fav": "Favorita: +15% prob. de aparecer.",
		"4_spec": "Savia Regenerativa: Cura 12 HP cada 100 de combo."
	},
	"damage_boost": {
		1: "Sangrado inflige daño base.",
		2: "+20% daño por sangrado.",
		3: "+40% daño por sangrado.",
		"4_fav": "Favorita: +15% prob. de aparecer.",
		"4_spec": "Cortes Quirúrgicos: Sangrado dura 2s más."
	},
	"crit_boost": {
		1: "+1% crítico por enemigo (Máx +40%).",
		2: "+1.2% crítico por enemigo (Máx +45%).",
		3: "+1.4% crítico por enemigo (Máx +50%).",
		"4_fav": "Favorita: +15% prob. de aparecer.",
		"4_spec": "Ojo de Halcón: Crítico multiplica x3."
	},
	"auto_speed": {
		1: "Micro-explosiones en radio de 100px.",
		2: "+20% radio de explosión.",
		3: "+40% radio de explosión.",
		"4_fav": "Favorita: +15% prob. de aparecer.",
		"4_spec": "Explosiones en Cadena: Radio +60% y 1.5x daño."
	}
}


# Otros boosts que no son habilidades de 5 niveles
var flat_upgrades = {
	"heal": {"name": "Raíces Profundas", "desc": "Tu Rábano absorbe nutrientes del combate. Por cada 100 de tu Combo, recuperas 5 HP.", "rarity": "comun"},
	"damage_boost": {"name": "Filo Sangrón", "desc": "Tus cortes desgarran a los enemigos. Aplica Sangrado durante 3s (el daño se duplica si se mueven).", "rarity": "comun"},
	"crit_boost": {"name": "Frenesí de Cosecha", "desc": "Ganas +1% de prob. de Crítico por cada enemigo actualmente en pantalla (Máximo +40%).", "rarity": "comun"},
	"auto_speed": {"name": "Corte Fantasmal", "desc": "Ataques de tu auto-clicker generan micro-explosiones que dañan en un área pequeña.", "rarity": "rara"},
	"mirror_slice": {"name": "Corte Espejo", "desc": "Crea un tajo fantasma opuesto.", "rarity": "comun"},
	"double_slice": {"name": "Tajo Doble", "desc": "Crea un corte paralelo extra.", "rarity": "comun"},
	"wind_gust": {"name": "Ráfaga de Viento", "desc": "Lanza proyectiles de aire al cortar.", "rarity": "comun"},
	"toxic_compost": {"name": "Abono Tóxico", "desc": "Los enemigos sueltan ácido al morir.", "rarity": "comun"},
	"energy_shield": {"name": "Escudo de Energía", "desc": "Anillo que absorbe impactos directos.", "rarity": "rara"},
	"sword_craft": {"name": "Espada de Craft", "desc": "Espada pixelada que ataca sola.", "rarity": "rara"},
	"frost_avalanche": {"name": "Avalancha de Nieve", "desc": "Congela a los enemigos en pantalla.", "rarity": "rara"},
	"earthquake": {"name": "Terremoto", "desc": "Onda masiva tras combo.", "rarity": "epica"},
	"infernal_hole": {"name": "Agujero Infernal", "desc": "Sinergia [Agujero Negro + Corte Hot]: El agujero negro se vuelve de fuego, succiona más fuerte, quema enemigos y detona al final.", "rarity": "legendaria"},
	"orbital_satellite": {"name": "Satélite Orbital", "desc": "Sinergia [Satélite Agrícola + Hojas Metralleta]: El satélite se convierte en torreta orbital y dispara ráfagas de semillas.", "rarity": "legendaria"},
	"radioactive_swamp": {"name": "Pantano Radioactivo", "desc": "Sinergia [Veneno Radiactivo + Abono Tóxico]: El veneno dura más y se propaga automáticamente entre enemigos cercanos.", "rarity": "legendaria"},
	"field_squad": {"name": "Escuadrón del Campo", "desc": "Sinergia [Chayanne Chiquito + Chalan con Minigun + Alien Domesticado]: Tus mascotas reciben +50% velocidad y daño, y crecen.", "rarity": "legendaria"},
	"living_fortress": {"name": "Fortaleza Viviente", "desc": "Sinergia [Papa Espantapájaros + Escudo de Hojas]: Las hojas del escudo comienzan a orbitar y proteger también a la Papa Espantapájaros.", "rarity": "legendaria"},
	"ajo_negativo": {"name": "Ajo Negativo", "desc": "Sinergia [Corte Hot + Tajo Relámpago]: Tus rayos dejan brasas de fuego eléctrico en el suelo, y los enemigos electrificados explotan al morir.", "rarity": "legendaria"},
	"los_compadres": {"name": "Los Compadres", "desc": "Sinergia [Chayanne Chiquito + Chalan con Minigun]: Chayanne y Chalán luchan en equipo, dándose un +80% de velocidad cuando el otro ataca.", "rarity": "legendaria"},
	"war_garden": {"name": "Jardín de Guerra", "desc": "Sinergia [Aura de Hojas + Hojas Metralleta]: Las semillas de la nova orbitan alrededor del rábano y disparan sub-proyectiles teledirigidos.", "rarity": "legendaria"},
	"infected_potato": {"name": "Papa Infectada", "desc": "Sinergia [Papa Espantapájaros + Veneno Radiactivo]: La Papa Espantapájaros emite una nube de veneno radioactivo permanente a su alrededor.", "rarity": "legendaria"},
	"excalibur_vegetal": {"name": "Excalibur Vegetal", "desc": "Sinergia [Espada de Craft + Satélite Agrícola]: La espada se convierte en Excalibur, cae como un meteoro sobre el enemigo más fuerte.", "rarity": "legendaria"},
	"deforesador": {"name": "Deforesador Supremo", "desc": "Sinergia [Leñador Furioso + Búmeran]: Las hachas se convierten en búmeranes gigantes devastadores que trituran todo a su paso.", "rarity": "legendaria"},
	
	# Cartas de Cofre (Temporales/Especiales)
	"sayonara": {"name": "Disco Sayonara", "desc": "Limpia la pantalla deteniendo el tiempo al instante.", "rarity": "epica"},
	"steroids": {"name": "Abono Mágico", "desc": "Tu rábano se vuelve gigante, inflige triple daño y gana doble XP.", "rarity": "epica"},
	"conqueror_aura": {"name": "Aura Conquistador", "desc": "Un pulso defensivo constante alrededor de tu base cada 8 segundos.", "rarity": "epica"},
	"campesino_extremo": {"name": "Campesino Extremo", "desc": "El Carro Minero aparece gratis, recogiendo todo y duplicando XP.", "rarity": "epica"},
	"reactor_nuclear": {"name": "Reactor Nuclear", "desc": "Desata explosiones nucleares masivas cada 8 segundos.", "rarity": "epica"},
	"sobrecarga_cuantica": {"name": "Sobrecarga Cuántica", "desc": "Los cooldowns de auras, torretas y mascotas son 3 veces más rápidos.", "rarity": "epica"},
	"lluvia_rabanos": {"name": "Lluvia de Rábanos", "desc": "Rábanos gigantes caen del cielo aplastando enemigos.", "rarity": "epica"},
	"senal_pirata": {"name": "Señal Pirata", "desc": "Una nave orbital hackeada dispara láseres a los invasores.", "rarity": "epica"},
	"sindicato_alien": {"name": "Sindicato Alienígena", "desc": "La mitad de los aliens se niegan a trabajar (caminan muy lento).", "rarity": "epica"}
}

func get_skill_level(id: String) -> int:
	return skill_levels.get(id, 0)

func get_card_upgrade_int_level(id: String) -> int:
	var val = card_upgrade_levels.get(id, 0)
	if typeof(val) == TYPE_STRING:
		return 4
	return int(val)

func get_next_upgrade_desc(id: String) -> String:
	var current_lvl = get_skill_level(id)
	if skills_data.has(id):
		if current_lvl >= 5: return "Nivel Máximo Alcanzado"
		var next_lvl = current_lvl + 1
		return skills_data[id]["levels"].get(next_lvl, "Nivel Máximo Alcanzado")
	elif flat_upgrades.has(id):
		return flat_upgrades[id]["desc"]
	return ""

# Niveles de mejora de cartas (Meta-Tienda Permanente)
var card_upgrade_levels = {
	"fire_slice": 0, "lightning_slice": 0, "shield": 0, "explosive_slice": 0,
	"black_hole": 0, "fire_wall": 0, "turret": 0, "seed_nova": 0, "aura": 0,
	"mining_cart": 0, "pet_chayanne": 0, "pet_minigun": 0, "thorns": 0,
	"toxic_aura": 0, "cosmic_magnet": 0, "tornado": 0, "axe_thrower": 0,
	"satellite": 0, "scarecrow": 0, "boomerang": 0, "tamed_alien": 0,
	
	# Mejoras Planas
	"heal": 0, "damage_boost": 0, "crit_boost": 0, "auto_speed": 0,
	"mirror_slice": 0, "double_slice": 0, "wind_gust": 0, "toxic_compost": 0,
	"energy_shield": 0, "sword_craft": 0, "frost_avalanche": 0, "earthquake": 0,
	
	# Sinergias
	"infernal_hole": 0, "orbital_satellite": 0, "radioactive_swamp": 0, "field_squad": 0,
	"living_fortress": 0, "ajo_negativo": 0, "los_compadres": 0, "war_garden": 0, "infected_potato": 0,
	"excalibur_vegetal": 0, "deforesador": 0,
	
	# Cartas de Cofre
	"sayonara": 0, "steroids": 0, "conqueror_aura": 0, "campesino_extremo": 0,
	"reactor_nuclear": 0, "sobrecarga_cuantica": 0, "lluvia_rabanos": 0, "senal_pirata": 0, "sindicato_alien": 0
}

var unlocked_skills = []
var equipped_deck = []

var meta_base_damage: int = 1
var meta_base_health: int = 100
var meta_crit_chance: float = 0.0

var cost_meta_damage: int = 50
var cost_meta_health: int = 50
var cost_meta_crit: int = 100


# --- PERSISTENCIA ---
const SAVE_PATH = "user://savegame.cfg"

# Descripciones del Bestiario
var alien_data = {
	0: {"name": "Alien Normal", "desc": "Un invasor estándar."},
	1: {"name": "Alien Tanque", "desc": "Lento pero resistente."},
	2: {"name": "Alien Rapido", "desc": "Gran velocidad."},
	3: {"name": "Alien Kamikaze", "desc": "Explota al contacto."},
	4: {"name": "Alien Troya", "desc": "Libera horda al morir."},
	5: {"name": "Alien Curador", "desc": "Sana a otros aliens."},
	6: {"name": "Alien Sniper", "desc": "Dispara desde lejos."},
	7: {"name": "Alien Minero", "desc": "Viaja bajo tierra."},
	8: {"name": "Alien Boss", "desc": "Comandante de la invasión."}
}
var bestiary = {0:0, 1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0, 8:0}
var bestiary_milestones = {0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 1}


# --- SISTEMA DE EXPERIENCIA ---
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 10
var pending_level_ups: int = 0

# --- SISTEMA DE OLEADAS ---
var current_wave: int = 1
var enemies_spawned_this_wave: int = 0
var enemies_killed_in_wave: int = 0
var chests_spawned_this_wave: int = 0
var is_boss_wave: bool = false

# --- ESTADÍSTICAS DE COMBATE ---
var click_damage: int = 1
var auto_damage: int = 0
var crit_chance: float = 0.0 
var crit_multiplier: float = 2.0
var prestige_multiplier: float = 1.0
var auto_timer: Timer

# --- HABILIDADES ROGUELITE (Bools para flags rápidos) ---
var has_earthquake: bool = false
var has_infernal_hole: bool = false
var has_orbital_satellite: bool = false
var has_radioactive_swamp: bool = false
var has_field_squad: bool = false
var has_living_fortress: bool = false
var has_ajo_negativo: bool = false
var has_los_compadres: bool = false
var has_war_garden: bool = false
var has_infected_potato: bool = false
var has_excalibur_vegetal: bool = false
var has_deforesador: bool = false
var has_fire_slice: bool = false
var has_mirror_slice: bool = false
var has_explosive_slice: bool = false
var has_toxic_compost: bool = false
var has_double_slice: bool = false
var has_lightning_slice: bool = false
var has_wind_gust: bool = false
var wind_gust_count: int = 0
var has_black_hole: bool = false
var has_fire_wall: bool = false
var has_knockback_aura: bool = false
var has_sword_craft: bool = false
var has_mining_cart: bool = false
var has_energy_shield: bool = false # Renombrado de shield_energy_hits logic

var shield_energy_hits: int = 0
var pet_chayanne_level: int = 0
var is_steroid_mode: bool = false
var steroid_multiplier: float = 1.0
var seed_nova_count: int = 0
var turret_level: int = 0
var shield_level: int = 0
var shield_damage: int = 2

# --- DURACIÓN DE RECOMPENSAS (COFRES) ---
var sayonara_uses: int = 0
var steroids_rounds: int = 0
var conqueror_aura_rounds: int = 0
var campesino_extremo_rounds: int = 0
var reactor_nuclear_rounds: int = 0
var sobrecarga_cuantica_rounds: int = 0
var lluvia_rabanos_rounds: int = 0
var senal_pirata_rounds: int = 0
var sindicato_alien_rounds: int = 0

# --- SISTEMA DE COMBO ---
var current_combo: int = 0
var combo_timer: Timer

func _ready() -> void:
	load_game()
	auto_timer = Timer.new()
	auto_timer.wait_time = 1.0
	auto_timer.timeout.connect(_on_auto_timer_timeout)
	add_child(auto_timer)
	auto_timer.start()
	
	combo_timer = Timer.new()
	combo_timer.wait_time = 2.0 
	combo_timer.one_shot = true
	combo_timer.timeout.connect(_on_combo_timeout)
	add_child(combo_timer)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func add_combo() -> void:
	current_combo += 1
	combo_updated.emit(current_combo)
	combo_timer.start()
	if current_combo > best_combo:
		best_combo = current_combo
		save_game()
	if get_skill_level("heal") > 0 and current_combo > 0 and current_combo % 100 == 0:
		var base = null
		for node in get_tree().get_nodes_in_group("BaseRabanito"):
			if node.name == "BaseRabanito":
				base = node
				break
		if base:
			var heal_lvl = get_skill_level("heal")
			var meta_lvl = get_card_upgrade_int_level("heal")
			var heal_meta = card_upgrade_levels.get("heal", 0)
			var is_spec = (typeof(heal_meta) == TYPE_STRING and heal_meta == "4_spec")
			
			var base_heal = 12 if is_spec else (5 + meta_lvl * 2)
			var total_heal = base_heal * heal_lvl
			
			base.current_health = min(base.current_health + total_heal, base.max_health)
			if "health_bar" in base: base.health_bar.value = base.current_health
	if has_earthquake and current_combo > 0:
		var req = 150
		if current_combo % req == 0: trigger_earthquake()

func trigger_earthquake() -> void:
	var lvl_val = get_skill_level("earthquake")
	var lvl = 4 if typeof(lvl_val) == TYPE_STRING else lvl_val
	
	var base_damage = 30
	var radius = 400.0 # Valor base
	
	if lvl >= 2: base_damage = int(base_damage * 1.2) # Nivel 2: +20% daño
	if lvl >= 3: radius *= 1.15 # Nivel 3: +15% radio
	
	var scene = get_tree().current_scene
	if scene.has_method("shake_camera"): scene.shake_camera(0.8, 25)
	
	var base = get_tree().get_first_node_in_group("BaseRabanito")
	var origin_pos = base.global_position if base else Vector2.ZERO
	
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and origin_pos.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.take_damage(base_damage)
				
				var apply_stun = false
				if typeof(lvl_val) == TYPE_STRING and lvl_val == "4_spec":
					apply_stun = true # Sismo Eterno
				elif randf() < 0.2: # Probabilidad base de aturdir
					apply_stun = true
					
				if apply_stun and e.has_method("apply_frost"):
					e.apply_frost()

func _on_combo_timeout() -> void:
	current_combo = 0
	combo_updated.emit(current_combo)

func save_game() -> void:
	var config = ConfigFile.new()
	config.set_value("Progreso", "total_gold", total_gold)
	config.set_value("Progreso", "best_wave", best_wave)
	config.set_value("Progreso", "best_combo", best_combo)
	config.set_value("Progreso", "total_enemies_defeated", total_enemies_defeated)
	config.set_value("Progreso", "is_beta_tester", is_beta_tester)
	config.set_value("Progreso", "bestiary", bestiary)
	config.set_value("Progreso", "bestiary_milestones", bestiary_milestones)
	config.set_value("Progreso", "card_upgrades", card_upgrade_levels)
	config.set_value("Progreso", "unlocked_skills", unlocked_skills)
	config.set_value("Progreso", "mastery_total", mastery_total_count)
	config.set_value("Progreso", "tutorial_completed", tutorial_completed)
	config.set_value("Progreso", "last_login_day_num", last_login_day_num)
	config.set_value("Progreso", "consecutive_logins", consecutive_logins)
	config.set_value("Perfil", "profile_stats", profile_stats)
	config.set_value("Tienda", "meta_base_damage", meta_base_damage)
	config.set_value("Tienda", "meta_base_health", meta_base_health)
	config.set_value("Tienda", "meta_crit_chance", meta_crit_chance)
	config.set_value("Tienda", "cost_meta_damage", cost_meta_damage)
	config.set_value("Tienda", "cost_meta_health", cost_meta_health)
	config.set_value("Tienda", "cost_meta_crit", cost_meta_crit)
	config.set_value("Mazo", "deck_level", deck_level)
	config.set_value("Mazo", "deck_unlocked_slots", deck_unlocked_slots)
	config.set_value("Mazo", "deck_equipped_cards", deck_equipped_cards)
	config.set_value("Mazo", "veteran_badges", veteran_badges)
	config.set_value("Ajustes", "music_volume", music_volume)
	config.set_value("Ajustes", "sfx_volume", sfx_volume)
	config.set_value("Ajustes", "damage_numbers_enabled", damage_numbers_enabled)
	config.set_value("Ajustes", "shaders_enabled", shaders_enabled)
	config.set_value("Ajustes", "screen_shake_enabled", screen_shake_enabled)
	config.set_value("Ajustes", "language", language)
	config.save(SAVE_PATH)

func load_game() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		total_gold = config.get_value("Progreso", "total_gold", 0)
		best_wave = config.get_value("Progreso", "best_wave", 1)
		best_combo = config.get_value("Progreso", "best_combo", 0)
		total_enemies_defeated = 0
		is_beta_tester = config.get_value("Progreso", "is_beta_tester", true)
		mastery_total_count = config.get_value("Progreso", "mastery_total", 0)
		
		# --- FUSIÓN SEGURA DEL BESTIARIO ---
		var saved_bestiary = config.get_value("Progreso", "bestiary", {})
		if typeof(saved_bestiary) == TYPE_DICTIONARY:
			for k in saved_bestiary.keys(): 
				# Convertir llaves a int (ConfigFile a veces guarda llaves como string ej: "0": 1)
				var int_k = k.to_int() if typeof(k) == TYPE_STRING else k
				if bestiary.has(int_k): 
					bestiary[int_k] = saved_bestiary[k]
					
		# Recalcular total_enemies_defeated desde el bestiario
		for k in bestiary.keys():
			total_enemies_defeated += bestiary[k]
		
		# --- FUSIÓN SEGURA DE HITOS DEL BESTIARIO ---
		var saved_milestones = config.get_value("Progreso", "bestiary_milestones", {})
		if typeof(saved_milestones) == TYPE_DICTIONARY:
			for k in saved_milestones.keys():
				var int_k = k.to_int() if typeof(k) == TYPE_STRING else k
				if bestiary_milestones.has(int_k):
					bestiary_milestones[int_k] = saved_milestones[k]
		
		# --- FUSIÓN SEGURA DE LA META-TIENDA (El Bug Arreglado) ---
		var saved_upgrades = config.get_value("Progreso", "card_upgrades", {})
		if typeof(saved_upgrades) == TYPE_DICTIONARY:
			for k in saved_upgrades.keys(): 
				if card_upgrade_levels.has(k): 
					# Si la habilidad existe en la nueva versión, le devolvemos su nivel (ya sea int 10 o String "4_spec")
					card_upgrade_levels[k] = saved_upgrades[k]
			
		unlocked_skills = config.get_value("Progreso", "unlocked_skills", [])
		tutorial_completed = config.get_value("Progreso", "tutorial_completed", false)
		last_login_day_num = config.get_value("Progreso", "last_login_day_num", 0)
		consecutive_logins = config.get_value("Progreso", "consecutive_logins", 0)
		var saved_profile = config.get_value("Perfil", "profile_stats", {})
		if typeof(saved_profile) == TYPE_DICTIONARY:
			for k in saved_profile.keys():
				profile_stats[k] = saved_profile[k]
		check_title_unlocks()
		meta_base_damage = config.get_value("Tienda", "meta_base_damage", 1)
		meta_base_health = config.get_value("Tienda", "meta_base_health", 100)
		meta_crit_chance = config.get_value("Tienda", "meta_crit_chance", 0.0)
		cost_meta_damage = config.get_value("Tienda", "cost_meta_damage", 50)
		cost_meta_health = config.get_value("Tienda", "cost_meta_health", 50)
		cost_meta_crit = config.get_value("Tienda", "cost_meta_crit", 100)
		
		deck_level = config.get_value("Mazo", "deck_level", 1)
		deck_unlocked_slots = config.get_value("Mazo", "deck_unlocked_slots", 0)
		deck_equipped_cards = config.get_value("Mazo", "deck_equipped_cards", ["", "", ""])
		veteran_badges = config.get_value("Mazo", "veteran_badges", 0)
		
		music_volume = config.get_value("Ajustes", "music_volume", 0.8)
		sfx_volume = config.get_value("Ajustes", "sfx_volume", 0.8)
		damage_numbers_enabled = config.get_value("Ajustes", "damage_numbers_enabled", true)
		shaders_enabled = config.get_value("Ajustes", "shaders_enabled", true)
		screen_shake_enabled = config.get_value("Ajustes", "screen_shake_enabled", true)
		language = config.get_value("Ajustes", "language", "es")
		
		# Auto-desbloquear slot 1 si record >= 10 y no hay slots desbloqueados
		if best_wave >= 10 and deck_unlocked_slots == 0:
			deck_unlocked_slots = 1

func _on_auto_timer_timeout() -> void:
	if auto_damage > 0:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and "current_health" in e and e.current_health > 0:
				if e.get("is_underground"): continue
				
				var dmg = int(auto_damage * prestige_multiplier * steroid_multiplier)
				e.take_damage(dmg)
				
				if get_skill_level("auto_speed") > 0:
					var target_pos = e.global_position
					var lvl = get_skill_level("auto_speed")
					var meta_lvl = get_card_upgrade_int_level("auto_speed")
					var auto_speed_meta = card_upgrade_levels.get("auto_speed", 0)
					var is_spec = (typeof(auto_speed_meta) == TYPE_STRING and auto_speed_meta == "4_spec")
					
					var radius_mult = 1.0 + (lvl - 1) * 0.1 + meta_lvl * 0.2
					if is_spec: radius_mult += 0.2
					var radius = 100.0 * radius_mult
					var radius_sq = radius * radius
					
					var dmg_mult = 1.5 if is_spec else 1.0
					var final_splash_dmg = int(dmg * dmg_mult)
					
					for other in enemies:
						if other != e and is_instance_valid(other) and "current_health" in other and other.current_health > 0:
							if other.global_position.distance_squared_to(target_pos) < radius_sq:
								other.take_damage(final_splash_dmg)
					var scene = get_tree().current_scene
					if scene.has_method("create_micro_explosion"):
						scene.create_micro_explosion(target_pos)
				break

func add_coins(amount: int) -> void:
	total_coins += amount
	coins_updated.emit(total_coins)

func get_total_enemies_for_current_wave() -> int:
	return 20 + (current_wave * 8)

func gain_xp(amount: int) -> void:
	var mult = 1
	if is_steroid_mode:
		mult *= 2
	if campesino_extremo_rounds > 0:
		mult *= 2
	current_xp += amount * mult
	if current_xp >= xp_to_next_level:
		var over = current_xp - xp_to_next_level
		current_level += 1; pending_level_ups += 1; xp_to_next_level = int(xp_to_next_level * 1.15); current_xp = 0
		xp_updated.emit(0, xp_to_next_level); level_up.emit(current_level)
		if over > 0: gain_xp(over)
	else:
		xp_updated.emit(current_xp, xp_to_next_level)

func notify_enemy_defeated(v: int = -1) -> void:
	enemies_defeated += 1; enemies_killed_in_wave += 1
	total_enemies_defeated += 1
	increment_stat("aliens_killed", 1)
	increment_stat("aliens_in_therapy", randi() % 3 + 1)
	if v != -1 and bestiary.has(v): 
		bestiary[v] += 1
		if v == 8: 
			pending_level_ups += 1; level_up.emit(current_level)
			increment_stat("bosses_killed", 1)
	enemy_defeated.emit(enemies_defeated)
	if enemies_killed_in_wave >= get_total_enemies_for_current_wave():
		current_wave += 1; chests_spawned_this_wave = 0
		if steroids_rounds > 0:
			steroids_rounds -= 1
			if steroids_rounds == 0: deactivate_steroids()
		if campesino_extremo_rounds > 0:
			campesino_extremo_rounds -= 1
			if campesino_extremo_rounds == 0:
				var scene = get_tree().current_scene
				if scene.has_method("force_update_skills"): scene.force_update_skills()
		if reactor_nuclear_rounds > 0:
			reactor_nuclear_rounds -= 1
		if sobrecarga_cuantica_rounds > 0:
			sobrecarga_cuantica_rounds -= 1
			if sobrecarga_cuantica_rounds == 0:
				var scene = get_tree().current_scene
				if scene.has_method("force_update_skills"): scene.force_update_skills()
		if lluvia_rabanos_rounds > 0:
			lluvia_rabanos_rounds -= 1
		if senal_pirata_rounds > 0:
			senal_pirata_rounds -= 1
		if sindicato_alien_rounds > 0:
			sindicato_alien_rounds -= 1
		if current_wave > best_wave: best_wave = current_wave
		save_game() # Guardar siempre al final de cada oleada (stats, total_enemies_defeated, etc)
		if conqueror_aura_rounds > 0:
			conqueror_aura_rounds -= 1
		enemies_killed_in_wave = 0
		enemies_spawned_this_wave = 0 # Reset para que Main.gd vuelva a spawnear
		is_boss_wave = (current_wave % 5 == 0)
		wave_updated.emit(current_wave)

func deactivate_steroids() -> void:
	is_steroid_mode = false; steroid_multiplier = 1.0
	var b = get_tree().get_first_node_in_group("BaseRabanito")
	if b: b.scale = Vector2.ONE; b.modulate = Color.WHITE

func reset_run() -> void:
	get_tree().paused = false
	current_wave = 1; current_level = 1; current_xp = 0; xp_to_next_level = 10; pending_level_ups = 0
	enemies_killed_in_wave = 0; enemies_defeated = 0; current_combo = 0
	enemies_spawned_this_wave = 0 
	chests_spawned_this_wave = 0 
	skill_levels.clear(); mastered_skills.clear()
	sayonara_uses = 0
	steroids_rounds = 0
	conqueror_aura_rounds = 0
	campesino_extremo_rounds = 0
	reactor_nuclear_rounds = 0
	sobrecarga_cuantica_rounds = 0
	lluvia_rabanos_rounds = 0
	senal_pirata_rounds = 0
	sindicato_alien_rounds = 0
	has_earthquake = false; has_infernal_hole = false; has_orbital_satellite = false; has_radioactive_swamp = false; has_field_squad = false; has_living_fortress = false
	has_ajo_negativo = false; has_los_compadres = false; has_war_garden = false; has_infected_potato = false; has_excalibur_vegetal = false; has_deforesador = false; has_fire_slice = false; has_mirror_slice = false; has_explosive_slice = false
	has_toxic_compost = false; has_double_slice = false; has_lightning_slice = false; has_wind_gust = false
	wind_gust_count = 0; shield_damage = 2; active_damage_numbers = 0
	has_black_hole = false; has_fire_wall = false; has_knockback_aura = false; has_mining_cart = false
	has_sword_craft = false; has_energy_shield = false; shield_energy_hits = 0
	pet_chayanne_level = 0; seed_nova_count = 0; turret_level = 0; shield_level = 0
	is_steroid_mode = false; steroid_multiplier = 1.0
	click_damage = meta_base_damage; crit_chance = meta_crit_chance; prestige_multiplier = 1.0; auto_damage = 0
	apply_equipped_deck()
	xp_updated.emit(0, xp_to_next_level); level_up.emit(1); wave_updated.emit(1); combo_updated.emit(0)

func hard_reset() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	total_gold = 0
	best_wave = 1
	best_combo = 0
	total_enemies_defeated = 0
	is_beta_tester = true
	mastery_total_count = 0
	tutorial_completed = false
	last_login_day_num = 0
	consecutive_logins = 0
	profile_stats = {
		"player_name": "Said",
		"equipped_title": "Novato del Huerto",
		"prestige": 0,
		"unlocked_titles": ["Novato del Huerto"],
		"equipped_avatar": "Alien Normal",
		"unlocked_avatars": ["Alien Normal"],
		
		"time_played": 0.0,
		"matches_played": 0,
		"wins": 0,
		"losses": 0,
		"chests_opened": 0,
		
		"aliens_killed": 0,
		"bosses_killed": 0,
		"total_damage": 0,
		"total_crit_damage": 0,
		"finger_cuts": 0,
		"enemies_burned": 0,
		"enemies_electrocuted": 0,
		"enemies_absorbed": 0,
		
		"gold_earned": 0,
		"gold_spent": 0,
		"coins_collected": 0,
		"total_xp_earned": 0,
		"most_expensive_upgrade": 0,
		
		"card_choices": {},
		"sinergias_discovered": [],
		
		"max_crit_damage": 0,
		"max_kills_in_match": 0,
		"max_gold_in_match": 0,
		"max_level_reached": 1,
		"max_cards_level_5": 0,
		
		"radishes_protected": 1,
		"radishes_lost": 0,
		"aliens_in_therapy": 0,
		"screens_shaken": 0,
		"explosions_caused": 0,
		"kilometers_cut": 0.0
	}
	
	meta_base_damage = 1
	meta_base_health = 100
	meta_crit_chance = 0.0
	cost_meta_damage = 50
	cost_meta_health = 50
	cost_meta_crit = 100
	
	deck_level = 1
	deck_unlocked_slots = 0
	deck_equipped_cards = ["", "", ""]
	veteran_badges = 0
	
	unlocked_skills.clear()
	bestiary = {0:0, 1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0, 8:0}
	bestiary_milestones = {0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 1}
	
	for k in card_upgrade_levels.keys():
		card_upgrade_levels[k] = 0
		
	music_volume = 0.8
	sfx_volume = 0.8
	damage_numbers_enabled = true
	shaders_enabled = true
	screen_shake_enabled = true
	language = "es"
	
	save_game()

func unlock_skill(id: String) -> void:
	if not unlocked_skills.has(id): unlocked_skills.append(id); save_game()

func apply_equipped_deck() -> void:
	if deck_level < 2:
		return
	var init_level = 1 if deck_level == 2 else 2
	for id in deck_equipped_cards:
		if id != "":
			unlock_skill(id) # Asegurar registro en unlocked_skills
			_apply_skill_instantly(id, init_level)

func _apply_skill_instantly(id: String, level: int = 1) -> void:
	skill_levels[id] = level
	match id:
		"fire_slice": has_fire_slice = true
		"lightning_slice": has_lightning_slice = true
		"shield": shield_level = level
		"turret": turret_level = level
		"aura": has_knockback_aura = true
		"mining_cart": has_mining_cart = true
		"seed_nova": seed_nova_count = level
		"black_hole": has_black_hole = true
		"explosive_slice": has_explosive_slice = true
		"fire_wall": has_fire_wall = true
		"pet_chayanne": pet_chayanne_level = level
		"pet_minigun": pass
		"tornado": pass
		"scarecrow": pass
		"tamed_alien": pass
		"axe_thrower": pass
		"satellite": pass
		"boomerang": pass
		"thorns": pass
		"toxic_aura": pass
		"cosmic_magnet": pass
		"mirror_slice": has_mirror_slice = true
		"double_slice": has_double_slice = true
		"wind_gust":
			has_wind_gust = true
			wind_gust_count = level
		"toxic_compost": has_toxic_compost = true
		"energy_shield":
			has_energy_shield = true
			shield_energy_hits = 3
		"sword_craft": has_sword_craft = true
		"earthquake": has_earthquake = true
		"infernal_hole": has_infernal_hole = true
		"orbital_satellite": has_orbital_satellite = true
		"radioactive_swamp": has_radioactive_swamp = true
		"field_squad": has_field_squad = true
		"living_fortress": has_living_fortress = true
		"ajo_negativo": has_ajo_negativo = true
		"los_compadres": has_los_compadres = true
		"war_garden": has_war_garden = true
		"infected_potato": has_infected_potato = true
		"excalibur_vegetal": has_excalibur_vegetal = true
		"deforesador": has_deforesador = true
		"sayonara":
			sayonara_uses = level
		"steroids":
			steroids_rounds = 9999
		"conqueror_aura":
			conqueror_aura_rounds = 9999
		"campesino_extremo":
			campesino_extremo_rounds = 9999
		"reactor_nuclear":
			reactor_nuclear_rounds = 9999
		"sobrecarga_cuantica":
			sobrecarga_cuantica_rounds = 9999
		"lluvia_rabanos":
			lluvia_rabanos_rounds = 9999
		"senal_pirata":
			senal_pirata_rounds = 9999
		"sindicato_alien":
			sindicato_alien_rounds = 9999
		"auto_speed":
			auto_damage = level
			auto_timer.wait_time = max(0.2, 1.0 - (level - 1) * 0.1)
		"damage_boost":
			pass
		"crit_boost":
			pass

# --- FUNCIONES DE MAZO INICIAL ---

func get_deck_affinity() -> String:
	if deck_equipped_cards.size() < 3:
		return "Ninguna"
	var cards = deck_equipped_cards
	if cards.has(""):
		return "Ninguna"
	
	var is_tech = true
	var is_pets = true
	var is_elem = true
	for c in cards:
		if not c in ["lightning_slice", "satellite", "turret"]: is_tech = false
		if not c in ["pet_chayanne", "pet_minigun", "tamed_alien"]: is_pets = false
		if not c in ["fire_slice", "fire_wall", "toxic_aura"]: is_elem = false
		
	if is_tech: return "Tecnológica"
	if is_pets: return "Mascotas"
	if is_elem: return "Elemental"
	return "Ninguna"

func upgrade_deck_level() -> bool:
	if deck_level == 1:
		if total_gold >= 10000:
			total_gold -= 10000
			deck_level = 2
			save_game()
			return true
	elif deck_level == 2:
		if total_gold >= 30000:
			total_gold -= 30000
			deck_level = 3
			save_game()
			return true
	return false

func unlock_deck_slot(slot_idx: int) -> bool:
	if slot_idx == 1 and deck_unlocked_slots == 1 and best_wave >= 20:
		if total_gold >= 5000:
			total_gold -= 5000
			deck_unlocked_slots = 2
			save_game()
			return true
	elif slot_idx == 2 and deck_unlocked_slots == 2 and best_wave >= 30:
		if total_gold >= 15000:
			total_gold -= 15000
			deck_unlocked_slots = 3
			save_game()
			return true
	return false

func prestige_deck() -> bool:
	if best_wave >= 50:
		deck_level = 1
		deck_unlocked_slots = 1
		deck_equipped_cards = ["", "", ""]
		veteran_badges += 1
		increment_stat("prestige", 1)
		increment_stat("radishes_protected", 1)
		save_game()
		return true
	return false

func register_mastery(id: String) -> void:
	if not mastered_skills.has(id):
		mastered_skills.append(id)
		mastery_total_count += 1
		save_game()

func _process(delta: float) -> void:
	if profile_stats.has("time_played"):
		profile_stats["time_played"] += delta

func increment_stat(stat_name: String, amount: float = 1.0) -> void:
	if profile_stats.has(stat_name):
		profile_stats[stat_name] += amount
	else:
		profile_stats[stat_name] = amount
	check_title_unlocks()

func check_title_unlocks() -> void:
	if not profile_stats.has("unlocked_titles"):
		profile_stats["unlocked_titles"] = ["Novato del Huerto"]
	
	var ut = profile_stats["unlocked_titles"]
	
	if profile_stats.get("matches_played", 0) >= 1 and not ut.has("Novato del Huerto"):
		ut.append("Novato del Huerto")
		
	if best_wave >= 10 and not ut.has("Defensor"):
		ut.append("Defensor")
		
	if best_wave >= 20 and not ut.has("Jardinero de Guerra"):
		ut.append("Jardinero de Guerra")
		
	if total_enemies_defeated >= 10000 and not ut.has("Exterminador"):
		ut.append("Exterminador")
		
	var boss_kills = bestiary.get(8, 0)
	if boss_kills >= 100 and not ut.has("Cazajefes"):
		ut.append("Cazajefes")
		
	if best_wave >= 50 and not ut.has("El Elegido del Rábano"):
		ut.append("El Elegido del Rábano")
		
	var prestige_val = profile_stats.get("prestige", 0)
	if prestige_val >= 1 and not ut.has("El Dorado"):
		ut.append("El Dorado")
		
	if total_enemies_defeated >= 50000 and not ut.has("Devorador de Invasores"):
		ut.append("Devorador de Invasores")
		
	profile_stats["unlocked_titles"] = ut
	
	if not profile_stats.has("unlocked_avatars"):
		profile_stats["unlocked_avatars"] = ["Alien Normal"]
	var ua = profile_stats["unlocked_avatars"]
	
	if not ua.has("Alien Normal"): ua.append("Alien Normal")
	
	if bestiary.get(1, 0) >= 50 and not ua.has("Alien Curador"): ua.append("Alien Curador")
	
	if bestiary.get(2, 0) >= 50 and not ua.has("Alien Kamikaze"): ua.append("Alien Kamikaze")
	
	if best_wave >= 15 and not ua.has("Devorarábanos"): ua.append("Devorarábanos")
	
	if mastery_total_count >= 3 and not ua.has("Chayanne"): ua.append("Chayanne")
	
	if profile_stats.get("gold_spent", 0) >= 5000 and not ua.has("Papa Espantapájaros"): ua.append("Papa Espantapájaros")
	
	if best_wave >= 30 and not ua.has("Rábano Dorado"): ua.append("Rábano Dorado")
	
	if best_wave >= 50 and not ua.has("Rábano Cosmic"): ua.append("Rábano Cósmico")
	
	profile_stats["unlocked_avatars"] = ua
