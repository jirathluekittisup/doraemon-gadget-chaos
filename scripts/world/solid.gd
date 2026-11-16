class_name Solid
extends StaticBody2D
## Rectangular block of level geometry. Position is the top-left corner.
## style: "ground" (street, then factory floor after factory_x), "roof", "block", "metal",
## "factory", "building", "conveyor" or "boundary".

var size := Vector2(64, 64)
var style := "block"
## World x where the ground turns from street into factory floor.
var factory_x := INF
## Conveyor only: how fast the belt carries things standing on it (px/s, + is right).
var belt_speed := 0.0
var _cs := CollisionShape2D.new()
var _t := 0.0


func setup(rect: Rect2, style_name := "block") -> Solid:
	position = rect.position
	size = rect.size
	style = style_name
	return self


func _ready() -> void:
	collision_layer = Game.LAYER_WORLD
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	_cs.shape = shape
	_cs.position = size * 0.5
	add_child(_cs)
	if style == "conveyor":
		constant_linear_velocity = Vector2(belt_speed, 0)
	set_process(style == "conveyor")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func get_global_rect() -> Rect2:
	return Rect2(global_position, size)


func _draw() -> void:
	match style:
		"ground":
			var split := clampf(factory_x - position.x, 0.0, size.x)
			_draw_street(Rect2(0, 0, split, size.y))
			_draw_factory_floor(Rect2(split, 0, size.x - split, size.y))
		"roof":
			_draw_roof()
		"metal":
			_draw_metal()
		"factory":
			_draw_factory_wall()
		"building":
			_draw_building()
		"conveyor":
			_draw_conveyor()
		"boundary":
			draw_rect(Rect2(Vector2.ZERO, size), Color("#1d2539"))
		_:
			_draw_block()


func _draw_street(r: Rect2) -> void:
	if r.size.x <= 0.0:
		return
	draw_rect(r, Color("#4a4f5c"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 14)), Color("#cfc8ba"))
	draw_rect(Rect2(r.position + Vector2(0, 14), Vector2(r.size.x, 5)), Color("#8f8879"))
	draw_line(r.position, r.position + Vector2(r.size.x, 0), Paint.INK, 2.0)
	var x := r.position.x
	while x < r.end.x:
		draw_line(Vector2(x, 2), Vector2(x, 14), Color("#aaa292"), 1.5)
		if int(x) % 160 < 40:
			draw_rect(Rect2(x + 20.0, 60, 60, 6), Color("#e8e2d0"))
		x += 40.0
	draw_rect(Rect2(r.position + Vector2(0, 19), Vector2(r.size.x, 3)), Color(0, 0, 0, 0.25))


func _draw_factory_floor(r: Rect2) -> void:
	if r.size.x <= 0.0:
		return
	draw_rect(r, Color("#323b4f"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 12)), Color("#7d8aa0"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color("#a9b5c6"))
	draw_line(r.position, r.position + Vector2(r.size.x, 0), Paint.INK, 2.0)
	var x := r.position.x
	while x < r.end.x:
		draw_line(Vector2(x, 0), Vector2(x, 12), Paint.INK, 1.5)
		draw_circle(Vector2(x + 8.0, 7), 1.5, Color("#4b5568"))
		draw_circle(Vector2(x + 72.0, 7), 1.5, Color("#4b5568"))
		draw_line(Vector2(x, 12), Vector2(x, r.size.y), Color("#283042"), 2.0)
		x += 80.0
	draw_rect(Rect2(r.position + Vector2(0, 12), Vector2(r.size.x, 4)), Color(0, 0, 0, 0.3))


func _draw_roof() -> void:
	Paint.rrect(self, Rect2(Vector2.ZERO, size), Color("#3f5f96"), 3.0, Paint.INK, 2.0)
	var x := 6.0
	while x < size.x - 4.0:
		draw_arc(Vector2(x + 6.0, 4.0), 6.0, 0.0, PI, 8, Color("#2c4675"), 2.0, true)
		x += 12.0
	draw_line(Vector2(3, 3), Vector2(size.x - 3, 3), Color("#6d8cc4"), 2.0)


