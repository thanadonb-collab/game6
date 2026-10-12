class_name VFX
extends RefCounted
## Small, renderer-agnostic effects (work in the Compatibility / Web renderer).

static func _glow_mat(color: Color, additive := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = color
	m.vertex_color_use_as_albedo = true
	m.billboard_keep_scale = true
	return m


static var _dot: GradientTexture2D
static func soft_dot() -> Texture2D:
	if _dot == null:
		_dot = GradientTexture2D.new()
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.35, Color(1, 1, 1, 0.6))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		_dot.gradient = g
		_dot.fill = GradientTexture2D.FILL_RADIAL
		_dot.fill_from = Vector2(0.5, 0.5)
		_dot.fill_to = Vector2(0.5, 0.0)
		_dot.width = 64
		_dot.height = 64
	return _dot


static func _free_after(node: Node, t: float) -> void:
	var tm := node.get_tree().create_timer(t)
	tm.timeout.connect(node.queue_free)


## Burst of glowing particles.
static func sparks(root: Node3D, pos: Vector3, color: Color, amount := 24, speed := 3.0, life := 0.6, size := 0.06, gravity := -6.0) -> void:
	var p := CPUParticles3D.new()
	root.add_child(p)
	p.global_position = pos
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = life
	p.direction = Vector3.UP
	p.spread = 180
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, gravity, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(size, size) * 2.0
	var m := _glow_mat(color)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = soft_dot()
	q.material = m
	p.mesh = q
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = g
	p.emitting = true
	_free_after(p, life + 0.3)


## Slowly rising motes (magic aura).
static func motes(root: Node3D, pos: Vector3, color: Color, radius := 0.8, life := 1.6, amount := 40) -> void:
	var p := CPUParticles3D.new()
	root.add_child(p)
	p.global_position = pos
	p.one_shot = true
	p.explosiveness = 0.3
	p.amount = amount
	p.lifetime = life
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = radius
	p.emission_ring_inner_radius = radius * 0.6
	p.emission_ring_height = 0.1
	p.direction = Vector3.UP
	p.spread = 15
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 2.0
	p.gravity = Vector3(0, 0.6, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.16, 0.16)
	var m := _glow_mat(color)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = soft_dot()
	q.material = m
	p.mesh = q
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.2, Color(1, 1, 1, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = g
	p.emitting = true
	_free_after(p, life + 0.6)


## Expanding flat ring on the ground.
static func ring(root: Node3D, pos: Vector3, color: Color, to_radius := 3.0, time := 0.7, width := 0.25) -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 1.0 - width
	t.outer_radius = 1.0
	t.rings = 48
	t.ring_segments = 6
	mi.mesh = t
	var m := _glow_mat(color)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.global_position = pos + Vector3(0, 0.05, 0)
	mi.scale = Vector3(0.2, 0.05, 0.2)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(to_radius, 0.05, to_radius), time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, time).set_ease(Tween.EASE_IN)
	_free_after(mi, time + 0.1)


## Short-lived point light.
static func flash(root: Node3D, pos: Vector3, color: Color, energy := 4.0, range_ := 5.0, time := 0.5) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_
	root.add_child(l)
	l.global_position = pos
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, time).set_ease(Tween.EASE_IN)
	_free_after(l, time + 0.05)


## Crescent sword trail in front of the character.
static func slash(root: Node3D, xform: Transform3D, color: Color, radius := 1.25, time := 0.28) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var seg := 22
	for i in seg + 1:
		var t := float(i) / seg
		var a := lerpf(-1.2, 1.4, t)
		var w := sin(t * PI)
		var c := Color(color.r, color.g, color.b, w)
		var outer := Vector3(sin(a) * radius, 0.25 * (t - 0.5), -cos(a) * radius)
		var inner := outer * (1.0 - 0.32 * w)
		im.surface_set_color(c)
		im.surface_add_vertex(outer)
		im.surface_set_color(Color(c.r, c.g, c.b, 0.0))
		im.surface_add_vertex(inner)
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var m := _glow_mat(Color(1, 1, 1, 1))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.global_transform = xform
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(m, "albedo_color:a", 0.0, time)
	tw.tween_property(mi, "rotation:y", mi.rotation.y - 0.5, time)
	_free_after(mi, time + 0.05)


