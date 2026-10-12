extends Node3D
## Third-person orbit camera.
## Drag = orbit · wheel / pinch buttons = zoom · short click / tap = walk there.

@export var target_path: NodePath
@export var distance := 5.2
@export var min_distance := 2.2
@export var max_distance := 14.0
@export var pitch_deg := -16.0
@export var height := 1.25
@export var follow_speed := 8.0
@export var turntable := false
@export var turntable_speed := 18.0   # deg / s
@export var start_yaw := 22.0

@onready var cam: Camera3D = $Camera3D
var target: Node3D
var yaw_deg := 0.0
var _drag := false
var _press_pos := Vector2.ZERO
var _moved := 0.0
var _zoom := 0.0


func _ready() -> void:
	target = get_node(target_path)
	yaw_deg = start_yaw
	_zoom = distance
	global_position = target.global_position + Vector3.UP * height


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_drag = true
				_press_pos = mb.position
				_moved = 0.0
			else:
				_drag = false
				if mb.button_index == MOUSE_BUTTON_LEFT and _moved < 8.0:
					_click_ground(mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_by(-0.6)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_by(0.6)
	elif e is InputEventMouseMotion and _drag:
		var mm := e as InputEventMouseMotion
		_moved += mm.relative.length()
		if _moved >= 8.0:
			yaw_deg -= mm.relative.x * 0.3
			pitch_deg = clampf(pitch_deg - mm.relative.y * 0.2, -60.0, 8.0)
	elif e is InputEventMagnifyGesture:
		zoom_by((1.0 - (e as InputEventMagnifyGesture).factor) * 6.0)


func zoom_by(d: float) -> void:
	_zoom = clampf(_zoom + d, min_distance, max_distance)


func _click_ground(screen: Vector2) -> void:
	var from := cam.project_ray_origin(screen)
	var dir := cam.project_ray_normal(screen)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 200.0)
	q.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit and target.has_method("set_move_target"):
		target.set_move_target(hit.position)
		VFX.ring(get_parent(), hit.position, Color(1, 0.85, 0.4), 0.6, 0.45, 0.3)


func _process(delta: float) -> void:
	if turntable:
		yaw_deg += turntable_speed * delta
	distance = lerpf(distance, _zoom, clampf(delta * 8.0, 0, 1))
	var want := target.global_position + Vector3.UP * height
	global_position = global_position.lerp(want, clampf(delta * follow_speed, 0, 1))
	rotation_degrees = Vector3(pitch_deg, yaw_deg, 0)
	# keep the camera out of walls and towers
	var d := distance
	var want_cam := global_transform * Vector3(0, 0, distance)
	var q := PhysicsRayQueryParameters3D.create(global_position, want_cam)
	q.collision_mask = 1
	if target is CollisionObject3D:
		q.exclude = [(target as CollisionObject3D).get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		d = maxf(0.6, global_position.distance_to(hit.position) - 0.35)
	cam.position = Vector3(0, 0, d)
