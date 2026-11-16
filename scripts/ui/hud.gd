class_name Hud
extends Control
## Portrait, health and bells (top left), objective (top right), gadget bar (bottom), messages.

const PANEL := Color(0.07, 0.11, 0.24, 0.86)
const PANEL_EDGE := Color("#3b6fd0")

var player: Player
var bells := 0
var bells_total := 0
var title := ""
var level_name := ""
## Set by boss levels to show the boss health bar.
var boss: Boss
var subtitle := ""
## [max_x, text] pairs: the first whose max_x is past the player gives the objective.
var objectives: Array = []
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_message(t: String, s := "") -> void:
	title = t
	subtitle = s


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var font := ThemeDB.fallback_font
	_draw_status(font)
	_draw_objective(font)
	_draw_slots(font)
	if boss != null and is_instance_valid(boss):
		_draw_boss_bar(font)
	if _t < 3.5 and level_name != "":
		var a := clampf(minf(_t * 3.0, (3.5 - _t) * 2.0), 0.0, 1.0)
		var w := font.get_string_size(level_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x + 60.0
		var box := Rect2(size.x * 0.5 - w * 0.5, 160, w, 64)
		draw_style_box(Paint.box(Color(PANEL, PANEL.a * a), 16.0, Color(PANEL_EDGE, a), 2.0, 6.0), box)
		_text_centered(font, level_name, Vector2(size.x * 0.5, box.position.y + 44), 34, Color(1.0, 0.82, 0.25, a))
	_text(font, "A/D move · W/Space jump · LMB use · RMB alt · 1-3/wheel switch · E door · R restart · Esc loadout",
		Vector2(14, size.y - 8), 12, Color(1, 1, 1, 0.75))
	if title != "":
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.1, 0.6))
		var box := Rect2(size.x * 0.5 - 330, size.y * 0.5 - 90, 660, 150)
		draw_style_box(Paint.box(PANEL, 18.0, PANEL_EDGE, 3.0, 10.0), box)
		_text_centered(font, title, Vector2(size.x * 0.5, box.position.y + 68), 44, Color("#ffd23f"))
		_text_centered(font, subtitle, Vector2(size.x * 0.5, box.position.y + 112), 17, Color(0.9, 0.93, 1.0))


func _draw_status(font: Font) -> void:
	var panel := Rect2(12, 12, 300, 82)
	draw_style_box(Paint.box(PANEL, 16.0, PANEL_EDGE, 2.0, 6.0), panel)
	var pc := Vector2(52, 53)
	Paint.circle(self, pc, 32.0, Color.WHITE, Paint.INK, 2.5)
	Paint.circle(self, pc, 28.0, Color("#bfe6ff"), Paint.INK, 0.0)
	draw_set_transform(pc + Vector2(-2, 4), 0.0, Vector2(1.35, 1.35))
	Paint.head(self, Vector2.ZERO, false, player.health <= 0, player.health > 0)
	draw_set_transform(Vector2.ZERO)
	for i in player.max_health:
		var full := i < player.health
		_heart(Vector2(106 + i * 30, 36), 10.0, Color("#ff3d5e") if full else Color("#2a3352"))
	var bar := Rect2(94, 56, 200, 10)
	draw_style_box(Paint.box(Color("#0c1430"), 5.0, Paint.INK, 1.5), bar)
	var cape_ratio := player.invisible_left / InvisibilityCape.DURATION if player.is_invisible else 0.0
	var hp_ratio := float(player.health) / player.max_health
	var fill := Rect2(bar.position + Vector2(2, 2), Vector2((bar.size.x - 4) * (cape_ratio if player.is_invisible else hp_ratio), 6))
	if fill.size.x > 1.0:
		draw_style_box(Paint.box(Color("#b39ddb") if player.is_invisible else Color("#36c2ff"), 3.0, Color(0, 0, 0, 0), 0.0), fill)
	if bells_total > 0:
		Paint.circle(self, Vector2(102, 82), 7.0, Paint.BELL, Paint.INK, 1.5)
		_text(font, "%d / %d" % [bells, bells_total], Vector2(114, 88), 15, Color.WHITE)
	if player.is_invisible:
		_text(font, "INVISIBLE", Vector2(200, 88), 13, Color("#e1d5ff"))


