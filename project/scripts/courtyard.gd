@tool
extends Node3D
## Procedural environment: the royal courtyard of Elvaren at dusk, with the
## Haupttür (dimensional gate) glowing beyond the north gatehouse.
## Built in code so it stays light for the Web build; visible in the editor too.

@export var rebuild := false:
	set(v):
		if v and is_inside_tree():
			_build()

const WALL_R := 17.0
const GATE_Z := -30.0

var stone_mat: ShaderMaterial
var roof_mat: StandardMaterial3D
var wood_mat: StandardMaterial3D
var iron_mat: StandardMaterial3D
var gold_mat: StandardMaterial3D
var straw_mat: StandardMaterial3D


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_materials()
	_ground()
	_walls()
	_gatehouse()
	_keep()
	_props()
	_portal()
	_scenery()


# ------------------------------------------------------------------ helpers
func _materials() -> void:
	stone_mat = ShaderMaterial.new()
	stone_mat.shader = load("res://shaders/stone.gdshader")
	roof_mat = _std(Color(0.16, 0.24, 0.48), 0.7)
	wood_mat = _std(Color(0.42, 0.27, 0.15), 0.9)
	iron_mat = _std(Color(0.25, 0.25, 0.28), 0.5, 0.8)
	gold_mat = _std(Color(1.0, 0.76, 0.30), 0.35, 0.35)
	straw_mat = _std(Color(0.80, 0.66, 0.36), 1.0)


