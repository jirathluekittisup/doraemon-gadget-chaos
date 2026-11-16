class_name Paint
extends RefCounted
## Cartoon drawing helpers for the procedural art: outlined shapes, Doraemon and gadget icons.
## Colors above 1.0 glow (2D HDR + WorldEnvironment glow).

const INK := Color("#16203a")
const DORA_BLUE := Color("#1aa3e8")
const DORA_RED := Color("#e8302a")
const BELL := Color("#ffc928")

static var _boxes := {}


static func box(fill: Color, radius := 6.0, border := INK, bw := 2.0, shadow := 0.0) -> StyleBoxFlat:
	var key := "%s|%s|%s|%s|%s" % [fill.to_html(), radius, border.to_html(), bw, shadow]
	if _boxes.has(key):
		return _boxes[key]
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(int(radius))
	sb.border_color = border
	sb.set_border_width_all(int(round(bw)))
	sb.anti_aliasing = true
	if shadow > 0.0:
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = int(shadow)
		sb.shadow_offset = Vector2(0, shadow * 0.5)
	_boxes[key] = sb
	return sb


static func rrect(ci: CanvasItem, r: Rect2, fill: Color, radius := 6.0, border := INK, bw := 2.0) -> void:
	ci.draw_style_box(box(fill, radius, border, bw), r)


static func circle(ci: CanvasItem, c: Vector2, r: float, fill: Color, border := INK, bw := 2.0) -> void:
	if bw > 0.0:
		ci.draw_circle(c, r, border, true, -1.0, true)
	ci.draw_circle(c, r - bw, fill, true, -1.0, true)


static func ellipse_points(c: Vector2, rx: float, ry: float, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, border := INK, bw := 2.0) -> void:
	if bw > 0.0:
		ci.draw_colored_polygon(ellipse_points(c, rx, ry), border)
	ci.draw_colored_polygon(ellipse_points(c, rx - bw, ry - bw), fill)


static func ring(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, w: float) -> void:
	var pts := ellipse_points(c, rx, ry, 36)
	pts.append(pts[0])
	ci.draw_polyline(pts, col, w, true)


## Rounded limb with an outline.
static func limb(ci: CanvasItem, a: Vector2, b: Vector2, w: float, fill: Color) -> void:
	ci.draw_line(a, b, INK, w + 3.0, true)
	ci.draw_circle(a, (w + 3.0) * 0.5, INK, true, -1.0, true)
	ci.draw_circle(b, (w + 3.0) * 0.5, INK, true, -1.0, true)
	ci.draw_line(a, b, fill, w, true)
	ci.draw_circle(a, w * 0.5, fill, true, -1.0, true)
	ci.draw_circle(b, w * 0.5, fill, true, -1.0, true)


static func shadow(ci: CanvasItem, c: Vector2, rx: float) -> void:
	ci.draw_colored_polygon(ellipse_points(c, rx, rx * 0.22, 20), Color(0, 0, 0, 0.22))


