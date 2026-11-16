class_name Backdrop
extends Node2D
## Sky, two parallax layers and the near scenery (neighborhood houses, then factory interior).
## Add it to the level before the level geometry.

var factory_x := 1720.0
var room_w := 3600.0
var floor_y := 600.0


class Painter extends Node2D:
	var paint: Callable

	func _draw() -> void:
		paint.call(self)


func _ready() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -100
	add_child(sky_layer)
	var grad := Gradient.new()
	grad.set_color(0, Color("#4aa8ec"))
	grad.set_color(1, Color("#d6f0ff"))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var sky := TextureRect.new()
	sky.texture = tex
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky_layer.add_child(sky)

	_add_parallax(0.15, _paint_far, -30)
	_add_parallax(0.45, _paint_mid, -20)
	var near := Painter.new()
	near.paint = _paint_near
	near.z_index = -10
	add_child(near)


func _add_parallax(scale: float, paint: Callable, z: int) -> void:
	var p := Parallax2D.new()
	p.scroll_scale = Vector2(scale, 1.0)
	p.z_index = z
	add_child(p)
	var painter := Painter.new()
	painter.paint = paint
	p.add_child(painter)


func _paint_far(ci: CanvasItem) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var x := -700.0
	while x < room_w * 0.15 + 1800.0:
		var w := rng.randf_range(50, 110)
		var h := rng.randf_range(140, 330)
		var r := Rect2(x, floor_y - 40.0 - h, w, h + 40.0)
		ci.draw_rect(r, Color("#a9d2f2"))
		var wy := r.position.y + 12.0
		while wy < floor_y - 60.0:
			var wx := r.position.x + 8.0
			while wx < r.end.x - 10.0:
				ci.draw_rect(Rect2(wx, wy, 6, 8), Color("#c4e2f8"))
				wx += 14.0
			wy += 18.0
		x += w + rng.randf_range(4, 30)
	for i in int((room_w * 0.15 + 2400.0) / 230.0):
		var c := Vector2(-600.0 + i * 230.0 + rng.randf_range(-40, 40), rng.randf_range(50, 210))
		var s := rng.randf_range(0.7, 1.4)
		for j in 4:
			var o := Vector2((j - 1.5) * 26.0, -absf(j - 1.5) * -6.0 - (12.0 if j in [1, 2] else 0.0)) * s
			ci.draw_circle(c + o, (24.0 if j in [1, 2] else 17.0) * s, Color(1, 1, 1, 0.85), true, -1.0, true)
		ci.draw_rect(Rect2(c + Vector2(-50, 0) * s, Vector2(100, 14) * s), Color(1, 1, 1, 0.85))


func _paint_mid(ci: CanvasItem) -> void:
	var house := Color("#8fbbe0")
	var split := minf(factory_x, room_w) * 0.45 + 300.0
	var x := -700.0
	var i := 0
	while x < split:
		var h := 110.0 + (i % 3) * 25.0
		ci.draw_rect(Rect2(x, floor_y - h, 150, h), house)
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(x - 12, floor_y - h), Vector2(x + 75, floor_y - h - 50), Vector2(x + 162, floor_y - h),
		]), house.darkened(0.12))
		for wx in [25.0, 95.0]:
			ci.draw_rect(Rect2(x + wx, floor_y - h + 25.0, 30, 24), Color("#b5d4ee"))
		x += 175.0
		i += 1
	var factory := Color("#7c99bd")
	x = split - 80.0
	i = 0
	while x < room_w * 0.45 + 1600.0:
		var w := 220.0 + (i % 2) * 80.0
		var h := 200.0 + (i % 3) * 40.0
		ci.draw_rect(Rect2(x, floor_y - h, w, h), factory)
		var tx := x + 10.0
		while tx < x + w:
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(tx, floor_y - h), Vector2(tx + 40.0, floor_y - h - 30.0), Vector2(tx + 40.0, floor_y - h),
			]), factory)
			tx += 50.0
		var stack := Rect2(x + w * 0.7, floor_y - h - 150.0, 26, 150)
		ci.draw_rect(stack, factory.darkened(0.1))
		ci.draw_rect(Rect2(stack.position + Vector2(-3, 0), Vector2(32, 10)), factory.darkened(0.2))
		for s in 4:
			ci.draw_circle(stack.position + Vector2(13.0 + s * 18.0, -14.0 - s * 22.0), 14.0 + s * 6.0, Color(0.85, 0.88, 0.92, 0.6 - s * 0.12), true, -1.0, true)
		var wy := floor_y - h + 30.0
		while wy < floor_y - 30.0:
			ci.draw_rect(Rect2(x + 16.0, wy, w - 32.0, 10), Color("#9db6d4"))
			wy += 36.0
		x += w + 60.0
		i += 1


