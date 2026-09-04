// Expanding ring of UV distortion for heavy hits and boss slams.
//
// Reads the screen, so it carries the same risk as grade.gdshader and gets the
// same treatment: its own node, and it does nothing at all when `strength` is
// 0 (the shader early-outs to a straight copy, so there is no cost and no
// possible artefact when idle).
//
// Ordering note: in 2D the screen is copied to the back-buffer once, at the
// FIRST node that reads it. This node sits ABOVE Grade in the tree, so it
// samples the already-graded image. If a third screen-reading effect is ever
// added between them, it needs a BackBufferCopy node in between or it will
// silently sample a stale frame.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

// Ring centre in screen UV (0..1).
uniform vec2 center = vec2(0.5, 0.5);
// 0 -> 1 as the ring travels outward.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Overall displacement, faded out by the caller.
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float ring_width : hint_range(0.01, 0.3) = 0.08;
uniform float max_radius : hint_range(0.05, 1.0) = 0.45;
// Screen aspect, so the ring stays circular on a wide window.
uniform float aspect = 1.7777;

void fragment() {
	vec2 uv = SCREEN_UV;
	if (strength <= 0.001) {
		COLOR = vec4(texture(screen_tex, uv).rgb, 1.0);
	} else {
		vec2 d = uv - center;
		d.x *= aspect;
		float dist = length(d);
		float radius = progress * max_radius;
		// 1 at the ring's crest, 0 away from it.
		float band = 1.0 - smoothstep(0.0, ring_width, abs(dist - radius));
		// Fade the whole thing out as the ring expands, so it dissipates.
		float push = band * strength * (1.0 - progress) * 0.045;
		vec2 dir = dist > 0.0001 ? normalize(d) : vec2(0.0);
		dir.x /= aspect;
		vec3 col = texture(screen_tex, uv - dir * push).rgb;
		// A touch of brightening on the crest so it reads as force, not a smear.
		col += vec3(0.35, 0.30, 0.26) * band * strength * (1.0 - progress) * 0.5;
		COLOR = vec4(col, 1.0);
	}
}
