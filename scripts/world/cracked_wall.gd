class_name CrackedWall
extends Solid
## Breaks when punched by the Super Gloves or hit by a thrown object.


func break_wall() -> void:
	Fx.ring(self, global_position + size * 0.5, Color("#d7c4a3"), 40)
	Fx.text(self, "CRASH!", global_position + Vector2(size.x * 0.5, -10), Color("#ffe0a3"))
	queue_free()


func _draw() -> void:
	Paint.rrect(self, Rect2(Vector2.ZERO, size), Color("#c9b99c"), 2.0, Paint.INK, 2.0)
	for y in range(20, int(size.y), 20):
		draw_line(Vector2(2, y), Vector2(size.x - 2, y), Color("#a8987b"), 1.5)
	var dark := Color("#4a3b28")
	draw_polyline(PackedVector2Array([
		Vector2(size.x * 0.2, 2), Vector2(size.x * 0.75, size.y * 0.3),
		Vector2(size.x * 0.25, size.y * 0.55), Vector2(size.x * 0.8, size.y - 2),
	]), dark, 2.0, true)
	draw_line(Vector2(size.x * 0.75, size.y * 0.3), Vector2(size.x - 2, size.y * 0.42), dark, 1.5, true)
