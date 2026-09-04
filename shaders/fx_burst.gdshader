// Radial streak burst — the replacement for the CPUParticles2D "impact" puff.
//
// Particles were the wrong tool here: a dozen square dots fading out reads as
// confetti, not as force. This draws real streaks that shoot out, stretch, and
// snap back, all from one quad and one draw call.
//
// Each spoke gets its own length, width and speed from a hash of its index, so
// the burst is irregular; `seed` varies it per instance.
shader_type canvas_item;
render_mode blend_add, unshaded;

const float TAU_ = 6.28318530718;

uniform vec4 color : source_color = vec4(1.0, 0.7, 0.35, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int spokes : hint_range(4, 32) = 13;
uniform float seed = 0.0;
// Hot core flash at the centre on the first frames.
uniform float core : hint_range(0.0, 1.0) = 1.0;

float hash1(float n) {
	return fract(sin(n * 127.1 + seed * 311.7) * 43758.5453);
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 2.0;
	float ang = atan(p.y, p.x) / TAU_ + 0.5;   // 0..1 around the quad

	float fs = float(spokes);
	float idx = floor(ang * fs);
	float within = fract(ang * fs);

	// Per-spoke character.
	float len = mix(0.45, 1.0, hash1(idx));
	float wide = mix(0.10, 0.34, hash1(idx + 7.3));
	float speed = mix(0.8, 1.25, hash1(idx + 19.1));

	// The streak is a radial segment whose head races outward and whose tail
	// follows, so it stretches then contracts.
	float head = clamp(progress * speed, 0.0, 1.0) * len;
	float tail = max(0.0, head - mix(0.16, 0.34, hash1(idx + 3.7)));

	float radial = smoothstep(tail, tail + 0.03, d) * (1.0 - smoothstep(head - 0.03, head, d));
	// Taper the streak toward its tip.
	float taper = 1.0 - smoothstep(0.0, 1.0, d / max(len, 0.001)) * 0.55;
	float angular = 1.0 - smoothstep(0.0, wide * taper, abs(within - 0.5));

	float streak = radial * angular;

	// Bright core that collapses quickly.
	float core_a = core * (1.0 - smoothstep(0.0, 0.32, d)) * (1.0 - smoothstep(0.0, 0.28, progress));

	float alpha = (streak * (1.0 - progress) + core_a);
	COLOR = vec4(color.rgb * (1.0 + core_a * 2.0), clamp(alpha, 0.0, 1.0) * color.a);
}
