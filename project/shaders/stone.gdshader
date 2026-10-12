shader_type spatial;
// World-space brick pattern for walls/towers (tri-planar by dominant normal).
uniform vec3 brick_a : source_color = vec3(0.50, 0.49, 0.48);
uniform vec3 brick_b : source_color = vec3(0.64, 0.62, 0.58);
uniform vec3 mortar : source_color = vec3(0.40, 0.39, 0.37);
uniform vec2 brick_size = vec2(0.62, 0.30);
uniform float moss = 0.35;
varying vec3 wp;
varying vec3 wn;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
vec3 bricks(vec2 uv, out float m) {
	vec2 s = uv / brick_size;
	s.x += step(1.0, mod(floor(s.y), 2.0)) * 0.5;
	vec2 c = floor(s); vec2 f = fract(s);
	float e = min(min(f.x, 1.0 - f.x) * brick_size.x, min(f.y, 1.0 - f.y) * brick_size.y);
	m = smoothstep(0.012, 0.04, e);
	return mix(brick_a, brick_b, hash(c)) * (0.85 + 0.3 * noise(uv * 4.0));
}
void fragment() {
	vec3 an = abs(wn);
	vec2 uv = an.y > 0.7 ? wp.xz : (an.x > an.z ? wp.zy : wp.xy);
	float m;
	vec3 b = bricks(uv, m);
	vec3 col = mix(mortar, b, m);
	float mo = smoothstep(0.55, 0.85, noise(wp.xz * 0.7 + wp.y * 0.3)) * smoothstep(2.5, 0.0, wp.y) * moss;
	col = mix(col, vec3(0.25, 0.36, 0.15), mo);
	ALBEDO = col;
	ROUGHNESS = 0.92;
}