func _draw_boss_bar(font: Font) -> void:
	var w := 520.0
	var box := Rect2(size.x * 0.5 - w * 0.5, 84, w, 46)
	draw_style_box(Paint.box(PANEL, 14.0, Color("#d0453a"), 2.0, 6.0), box)
	_text_centered(font, boss.display_name, Vector2(size.x * 0.5, box.position.y + 18), 14, Color("#ffd23f"))
	var bar := Rect2(box.position.x + 14.0, box.position.y + 26.0, w - 28.0, 12)
	draw_style_box(Paint.box(Color("#0c1430"), 6.0, Paint.INK, 1.5), bar)
	var ratio := clampf(boss.health / boss.max_health, 0.0, 1.0)
	if ratio > 0.0:
		var fill := Rect2(bar.position + Vector2(2, 2), Vector2((bar.size.x - 4.0) * ratio, 8))
		draw_style_box(Paint.box(Color("#a855f7") if boss.phase_two else Color("#ff4d3a"), 4.0, Color(0, 0, 0, 0), 0.0), fill)
	draw_line(Vector2(bar.position.x + bar.size.x * 0.5, bar.position.y), Vector2(bar.position.x + bar.size.x * 0.5, bar.end.y), Color(1, 1, 1, 0.5), 1.5)


func _draw_objective(font: Font) -> void:
	var text := ""
	for o in objectives:
		if player.global_position.x < float(o[0]):
			text = o[1]
			break
	if text == "":
		return
	var w := maxf(330.0, font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 64.0)
	var box := Rect2(size.x - w - 12.0, 12, w, 56)
	draw_style_box(Paint.box(PANEL, 14.0, PANEL_EDGE, 2.0, 6.0), box)
	var ic := box.position + Vector2(24, 28)
	Paint.circle(self, ic, 12.0, Color("#ffd23f"), Paint.INK, 2.0)
	_text_centered(font, "!", ic + Vector2(0, 6), 17, Paint.INK, false)
	_text(font, "Objective", box.position + Vector2(46, 22), 13, Color("#ffd23f"))
	_text(font, text, box.position + Vector2(46, 42), 14, Color.WHITE)


func _draw_slots(font: Font) -> void:
	var n := player.gadgets.size()
	if n == 0:
		return
	var w := 92.0
	var gap := 12.0
	var x0 := (size.x - (n * w + (n - 1) * gap)) * 0.5
	var y0 := size.y - w - 40.0
	var bar := Rect2(x0 - 14.0, y0 - 12.0, n * w + (n - 1) * gap + 28.0, w + 36.0)
	draw_style_box(Paint.box(PANEL, 18.0, PANEL_EDGE, 2.0, 6.0), bar)
	for i in n:
		var g := player.gadgets[i]
		var r := Rect2(x0 + i * (w + gap), y0, w, w - 18.0)
		var active := i == player.active_slot
		if active:
			var pulse := 0.5 + 0.5 * sin(_t * 5.0)
			draw_style_box(Paint.box(Color(0, 0, 0, 0), 14.0, Color(g.color, 0.4 + 0.3 * pulse), 4.0), r.grow(3.0))
		draw_style_box(Paint.box(Color("#1a2a55") if active else Color("#111a36"), 12.0, g.color if active else Color("#2c3b6b"), 2.5), r)
		Paint.gadget_icon(self, g.id, r.get_center() + Vector2(0, -2), 50.0)
		if g.cooldown_left > 0.0:
			var h := r.size.y * g.cooldown_ratio()
			draw_style_box(Paint.box(Color(0, 0, 0, 0.55), 12.0, Color(0, 0, 0, 0), 0.0), Rect2(r.position.x, r.end.y - h, r.size.x, h))
		Paint.circle(self, r.position + Vector2(12, 12), 10.0, g.color, Paint.INK, 1.5)
		_text_centered(font, str(i + 1), r.position + Vector2(12, 17), 13, Paint.INK, false)
		_text_centered(font, g.display_name, Vector2(r.get_center().x, r.end.y + 15.0), 12, Color.WHITE if active else Color(0.75, 0.8, 0.9))
		var status := g.get_status()
		if status != "":
			_text_centered(font, status, Vector2(r.get_center().x, r.end.y - 6.0), 11, Color("#cfe3ff"))
	var ag := player.active_gadget()
	if ag != null:
		_text_centered(font, Game.GADGETS[ag.id]["help"], Vector2(size.x * 0.5, bar.position.y - 10.0), 14, Color.WHITE)


func _heart(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var t := TAU * i / 32.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(c + Vector2(x, y) * r / 16.0)
	var outline := PackedVector2Array()
	for p in pts:
		outline.append(c + (p - c) * 1.22)
	draw_colored_polygon(outline, Paint.INK)
	draw_colored_polygon(pts, col)
	draw_circle(c + Vector2(-r * 0.4, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.5))


func _text(font: Font, s: String, pos: Vector2, fs: int, col: Color, outline := true) -> void:
	if outline:
		draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(Paint.INK, 0.9))
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _text_centered(font: Font, s: String, pos: Vector2, fs: int, col: Color, outline := true) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_text(font, s, pos - Vector2(w * 0.5, 0), fs, col, outline)
