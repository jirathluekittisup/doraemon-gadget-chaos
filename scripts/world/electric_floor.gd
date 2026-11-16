class_name ElectricFloor
extends Area2D
## Electrified strip on the floor. Zaps Doraemon (1 damage) and bounces him back up.
## Node position is the left end, on the floor surface.

var width := 400.0
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Game.LAYER_PLAYER
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 14)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(width * 0.5, -7)
	add_child(cs)


func _physics_process(delta: float) -> void:
	_t += delta
	for body in get_overlapping_bodies():
		var player := body as Player
		if player == null or player.health <= 0:
			continue
		var before := player.health
		player.take_damage(1, player.global_position - Vector2(player.facing * 10.0, 0))
		if player.health < before:
			player.velocity.y = -600.0
			Fx.burst(self, player.global_position, Color(1.2, 1.8, 3.0), 14, 260.0)
			Fx.text(self, "ZAP!", player.center() + Vector2(0, -30), Color("#9be7ff"))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, -6, width, 6), Color("#1d2539"))
	var x := 0.0
	while x < width:
		draw_line(Vector2(x, -6), Vector2(x, 0), Color("#4b5568"), 2.0)
		x += 10.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_t * 20.0)
	for arc in int(width / 60.0):
		var pts := PackedVector2Array()
		var ax := rng.randf() * width
		for i in 6:
			pts.append(Vector2(ax + i * 8.0, -4.0 - rng.randf() * 12.0))
		draw_polyline(pts, Color(1.4, 2.0, 3.0, 0.9), 1.5, true)
	draw_rect(Rect2(0, -3, width, 3), Color(0.6, 1.2, 2.2, 0.5 + 0.3 * sin(_t * 25.0)))
