class_name Shutter
extends Solid
## Security shutter that slams shut when the alarm goes off.

var closed := false


func set_closed(value: bool) -> void:
	closed = value
	_cs.set_deferred("disabled", not value)
	queue_redraw()


func _draw() -> void:
	if not closed:
		Paint.rrect(self, Rect2(-2, 0, size.x + 4, 8), Color("#5a6377"), 2.0, Paint.INK, 1.5)
		return
	Paint.rrect(self, Rect2(Vector2.ZERO, size), Color("#8d99ab"), 2.0, Paint.INK, 2.0)
	var y := 8.0
	while y < size.y - 10.0:
		draw_line(Vector2(2, y), Vector2(size.x - 2, y), Color("#5a6377"), 2.0)
		y += 8.0
	for i in 3:
		var x := i * 8.0
		draw_line(Vector2(x, size.y - 2), Vector2(x + 8.0, size.y - 10.0), Color("#f2c230"), 3.0)
