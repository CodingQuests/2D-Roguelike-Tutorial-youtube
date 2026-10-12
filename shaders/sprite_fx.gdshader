shader_type canvas_item;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4  flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float outline_width : hint_range(0.0, 6.0) = 0.0;
uniform vec4  outline_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
// Pulses the outline alpha. 0 = steady.
uniform float outline_pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	if (outline_width > 0.0) {
		vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
		float a = 0.0;
		a = max(a, texture(TEXTURE, UV + vec2( px.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0,  px.y)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
		a = max(a, texture(TEXTURE, UV + px * 0.7071).a);
		a = max(a, texture(TEXTURE, UV - px * 0.7071).a);
		a = max(a, texture(TEXTURE, UV + vec2( px.x, -px.y) * 0.7071).a);
		a = max(a, texture(TEXTURE, UV + vec2(-px.x,  px.y) * 0.7071).a);
		float pulse = 1.0 - outline_pulse * 0.45 * (0.5 + 0.5 * sin(TIME * 7.0));
		col = mix(col, vec4(outline_color.rgb, outline_color.a * pulse),
			clamp(a - col.a, 0.0, 1.0));
	}
	
	col.rgb = mix(col.rgb, flash_color.rgb, flash_amount);
	COLOR = col;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