func _std(c: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _mi(mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE, parent: Node = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mat:
		mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(r_top: float, r_bot: float, h: float, seg := 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


func _collider(size: Vector3, xform: Transform3D) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	add_child(sb)
	sb.transform = xform


## Merges many primitive meshes into one draw call.
class Merger:
	var st := SurfaceTool.new()
	var used := false
	func add(mesh: Mesh, xf: Transform3D) -> void:
		if not used:
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			used = true
		st.append_from(mesh, 0, xf)
	func commit() -> ArrayMesh:
		return st.commit() if used else null


# ------------------------------------------------------------------ pieces
func _ground() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(140, 140)
	pm.subdivide_width = 4
	pm.subdivide_depth = 4
	var gm := ShaderMaterial.new()
	gm.shader = load("res://shaders/ground.gdshader")
	_mi(pm, gm, Vector3.ZERO)
	_collider(Vector3(140, 1, 140), Transform3D(Basis(), Vector3(0, -0.5, 0)))
	# central dais
	_mi(_cyl(3.0, 3.25, 0.18, 48), stone_mat, Vector3(0, 0.09, 0))
	_mi(_cyl(3.0, 3.0, 0.02, 48), _std(Color(0.55, 0.52, 0.48), 0.6), Vector3(0, 0.185, 0))
	_mi(_cyl(0.9, 0.9, 0.025, 32), gold_mat, Vector3(0, 0.19, 0))
	_collider(Vector3(5.0, 0.18, 5.0), Transform3D(Basis(), Vector3(0, -0.05, 0)))


func _wall_segment(m: Merger, a0: float, a1: float, h := 4.2, th := 1.4) -> void:
	var p0 := Vector3(cos(a0), 0, sin(a0)) * WALL_R
	var p1 := Vector3(cos(a1), 0, sin(a1)) * WALL_R
	var mid := (p0 + p1) * 0.5
	var ln := p0.distance_to(p1) + 0.05
	var basis := Basis(Vector3.UP, -atan2(p1.z - p0.z, p1.x - p0.x))
	m.add(_box(Vector3(ln, h, th)), Transform3D(basis, mid + Vector3(0, h / 2, 0)))
	# walkway lip + merlons
	m.add(_box(Vector3(ln, 0.25, th + 0.3)), Transform3D(basis, mid + Vector3(0, h, 0)))
	var n := int(ln / 1.1)
	for i in n:
		var t := (i + 0.5) / n - 0.5
		var off := basis * Vector3(t * ln, 0, th * 0.42)
		m.add(_box(Vector3(0.55, 0.7, 0.35)), Transform3D(basis, mid + off + Vector3(0, h + 0.47, 0)))
	_collider(Vector3(ln, h, th), Transform3D(basis, mid + Vector3(0, h / 2, 0)))


func _tower(m: Merger, roofs: Merger, pos: Vector3, r := 1.7, h := 7.5) -> void:
	m.add(_cyl(r, r * 1.08, h, 20), Transform3D(Basis(), pos + Vector3(0, h / 2, 0)))
	m.add(_cyl(r * 1.15, r * 1.15, 0.5, 20), Transform3D(Basis(), pos + Vector3(0, h + 0.25, 0)))
	for i in 10:
		var a := TAU * i / 10
		m.add(_box(Vector3(0.5, 0.6, 0.4)), Transform3D(Basis(Vector3.UP, -a), pos + Vector3(cos(a), 0, sin(a)) * r * 1.05 + Vector3(0, h + 0.8, 0)))
	roofs.add(_cyl(0.0, r * 1.3, 3.2, 20), Transform3D(Basis(), pos + Vector3(0, h + 2.1, 0)))
	_collider(Vector3(r * 1.8, h, r * 1.8), Transform3D(Basis(), pos + Vector3(0, h / 2, 0)))
	# flag
	_mi(_cyl(0.04, 0.04, 2.2, 6), iron_mat, pos + Vector3(0, h + 4.6, 0))
	var flag := QuadMesh.new()
	flag.size = Vector2(1.0, 0.6)
	flag.subdivide_width = 6
	var fm := ShaderMaterial.new()
	fm.shader = load("res://shaders/banner.gdshader")
	fm.set_shader_parameter("wave", 0.06)
	_mi(flag, fm, pos + Vector3(0.52, h + 5.2, 0), Vector3(0, 0, 90))


func _walls() -> void:
	var m := Merger.new()
	var roofs := Merger.new()
	var gap := deg_to_rad(9.0)
	var north := -PI / 2
	var towers := [north - gap - 0.06, north + gap + 0.06, deg_to_rad(-30), deg_to_rad(30), deg_to_rad(90), deg_to_rad(150), deg_to_rad(210)]
	# segments between towers (skip the gate gap)
	var start := north + gap
	var end := north - gap + TAU
	var steps := 26
	for i in steps:
		var a0 := lerpf(start, end, float(i) / steps)
		var a1 := lerpf(start, end, float(i + 1) / steps)
		_wall_segment(m, a0, a1)
	for a in towers:
		_tower(m, roofs, Vector3(cos(a), 0, sin(a)) * WALL_R)
	var wall := _mi(m.commit(), stone_mat, Vector3.ZERO)
	wall.name = "Walls"
	_mi(roofs.commit(), roof_mat, Vector3.ZERO).name = "Roofs"


func _gatehouse() -> void:
	# open north gate with raised portcullis and royal banners
	var z := -WALL_R
	var m := Merger.new()
	m.add(_box(Vector3(6.4, 1.6, 2.0)), Transform3D(Basis(), Vector3(0, 5.3, z)))
	for i in 7:
		m.add(_box(Vector3(0.55, 0.7, 0.4)), Transform3D(Basis(), Vector3(-2.7 + i * 0.9, 6.45, z + 0.8)))
	_mi(m.commit(), stone_mat, Vector3.ZERO)
	var bars := Merger.new()
	for i in 7:
		bars.add(_cyl(0.05, 0.05, 1.2, 6), Transform3D(Basis(), Vector3(-2.4 + i * 0.8, 4.1, z)))
	bars.add(_box(Vector3(5.0, 0.1, 0.1)), Transform3D(Basis(), Vector3(0, 3.6, z)))
	_mi(bars.commit(), iron_mat, Vector3.ZERO)
	for sx in [-1.0, 1.0]:
		_banner(Vector3(sx * 2.1, 4.5, z + 1.05), Vector2(1.1, 2.6), 0.0)


func _banner(pos: Vector3, size: Vector2, yaw: float) -> void:
	var q := QuadMesh.new()
	q.size = size
	q.subdivide_depth = 8
	q.subdivide_width = 3
	var bm := ShaderMaterial.new()
	bm.shader = load("res://shaders/banner.gdshader")
	var b := _mi(q, bm, pos, Vector3(0, yaw, 0))
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mi(_cyl(0.05, 0.05, size.x + 0.3, 8), gold_mat, pos + Vector3(0, size.y / 2 + 0.05, 0), Vector3(0, yaw, 90))


func _keep() -> void:
	# castle keep looming behind the courtyard (south)
	var m := Merger.new()
	var roofs := Merger.new()
	var c := Vector3(0, 0, 25)
	m.add(_box(Vector3(14, 11, 8)), Transform3D(Basis(), c + Vector3(0, 5.5, 0)))
	m.add(_box(Vector3(8, 5, 6)), Transform3D(Basis(), c + Vector3(0, 13.5, 0)))
	for sx in [-1.0, 1.0]:
		var tp := c + Vector3(sx * 7.2, 0, -3.5)
		m.add(_cyl(2.0, 2.2, 15, 20), Transform3D(Basis(), tp + Vector3(0, 7.5, 0)))
		roofs.add(_cyl(0.0, 2.6, 5.0, 20), Transform3D(Basis(), tp + Vector3(0, 17.5, 0)))
	roofs.add(_cyl(0.0, 5.4, 5.5, 4), Transform3D(Basis(Vector3.UP, PI / 4), c + Vector3(0, 18.7, 0)))
	_mi(m.commit(), stone_mat, Vector3.ZERO)
	_mi(roofs.commit(), roof_mat, Vector3.ZERO)
	for i in 3:
		_banner(c + Vector3(-4 + i * 4, 7.5, -4.05), Vector2(1.6, 4.2), 180.0)
	# warm windows
	var win := _std(Color(1.0, 0.75, 0.35))
	win.emission_enabled = true
	win.emission = Color(1.0, 0.65, 0.25)
	win.emission_energy_multiplier = 2.0
	for i in 5:
		_mi(_box(Vector3(0.6, 1.1, 0.05)), win, c + Vector3(-5 + i * 2.5, 9.0, -4.03))


func _brazier(pos: Vector3) -> void:
	_mi(_cyl(0.18, 0.25, 1.0, 10), iron_mat, pos + Vector3(0, 0.5, 0))
	_mi(_cyl(0.55, 0.3, 0.35, 14), iron_mat, pos + Vector3(0, 1.15, 0))
	_mi(_cyl(0.5, 0.5, 0.05, 14), _std(Color(0.15, 0.08, 0.05)), pos + Vector3(0, 1.3, 0))
	_collider(Vector3(0.7, 1.4, 0.7), Transform3D(Basis(), pos + Vector3(0, 0.7, 0)))
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.9
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.25
	p.direction = Vector3.UP
	p.spread = 12
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.4
	p.gravity = Vector3(0, 1.5, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var q := QuadMesh.new()
	q.size = Vector2(0.35, 0.35)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fm.vertex_color_use_as_albedo = true
	fm.albedo_texture = _soft_dot()
	q.material = fm
	p.mesh = q
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.4, 1))
	g.add_point(0.5, Color(1.0, 0.4, 0.1, 0.8))
	g.set_color(g.get_point_count() - 1, Color(0.3, 0.05, 0.0, 0))
	p.color_ramp = g
	p.position = pos + Vector3(0, 1.35, 0)
	add_child(p)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.62, 0.3)
	l.light_energy = 2.2
	l.omni_range = 7.0
	l.position = pos + Vector3(0, 1.9, 0)
	add_child(l)
	var fl := FireFlicker.new()
	fl.light = l
	add_child(fl)


class FireFlicker:
	extends Node
	var light: OmniLight3D
	var t := randf() * 10.0
	func _process(d: float) -> void:
		t += d
		if light:
			light.light_energy = 2.0 + sin(t * 11.0) * 0.25 + sin(t * 23.0) * 0.15


static var _dot_tex: GradientTexture2D
func _soft_dot() -> Texture2D:
	if _dot_tex == null:
		_dot_tex = GradientTexture2D.new()
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		_dot_tex.gradient = g
		_dot_tex.fill = GradientTexture2D.FILL_RADIAL
		_dot_tex.fill_from = Vector2(0.5, 0.5)
		_dot_tex.fill_to = Vector2(0.5, 0.0)
		_dot_tex.width = 64
		_dot_tex.height = 64
	return _dot_tex


func _dummy(pos: Vector3, yaw: float) -> void:
	var d := Node3D.new()
	d.name = "TrainingDummy"
	d.position = pos
	d.rotation_degrees.y = yaw
	add_child(d)
	_mi(_cyl(0.07, 0.08, 1.9, 8), wood_mat, Vector3(0, 0.95, 0), Vector3.ZERO, Vector3.ONE, d)
	_mi(_cyl(0.05, 0.05, 1.1, 8), wood_mat, Vector3(0, 1.45, 0), Vector3(0, 0, 90), Vector3.ONE, d)
	_mi(_cyl(0.28, 0.24, 0.7, 12), straw_mat, Vector3(0, 1.25, 0), Vector3.ZERO, Vector3.ONE, d)
	var head := SphereMesh.new()
	head.radius = 0.17
	head.height = 0.34
	_mi(head, straw_mat, Vector3(0, 1.8, 0), Vector3.ZERO, Vector3.ONE, d)
	_mi(_cyl(0.3, 0.3, 0.06, 16), _std(Color(0.7, 0.1, 0.1)), Vector3(0, 1.3, -0.25), Vector3(90, 0, 0), Vector3.ONE, d)
	_collider(Vector3(0.6, 1.9, 0.6), Transform3D(Basis(), pos + Vector3(0, 0.95, 0)))


func _rack(pos: Vector3, yaw: float) -> void:
	var r := Node3D.new()
	r.position = pos
	r.rotation_degrees.y = yaw
	add_child(r)
	for sx in [-0.9, 0.9]:
		_mi(_box(Vector3(0.1, 1.4, 0.1)), wood_mat, Vector3(sx, 0.7, 0), Vector3.ZERO, Vector3.ONE, r)
	_mi(_box(Vector3(2.0, 0.08, 0.12)), wood_mat, Vector3(0, 1.2, 0), Vector3.ZERO, Vector3.ONE, r)
	_mi(_box(Vector3(2.0, 0.08, 0.3)), wood_mat, Vector3(0, 0.15, 0), Vector3.ZERO, Vector3.ONE, r)
	for i in 5:
		var x := -0.7 + i * 0.35
		_mi(_cyl(0.025, 0.025, 1.7, 6), wood_mat, Vector3(x, 0.95, 0.02), Vector3(8, 0, 0), Vector3.ONE, r)
		_mi(_cyl(0.0, 0.05, 0.25, 4), iron_mat, Vector3(x, 1.88, 0.15), Vector3(8, 0, 0), Vector3.ONE, r)


func _props() -> void:
	for a in [45.0, 135.0, 225.0, 315.0]:
		var r := deg_to_rad(a)
		_brazier(Vector3(cos(r), 0, sin(r)) * 6.0)
	for a in [-60.0, -120.0, 20.0, 160.0, 60.0, 120.0]:
		var r := deg_to_rad(a)
		var p := Vector3(cos(r), 0, sin(r)) * 10.5
		_mi(_cyl(0.06, 0.07, 5.2, 8), wood_mat, p + Vector3(0, 2.6, 0))
		_mi(SphereMesh.new(), gold_mat, p + Vector3(0, 5.3, 0), Vector3.ZERO, Vector3.ONE * 0.18)
		_banner(p + Vector3(0, 3.5, 0) + Vector3(-p.x, 0, -p.z).normalized() * 0.07, Vector2(0.9, 2.2), rad_to_deg(atan2(-p.x, -p.z)))
	_dummy(Vector3(6.5, 0, 1.5), -100)
	_dummy(Vector3(7.5, 0, -1.2), -80)
	_rack(Vector3(11.5, 0, 3.0), -95)
	# crates & barrels near the walls
	var crate := _std(Color(0.55, 0.38, 0.2))
	for i in 6:
		var a := deg_to_rad(200 + i * 7)
		var p := Vector3(cos(a), 0, sin(a)) * 14.2
		var s := 0.7 + (i % 3) * 0.15
		_mi(_box(Vector3(s, s, s)), crate, p + Vector3(0, s / 2, 0), Vector3(0, i * 23, 0))
		if i % 2 == 0:
			_mi(_cyl(0.35, 0.35, 0.9, 12), wood_mat, p + Vector3(0.9, 0.45, 0.4))
	# well
	_mi(_cyl(1.1, 1.1, 0.9, 20), stone_mat, Vector3(-8, 0.45, 6))
	_mi(_cyl(0.95, 0.95, 0.02, 20), _std(Color(0.1, 0.25, 0.35), 0.1, 0.3), Vector3(-8, 0.75, 6))
	for sx in [-0.85, 0.85]:
		_mi(_box(Vector3(0.12, 2.0, 0.12)), wood_mat, Vector3(-8 + sx, 1.4, 6))
	_mi(_cyl(0.0, 1.4, 0.8, 4), roof_mat, Vector3(-8, 2.6, 6), Vector3(0, 45, 0))
	_collider(Vector3(2.2, 1.0, 2.2), Transform3D(Basis(), Vector3(-8, 0.5, 6)))


func _portal() -> void:
	# The Haupttür: an ancient stone arch, torn open into another world.
	var g := Node3D.new()
	g.name = "Haupttur"
	g.position = Vector3(0, 0, GATE_Z)
	add_child(g)
	var dark := ShaderMaterial.new()
	dark.shader = load("res://shaders/stone.gdshader")
	dark.set_shader_parameter("brick_a", Color(0.30, 0.28, 0.34))
	dark.set_shader_parameter("brick_b", Color(0.42, 0.39, 0.46))
	dark.set_shader_parameter("mortar", Color(0.12, 0.10, 0.16))
	dark.set_shader_parameter("brick_size", Vector2(1.3, 0.7))
	dark.set_shader_parameter("moss", 0.0)
	var m := Merger.new()
	for sx in [-1.0, 1.0]:
		m.add(_box(Vector3(2.0, 10, 2.2)), Transform3D(Basis(), Vector3(sx * 5.2, 5, 0)))
		m.add(_box(Vector3(2.6, 1.0, 2.8)), Transform3D(Basis(), Vector3(sx * 5.2, 0.5, 0)))
		m.add(_box(Vector3(2.4, 0.8, 2.6)), Transform3D(Basis(), Vector3(sx * 5.2, 10.2, 0)))
	m.add(_box(Vector3(13.0, 1.6, 2.6)), Transform3D(Basis(), Vector3(0, 11.3, 0)))
	m.add(_box(Vector3(9.0, 1.2, 2.0)), Transform3D(Basis(), Vector3(0, 12.6, 0)))
	m.add(_box(Vector3(3.0, 1.4, 1.6)), Transform3D(Basis(), Vector3(0, 13.9, 0)))
	_mi(m.commit(), dark, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, g)
	# glowing runes on the pillars
	var rune := _std(Color(0.7, 0.4, 1.0))
	rune.emission_enabled = true
	rune.emission = Color(0.65, 0.3, 1.0)
	rune.emission_energy_multiplier = 3.0
	rune.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for sx in [-1.0, 1.0]:
		for i in 4:
			_mi(_box(Vector3(0.35, 0.35, 0.05)), rune, Vector3(sx * 5.2, 2.5 + i * 2.0, 1.13), Vector3(0, 0, 45), Vector3.ONE, g)
	# the gate surface
	var q := QuadMesh.new()
	q.size = Vector2(8.6, 10.4)
	var pm := ShaderMaterial.new()
	pm.shader = load("res://shaders/portal.gdshader")
	var surf := _mi(q, pm, Vector3(0, 5.3, 0.1), Vector3.ZERO, Vector3.ONE, g)
	surf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var back := _mi(q, pm, Vector3(0, 5.3, -0.1), Vector3(0, 180, 0), Vector3.ONE, g)
	back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lbl := Label3D.new()
	lbl.text = "HAUPTTÜR"
	lbl.font_size = 160
	lbl.pixel_size = 0.01
	lbl.modulate = Color(0.85, 0.65, 1.0)
	lbl.outline_size = 18
	lbl.outline_modulate = Color(0.1, 0.0, 0.2)
	lbl.position = Vector3(0, 11.3, 1.32)
	g.add_child(lbl)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 0.3, 1.0)
	l.light_energy = 3.0
	l.omni_range = 13.0
	l.position = Vector3(0, 4.0, 3.0)
	g.add_child(l)
	# drifting motes pulled out of the gate
	var p := CPUParticles3D.new()
	p.amount = 60
	p.lifetime = 4.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(4.0, 5.0, 0.3)
	p.direction = Vector3(0, 0.2, 1)
	p.spread = 25
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.5
	p.gravity = Vector3.ZERO
	var dq := QuadMesh.new()
	dq.size = Vector2(0.18, 0.18)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dm.vertex_color_use_as_albedo = true
	dm.albedo_texture = _soft_dot()
	dq.material = dm
	p.mesh = dq
	var gr := Gradient.new()
	gr.set_color(0, Color(0.7, 0.4, 1.0, 0))
	gr.add_point(0.3, Color(0.6, 0.5, 1.0, 1))
	gr.set_color(gr.get_point_count() - 1, Color(0.3, 0.9, 1.0, 0))
	p.color_ramp = gr
	p.position = Vector3(0, 5.3, 0.4)
	g.add_child(p)
	# scorched ground in front of the gate
	var scorch := _std(Color(0.12, 0.08, 0.16), 1.0)
	_mi(_cyl(7.0, 7.0, 0.02, 32), scorch, Vector3(0, 0.01, 3.0), Vector3.ZERO, Vector3(1, 1, 0.7), g)
	for sx in [-1.0, 1.0]:
		_collider(Vector3(2.0, 10, 2.2), Transform3D(Basis(), g.position + Vector3(sx * 5.2, 5, 0)))
	_collider(Vector3(8.4, 10, 0.4), Transform3D(Basis(), g.position + Vector3(0, 5, 0)))
	# road from the gate to the courtyard
	var road := _std(Color(0.42, 0.36, 0.28), 1.0)
	_mi(_box(Vector3(4.0, 0.02, 12.5)), road, Vector3(0, 0.01, -WALL_R - 6.4))


