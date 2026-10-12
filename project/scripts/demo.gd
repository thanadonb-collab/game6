extends Node3D
## HAUPTTÜR character showcase — wires the HUD to the player.

@onready var player: CommanderPlayer = $Player
@onready var cam_rig = $CameraRig
@onready var ui = $UI

## Characters that share the HAUPTTÜR humanoid rig & animation set.
## tip = weapon point in model space (sword tip, bow hand, staff crystal, muzzle).
const ROSTER := [
	{
		"scene": "res://characters/commander/commander.glb", "fx": "sword", "color": Color(0.45, 0.85, 1.0),
		"tip": Vector3(-0.745, 1.445, 1.02),
		"name": "จอมพลอัลดริก",
		"title": "Marshal Aldric · Royal Marshal of Elvaren",
		"role": "ฝ่ายอาณาจักร · ผู้บัญชาการกองทัพ (ตัวผู้เล่น)",
		"lore": "สวมเกราะเงินขลิบทองกับผ้าคลุมสีชาด ถือดาบรูน “แสงอรุณ” ที่เรืองแสงทุกครั้งที่ปลุกขวัญทหาร และโล่ตราตะวันของราชวงศ์ เขาคือผู้ยืนขวางประตู Haupttür ไม่ให้กองทัพจากต่างมิติบุกเข้าเมือง",
	},
	{
		"scene": "res://characters/knight/knight.glb", "fx": "sword", "color": Color(0.5, 1.0, 0.85),
		"tip": Vector3(-0.745, 1.445, 1.02),
		"labels": {"Cast": "ปลุกขวัญ"},
		"name": "เซอร์เคเลน",
		"title": "Sir Kaelen · Knight of the Silver Lion",
		"role": "ฝ่ายอาณาจักร · อัศวินแนวหน้า ระยะประชิด",
		"lore": "องครักษ์ประตูเมืองในเกราะเต็มตัว หมวกเหล็กปิดหน้า โล่ทรงว่าวตรากางเขนขาวของภาคีสิงห์เงิน ดาบยาวสลักรูนสีมรกตฟันเกราะศัตรูได้",
	},
	{
		"scene": "res://characters/archer/archer.glb", "fx": "bow", "color": Color(0.55, 1.0, 0.6),
		"tip": Vector3(0.745, 1.445, 0.0),
		"labels": {"Attack": "ยิงธนู", "Block": "หลบหลีก", "Cast": "ห่าธนูฟ้า", "Command": "ชี้เป้า"},
		"name": "ซิลเวน",
		"title": "Sylwen · Elf Ranger of the Verdant March",
		"role": "ฝ่ายอาณาจักร · นักธนูเอลฟ์ ยิงได้ทั้งภาคพื้นและอากาศ",
		"lore": "เอลฟ์ผู้เฝ้าป่าชายแดน สวมผ้าคลุมสีป่าลึก ธนูยาวประดับใบไม้เรืองแสง ท่าปลุกพลังของเธอคือการยิงห่าธนูขึ้นฟ้าให้ตกใส่ทัพศัตรู",
	},
	{
		"scene": "res://characters/mage/mage.glb", "fx": "staff", "color": Color(0.7, 0.55, 1.0),
		"tip": Vector3(-0.745, 1.445, 1.37),
		"labels": {"Attack": "ยิงลูกเวท", "Block": "ม่านพลัง", "Cast": "เวทดวงดาว", "Command": "ชี้คทา"},
		"name": "อัครจอมเวทไลรา",
		"title": "Archmage Lyra · Astral Sorceress",
		"role": "ฝ่ายอาณาจักร · เวทระยะไกล โจมตีเป็นวงกว้าง",
		"lore": "นักเวทดวงดาวแห่งสภาเวทหลวง ไม้เท้าคริสตัลรวบรวมแสงดาวยามค่ำมาเป็นลูกไฟเวท และกางม่านพลังปกป้องทหารในยามคับขัน",
	},
	{
		"scene": "res://characters/soldier/soldier.glb", "fx": "rifle", "color": Color(1.0, 0.5, 0.3),
		"tip": Vector3(-0.745, 1.50, 0.86),
		"labels": {"Attack": "ยิงปืน", "Command": "สัญญาณมือ"},
		"name": "ทหารข้ามมิติ",
		"title": "Gate Expeditionary Rifleman",
		"role": "ฝ่ายศัตรู · ทหารราบติดปืนไรเฟิลจากอีกฝั่งประตู",
		"lore": "ทหารสมัยใหม่ที่บุกผ่านประตู Haupttür สวมแว่นมองกลางคืนเรืองแสงสีแดง ยิงได้ไกลและแม่นยำ แต่ไม่เคยเจอเวทมนตร์และมังกรมาก่อน",
	},
]