## Doraemon facing right with feet at the origin, about 58 units tall.
## walk: walk-cycle phase in radians; moving: 0..1 how fast he walks.
## wave: if >= 0, the front arm is raised and tilted by this many radians (waving pose).
static func doraemon(ci: CanvasItem, walk: float, moving: float, airborne: bool, blink: bool, grey := false, wave := -1.0) -> void:
	var blue := Color(0.5, 0.53, 0.62) if grey else DORA_BLUE
	var swing := sin(walk) * moving
	var bob := absf(cos(walk)) * 1.5 * moving
	var lift := 3.0 if airborne else 0.0

	var back_hand := Vector2(-15, -33) if airborne else Vector2(-11.0 - swing * 4.0, -15.0 - bob)
	limb(ci, Vector2(-8, -21 - bob), back_hand, 5.5, blue.darkened(0.18))
	circle(ci, back_hand, 4.2, Color(0.88, 0.9, 0.95), INK, 1.5)
	circle(ci, Vector2(-12, -10 - bob), 2.8, DORA_RED, INK, 1.2)

	if wave >= 0.0:
		# Waving arm sticks out from the side of the body, up and away from the head.
		# Drawn before the body so its base hides behind it.
		var shoulder := Vector2(11, -21 - bob)
		var hand := shoulder + Vector2(14, -14).rotated(wave - 0.2)
		limb(ci, shoulder, hand, 6.0, blue)
		circle(ci, hand, 5.2, Color.WHITE, INK, 1.5)

	ellipse(ci, Vector2(-5.0 - swing * 5.0, -3.5 - maxf(0.0, -sin(walk)) * 2.5 * moving - lift), 7.5, 3.8, Color.WHITE, INK, 1.5)
	ellipse(ci, Vector2(6.0 + swing * 5.0, -3.5 - maxf(0.0, sin(walk)) * 2.5 * moving - lift), 7.5, 3.8, Color.WHITE, INK, 1.5)

	rrect(ci, Rect2(-12, -28 - bob, 27, 23), blue, 10.0, INK, 1.5)
	ellipse(ci, Vector2(2.5, -15.5 - bob), 10.0, 8.5, Color.WHITE, INK, 1.2)
	ci.draw_arc(Vector2(2.5, -16 - bob), 5.6, 0.15, PI - 0.15, 10, INK, 1.2, true)

	rrect(ci, Rect2(-9, -28.5 - bob, 22, 4.5), DORA_RED, 2.0, INK, 1.0)
	circle(ci, Vector2(2.5, -23 - bob), 3.6, BELL, INK, 1.0)
	ci.draw_line(Vector2(-0.6, -23.6 - bob), Vector2(5.6, -23.6 - bob), INK, 0.8, true)
	ci.draw_circle(Vector2(2.5, -21.6 - bob), 0.8, INK)

	head(ci, Vector2(1, -42 - bob), blink, grey, wave >= 0.0)

	if wave < 0.0:
		var front_hand := Vector2(15, -36) if airborne else Vector2(12.0 + swing * 4.0, -15.0 - bob)
		limb(ci, Vector2(8, -21 - bob), front_hand, 5.5, blue)
		circle(ci, front_hand, 4.4, Color.WHITE, INK, 1.5)


## Doraemon's head (facing right) centered on c, radius 17 units.
static func head(ci: CanvasItem, c: Vector2, blink := false, grey := false, open_mouth := false) -> void:
	var blue := Color(0.5, 0.53, 0.62) if grey else DORA_BLUE
	circle(ci, c, 17.0, blue, INK, 1.8)
	ellipse(ci, c + Vector2(3.5, 3.8), 13.2, 12.2, Color.WHITE, INK, 1.2)
	for ex in [-0.6, 7.0]:
		var e: Vector2 = c + Vector2(ex, -8.0)
		if blink:
			ci.draw_line(e + Vector2(-3, 0.5), e + Vector2(3, 0.5), INK, 1.6, true)
		else:
			ellipse(ci, e, 3.9, 5.2, Color.WHITE, INK, 1.2)
			ci.draw_circle(e + Vector2(1.5, 1.0), 1.6, INK, true, -1.0, true)
			ci.draw_circle(e + Vector2(1.9, 0.4), 0.5, Color.WHITE)
	circle(ci, c + Vector2(4, -1.8), 3.0, DORA_RED, INK, 1.0)
	ci.draw_circle(c + Vector2(3.1, -2.8), 0.9, Color(1, 1, 1, 0.9))
	ci.draw_line(c + Vector2(4, 1.2), c + Vector2(4, 8.0), INK, 1.0, true)
	if open_mouth:
		var pts := PackedVector2Array()
		for i in 13:
			var a := PI * i / 12.0
			pts.append(c + Vector2(4.0 + cos(a) * 8.0, 7.5 + sin(a) * 7.0))
		ci.draw_colored_polygon(pts, INK)
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(c + Vector2(4, 7.5) + (p - c - Vector2(4, 7.5)) * 0.85)
		ci.draw_colored_polygon(inner, Color("#c42a2a"))
		ci.draw_circle(c + Vector2(5, 12), 3.0, Color("#ff7a7a"))
	else:
		ci.draw_arc(c + Vector2(4, 3.5), 7.8, 0.35, PI - 0.35, 14, INK, 1.2, true)
	for i in 3:
		var dy := -2.0 + i * 3.2
		ci.draw_line(c + Vector2(-2.5, 3.0 + dy * 0.3), c + Vector2(-9.5, 1.5 + dy * 1.1), INK, 0.8, true)
		ci.draw_line(c + Vector2(10.5, 3.0 + dy * 0.3), c + Vector2(16.0, 1.5 + dy * 1.1), INK, 0.8, true)


