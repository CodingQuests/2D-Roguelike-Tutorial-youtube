// Full-screen colour grade. The game's palette comes from three unrelated
// sources — Kenney dungeon tiles, Kenney UI tiles, and code-picked effect
// colours — so nothing ties them together. Lifting the shadows toward a cool
// blue, warming the highlights and easing the saturation down gives every
// element a shared colour identity without touching a single asset.
//
// Deliberately a SEPARATE node from screen_fx.gdshader: that one is UV-only on
// purpose, so it always compiles and can never black-screen. This one reads the
// screen, so it gets its own node and its own risk.
//
// Sits UNDER ScreenFX in the tree, so the corruption/damage overlays are drawn
// on top of the graded image rather than being graded themselves.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;

uniform float saturation : hint_range(0.0, 2.0) = 0.94;
// Shadow tint (added to darks) and highlight tint (multiplied into lights).
uniform vec4 lift : source_color = vec4(0.05, 0.06, 0.12, 1.0);
uniform vec4 gain : source_color = vec4(1.05, 1.00, 0.94, 1.0);
uniform float vignette : hint_range(0.0, 1.0) = 0.22;
// Global mix, so the whole grade can be faded out (death screen, menus).
uniform float amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec3 src = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(src, vec3(0.299, 0.587, 0.114));

	vec3 col = mix(vec3(l), src, saturation);
	// Lift darks toward the shadow tint, and tint the brights with gain.
	col = mix(col + lift.rgb * (1.0 - l), col * gain.rgb, l);

	// Soft corner falloff — focuses the eye and hides the dungeon's edges.
	vec2 c = SCREEN_UV - vec2(0.5);
	float v = 1.0 - vignette * smoothstep(0.25, 0.85, length(c) * 1.4);
	col *= v;

	COLOR = vec4(mix(src, col, amount), 1.0);
}
