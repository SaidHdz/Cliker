shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 0.8); // Blanco semi-transparente
uniform float width : hint_range(0.0, 10.0) = 2.0; // Grosor de la línea

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * width;
	float alpha = 0.0;
	
	// Buscamos si hay píxeles alrededor
	alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
	
	vec4 orig_color = texture(TEXTURE, UV);
	
	// EL TRUCO: Si el píxel original es transparente, pero hay color alrededor, dibujamos la línea.
	// Si el píxel original tiene color (es el centro del rábano), lo hacemos 100% INVISIBLE.
	if (orig_color.a < 0.1 && alpha > 0.0) {
		COLOR = outline_color;
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}