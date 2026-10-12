extends CanvasLayer
## Showcase HUD — built in code so it's easy to restyle.

signal anim_requested(anim_name: StringName)
signal character_step(dir: int)
signal auto_toggled(on: bool)
signal turntable_toggled(on: bool)
signal run_toggled(on: bool)
signal speed_changed(v: float)
signal zoom(d: float)

const GOLD := Color(1.0, 0.80, 0.38)
const INK := Color(0.06, 0.07, 0.12, 0.82)
const EDGE := Color(0.85, 0.66, 0.28)

## name, Thai label, key hint
const ANIMS := [
	[&"Idle", "ยืนพัก", "—"],
	[&"Walk", "เดิน", "WASD"],
	[&"Run", "วิ่ง", "Shift"],
	[&"Attack", "ฟันดาบ", "J"],
	[&"Block", "ยกโล่ป้องกัน", "K"],
	[&"Cast", "ปลุกขวัญทัพ", "Q"],
	[&"Command", "สั่งการทัพ", "E"],
	[&"Hit", "ถูกโจมตี", "H"],
	[&"Death", "พ่ายแพ้", "X"],
	[&"Victory", "ฉลองชัย", "V"],
]

var theme_res: Theme
var name_lbl: Label
var title_lbl: Label
var role_lbl: Label
var lore_lbl: Label
var state_lbl: Label
var buttons := {}
var auto_btn: CheckButton
var root: Control
var anim_panel: Control
var help_panel: Control


func _ready() -> void:
	theme_res = _make_theme()
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme_res
	add_child(root)
	_build_title()
	_build_card()
	_build_anim_panel()
	_build_help()


# ------------------------------------------------------------------ theme
func _make_theme() -> Theme:
	var t := Theme.new()
	var latin: FontFile = load("res://fonts/kanit-latin-400-normal.woff2")
	var thai: FontFile = load("res://fonts/kanit-thai-400-normal.woff2")
	var latin_b: FontFile = load("res://fonts/kanit-latin-600-normal.woff2")
	var thai_b: FontFile = load("res://fonts/kanit-thai-600-normal.woff2")
	var f := FontVariation.new()
	f.base_font = latin
	f.fallbacks = [thai]
	var fb := FontVariation.new()
	fb.base_font = latin_b
	fb.fallbacks = [thai_b]
	t.default_font = f
	t.default_font_size = 17
	t.set_font("font", "TitleLabel", fb)
	t.set_type_variation("TitleLabel", "Label")
	t.set_font("font", "Button", fb)
	var panel := StyleBoxFlat.new()
	panel.bg_color = INK
	panel.border_color = EDGE
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(10)
	panel.set_content_margin_all(14)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 8
	t.set_stylebox("panel", "PanelContainer", panel)
	var bn := StyleBoxFlat.new()
	bn.bg_color = Color(0.13, 0.17, 0.32, 0.95)
	bn.border_color = Color(0.55, 0.45, 0.25)
	bn.set_border_width_all(1)
	bn.set_corner_radius_all(7)
	bn.content_margin_left = 10
	bn.content_margin_right = 10
	bn.content_margin_top = 6
	bn.content_margin_bottom = 6
	var bh := bn.duplicate() as StyleBoxFlat
	bh.bg_color = Color(0.20, 0.27, 0.50, 0.98)
	bh.border_color = GOLD
	var bp := bn.duplicate() as StyleBoxFlat
	bp.bg_color = Color(0.55, 0.40, 0.12, 0.98)
	bp.border_color = GOLD
	t.set_stylebox("normal", "Button", bn)
	t.set_stylebox("hover", "Button", bh)
	t.set_stylebox("pressed", "Button", bp)
	t.set_stylebox("hover_pressed", "Button", bp)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color(0.95, 0.93, 0.88))
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_pressed_color", "Button", Color(1, 0.97, 0.85))
	t.set_color("font_color", "Label", Color(0.93, 0.91, 0.86))
	t.set_color("font_color", "CheckButton", Color(0.93, 0.91, 0.86))
	t.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	return t


func _panel(anchor: int, offset: Vector2, min_w := 0.0) -> VBoxContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size.x = min_w
	root.add_child(p)
	p.set_anchors_and_offsets_preset(anchor, Control.PRESET_MODE_MINSIZE)
	p.position = offset
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	p.set_meta("vbox", v)
	return v