func _paint_near(ci: CanvasItem) -> void:
	_paint_neighborhood(ci)
	_paint_factory_interior(ci)


func _paint_neighborhood(ci: CanvasItem) -> void:
	var walls := [Color("#f3dfbf"), Color("#e9c9c4"), Color("#d6e6c3"), Color("#f0e6d2"), Color("#cfe0ee")]
	var x := -40.0
	var i := 0
	while x < factory_x - 120.0:
		var w := 260.0
		var top := floor_y - 230.0 - (i % 2) * 20.0
		var wall: Color = walls[i % walls.size()]
		Paint.rrect(ci, Rect2(x, top, w, floor_y - top), wall, 2.0, Paint.INK, 2.0)
		var roof := PackedVector2Array([
			Vector2(x - 22, top + 4), Vector2(x + 30, top - 52), Vector2(x + w - 30, top - 52), Vector2(x + w + 22, top + 4),
		])
		ci.draw_colored_polygon(roof, Color("#4a5f86"))
		ci.draw_polyline(roof, Paint.INK, 2.0, true)
		var ry := top - 44.0
		while ry < top:
			ci.draw_line(Vector2(x + 24.0 - (ry - top + 52.0) * 0.0, ry), Vector2(x + w - 24.0, ry), Color("#3a4c6e"), 1.5)
			ry += 10.0
		Paint.rrect(ci, Rect2(x - 6, top + 95, w + 12, 8), wall.darkened(0.25), 2.0, Paint.INK, 1.5)
		for wx in [30.0, 150.0]:
			for wy in [top + 25.0, top + 120.0]:
				Paint.rrect(ci, Rect2(x + wx, wy, 70, 50), Color("#9fd0f0"), 2.0, Paint.INK, 2.0)
				ci.draw_line(Vector2(x + wx + 35.0, wy), Vector2(x + wx + 35.0, wy + 50.0), Paint.INK, 1.5)
				ci.draw_line(Vector2(x + wx + 6.0, wy + 6.0), Vector2(x + wx + 20.0, wy + 30.0), Color(1, 1, 1, 0.5), 3.0)
		x += w + 80.0
		i += 1
	# Trees between houses.
	var trees: Array[float] = []
	var tree_x := 270.0
	while tree_x < factory_x - 200.0:
		trees.append(tree_x)
		tree_x += 340.0
	for tx in trees:
		ci.draw_rect(Rect2(tx - 5, floor_y - 120, 10, 70), Color("#7a5230"))
		for k in 5:
			var c := Vector2(tx + (k - 2) * 14.0, floor_y - 130.0 - absf(k - 2) * -8.0 - (16.0 if k == 2 else 0.0))
			Paint.circle(ci, c, 22.0, Color("#5fae4e"), Paint.INK, 2.0)
		for k in 5:
			ci.draw_circle(Vector2(tx + (k - 2) * 14.0, floor_y - 132.0 - (16.0 if k == 2 else 0.0)), 18.0, Color("#6fc25a"), true, -1.0, true)
	# Concrete block fence.
	Paint.rrect(ci, Rect2(-20, floor_y - 62, factory_x - 40.0, 62), Color("#c9ccd1"), 2.0, Paint.INK, 2.0)
	Paint.rrect(ci, Rect2(-24, floor_y - 68, factory_x - 32.0, 10), Color("#a9aeb5"), 2.0, Paint.INK, 2.0)
	var fy := floor_y - 46.0
	var row := 0
	while fy < floor_y:
		ci.draw_line(Vector2(-18, fy), Vector2(factory_x - 62.0, fy), Color("#a6abb2"), 1.0)
		var fx := -20.0 + (0.0 if row % 2 == 0 else 20.0)
		while fx < factory_x - 60.0:
			ci.draw_line(Vector2(fx, fy - 12.0), Vector2(fx, fy), Color("#a6abb2"), 1.0)
			fx += 40.0
		fy += 12.0
		row += 1
	# Utility poles and sagging wires.
	var poles: Array[float] = []
	var pole_x := 180.0
	while pole_x < factory_x - 200.0:
		poles.append(pole_x)
		pole_x += 420.0
	for p in poles:
		Paint.rrect(ci, Rect2(p - 6, floor_y - 440, 12, 440), Color("#9a9a92"), 3.0, Paint.INK, 2.0)
		Paint.rrect(ci, Rect2(p - 40, floor_y - 410, 80, 8), Color("#7d7d76"), 2.0, Paint.INK, 1.5)
		Paint.rrect(ci, Rect2(p - 30, floor_y - 370, 60, 6), Color("#7d7d76"), 2.0, Paint.INK, 1.5)
	for j in poles.size() - 1:
		for off in [-34.0, 34.0, -24.0]:
			var y0 := floor_y - (406.0 if off != -24.0 else 367.0)
			var a := Vector2(poles[j] + off, y0)
			var b := Vector2(poles[j + 1] + off, y0)
			var pts := PackedVector2Array()
			for s in 13:
				var t := s / 12.0
				pts.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * 26.0))
			ci.draw_polyline(pts, Color("#2a2f3a"), 1.5, true)


