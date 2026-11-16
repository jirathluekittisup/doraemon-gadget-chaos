class_name DoorJammer
extends Node2D
## Area where Anywhere Doors can't be placed. Position is the top-left corner; the antenna
## sits on top, in the middle.

var size := Vector2(100, 100)
var _t := 0.0


func _ready() -> void:
	add_to_group("door_jammer")


func get_global_rect() -> Rect2:
	return Rect2(global_position, size)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var base := Vector2(size.x * 0.5, 0)
	draw_line(base, base + Vector2(0, -34), Paint.INK, 3.0)
	Paint.rrect(self, Rect2(base + Vector2(-16, -10), Vector2(32, 10)), Color("#3a4559"), 2.0, Paint.INK, 1.5)
	var tip := base + Vector2(0, -36)
	var pulse := fposmod(_t * 0.8, 1.0)
	draw_arc(tip, 6.0 + pulse * 18.0, -PI * 0.8, -PI * 0.2, 10, Color(1.6, 0.6, 1.4, 1.0 - pulse), 2.0, true)
	draw_circle(tip, 3.5, Color(2.2, 0.5, 1.8), true, -1.0, true)
	# Small crossed-out door on the antenna box.
	var icon := Rect2(base + Vector2(-5, -9), Vector2(10, 8))
	draw_rect(icon, Color("#ff8cc6"))
	draw_line(icon.position, icon.end, Color("#c0392b"), 1.5)
