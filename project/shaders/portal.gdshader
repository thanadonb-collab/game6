shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
// The Haupttür — swirling dimensional gate (opaque vortex with bright streaks).
uniform vec4 deep : source_color = vec4(0.06, 0.01, 0.14, 1.0);
uniform vec4 col_a : source_color = vec4(0.55, 0.18, 1.0, 1.0);
uniform vec4 col_b : source_color = vec4(0.20, 0.85, 1.0, 1.0);
uniform float speed = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	float t = TIME * speed;
	float tw = a + r * 3.5 - t * 0.8;               // spiral coordinate
	float arms = pow(sin(tw * 4.0) * 0.5 + 0.5, 3.0);
	float n = noise(vec2(tw * 2.0, r * 7.0 - t * 1.4));
	float streak = arms * (0.4 + 0.9 * n);
	vec3 c = mix(col_a.rgb, col_b.rgb, smoothstep(0.2, 0.9, n * (1.0 - r)));
	vec3 col = deep.rgb + c * streak * (0.6 + 0.8 * (1.0 - r));
	col += vec3(0.85, 0.7, 1.0) * smoothstep(0.35, 0.0, r) * 0.9;   // bright core
	col += c * smoothstep(0.8, 1.0, r) * 0.9;                        // rim glow
	ALBEDO = col;
}
