shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
	float alpha = texture(TEXTURE, UV).a;
	
	float outline = 0.0;
	outline += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	outline = min(outline, 1.0) - alpha;
	
	vec4 color = texture(TEXTURE, UV);
	COLOR = mix(color, outline_color, outline);
}