func _scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var pine := Merger.new()
	var trunks := Merger.new()
	for i in 90:
		var a := rng.randf() * TAU
		var d := rng.randf_range(22.0, 50.0)
		var p := Vector3(cos(a) * d, 0, sin(a) * d)
		if absf(p.x) < 12.0 and p.z < -18.0 and p.z > -40.0:
			continue
		if p.z > 18.0 and absf(p.x) < 14.0 and p.z < 33.0:
			continue
		var s := rng.randf_range(0.8, 1.6)
		trunks.add(_cyl(0.15 * s, 0.2 * s, 1.2 * s, 6), Transform3D(Basis(), p + Vector3(0, 0.6 * s, 0)))
		for k in 3:
			pine.add(_cyl(0.0, (1.6 - k * 0.4) * s, 2.0 * s, 8), Transform3D(Basis(), p + Vector3(0, (1.6 + k * 1.1) * s, 0)))
	_mi(pine.commit(), _std(Color(0.13, 0.27, 0.16), 0.9), Vector3.ZERO)
	_mi(trunks.commit(), wood_mat, Vector3.ZERO)
	var mount := Merger.new()
	for i in 14:
		var a := TAU * i / 14 + rng.randf() * 0.2
		var d := rng.randf_range(75.0, 95.0)
		var h := rng.randf_range(18.0, 38.0)
		mount.add(_cyl(0.0, h * 1.3, h, 7), Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(cos(a) * d, h / 2 - 2.0, sin(a) * d)))
	_mi(mount.commit(), _std(Color(0.30, 0.32, 0.42), 1.0), Vector3.ZERO)
	# boundary so the player can't wander off the map
	for side in [[Vector3(0, 2, -60), Vector3(120, 4, 1)], [Vector3(0, 2, 60), Vector3(120, 4, 1)],
			[Vector3(-60, 2, 0), Vector3(1, 4, 120)], [Vector3(60, 2, 0), Vector3(1, 4, 120)]]:
		_collider(side[1], Transform3D(Basis(), side[0]))
