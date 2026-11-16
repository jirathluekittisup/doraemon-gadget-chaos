class_name Fx
extends Node2D
## Short-lived visual effects: floating text, rings, beams and particle bursts.

enum Kind { TEXT, RING, LINE, BURST }

var kind := Kind.TEXT
var label := ""
var color := Color.WHITE
var radius := 24.0
var line_end := Vector2.ZERO
var width := 3.0
var max_life := 0.8
var life := 0.8
var _parts: Array[Vector4] = []


static func text(from: Node, msg: String, pos: Vector2, col := Color.WHITE) -> void:
	var f := Fx.new()
	f.kind = Kind.TEXT
	f.label = msg
	f.color = col
	f.max_life = 0.9
	_spawn(from, f, pos)


static func ring(from: Node, pos: Vector2, col: Color, r := 24.0) -> void:
	var f := Fx.new()
	f.kind = Kind.RING
	f.color = col
	f.radius = r
	f.max_life = 0.35
	_spawn(from, f, pos)


static func line(from: Node, a: Vector2, b: Vector2, col: Color, w := 3.0) -> void:
	var f := Fx.new()
	f.kind = Kind.LINE
	f.color = col
	f.line_end = b - a
	f.width = w
	f.max_life = 0.25
	_spawn(from, f, a)


## Particles flying out from pos. Color channels above 1.0 glow.
static func burst(from: Node, pos: Vector2, col: Color, count := 10, speed := 220.0) -> void:
	var f := Fx.new()
	f.kind = Kind.BURST
	f.color = col
	f.max_life = 0.45
	f.radius = 2.0 + count * 0.15
	for i in count:
		var a := randf() * TAU
		var v := Vector2(cos(a), sin(a) - 0.4) * speed * randf_range(0.4, 1.0)
		f._parts.append(Vector4(0, 0, v.x, v.y))
	_spawn(from, f, pos)


static func _spawn(from: Node, f: Fx, pos: Vector2) -> void:
	f.life = f.max_life
	f.z_index = 50
	if from == null or not from.is_inside_tree() or from.get_tree().current_scene == null:
		f.free()
		return
	from.get_tree().current_scene.add_child(f)
	f.global_position = pos


func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if kind == Kind.TEXT:
		position.y -= 45.0 * delta
	elif kind == Kind.BURST:
		for i in _parts.size():
			var p := _parts[i]
			p.w += 500.0 * delta
			p.x += p.z * delta
			p.y += p.w * delta
			_parts[i] = p
	queue_redraw()


func _draw() -> void:
	var t := clampf(life / max_life, 0.0, 1.0)
	var c := Color(color, color.a * t)
	match kind:
		Kind.TEXT:
			var font := ThemeDB.fallback_font
			var fs := 20
			var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var pos := Vector2(-w * 0.5, 0)
			var pop := 1.0 + maxf(0.0, t - 0.8) * 2.0
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(pop, pop))
			draw_string_outline(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 7, Color(Paint.INK, t))
			draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
			draw_set_transform(Vector2.ZERO)
		Kind.BURST:
			for p in _parts:
				draw_circle(Vector2(p.x, p.y), radius * (0.4 + 0.6 * t), c, true, -1.0, true)
		Kind.RING:
			draw_arc(Vector2.ZERO, radius * (1.6 - 0.6 * t), 0.0, TAU, 28, c, 2.0 + 3.0 * t, true)
		Kind.LINE:
			draw_line(Vector2.ZERO, line_end, Color(c, c.a * 0.35), width * 3.0)
			draw_line(Vector2.ZERO, line_end, c, width)