func _paint_factory_interior(ci: CanvasItem) -> void:
	var r := Rect2(factory_x, -700, room_w - factory_x, floor_y + 700)
	ci.draw_rect(r, Color("#25304a"))
	var x := factory_x
	while x < room_w:
		ci.draw_rect(Rect2(x + 6.0, -700, 228, floor_y + 700), Color("#2b3756"))
		Paint.rrect(ci, Rect2(x + 52.0, 70, 140, 70), Color("#8cc3ec"), 3.0, Paint.INK, 3.0)
		ci.draw_line(Vector2(x + 122.0, 70), Vector2(x + 122.0, 140), Paint.INK, 3.0)
		ci.draw_line(Vector2(x + 60.0, 78), Vector2(x + 90.0, 132), Color(1, 1, 1, 0.35), 4.0)
		Paint.rrect(ci, Rect2(x - 14.0, -700, 28, floor_y + 700), Color("#1d2539"), 2.0, Paint.INK, 2.0)
		x += 240.0
	# Pipes.
	for py in [200.0, 236.0]:
		Paint.rrect(ci, Rect2(factory_x, py, room_w - factory_x, 18), Color("#4f6082"), 4.0, Paint.INK, 2.0)
		var jx := factory_x + 60.0
		while jx < room_w:
			Paint.rrect(ci, Rect2(jx, py - 3.0, 14, 24), Color("#6a7da3"), 2.0, Paint.INK, 1.5)
			jx += 180.0
	# Hanging lamps with soft light cones.
	var lx := factory_x + 380.0
	while lx < room_w:
		ci.draw_line(Vector2(lx, -100), Vector2(lx, 280), Paint.INK, 2.0)
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(lx - 14, 292), Vector2(lx + 14, 292), Vector2(lx + 120, floor_y), Vector2(lx - 120, floor_y),
		]), Color(1.0, 0.9, 0.6, 0.06))
		var shade := PackedVector2Array([Vector2(lx - 8, 280), Vector2(lx + 8, 280), Vector2(lx + 20, 294), Vector2(lx - 20, 294)])
		ci.draw_colored_polygon(shade, Color("#3a4559"))
		ci.draw_circle(Vector2(lx, 295), 6.0, Color(2.2, 1.9, 1.2), true, -1.0, true)
		lx += 480.0
	# Hazard stripe along the base of the wall.
	var sx := factory_x
	ci.draw_rect(Rect2(factory_x, floor_y - 12, room_w - factory_x, 12), Color("#b8932a"))
	while sx < room_w:
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(sx, floor_y), Vector2(sx + 7.0, floor_y - 12.0), Vector2(sx + 14.0, floor_y - 12.0), Vector2(sx + 7.0, floor_y),
		]), Color("#2a2a2a"))
		sx += 14.0