## Golden chevrons flying forward (the commander's order).
static func chevrons(root: Node3D, origin: Vector3, dir: Vector3, color: Color, count := 3) -> void:
	for i in count:
		var mi := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.9, 0.5, 0.04)
		mi.mesh = pm
		var m := _glow_mat(color)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		var start := origin + Vector3(0, 0.9, 0) + dir * (0.8 + i * 0.6)
		mi.global_position = start
		mi.look_at(start + Vector3.UP, dir)
		mi.rotate_object_local(Vector3.RIGHT, 0.0)
		m.albedo_color.a = 0.0
		var tw := mi.create_tween()
		tw.tween_interval(i * 0.12)
		tw.tween_property(m, "albedo_color:a", 0.9, 0.12)
		tw.parallel().tween_property(mi, "global_position", start + dir * 5.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.9).set_delay(0.3)
		_free_after(mi, 1.4 + i * 0.12)


## Glowing projectile flying from `from` along `dir` (arrow, bolt or tracer).
static func projectile(root: Node3D, from: Vector3, dir: Vector3, color: Color, kind := "bolt", dist := 14.0, time := 0.45, arc := 0.0) -> void:
	var mi := MeshInstance3D.new()
	var m := _glow_mat(color)
	match kind:
		"arrow":
			var b := BoxMesh.new()
			b.size = Vector3(0.025, 0.025, 0.8)
			mi.mesh = b
		"tracer":
			var b2 := BoxMesh.new()
			b2.size = Vector3(0.02, 0.02, 1.4)
			mi.mesh = b2
		_:
			var sp := SphereMesh.new()
			sp.radius = 0.14
			sp.height = 0.28
			mi.mesh = sp
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.global_position = from
	var d := dir.normalized()
	var to := from + d * dist
	if absf(d.y) < 0.99:
		mi.look_at(from + d, Vector3.UP)
	var tw := mi.create_tween()
	if arc > 0.0:
		var step := func(t: float) -> void:
			if not is_instance_valid(mi):
				return
			var p := from.lerp(to, t) + Vector3.UP * arc * 4.0 * t * (1.0 - t)
			var t2 := minf(t + 0.03, 1.0)
			var p2 := from.lerp(to, t2) + Vector3.UP * arc * 4.0 * t2 * (1.0 - t2)
			mi.global_position = p
			if p.distance_to(p2) > 0.001 and absf((p2 - p).normalized().y) < 0.99:
				mi.look_at(p2, Vector3.UP)
		tw.tween_method(step, 0.0, 1.0, time)
	else:
		tw.tween_property(mi, "global_position", to, time)
	var finish := func() -> void:
		if is_instance_valid(mi):
			sparks(root, mi.global_position, color, 14, 2.5, 0.4)
			mi.queue_free()
	tw.tween_callback(finish)
	if kind == "bolt":
		var trail := CPUParticles3D.new()
		trail.amount = 30
		trail.lifetime = 0.35
		trail.local_coords = false
		trail.direction = Vector3.UP
		trail.spread = 180
		trail.initial_velocity_max = 0.3
		trail.gravity = Vector3.ZERO
		var q := QuadMesh.new()
		q.size = Vector2(0.18, 0.18)
		var tm := _glow_mat(color)
		tm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		tm.albedo_texture = soft_dot()
		q.material = tm
		trail.mesh = q
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.9))
		g.set_color(1, Color(1, 1, 1, 0))
		trail.color_ramp = g
		mi.add_child(trail)


## Muzzle flash for firearms.
static func muzzle(root: Node3D, pos: Vector3, dir: Vector3, color := Color(1.0, 0.7, 0.3)) -> void:
	flash(root, pos, color, 3.0, 4.0, 0.08)
	sparks(root, pos, color, 8, 2.0, 0.12, 0.05, 0.0)
	projectile(root, pos + dir * 0.4, dir, Color(1.0, 0.85, 0.5), "tracer", 18.0, 0.18)
