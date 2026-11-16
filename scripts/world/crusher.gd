class_name Crusher
extends Node2D
## Factory piston. Slams down on a fixed cycle, crushing robots and crates and hurting Doraemon.
## Node x is the piston's center; y is world origin.

const UP_HOLD := 1.5
const SLAM := 0.12
const DOWN_HOLD := 0.45
const RISE := 0.9
const WIDTH := 90.0

var top_y := 300.0
var floor_y := 600.0
var phase := 0.0
var extension := 0.0


func _physics_process(delta: float) -> void:
	phase = fmod(phase + delta, UP_HOLD + SLAM + DOWN_HOLD + RISE)
	if phase < UP_HOLD:
		extension = 0.0
	elif phase < UP_HOLD + SLAM:
		extension = (phase - UP_HOLD) / SLAM
	elif phase < UP_HOLD + SLAM + DOWN_HOLD:
		extension = 1.0
	else:
		extension = 1.0 - (phase - UP_HOLD - SLAM - DOWN_HOLD) / RISE
	if extension > 0.7:
		_crush()
	queue_redraw()


func _head_bottom() -> float:
	return lerpf(top_y + 40.0, floor_y, extension)


func _crush() -> void:
	var rect := Rect2(global_position.x - WIDTH * 0.5 + 4.0, top_y, WIDTH - 8.0, _head_bottom() - top_y)
	var mask := Game.LAYER_PLAYER | Game.LAYER_ENEMY | Game.LAYER_PROP
	for body in Game.bodies_in_rect(self, rect, mask):
		if body is Player:
			body.take_damage(2, Vector2(global_position.x, body.center().y))
		elif body is Robot:
			Fx.text(self, "CRUNCH!", body.center() + Vector2(0, -30), Color("#ffab40"))
			body.die()
		elif body is Prop:
			Fx.ring(self, body.global_position, Color("#b5803f"), 30)
			body.queue_free()


func _draw() -> void:
	var hb := _head_bottom()
	var steel := Color("#7d8aa0")
	Paint.rrect(self, Rect2(-14, top_y - 520, 28, 500), Color("#3a4559"), 3.0, Paint.INK, 2.0)
	Paint.rrect(self, Rect2(-WIDTH * 0.5 - 10.0, top_y - 34, WIDTH + 20.0, 46), Color("#4b5a72"), 6.0, Paint.INK, 2.0)
	for x in [-WIDTH * 0.5 - 2.0, WIDTH * 0.5 + 2.0]:
		draw_circle(Vector2(x, top_y - 22), 2.5, Color("#9aa7b8"), true, -1.0, true)
	var warn := phase > UP_HOLD - 0.45 and phase < UP_HOLD + SLAM + DOWN_HOLD
	Paint.circle(self, Vector2(0, top_y - 12), 7.0, Color(3.0, 0.35, 0.25) if warn else Color(0.4, 0.1, 0.1), Paint.INK, 1.5)
	if hb - top_y - 40.0 > 0.0:
		Paint.rrect(self, Rect2(-11, top_y + 8, 22, hb - top_y - 36.0), steel, 3.0, Paint.INK, 2.0)
		draw_line(Vector2(-4, top_y + 10), Vector2(-4, hb - 30.0), Color(1, 1, 1, 0.35), 3.0)
	var head := Rect2(-WIDTH * 0.5, hb - 32.0, WIDTH, 32.0)
	Paint.rrect(self, head, Color("#f2a33a"), 4.0, Paint.INK, 2.0)
	for i in 5:
		var x := head.position.x + 8.0 + i * 17.0
		draw_line(Vector2(x, head.end.y - 3.0), Vector2(x + 10.0, head.position.y + 3.0), Color("#2a2a2a"), 5.0)
	Paint.rrect(self, Rect2(-WIDTH * 0.5 - 4.0, hb - 8.0, WIDTH + 8.0, 8.0), Color("#5a6377"), 2.0, Paint.INK, 1.5)
	draw_rect(Rect2(-WIDTH * 0.5, floor_y - 4.0, WIDTH, 4.0), Color(1.4, 1.1, 0.2, 0.7))
