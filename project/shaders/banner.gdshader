shader_type spatial;
render_mode cull_disabled;
// Royal banner of Elvaren: blue field, gold border, gold sun. Waves in the wind.
uniform vec3 field : source_color = vec3(0.10, 0.20, 0.55);
uniform vec3 trim : source_color = vec3(1.0, 0.76, 0.30);
uniform float wave = 0.08;
void vertex() {
	VERTEX.z += sin(TIME * 2.2 + UV.y * 5.0 + NODE_POSITION_WORLD.x) * wave * (0.3 + UV.y);
	VERTEX.x += sin(TIME * 1.7 + UV.y * 3.0) * wave * 0.3 * UV.y;
}
void fragment() {
	vec2 uv = UV;
	float border = step(uv.x, 0.07) + step(0.93, uv.x) + step(uv.y, 0.05);
	// swallow-tail bottom
	if (uv.y > 0.86 && abs(uv.x - 0.5) < (uv.y - 0.86) * 2.5) discard;
	vec2 c = uv - vec2(0.5, 0.42);
	c.y *= 0.62;
	float r = length(c);
	float a = atan(c.y, c.x);
	float sun = step(r, 0.11) + step(r, 0.19) * step(0.75, cos(a * 12.0)) * step(0.11, r);
	float b2 = step(abs(uv.y - 0.82), 0.012);
	vec3 col = field;
	col = mix(col, trim, clamp(border + sun + b2, 0.0, 1.0));
	ALBEDO = col;
	ROUGHNESS = 0.8;
	METALLIC = clamp(border + sun, 0.0, 1.0) * 0.4;
}