## Background cast placed around the courtyard and the gate.
const EXTRAS := [
	[3, Vector3(-3.6, 0, -2.2), 0.0, ["Idle", "Attack", "Idle", "Block"]],
	[2, Vector3(3.6, 0, -2.2), 0.0, ["Idle", "Attack", "Idle", "Cast"]],
	[1, Vector3(-2.6, 0, -13.2), 0.0, ["Idle", "Block", "Idle"]],
	[1, Vector3(2.6, 0, -13.2), 0.0, ["Idle", "Attack", "Idle"]],
	[4, Vector3(-2.2, 0, -25.5), 180.0, ["Idle", "Attack", "Idle", "Command"]],
	[4, Vector3(2.4, 0, -26.0), 180.0, ["Attack", "Idle", "Walk", "Idle"]],
	[4, Vector3(0.2, 0, -27.0), 180.0, ["Command", "Idle", "Attack"]],
]

const SHOWCASE := [
	[&"Idle", 2.5], [&"Walk", 3.2], [&"Run", 2.6], [&"Attack", 0.0], [&"Block", 2.4],
	[&"Cast", 0.0], [&"Command", 0.0], [&"Hit", 0.0], [&"Victory", 0.0], [&"Death", 2.6],
]

var roster := []
var index := 0
var auto := false
var _step := 0
var _wait := 0.0
var _waiting_action := false


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-34, -28, 0)
	for r in ROSTER:
		if ResourceLoader.exists(r.scene):
			roster.append(r)
	ui.anim_requested.connect(_on_anim)
	ui.character_step.connect(func(d): _select((index + d + roster.size()) % roster.size()))
	ui.auto_toggled.connect(_set_auto)
	ui.turntable_toggled.connect(func(on): cam_rig.turntable = on)
	ui.run_toggled.connect(func(on): player.run_toggle = on)
	ui.speed_changed.connect(func(v): Engine.time_scale = v)
	ui.zoom.connect(func(d): cam_rig.zoom_by(d))
	player.state_changed.connect(func(s): ui.set_state(s))
	player.rig.action_finished.connect(_on_action_done)
	_spawn_extras()
	_select(0)
	# start with the auto showcase so a first-time visitor sees every pose
	_set_auto(true)
	ui.set_auto(true)


func _spawn_extras() -> void:
	var npc_script := load("res://scripts/npc.gd")
	for e in EXTRAS:
		var r: Dictionary = ROSTER[e[0]]
		if not ResourceLoader.exists(r.scene):
			continue
		var n := Node3D.new()
		n.set_script(npc_script)
		n.model_scene = load(r.scene)
		n.sequence = PackedStringArray(e[3])
		n.tip = r.tip
		n.fx_kind = r.fx
		n.fx_color = r.color
		n.position = e[1]
		n.rotation_degrees.y = e[2]
		add_child(n)


func _select(i: int) -> void:
	index = i
	_step = 0
	_waiting_action = false
	_wait = 0.4
	var r: Dictionary = roster[i]
	player.revive()
	player.fx_kind = r.fx
	player.fx_color = r.color
	player.rig.sword_tip = r.tip
	player.rig.model_scene = load(r.scene)
	var anims := player.rig.anim.get_animation_list() if player.rig.anim else PackedStringArray()
	var av := []
	for a in anims:
		av.append(StringName(a))
	ui.set_character(r.name, r.title, r.role, r.lore, av, r.get("labels", {}))
	ui.set_state("Idle")


func _on_anim(n: StringName) -> void:
	if auto:
		_set_auto(false)
		ui.set_auto(false)
	_play(n)


func _play(n: StringName) -> void:
	if n in [&"Idle", &"Walk", &"Run", &"Block"]:
		player.force_block = false
		if n == &"Block":
			player.force_block = true
			player.show_loop(&"Block")
		else:
			player.show_loop(n)
	else:
		player.force_block = false
		player.do_action(n)


func _set_auto(on: bool) -> void:
	auto = on
	_step = 0
	_wait = 0.0
	_waiting_action = false
	if not on:
		player.force_block = false
	else:
		_next()


func _next() -> void:
	var item = SHOWCASE[_step % SHOWCASE.size()]
	_step += 1
	for k in SHOWCASE.size():
		if player.rig.has_anim(item[0]):
			break
		item = SHOWCASE[_step % SHOWCASE.size()]
		_step += 1
	var n: StringName = item[0]
	if n == &"Death" and player.dead:
		player.revive()
	if player.dead:
		player.revive()
	_play(n)
	if item[1] > 0.0:
		_wait = item[1]
		_waiting_action = false
	else:
		_wait = 0.0
		_waiting_action = true


func _on_action_done(n: StringName) -> void:
	if auto and _waiting_action:
		_waiting_action = false
		_wait = 0.35


func _process(delta: float) -> void:
	if not auto:
		return
	if _waiting_action:
		return
	_wait -= delta
	if _wait <= 0.0:
		if player.dead:
			player.revive()
			_wait = 1.0
			return
		_next()
