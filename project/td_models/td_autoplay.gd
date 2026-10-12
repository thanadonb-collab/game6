extends Node3D
## Loops one clip on the imported character (used by enemy units, whose
## enemy.gd does not drive animations). Defenders are driven by defender.gd.
@export var clip: StringName = &"Walk"
@export var speed := 1.0

func _ready() -> void:
	var ap := find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation(clip):
		ap.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		ap.speed_scale = speed
		ap.play(clip)