func _label(parent: Node, text: String, size := 17, color := Color(0.93, 0.91, 0.86), bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.theme_type_variation = "TitleLabel"
	parent.add_child(l)
	return l


# ------------------------------------------------------------------ blocks
func _build_title() -> void:
	var v := _panel(Control.PRESET_TOP_LEFT, Vector2(16, 16))
	var h := HBoxContainer.new()
	v.add_child(h)
	_label(h, "HAUPTTÜR", 34, GOLD, true)
	var sub := _label(h, "  Character Showcase", 16, Color(0.75, 0.75, 0.82))
	sub.size_flags_vertical = Control.SIZE_SHRINK_END
	_label(v, "ตัวละครฝ่ายอาณาจักร · ทดสอบท่าทางใน Godot", 15, Color(0.8, 0.8, 0.86))


func _build_card() -> void:
	var v := _panel(Control.PRESET_TOP_LEFT, Vector2(16, 128), 330)
	var sw := HBoxContainer.new()
	v.add_child(sw)
	var prev := Button.new()
	prev.text = " < "
	prev.pressed.connect(func(): character_step.emit(-1))
	sw.add_child(prev)
	name_lbl = _label(sw, "", 24, GOLD, true)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var nxt := Button.new()
	nxt.text = " > "
	nxt.pressed.connect(func(): character_step.emit(1))
	sw.add_child(nxt)
	title_lbl = _label(v, "", 15, Color(0.75, 0.8, 0.95))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_lbl = _label(v, "", 16)
	role_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role_lbl.custom_minimum_size.x = 300
	lore_lbl = _label(v, "", 14, Color(0.78, 0.78, 0.8))
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.custom_minimum_size.x = 300
	var sep := HSeparator.new()
	v.add_child(sep)
	state_lbl = _label(v, "ท่าทาง: ยืนพัก", 16, GOLD)


var labels := {}


func set_character(display: String, title: String, role: String, lore: String, available: Array, overrides := {}) -> void:
	name_lbl.text = display
	title_lbl.text = title
	role_lbl.text = role
	lore_lbl.text = lore
	role_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5) if role.begins_with("ฝ่ายศัตรู") else Color(0.93, 0.91, 0.86))
	labels.clear()
	for a in ANIMS:
		var n: StringName = a[0]
		labels[n] = overrides.get(String(n), a[1])
		if buttons.has(n):
			buttons[n].text = "%s  [%s]" % [labels[n], a[2]]
			buttons[n].disabled = not (n in available)


func set_state(anim_name: String) -> void:
	var n := StringName(anim_name)
	if labels.has(n):
		state_lbl.text = "ท่าทาง: %s (%s)" % [labels[n], anim_name]
		return
	state_lbl.text = "ท่าทาง: " + anim_name


func _build_anim_panel() -> void:
	var p := PanelContainer.new()
	root.add_child(p)
	anim_panel = p
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	_label(v, "ท่าทาง · Animations", 19, GOLD, true)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for a in ANIMS:
		var b := Button.new()
		b.text = "%s  [%s]" % [a[1], a[2]]
		b.custom_minimum_size = Vector2(150, 40)
		b.tooltip_text = String(a[0])
		var n: StringName = a[0]
		b.pressed.connect(func(): anim_requested.emit(n))
		grid.add_child(b)
		buttons[n] = b
	v.add_child(HSeparator.new())
	auto_btn = CheckButton.new()
	auto_btn.text = "โชว์ทุกท่าอัตโนมัติ"
	auto_btn.toggled.connect(func(on): auto_toggled.emit(on))
	v.add_child(auto_btn)
	var tt := CheckButton.new()
	tt.text = "หมุนกล้องรอบตัวละคร"
	tt.toggled.connect(func(on): turntable_toggled.emit(on))
	v.add_child(tt)
	var rt := CheckButton.new()
	rt.text = "โหมดวิ่ง (สำหรับจอสัมผัส)"
	rt.toggled.connect(func(on): run_toggled.emit(on))
	v.add_child(rt)
	var sh := HBoxContainer.new()
	v.add_child(sh)
	_label(sh, "ความเร็ว", 15)
	var sl := HSlider.new()
	sl.min_value = 0.25
	sl.max_value = 1.5
	sl.step = 0.05
	sl.value = 1.0
	sl.custom_minimum_size.x = 150
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(sl)
	var sv := _label(sh, "1.00x", 15, GOLD)
	sl.value_changed.connect(func(x):
		sv.text = "%.2fx" % x
		speed_changed.emit(x))
	var zh := HBoxContainer.new()
	v.add_child(zh)
	_label(zh, "ซูม", 15)
	for z in [["-", 1.0], ["+", -1.0]]:
		var zb := Button.new()
		zb.text = z[0]
		zb.custom_minimum_size = Vector2(44, 34)
		var d: float = z[1]
		zb.pressed.connect(func(): zoom.emit(d))
		zh.add_child(zb)
	p.reset_size()
	p.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)


func set_auto(on: bool) -> void:
	auto_btn.set_pressed_no_signal(on)


func _build_help() -> void:
	var p := PanelContainer.new()
	root.add_child(p)
	help_panel = p
	var l := Label.new()
	l.text = "WASD / ลูกศร = เดิน   Shift = วิ่ง   คลิก/แตะพื้น = เดินไปจุดนั้น   ลาก = หมุนกล้อง   ล้อเมาส์ = ซูม   R = ฟื้นคืน"
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	p.add_child(l)
	p.reset_size()
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 14)
