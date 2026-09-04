// One shader for every per-sprite effect, so a sprite only ever needs a single
// ShaderMaterial. Three independent layers, all off at their default values:
//
//   flash_amount   -> blend toward flash_color (hit feedback)
//   outline_width  -> coloured rim outside the silhouette (telegraph, elite,
//                     interactable highlight)
//   dissolve       -> noise-driven burn-away with a hot leading edge (death,
//                     pickup collection)
//
// Replaces the old flash.gdshader, which did only the first of these.
shader_type canvas_item;

// --- Hit flash ---------------------------------------------------------------
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4  flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// --- Outline -----------------------------------------------------------------
uniform float outline_width : hint_range(0.0, 6.0) = 0.0;
uniform vec4  outline_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
// Pulses the outline alpha. 0 = steady.
uniform float outline_pulse : hint_range(0.0, 1.0) = 0.0;

// --- Dissolve ----------------------------------------------------------------
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D dissolve_noise : repeat_enable;
uniform vec4 dissolve_edge_color : source_color = vec4(1.0, 0.75, 0.25, 1.0);
uniform float dissolve_edge : hint_range(0.0, 0.4) = 0.12;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	// Outline: sample the alpha around this pixel; anything that is transparent
	// here but opaque nearby is rim. 8 taps so diagonals don't get notched.
	//
	// NOTE: this can only draw INSIDE the texture's own bounds. Tiles that run
	// flush to the edge of their image get a clipped outline on that side —
	// give the sprite a region/atlas with a pixel of padding if that matters.
	if (outline_width > 0.0) {
		vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
		float a = 0.0;
		a = max(a, texture(TEXTURE, UV + vec2( px.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0,  px.y)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
		a = max(a, texture(TEXTURE, UV + px * 0.7071).a);
		a = max(a, texture(TEXTURE, UV - px * 0.7071).a);
		a = max(a, texture(TEXTURE, UV + vec2(px.x, -px.y) * 0.7071).a);
		a = max(a, texture(TEXTURE, UV + vec2(-px.x, px.y) * 0.7071).a);
		float rim = clamp(a - col.a, 0.0, 1.0);
		float pulse = 1.0 - outline_pulse * 0.45 * (0.5 + 0.5 * sin(TIME * 7.0));
		col = mix(col, vec4(outline_color.rgb, outline_color.a * pulse), rim);
	}

	// Flash: blend toward the flash colour, keeping the silhouette intact.
	col.rgb = mix(col.rgb, flash_color.rgb, flash_amount);

	// Dissolve: cut away pixels whose noise value is below the threshold, and
	// light up the pixels just above it so the edge burns.
	if (dissolve > 0.0) {
		float n = texture(dissolve_noise, UV).r;
		float cut = dissolve * (1.0 + dissolve_edge);
		if (n < cut - dissolve_edge) {
			col.a = 0.0;
		} else if (n < cut) {
			col = vec4(dissolve_edge_color.rgb, col.a * dissolve_edge_color.a);
		}
	}

	COLOR = col;
}
