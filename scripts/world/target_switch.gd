class_name TargetSwitch
extends StaticBody2D
## Bonus target at the back of a tube. Only an Air Cannon shot traveling into its face counts.
## Stays lit once hit. Position is the top-left corner.

signal hit

const SIZE := Vector2(12, 40)
const OPEN_TIME := 1.1

## Which way the target faces: -1 left (needs a shot traveling right), 1 right.
var face := -1
## If above 0, a shutter covers it except for OPEN_TIME out of every period seconds.
var open_period := 0.0
var lit := false
var _t := 0.0


func _ready() -> void:
	collision_layer = Game.LAYER_WORLD
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = SIZE * 0.5
	add_child(cs)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func is_open() -> bool:
	return open_period <= 0.0 or fmod(_t, open_period) < OPEN_TIME


func take_hit(_amount: float, dir: Vector2, source: Node = null, _knock := 0.0) -> bool:
	if lit or not source is AirShot or signf(dir.x) != -face:
		return false
	if not is_open():
		Fx.ring(self, global_position + SIZE * 0.5, Color(0.8, 0.85, 1), 12)
		return false
	lit = true
	Fx.burst(self, global_position + SIZE * 0.5, Color(0.5, 2.4, 0.9), 16, 240.0)
	Fx.text(self, "TARGET HIT!", global_position + Vector2(SIZE.x * 0.5, -24), Color("#9dff9d"))
	hit.emit()
	return true


func _draw() -> void:
	Paint.rrect(self, Rect2(Vector2.ZERO, SIZE), Color("#2a3245"), 3.0, Paint.INK, 2.0)
	var c := SIZE * 0.5
	var col := Color(0.4, 2.4, 0.8) if lit else Color(2.4, 0.5, 0.3)
	draw_circle(c, 5.0, col, true, -1.0, true)
	draw_arc(c, 8.0, 0.0, TAU, 16, Color(col, 0.6), 1.5, true)
	if open_period > 0.0 and not lit and not is_open():
		var bx := SIZE.x + 2.0 if face > 0 else -8.0
		Paint.rrect(self, Rect2(bx, 0, 6, SIZE.y), Color("#8d99ab"), 2.0, Paint.INK, 1.5)
