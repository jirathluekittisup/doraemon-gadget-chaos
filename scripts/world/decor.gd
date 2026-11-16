class_name Decor
extends Node2D
## Non-solid scenery. Position is the top-left corner of `size`.
## kind: "interior", "ac_unit", "water_tank", "billboard", "factory_gate", "cage".

var kind := "interior"
var size := Vector2(100, 100)
## Cage only: Nobita has been freed.
var opened := false
var _t := 0.0


func _ready() -> void:
	z_index = 1 if kind == "cage" else -5
	set_process(kind in ["cage", "ac_unit"])


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		"interior":
			_draw_interior()
		"ac_unit":
			_draw_ac_unit()
		"water_tank":
			_draw_water_tank()
		"billboard":
			_draw_billboard()
		"factory_gate":
			_draw_factory_gate()
		"cage":
			_draw_cage()


func _draw_interior() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#cdbf9f"))
	var x := 0.0
	while x < size.x:
		draw_rect(Rect2(x, 0, 12, size.y), Color("#c3b493"))
		x += 28.0
	draw_rect(Rect2(0, size.y - 22.0, size.x, 22), Color("#9c7b55"))
	draw_rect(Rect2(0, 0, size.x, 6), Color(0, 0, 0, 0.25))


func _draw_ac_unit() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Paint.rrect(self, r, Color("#d6dbe2"), 4.0, Paint.INK, 2.0)
	var c := Vector2(size.x * 0.38, size.y * 0.5)
	var rad := minf(size.x, size.y) * 0.34
	Paint.circle(self, c, rad, Color("#8d99ab"), Paint.INK, 1.5)
	for i in 3:
		var a := _t * 12.0 + i * TAU / 3.0
		draw_line(c, c + Vector2.from_angle(a) * (rad - 2.0), Paint.INK, 2.0, true)
	for i in 4:
		var y := 6.0 + i * (size.y - 12.0) / 3.0
		draw_line(Vector2(size.x * 0.72, y), Vector2(size.x - 6.0, y), Color("#8d99ab"), 2.0)


func _draw_water_tank() -> void:
	for lx in [size.x * 0.2, size.x * 0.8]:
		draw_line(Vector2(lx, size.y * 0.55), Vector2(lx, size.y), Paint.INK, 3.0)
	Paint.rrect(self, Rect2(0, 0, size.x, size.y * 0.6), Color("#7fb3d9"), 8.0, Paint.INK, 2.0)
	for i in 3:
		var y := size.y * 0.12 + i * size.y * 0.15
		draw_line(Vector2(4, y), Vector2(size.x - 4.0, y), Color("#5d8fb8"), 2.0)


func _draw_billboard() -> void:
	for lx in [size.x * 0.25, size.x * 0.75]:
		Paint.rrect(self, Rect2(lx - 5.0, size.y * 0.5, 10, size.y * 0.5), Color("#7d7d76"), 2.0, Paint.INK, 2.0)
	var board := Rect2(0, 0, size.x, size.y * 0.55)
	Paint.rrect(self, board, Color("#ffe8a3"), 6.0, Paint.INK, 3.0)
	Paint.rrect(self, board.grow(-8.0), Color("#ff9f43"), 4.0, Paint.INK, 2.0)
	var font := ThemeDB.fallback_font
	var text := "DORAYAKI!"
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	draw_string_outline(font, Vector2((size.x - w) * 0.5, board.get_center().y + 10.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, Paint.INK)
	draw_string(font, Vector2((size.x - w) * 0.5, board.get_center().y + 10.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)


func _draw_factory_gate() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Paint.rrect(self, r, Color("#4b5a72"), 4.0, Paint.INK, 3.0)
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 60), Vector2(x, size.y), Color("#3d4a60"), 3.0)
		x += 40.0
	var plate := Rect2(size.x * 0.5 - 150.0, 14, 300, 44)
	Paint.rrect(self, plate, Color("#f2c230"), 6.0, Paint.INK, 3.0)
	var font := ThemeDB.fallback_font
	var text := "ROBOT FACTORY"
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	draw_string(font, Vector2(plate.get_center().x - w * 0.5, plate.get_center().y + 10.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Paint.INK)
	for i in 2:
		var lx := 30.0 + i * (size.x - 60.0)
		draw_circle(Vector2(lx, 36), 7.0, Color(2.6, 0.4, 0.3), true, -1.0, true)
	var stripe := Rect2(0, size.y - 16.0, size.x, 16)
	draw_rect(stripe, Color("#f2c230"))
	var sx := 0.0
	while sx < size.x:
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx, stripe.end.y), Vector2(sx + 10.0, stripe.position.y),
			Vector2(sx + 20.0, stripe.position.y), Vector2(sx + 10.0, stripe.end.y),
		]), Color("#2a2a2a"))
		sx += 20.0


