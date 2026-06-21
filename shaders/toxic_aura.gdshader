shader_type canvas_item;

// Variables que puedes modificar desde el Inspector de Godot
uniform vec4 base_color : source_color = vec4(0.1, 0.8, 0.2, 1.0); // Verde tóxico oscuro
uniform vec4 edge_color : source_color = vec4(0.6, 1.0, 0.3, 1.0); // Verde neón brillante para el borde
uniform float speed = 3.0; // Velocidad de la ondulación
uniform float radius = 0.45; // Tamaño máximo del aura
uniform float edge_thickness = 0.15; // Grosor del anillo

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	vec2 uv = UV - center;
	float dist = length(uv);

	// 1. Calculamos el ángulo para hacer que el gas "rote"
	float angle = atan(uv.y, uv.x);

	// 2. Deformación orgánica (hace que el círculo sea ondulado, como gas o ácido)
	float distortion = sin(angle * 6.0 + TIME * speed) * 0.02;
	float distorted_dist = dist + distortion;

	// 3. Centro Hueco (Para no tapar al Rabanito)
	float inner_fade = smoothstep(0.1, radius - edge_thickness, distorted_dist);

	// 4. Borde exterior (Define dónde termina el daño)
	float outer_fade = smoothstep(radius, radius - edge_thickness, distorted_dist);

	// 5. Anillo principal de gas
	float ring = inner_fade * outer_fade;

	// 6. Resalte del borde exterior (Brillo para marcar la Hitbox)
	float edge_highlight = smoothstep(radius - edge_thickness * 0.5, radius, distorted_dist) * outer_fade;

	// 7. Pulso de opacidad (Late como si estuviera vivo)
	float pulse = (sin(TIME * speed * 0.5) * 0.2) + 0.8;

	// Mezclamos los colores: Verde oscuro adentro, Verde neón en el borde
	vec4 final_color = mix(base_color, edge_color, edge_highlight);
	
	// Calculamos la transparencia final
	final_color.a = (ring * 0.4 + edge_highlight * 0.7) * pulse;

	// Evitamos que se dibuje fuera del cuadrado del Sprite
	if (dist > 0.5) {
		final_color.a = 0.0;
	}

	COLOR = final_color;
}