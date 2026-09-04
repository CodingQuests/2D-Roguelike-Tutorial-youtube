// Full-screen "mood" overlay driven by the HUD. Pure UV math (no screen
// texture) so it always compiles, never black-screens, and is invisible when
// every uniform is 0. Layers, by intensity:
//   corruption  -> purple creeping vignette + chromatic edge fringe
//   low_health  -> red pulsing vignette
//   damage      -> quick full-screen red flash
//   impact      -> soft bright vignette pop (heavy hits / tier-ups)
shader_type canvas_item;

uniform float corruption : hint_range(0.0, 1.0) = 0.0;
uniform float low_health : hint_range(0.0, 1.0) = 0.0;
uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform float impact : hint_range(0.0, 1.0) = 0.0;
uniform float time = 0.0;

void fragment() {
	vec2 uv = UV;
	vec2 c = uv - vec2(0.5);
	float d = length(c) * 1.4;            // 0 at centre -> ~1 at the corners
	float vig = smoothstep(0.30, 0.95, d); // soft edge mask

	vec3 col = vec3(0.0);
	float a = 0.0;

	// Corruption: purple vignette.
	float corr_v = vig * corruption;
	col += vec3(0.45, 0.08, 0.55) * corr_v;
	a = max(a, corr_v * 0.7);

	// Faux chromatic aberration: warm fringe on the left edge, cool on the
	// right. Driven by corruption and impacts.
	float fringe = corruption * 0.5 + impact;
	col += vec3(0.30, 0.0, 0.0) * vig * fringe * smoothstep(0.5, 0.0, uv.x);
	col += vec3(0.0, 0.18, 0.30) * vig * fringe * smoothstep(0.5, 1.0, uv.x);
	a = max(a, vig * fringe * 0.35);

	// Low health: red pulsing vignette.
	float pulse = 0.6 + 0.4 * sin(time * 6.0);
	float low_v = vig * low_health * pulse;
	col += vec3(0.70, 0.04, 0.06) * low_v;
	a = max(a, low_v * 0.85);

	// Impact: soft bright vignette pop.
	float imp_v = vig * impact;
	col += vec3(0.80, 0.70, 0.95) * imp_v;
	a = max(a, imp_v * 0.5);

	// Damage: quick full-screen red flash.
	col += vec3(0.80, 0.05, 0.05) * damage;
	a = max(a, damage * 0.45);

	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
