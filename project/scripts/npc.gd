extends Node3D
## Background character that loops through a list of clips (guards, gate soldiers).

@export var model_scene: PackedScene
@export var sequence: PackedStringArray = PackedStringArray(["Idle"])
@export var loop_hold := 3.5
@export var tip := Vector3(-0.745, 1.445, 1.02)
@export var fx_kind := ""
@export var fx_color := Color(1, 0.7, 0.3)

var rig: CharacterRig
var _i := 0
var _wait := 0.0
var _t := 0.0
var _fired := {}


func _ready() -> void:
	rig = CharacterRig.new()
	rig.sword_tip = tip
	rig.model_scene = model_scene
	add_child(rig)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	body.add_child(cs)
	add_child(body)
	_i = randi() % sequence.size()
	_wait = randf_range(0.2, 2.0)


func _process(delta: float) -> void:
	_t += delta
	_wait -= delta
	_fx()
	if _wait > 0.0:
		return
	var n := StringName(sequence[_i % sequence.size()])
	_i += 1
	_fired.clear()
	_t = 0.0
	rig.play(n, 0.25, 1.0, true)
	_wait = loop_hold if n in CharacterRig.LOOPING else rig.anim_length(n) + 0.4


func _fx() -> void:
	if rig.current != &"Attack" or fx_kind == "":
		return
	var tipm := rig.marker("tip")
	if tipm == null:
		return
	var fwd := -global_transform.basis.z
	var world := get_parent() as Node3D
	match fx_kind:
		"rifle":
			for i in 3:
				var k := "s%d" % i
				if _t > 0.42 + i * 0.135 and not _fired.has(k):
					_fired[k] = true
					VFX.muzzle(world, tipm.global_position, fwd)
		"bow":
			if _t > 0.86 and not _fired.has("a"):
				_fired["a"] = true
				var lh := rig.marker("left_hand")
				VFX.projectile(world, lh.global_position, fwd, fx_color, "arrow", 16.0, 0.45)
		"staff":
			if _t > 0.42 and not _fired.has("b"):
				_fired["b"] = true
				var lh := rig.marker("left_hand")
				VFX.projectile(world, lh.global_position + fwd * 0.2, fwd, fx_color, "bolt", 12.0, 0.55)