## Gadget icon centered on c, about s pixels across.
static func gadget_icon(ci: CanvasItem, id: String, c: Vector2, s: float) -> void:
	var u := s / 48.0
	match id:
		"air_cannon":
			rrect(ci, Rect2(c + Vector2(-18, -10) * u, Vector2(30, 20) * u), Color("#a9bdd3"), 6.0 * u, INK, 2.0)
			rrect(ci, Rect2(c + Vector2(-12, -10) * u, Vector2(5, 20) * u), Color("#6f87a3"), 2.0, INK, 1.5)
			ellipse(ci, c + Vector2(13, 0) * u, 6.0 * u, 12.0 * u, Color("#8ba3bf"), INK, 2.0)
			ellipse(ci, c + Vector2(14, 0) * u, 3.5 * u, 8.0 * u, Color("#1d2b45"), INK, 0.0)
			ci.draw_circle(c + Vector2(15, 0) * u, 3.0 * u, Color(0.6, 1.4, 2.2))
		"super_gloves":
			rrect(ci, Rect2(c + Vector2(-12, 6) * u, Vector2(22, 10) * u), Color("#f5f5f5"), 3.0 * u, INK, 2.0)
			for i in 4:
				rrect(ci, Rect2(c + Vector2(-12.0 + i * 5.5, -16.0 + absf(i - 1.5) * 2.0) * u, Vector2(6, 16) * u), Color("#ff5a3c"), 3.0 * u, INK, 1.5)
			rrect(ci, Rect2(c + Vector2(-13, -8) * u, Vector2(24, 17) * u), Color("#ff5a3c"), 6.0 * u, INK, 2.0)
			rrect(ci, Rect2(c + Vector2(8, -6) * u, Vector2(9, 12) * u), Color("#ff5a3c"), 4.0 * u, INK, 1.5)
		"anywhere_door":
			for d in [[-9.0, Color(1.6, 0.5, 1.6)], [9.0, Color(0.4, 1.0, 2.0)]]:
				var dc: Vector2 = c + Vector2(d[0], 1) * u
				var glow: Color = d[1]
				ci.draw_style_box(box(Color(glow, 0.35), 4.0 * u, Color(0, 0, 0, 0), 0.0), Rect2(dc + Vector2(-10, -20) * u, Vector2(20, 39) * u))
				rrect(ci, Rect2(dc + Vector2(-8, -18) * u, Vector2(16, 36) * u), Color("#ff8cc6"), 2.0 * u, INK, 2.0)
				rrect(ci, Rect2(dc + Vector2(-5, -14) * u, Vector2(10, 11) * u), Color("#f06fae"), 1.0, Color("#c94489"), 1.0)
				rrect(ci, Rect2(dc + Vector2(-5, 1) * u, Vector2(10, 12) * u), Color("#f06fae"), 1.0, Color("#c94489"), 1.0)
				ci.draw_circle(dc + Vector2(4.5, -1) * u, 1.8 * u, BELL, true, -1.0, true)
		"small_light":
			var beam := PackedVector2Array([c + Vector2(-2, -10) * u, c + Vector2(-20, -22) * u, c + Vector2(-20, -2) * u])
			ci.draw_colored_polygon(beam, Color(1.0, 0.95, 0.4, 0.45))
			rrect(ci, Rect2(c + Vector2(2, -5) * u, Vector2(18, 10) * u), Color("#7d8aa0"), 3.0 * u, INK, 2.0)
			var head_pts := PackedVector2Array([c + Vector2(4, -6) * u, c + Vector2(-4, -12) * u, c + Vector2(-4, 12) * u, c + Vector2(4, 6) * u])
			ci.draw_colored_polygon(head_pts, BELL)
			ci.draw_polyline(head_pts + PackedVector2Array([head_pts[0]]), INK, 2.0, true)
			ci.draw_line(c + Vector2(-4, -11) * u, c + Vector2(-4, 11) * u, Color(1.8, 1.7, 0.6), 3.0 * u, true)
		"invisibility_cape":
			var cape := PackedVector2Array([
				c + Vector2(-8, -16) * u, c + Vector2(8, -16) * u, c + Vector2(17, 16) * u,
				c + Vector2(6, 12) * u, c + Vector2(0, 17) * u, c + Vector2(-6, 12) * u, c + Vector2(-17, 16) * u,
			])
			ci.draw_colored_polygon(cape, Color("#8e6bd8"))
			ci.draw_polyline(cape + PackedVector2Array([cape[0]]), INK, 2.0, true)
			ci.draw_line(c + Vector2(-2, -12) * u, c + Vector2(-6, 12) * u, Color("#b79cf0"), 2.0 * u, true)
			ci.draw_line(c + Vector2(3, -12) * u, c + Vector2(7, 12) * u, Color("#6a4bb0"), 2.0 * u, true)
			circle(ci, c + Vector2(0, -15) * u, 3.5 * u, BELL, INK, 1.2)
