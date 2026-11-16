extends Control
## Pick 1 attack gadget and 2 utility gadgets before the level starts.

var _selected: Array[String] = []
var _cards := {}
var _status: Label
var _start: Button
var _level_buttons: Array[Button] = []
var _mission: Label


class Art extends Control:
	## Menu background: night-blue sky, city skyline, Doraemon waving.
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		var steps := 24
		for i in steps:
			var c := Color("#1a3a7a").lerp(Color("#4a86d0"), float(i) / steps)
			draw_rect(Rect2(0, size.y * i / steps, size.x, size.y / steps + 1.0), c)
		for i in 60:
			var p := Vector2(rng.randf() * size.x, rng.randf() * size.y * 0.5)
			draw_circle(p, rng.randf_range(0.8, 1.8), Color(1, 1, 1, 0.3 + 0.3 * sin(t * 2.0 + i)))
		var x := -20.0
		while x < size.x:
			var w := rng.randf_range(40, 90)
			var h := rng.randf_range(60, 170)
			draw_rect(Rect2(x, size.y - h, w, h), Color("#17306a"))
			var wy := size.y - h + 10.0
			while wy < size.y - 10.0:
				var wx := x + 6.0
				while wx < x + w - 8.0:
					if rng.randf() < 0.35:
						draw_rect(Rect2(wx, wy, 5, 7), Color(1.0, 0.85, 0.45, 0.6))
					wx += 12.0
				wy += 16.0
			x += w + 6.0
		var feet := Vector2(size.x - 120.0, size.y - 48.0)
		var k := 2.2
		draw_set_transform(feet, 0.0, Vector2(k, k))
		Paint.shadow(self, Vector2.ZERO, 16.0)
		draw_set_transform(feet + Vector2(0, -absf(sin(t * 2.5)) * 6.0), 0.0, Vector2(-k, k))
		Paint.doraemon(self, 0.0, 0.0, false, fmod(t, 3.5) < 0.12, false, 0.2 + 0.2 * sin(t * 7.0))
		draw_set_transform(Vector2.ZERO)


class Icon extends Control:
	var id := ""

	func _draw() -> void:
		Paint.gadget_icon(self, id, size * 0.5, 64.0)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := Art.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var title := _label("DORAEMON", 48, Color("#4fc3f7"))
	title.add_theme_color_override("font_outline_color", Color("#0b1530"))
	title.add_theme_constant_override("outline_size", 14)
	root.add_child(title)
	var sub := _label("GADGET CHAOS", 34, Color("#ffd23f"))
	sub.add_theme_color_override("font_outline_color", Color("#7a3d00"))
	sub.add_theme_constant_override("outline_size", 12)
	root.add_child(sub)
	var levels := HBoxContainer.new()
	levels.alignment = BoxContainer.ALIGNMENT_CENTER
	levels.add_theme_constant_override("separation", 10)
	root.add_child(levels)
	var group := ButtonGroup.new()
	for i in Game.LEVELS.size():
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(150, 36)
		b.add_theme_font_size_override("font_size", 16)
		var unlocked := Game.is_unlocked(i)
		b.text = Game.LEVELS[i]["short"] if unlocked else Game.LEVELS[i]["short"] + " (locked)"
		b.disabled = not unlocked
		b.add_theme_stylebox_override("normal", _box(Color(0.07, 0.11, 0.24, 0.9), Color("#2c3b6b")))
		b.add_theme_stylebox_override("hover", _box(Color(0.1, 0.16, 0.34, 0.95), Color("#4fc3f7")))
		b.add_theme_stylebox_override("pressed", _box(Color("#1b4f8a"), Color("#4fc3f7")))
		b.add_theme_stylebox_override("hover_pressed", _box(Color("#1f5a9c"), Color("#4fc3f7")))
		b.add_theme_stylebox_override("disabled", _box(Color(0.05, 0.08, 0.16, 0.7), Color("#1c2547")))
		b.set_pressed_no_signal(i == Game.selected_level)
		b.toggled.connect(func(on: bool) -> void: _on_level_toggled(i, on))
		levels.add_child(b)
		_level_buttons.append(b)
	_mission = _label("", 16, Color(0.85, 0.88, 0.95))
	root.add_child(_mission)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	root.add_child(row)
	for id in Game.GADGET_ORDER:
		row.add_child(_make_card(id))

	_status = _label("", 18, Color.WHITE)
	root.add_child(_status)

	var start_row := HBoxContainer.new()
	start_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(start_row)
	_start = Button.new()
	_start.custom_minimum_size = Vector2(300, 52)
	_start.add_theme_font_size_override("font_size", 20)
	_start.add_theme_stylebox_override("normal", _box(Color("#f2a22a"), Color("#7a3d00")))
	_start.add_theme_stylebox_override("hover", _box(Color("#ffb846"), Color("#7a3d00")))
	_start.add_theme_stylebox_override("pressed", _box(Color("#d98a14"), Color("#7a3d00")))
	_start.add_theme_stylebox_override("disabled", _box(Color(0.2, 0.24, 0.35, 0.9), Color("#2c3b6b")))
	_start.add_theme_color_override("font_color", Color("#2a1600"))
	_start.add_theme_color_override("font_hover_color", Color("#2a1600"))
	_start.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
	_start.pressed.connect(_start_level)
	start_row.add_child(_start)

	root.add_child(_label("A/D move · W/Space jump · mouse aim · LMB use gadget · RMB alternate · 1-3 or wheel switch gadget", 14, Color(0.7, 0.75, 0.85)))

	for id in Game.loadout:
		if _cards.has(id):
			_selected.append(id)
			(_cards[id] as Button).set_pressed_no_signal(true)
	_refresh()


