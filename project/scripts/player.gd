class_name CommanderPlayer
extends CharacterBody3D
## Player controller for the HAUPTTÜR commander.
## WASD / arrows move (relative to camera), Shift runs, click or tap the ground to walk there.
## J attack · K (hold) block · Q rally · E command · H hit · X defeat · V victory · R revive

signal action_started(anim_name: StringName)
signal state_changed(text: String)

@export var walk_speed := 1.35
@export var run_speed := 3.6
@export var turn_speed := 10.0
@export var camera_path: NodePath

@onready var rig: CharacterRig = $Rig

const ACTIONS := [&"Attack", &"Cast", &"Command", &"Hit", &"Death", &"Victory"]
const GOLD := Color(1.0, 0.78, 0.3)
const RUNE := Color(0.45, 0.85, 1.0)

var camera_rig: Node3D
var move_target = null
var action: StringName = &""
var dead := false
var block_held := false
var force_block := false
var run_toggle := false
var showcase_loop: StringName = &""     # loop clip forced by the UI (Walk/Run/Idle/Block)
var _fx_done := {}


func _ready() -> void:
	_setup_input()
	if camera_path:
		camera_rig = get_node(camera_path)
	rig.action_finished.connect(_on_action_finished)


func _setup_input() -> void:
	var map := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"run": [KEY_SHIFT], "attack": [KEY_J], "block": [KEY_K], "cast": [KEY_Q],
		"command": [KEY_E], "hit": [KEY_H], "death": [KEY_X], "victory": [KEY_V], "revive": [KEY_R],
	}
	for a in map:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
			for k in map[a]:
				var ev := InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(a, ev)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("attack"): do_action(&"Attack")
	elif e.is_action_pressed("cast"): do_action(&"Cast")
	elif e.is_action_pressed("command"): do_action(&"Command")
	elif e.is_action_pressed("hit"): do_action(&"Hit")
	elif e.is_action_pressed("death"): do_action(&"Death")
	elif e.is_action_pressed("victory"): do_action(&"Victory")
	elif e.is_action_pressed("revive"): revive()


## Plays a one-shot action clip (also used by the UI buttons).
func do_action(n: StringName) -> void:
	if dead and n != &"Death":
		return
	if not rig.has_anim(n):
		return
	showcase_loop = &""
	move_target = null
	action = n
	dead = n == &"Death"
	_fx_done.clear()
	rig.play(n, 0.12, 1.0, true)
	action_started.emit(n)
	state_changed.emit(String(n))


## Forces a looping clip (Idle / Walk / Run / Block) for the showcase.
func show_loop(n: StringName) -> void:
	if dead:
		revive()
	action = &""
	move_target = null
	showcase_loop = n
	rig.play(n, 0.2)
	state_changed.emit(String(n))


func revive() -> void:
	if not dead:
		return
	dead = false
	action = &""
	rig.play(&"Idle", 0.4, 1.0, true)
	VFX.motes(get_parent(), global_position, GOLD, 0.7, 1.4, 50)
	VFX.flash(get_parent(), global_position + Vector3.UP, GOLD, 3.0, 5.0, 0.8)
	state_changed.emit("Idle")


func set_move_target(p: Vector3) -> void:
	if dead or action != &"":
		return
	showcase_loop = &""
	move_target = Vector3(p.x, global_position.y, p.z)


func _on_action_finished(n: StringName) -> void:
	if n == action and n != &"Death":
		action = &""
		state_changed.emit("Idle")


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var running := Input.is_action_pressed("run") or run_toggle
	block_held = Input.is_action_pressed("block") or force_block
	var dir := Vector3.ZERO
	if input.length() > 0.05:
		move_target = null
		showcase_loop = &""
		var yaw := camera_rig.global_rotation.y if camera_rig else 0.0
		dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, yaw)
	elif move_target != null:
		var to: Vector3 = move_target - global_position
		to.y = 0
		if to.length() < 0.15:
			move_target = null
		else:
			dir = to.normalized()
			running = running or to.length() > 4.0

	var can_move := not dead and action == &"" and not block_held
	var speed := (run_speed if running else walk_speed) if can_move and dir.length() > 0.01 else 0.0
	var target_vel := dir.normalized() * speed
	velocity.x = move_toward(velocity.x, target_vel.x, 18.0 * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, 18.0 * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	if dir.length() > 0.01 and can_move:
		var want := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, want, clampf(turn_speed * delta, 0, 1))
	move_and_slide()
	_update_anim()
	_update_fx()