func _draw_block() -> void:
	Paint.rrect(self, Rect2(Vector2.ZERO, size), Color("#c5c9ce"), 2.0, Paint.INK, 2.0)
	var row := 0
	var y := 10.0
	while y < size.y:
		draw_line(Vector2(2, y), Vector2(size.x - 2, y), Color("#9ea4ab"), 1.0)
		var x := 20.0 if row % 2 == 0 else 40.0
		while x < size.x:
			draw_line(Vector2(x, y - 10.0), Vector2(x, y), Color("#9ea4ab"), 1.0)
			x += 40.0
		y += 10.0
		row += 1
	draw_line(Vector2(3, 3), Vector2(size.x - 3, 3), Color("#e6e9ec"), 2.0)


func _draw_metal() -> void:
	Paint.rrect(self, Rect2(Vector2.ZERO, size), Color("#5a6884"), 2.0, Paint.INK, 2.0)
	draw_line(Vector2(3, 3), Vector2(size.x - 3, 3), Color("#93a3bf"), 2.0)
	if size.x > size.y:
		var x := 10.0
		while x < size.x - 4.0:
			draw_circle(Vector2(x, size.y * 0.5 + 1.0), 1.5, Color("#2f3a50"))
			x += 20.0
	else:
		var y := 12.0
		while y < size.y - 6.0:
			draw_line(Vector2(4, y), Vector2(size.x - 4, y), Color("#3f4a62"), 2.0)
			y += 12.0


func _draw_factory_wall() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#2e3a58"))
	var x := 0.0
	while x < size.x:
		draw_rect(Rect2(x + 4.0, 0, 52, size.y - 20.0), Color("#34426a"))
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("#1d2539"), 3.0)
		var y := size.y - 60.0
		while y > 0.0:
			draw_circle(Vector2(x + 10.0, y), 2.0, Color("#55648f"))
			draw_circle(Vector2(x + 50.0, y), 2.0, Color("#55648f"))
			y -= 70.0
		x += 60.0
	var stripe := Rect2(0, size.y - 18.0, size.x, 18)
	draw_rect(stripe, Color("#f2c230"))
	var sx := 0.0
	while sx < size.x:
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx, stripe.end.y), Vector2(sx + 12.0, stripe.position.y),
			Vector2(sx + 24.0, stripe.position.y), Vector2(sx + 12.0, stripe.end.y),
		]), Color("#2a2a2a"))
		sx += 24.0
	draw_rect(Rect2(Vector2.ZERO, size), Paint.INK, false, 2.0)


func _draw_building() -> void:
	Paint.rrect(self, Rect2(Vector2.ZERO, size), Color("#d9cdb8"), 2.0, Paint.INK, 2.0)
	Paint.rrect(self, Rect2(-4, 0, size.x + 8, 12), Color("#8f8574"), 2.0, Paint.INK, 2.0)
	var y := 34.0
	while y < size.y - 40.0:
		var x := 22.0
		while x < size.x - 50.0:
			Paint.rrect(self, Rect2(x, y, 36, 44), Color("#8fc3e6"), 2.0, Paint.INK, 1.5)
			draw_line(Vector2(x + 18.0, y), Vector2(x + 18.0, y + 44.0), Paint.INK, 1.0)
			draw_line(Vector2(x + 4.0, y + 4.0), Vector2(x + 12.0, y + 22.0), Color(1, 1, 1, 0.4), 2.0)
			draw_rect(Rect2(x - 3.0, y + 44.0, 42, 4), Color("#a89c86"))
			x += 66.0
		y += 80.0


func _draw_conveyor() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Paint.rrect(self, r, Color("#2e3648"), 8.0, Paint.INK, 2.0)
	var belt := Rect2(4, 3, size.x - 8, 7)
	draw_rect(belt, Color("#4b5568"))
	var dir := signf(belt_speed) if belt_speed != 0.0 else 1.0
	var off := fposmod(_t * belt_speed, 24.0)
	var x := belt.position.x + off - 24.0
	while x < belt.end.x:
		if x > belt.position.x:
			var tip := x + 5.0 * dir
			draw_line(Vector2(x, belt.position.y + 1.0), Vector2(tip, belt.get_center().y), Color("#f2c230"), 2.0)
			draw_line(Vector2(tip, belt.get_center().y), Vector2(x, belt.end.y - 1.0), Color("#f2c230"), 2.0)
		x += 24.0
	var rx := 12.0
	while rx < size.x - 6.0:
		draw_circle(Vector2(rx, size.y - 6.0), 4.0, Color("#7d8aa0"))
		var a := _t * belt_speed * 0.15
		draw_line(Vector2(rx, size.y - 6.0), Vector2(rx, size.y - 6.0) + Vector2(cos(a), sin(a)) * 3.5, Paint.INK, 1.0)
		rx += 22.0
