class_name Portal
extends Area2D
## One half of an Anywhere Door pair. Anything entering keeps its velocity and its offset from
## the door, and comes out of the linked door. The boss can't use the doors.

const SIZE := Vector2(40, 76)

var color := Color("#ff4fd8")
var linked: Portal
var _armed_at := 0.0
var _t := 0.0
var _open := 0.0
var _pulse := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Game.LAYER_PLAYER | Game.LAYER_ENEMY | Game.LAYER_PROP | Game.LAYER_PROJECTILE
	monitorable = false
	z_index = -1
	var shape := RectangleShape2D.new()
	shape.size = SIZE - Vector2(8, 8)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_entered)
	area_entered.connect(_on_entered)


## Called after placing or moving the door; ignores whatever it lands on for a moment.
func opened() -> void:
	_armed_at = _now() + 0.25
	Fx.ring(self, global_position, color, 30)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _on_entered(node: Node2D) -> void:
	# Miguel is too big for the door: he walks straight past it.
	if linked == null or not is_instance_valid(linked) or node is Boss:
		return
	var now := _now()
	if now < _armed_at or float(node.get_meta("portal_until", 0.0)) > now:
		return
	node.set_meta("portal_until", now + 0.35)
	# Shots always leave from the middle of the door, so they line up with a door pad's target.
	var offset := Vector2.ZERO if node is AirShot else node.global_position - global_position
	node.global_position = linked.global_position + offset
	_pulse = 1.0
	linked._pulse = 1.0
	Fx.burst(self, global_position, Color(color.r * 2.0, color.g * 2.0, color.b * 2.0), 10, 160.0)
	Fx.burst(self, linked.global_position, Color(linked.color.r * 2.0, linked.color.g * 2.0, linked.color.b * 2.0), 10, 160.0)


func _process(delta: float) -> void:
	_t += delta
	var linked_ok := linked != null and is_instance_valid(linked)
	_open = move_toward(_open, 1.0 if linked_ok else 0.0, delta * 3.0)
	_pulse = maxf(0.0, _pulse - delta * 3.0)
	queue_redraw()


## A pink door in a frame. The frame glows in the pair color; once both doors are placed the
## door swings open and shows light from the other side.
func _draw() -> void:
	var hw := SIZE.x * 0.5
	var hh := SIZE.y * 0.5
	var glow := Color(color.r * 2.0, color.g * 2.0, color.b * 2.0)
	var aura := Rect2(-hw - 8.0, -hh - 9.0, SIZE.x + 16.0, SIZE.y + 13.0)
	draw_style_box(Paint.box(Color(color, 0.16 + 0.08 * sin(_t * 4.0) + 0.3 * _pulse), 12.0, Color(0, 0, 0, 0), 0.0), aura)
	Paint.rrect(self, Rect2(-hw - 5.0, -hh - 5.0, SIZE.x + 10.0, SIZE.y + 5.0), Color("#c94489"), 4.0, Paint.INK, 2.0)
	draw_rect(Rect2(-hw - 5.0, -hh - 5.0, SIZE.x + 10.0, 3.0), glow)

	var doorway := Rect2(-hw, -hh, SIZE.x, SIZE.y)
	draw_rect(doorway, Color(0.1, 0.07, 0.18))
	if _open > 0.01:
		var inside := Color(glow.r * 0.55, glow.g * 0.55, glow.b * 0.55, _open).lerp(Color(2.4, 2.4, 2.4, _open), _pulse)
		draw_rect(doorway.grow(-2.0), inside)
		for i in 6:
			var a := _t * 1.6 + i * 1.05
			var p := Vector2(sin(a * 1.3) * hw * 0.6, fposmod(-_t * 30.0 + i * 13.0, SIZE.y) - hh)
			draw_circle(p, 1.6, Color(2.5, 2.5, 2.5, 0.7 * _open), true, -1.0, true)

	# Door panel swings toward the viewer on its left hinge.
	var w := SIZE.x * (1.0 - 0.72 * _open)
	var flare := 5.0 * _open
	var x0 := -hw
	var x1 := -hw + w
	var panel := PackedVector2Array([Vector2(x0, -hh), Vector2(x1, -hh - flare), Vector2(x1, hh + flare), Vector2(x0, hh)])
	draw_colored_polygon(panel, Color("#ff8cc6"))
	if w > 14.0:
		for band in [[-hh + 7.0, -4.0], [4.0, hh - 7.0]]:
			var y0: float = band[0]
			var y1: float = band[1]
			# Right edge is nearer the viewer, so it spreads by flare at the top and bottom.
			var inset := PackedVector2Array([
				Vector2(x0 + 5.0, y0), Vector2(x1 - 5.0, y0 * (1.0 + flare / hh)),
				Vector2(x1 - 5.0, y1 * (1.0 + flare / hh)), Vector2(x0 + 5.0, y1),
			])
			draw_colored_polygon(inset, Color("#f06fae"))
			draw_polyline(inset + PackedVector2Array([inset[0]]), Color("#c94489"), 1.2, true)
	draw_polyline(panel + PackedVector2Array([panel[0]]), Paint.INK, 2.0, true)
	Paint.circle(self, Vector2(x1 - 6.0, 3.0), 3.4, Paint.BELL, Paint.INK, 1.2)
	Paint.circle(self, Vector2(0, -hh - 13.0), 5.0, glow, Paint.INK, 1.5)