func _update_anim() -> void:
	if dead or action != &"":
		return
	var hv := Vector2(velocity.x, velocity.z).length()
	if block_held:
		rig.play(&"Block", 0.15)
	elif hv > 2.2:
		rig.play(&"Run", 0.2, clampf(hv / run_speed, 0.6, 1.4))
	elif hv > 0.15:
		rig.play(&"Walk", 0.2, clampf(hv / walk_speed, 0.5, 1.5))
	elif showcase_loop != &"":
		rig.play(showcase_loop, 0.2)
	else:
		rig.play(&"Idle", 0.25)


## Weapon style decides which effects the clips trigger: sword, bow, staff, rifle.
var fx_kind := "sword"
var fx_color := RUNE


## Timed effects inside the clips.
func _update_fx() -> void:
	if action == &"":
		return
	var t := rig.position_in_anim()
	var world := get_parent() as Node3D
	var fwd := -global_transform.basis.z
	var tip := rig.marker("tip")
	var tip_pos := tip.global_position if tip else global_position + Vector3.UP * 1.4 + fwd * 0.5
	match action:
		&"Attack":
			match fx_kind:
				"sword":
					if t > 0.40 and _once("slash"):
						var x := Transform3D(global_transform.basis, global_position + Vector3(0, 1.15, 0))
						x = x.rotated_local(Vector3.FORWARD, -0.35)
						VFX.slash(world, x, fx_color, 1.25)
						VFX.sparks(world, tip_pos, fx_color, 16, 2.5, 0.4)
				"bow":
					if t > 0.86 and _once("arrow"):
						var lh := rig.marker("left_hand")
						var p := lh.global_position if lh else tip_pos
						VFX.projectile(world, p, fwd, fx_color, "arrow", 16.0, 0.45)
				"staff":
					if t > 0.42 and _once("bolt"):
						var lh := rig.marker("left_hand")
						var p := (lh.global_position if lh else tip_pos) + fwd * 0.2
						VFX.flash(world, p, fx_color, 3.0, 4.0, 0.4)
						VFX.projectile(world, p, fwd, fx_color, "bolt", 12.0, 0.55)
				"rifle":
					for i in 3:
						if t > 0.42 + i * 0.135 and _once("shot%d" % i):
							VFX.muzzle(world, tip_pos, fwd)
		&"Cast":
			match fx_kind:
				"bow":
					if t > 1.19 and _once("volley"):
						var lh := rig.marker("left_hand")
						var p := lh.global_position if lh else tip_pos
						for i in 5:
							var d := fwd.rotated(Vector3.UP, (i - 2) * 0.12)
							VFX.projectile(world, p, d, fx_color, "arrow", 12.0 + i, 0.9 + i * 0.05, 3.5)
						VFX.motes(world, global_position, fx_color, 0.8, 1.2, 30)
				_:
					if t > 0.35 and _once("charge"):
						VFX.motes(world, global_position, GOLD, 0.9, 1.6, 50)
					if t > 0.68 and _once("burst"):
						VFX.flash(world, tip_pos, fx_color, 6.0, 7.0, 1.0)
						VFX.sparks(world, tip_pos, fx_color, 40, 4.0, 0.9, 0.08, -2.0)
						VFX.ring(world, global_position, GOLD, 4.0, 0.9)
						VFX.ring(world, global_position, fx_color, 2.6, 0.7, 0.15)
		&"Command":
			if t > 0.40 and _once("order"):
				var c := GOLD if fx_kind != "rifle" else Color(1.0, 0.3, 0.2)
				VFX.chevrons(world, global_position, fwd, c, 3)
				if fx_kind != "rifle":
					VFX.flash(world, tip_pos, GOLD, 3.0, 4.0, 0.6)
		&"Hit":
			if t > 0.05 and _once("hit"):
				VFX.sparks(world, global_position + Vector3.UP * 1.3 + fwd * 0.2, Color(1, 0.55, 0.2), 20, 3.0, 0.4)
		&"Death":
			if t > 1.15 and _once("dust"):
				VFX.sparks(world, global_position + Vector3(0, 0.1, 0), Color(0.75, 0.68, 0.58, 0.8), 30, 1.5, 0.8, 0.14, -1.0)
		&"Victory":
			if t > 0.45 and _once("glory"):
				VFX.flash(world, tip_pos, GOLD, 5.0, 6.0, 1.2)
				VFX.sparks(world, tip_pos, GOLD, 50, 3.5, 1.4, 0.07, -3.0)
				VFX.motes(world, global_position, GOLD, 1.2, 2.0, 60)


func _once(key: String) -> bool:
	if _fx_done.has(key):
		return false
	_fx_done[key] = true
	return true