func _label(text: String, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	return l


func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	return sb


func _make_card(id: String) -> Button:
	var info: Dictionary = Game.GADGETS[id]
	var col: Color = info["color"]
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(216, 262)
	b.add_theme_stylebox_override("normal", _box(Color(0.07, 0.11, 0.24, 0.9), Color("#2c3b6b")))
	b.add_theme_stylebox_override("hover", _box(Color(0.1, 0.16, 0.34, 0.95), col.darkened(0.2)))
	b.add_theme_stylebox_override("pressed", _box(col.darkened(0.62), col))
	b.add_theme_stylebox_override("hover_pressed", _box(col.darkened(0.55), col))

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 8)
	b.add_child(v)

	var icon := Icon.new()
	icon.id = id
	icon.custom_minimum_size = Vector2(0, 76)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	var title := _label(info["name"], 21, col)
	v.add_child(title)
	var is_attack: bool = info["type"] == "attack"
	v.add_child(_label("ATTACK" if is_attack else "UTILITY", 13, Color("#ff8a80") if is_attack else Color("#a5d6a7")))
	var desc := _label(info["desc"], 14, Color(0.92, 0.94, 1))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(186, 0)
	v.add_child(desc)

	b.toggled.connect(func(on: bool) -> void: _on_card_toggled(id, on))
	_cards[id] = b
	return b


func _on_card_toggled(id: String, on: bool) -> void:
	if not on:
		_selected.erase(id)
		_refresh()
		return
	if Game.GADGETS[id]["type"] == "attack":
		# Only one attack gadget: picking another swaps it in.
		for other in _selected.duplicate():
			if Game.GADGETS[other]["type"] == "attack":
				_selected.erase(other)
				(_cards[other] as Button).set_pressed_no_signal(false)
	elif Game.count_type(_selected, "utility") >= 2:
		(_cards[id] as Button).set_pressed_no_signal(false)
		_refresh()
		_status.text = "Only 2 Utility gadgets. Deselect one first."
		_status.add_theme_color_override("font_color", Color("#ffab91"))
		return
	_selected.append(id)
	_refresh()


func _refresh() -> void:
	var level_name: String = Game.LEVELS[Game.selected_level]["name"]
	_mission.text = "%s  ·  Choose 1 Attack gadget and 2 Utility gadgets." % level_name
	var total: int = Game.LEVELS[Game.selected_level]["bells"].size()
	if total > 0:
		_mission.text += "  ·  Golden Bells for this loadout: %d" % Game.reachable_bells(Game.selected_level, _selected)
	_start.text = "Start %s  (Enter)" % Game.LEVELS[Game.selected_level]["short"]
	var valid := Game.is_valid_loadout(_selected)
	_start.disabled = not valid
	var msg := "Attack %d / 1   ·   Utility %d / 2" % [Game.count_type(_selected, "attack"), Game.count_type(_selected, "utility")]
	var col := Color.WHITE
	if valid:
		msg += "  —  ready!"
		col = Color("#a5d6a7")
	_status.text = msg
	_status.add_theme_color_override("font_color", col)


func _on_level_toggled(index: int, on: bool) -> void:
	if on:
		Game.selected_level = index
		_refresh()


func _start_level() -> void:
	if not Game.is_valid_loadout(_selected):
		return
	Game.loadout.assign(_selected)
	Game.start_level()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		_start_level()
