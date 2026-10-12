shader_type spatial;
// Cobblestone courtyard fading into grass. World-space, no textures needed.
uniform float court_radius = 15.5;
uniform vec3 stone_a : source_color = vec3(0.47, 0.46, 0.44);
uniform vec3 stone_b : source_color = vec3(0.62, 0.60, 0.56);
uniform vec3 grout : source_color = vec3(0.33, 0.31, 0.29);
uniform vec3 grass_a : source_color = vec3(0.24, 0.36, 0.14);
uniform vec3 grass_b : source_color = vec3(0.38, 0.48, 0.20);
uniform vec3 gold : source_color = vec3(0.95, 0.72, 0.30);
varying vec3 wp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec2 p = wp.xz;
	float r = length(p);
	// stones: staggered rows of slightly irregular blocks
	vec2 s = p * vec2(2.6, 3.6);
	s.x += step(1.0, mod(floor(s.y), 2.0)) * 0.5;
	vec2 cell = floor(s);
	vec2 f = fract(s);
	vec2 j = vec2(hash(cell), hash(cell + 7.3)) * 0.08;
	float e = min(min(f.x - j.x, 1.0 - f.x - j.y), min(f.y - j.y, 1.0 - f.y - j.x));
	float g = smoothstep(0.02, 0.09, e);
	float h = hash(cell + 3.1);
	vec3 st = mix(stone_a, stone_b, h) * (0.85 + 0.3 * noise(p * 3.0));
	st = mix(grout, st, g);
	// circular gold inlay & sun rays around the centre dais
	float ring = smoothstep(0.06, 0.0, abs(r - 3.2)) + smoothstep(0.05, 0.0, abs(r - 3.55));
	float ang = atan(p.y, p.x);
	float rays = step(0.92, cos(ang * 12.0)) * step(r, 3.2) * step(1.2, r);
	st = mix(st, gold, clamp(ring + rays * 0.8, 0.0, 1.0) * 0.85);
	// grass outside
	float n = noise(p * 0.6) * 0.6 + noise(p * 2.7) * 0.4;
	vec3 gr = mix(grass_a, grass_b, n) * (0.9 + 0.2 * noise(p * 11.0));
	float edge = smoothstep(court_radius - 1.0, court_radius + 0.8, r + (noise(p * 1.3) - 0.5) * 2.0);
	vec3 col = mix(st, gr, edge);
	ALBEDO = col;
	ROUGHNESS = mix(0.85, 0.95, edge);
	METALLIC = clamp(ring + rays, 0.0, 1.0) * (1.0 - edge) * 0.6;
	SPECULAR = 0.3;
}
