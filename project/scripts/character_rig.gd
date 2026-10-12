class_name CharacterRig
extends Node3D
## Wraps an imported HAUPTTÜR character (.glb exported from Blender) and
## exposes animation helpers plus attachment points (sword tip, hands, head).
##
## The .glb faces +Z (glTF convention); this node turns it to face -Z, which is
## Godot's forward direction and what the tower-defense scenes expect.

signal action_finished(anim_name: StringName)

const LOOPING := [&"Idle", &"Walk", &"Run", &"Block"]
const BONE_PREFIX := "mixamorig_"

@export var model_scene: PackedScene:
	set(v):
		model_scene = v
		if is_inside_tree():
			_rebuild()
@export var model_scale := 1.0
## Character points in model space (glTF/Godot axes, before the 180° turn).
@export var sword_tip := Vector3(-0.745, 1.445, 1.02)

var model: Node3D
var anim: AnimationPlayer
var skeleton: Skeleton3D
var markers := {}
var current: StringName = &""


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if model:
		model.queue_free()
		model = null
	markers.clear()
	if model_scene == null:
		return
	model = model_scene.instantiate()
	add_child(model)
	model.rotation.y = PI
	model.scale = Vector3.ONE * model_scale
	anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var sks := model.find_children("*", "Skeleton3D", true, false)
	skeleton = sks[0] if sks.size() > 0 else null
	if anim:
		for n in anim.get_animation_list():
			var a := anim.get_animation(n)
			a.loop_mode = Animation.LOOP_LINEAR if StringName(n) in LOOPING else Animation.LOOP_NONE
		if not anim.animation_finished.is_connected(_on_finished):
			anim.animation_finished.connect(_on_finished)
	if skeleton:
		var tip_bone := "LeftHand" if sword_tip.x > 0 else "RightHand"
		markers["sword_tip"] = attach(tip_bone, sword_tip)
		markers["tip"] = markers["sword_tip"]
		markers["right_hand"] = attach("RightHand", Vector3(-0.745, 1.445, 0.0))
		markers["left_hand"] = attach("LeftHand", Vector3(0.745, 1.445, 0.0))
		markers["shield"] = attach("LeftForeArm", Vector3(0.56, 1.53, 0.0))
		markers["head"] = attach("Head", Vector3(0, 1.84, 0))
		markers["chest"] = attach("Spine2", Vector3(0, 1.32, 0.17))
	play(&"Idle")


## Creates a marker that follows `bone` and sits at `model_point` (rest pose).
func attach(bone: String, model_point: Vector3) -> Node3D:
	var idx := skeleton.find_bone(BONE_PREFIX + bone)
	if idx < 0:
		return null
	var ba := BoneAttachment3D.new()
	ba.name = "Attach_" + bone
	skeleton.add_child(ba)
	ba.bone_name = skeleton.get_bone_name(idx)
	var m := Marker3D.new()
	ba.add_child(m)
	var rest := skeleton.get_bone_global_rest(idx)
	m.transform = rest.affine_inverse() * Transform3D(Basis(), model_point)
	return m


func marker(name: String) -> Node3D:
	return markers.get(name)


func has_anim(n: StringName) -> bool:
	return anim != null and anim.has_animation(n)


func play(n: StringName, blend := 0.18, speed := 1.0, restart := false) -> void:
	if not has_anim(n):
		return
	if current == n and not restart and anim.is_playing():
		anim.speed_scale = speed
		return
	current = n
	anim.speed_scale = speed
	if restart:
		anim.stop()
	anim.play(n, blend)


func anim_length(n: StringName) -> float:
	return anim.get_animation(n).length if has_anim(n) else 0.0


func position_in_anim() -> float:
	return anim.current_animation_position if anim else 0.0


func _on_finished(n: StringName) -> void:
	action_finished.emit(n)