func _draw_cage() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Paint.rrect(self, Rect2(-6, size.y - 10.0, size.x + 12, 14), Color("#3a4559"), 3.0, Paint.INK, 2.0)
	draw_rect(r, Color(0.1, 0.12, 0.2, 0.35))
	var feet := Vector2(size.x * 0.5, size.y - 10.0)
	draw_set_transform(feet + Vector2(0, -absf(sin(_t * 3.0)) * 3.0), 0.0, Vector2(1.25, 1.25))
	_draw_nobita()
	draw_set_transform(Vector2.ZERO)
	if opened:
		Paint.rrect(self, Rect2(size.x - 20.0, -50, 150, 30), Color.WHITE, 10.0, Paint.INK, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 12.0, -30), "Thanks, Doraemon!", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Paint.INK)
		return
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y - 10.0), Paint.INK, 5.0)
		draw_line(Vector2(x, 0), Vector2(x, size.y - 10.0), Color("#9aa7b8"), 3.0)
		x += size.x / 6.0
	Paint.rrect(self, Rect2(-6, -8, size.x + 12, 12), Color("#3a4559"), 3.0, Paint.INK, 2.0)
	if int(_t * 0.5) % 2 == 0:
		Paint.rrect(self, Rect2(size.x - 10.0, -46, 110, 30), Color.WHITE, 10.0, Paint.INK, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 2.0, -26), "Doraemon!!", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Paint.INK)


## Nobita facing the viewer, feet at the origin, about 58 units tall.
func _draw_nobita() -> void:
	var skin := Color("#ffd9b3")
	var ink := Paint.INK
	Paint.ellipse(self, Vector2(-5, -2), 5.0, 3.0, Color("#5a4632"), ink, 1.2)
	Paint.ellipse(self, Vector2(5, -2), 5.0, 3.0, Color("#5a4632"), ink, 1.2)
	Paint.limb(self, Vector2(-4, -14), Vector2(-5, -4), 4.0, Color.WHITE)
	Paint.limb(self, Vector2(4, -14), Vector2(5, -4), 4.0, Color.WHITE)
	Paint.rrect(self, Rect2(-9, -22, 18, 10), Color("#2c3e7a"), 3.0, ink, 1.5)
	var wave := sin(_t * 8.0) * 0.4
	Paint.limb(self, Vector2(-9, -33), Vector2(-15, -42) + Vector2(0, wave * 4.0), 4.5, Color("#ffd23f"))
	Paint.circle(self, Vector2(-15, -42) + Vector2(0, wave * 4.0), 3.0, skin, ink, 1.0)
	Paint.limb(self, Vector2(9, -33), Vector2(15, -43) - Vector2(0, wave * 4.0), 4.5, Color("#ffd23f"))
	Paint.circle(self, Vector2(15, -43) - Vector2(0, wave * 4.0), 3.0, skin, ink, 1.0)
	Paint.rrect(self, Rect2(-10, -38, 20, 18), Color("#ffd23f"), 5.0, ink, 1.5)
	Paint.circle(self, Vector2(0, -50), 12.0, Color("#1c1c24"), ink, 1.5)
	Paint.circle(self, Vector2(0, -47), 10.0, skin, ink, 1.2)
	for tip in [Vector2(-7, -64), Vector2(0, -66), Vector2(7, -64)]:
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-5, 6), tip, tip + Vector2(5, 6)]), Color("#1c1c24"))
	for ex in [-4.0, 4.0]:
		draw_arc(Vector2(ex, -48), 3.6, 0.0, TAU, 14, ink, 1.4, true)
		draw_circle(Vector2(ex, -48), 1.1, ink)
	draw_line(Vector2(-0.4, -48), Vector2(0.4, -48), ink, 1.2)
	draw_arc(Vector2(0, -40), 2.5, PI + 0.4, TAU - 0.4, 8, ink, 1.2, true)
