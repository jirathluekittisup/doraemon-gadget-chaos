class_name SecurityLaser
extends Area2D
## Horizontal laser tripwire. Trips when a visible Doraemon touches the beam.
## Node position is the left emitter.

signal tripped(pos: Vector2)

var length := 560.0
var _cooldown := 0.0
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Game.LAYER_PLAYER
	var shape := RectangleShape2D.new()
	shape.size = Vector2(length, 4)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(length * 0.5, 0)
	add_child(cs)


func _physics_process(delta: float) -> void:
	_t += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown <= 0.0:
		for body in get_overlapping_bodies():
			var player := body as Player
			if player != null and not player.is_invisible and player.health > 0:
				_cooldown = 4.0
				tripped.emit(player.global_position)
				break
	queue_redraw()


func _draw() -> void:
	var on := _cooldown <= 0.0 or int(_t * 8.0) % 2 == 0
	var a := 1.0 if on else 0.4
	var flicker := 0.85 + 0.15 * sin(_t * 30.0)
	draw_line(Vector2.ZERO, Vector2(length, 0), Color(1.0, 0.1, 0.1, 0.25 * a), 9.0, true)
	draw_line(Vector2.ZERO, Vector2(length, 0), Color(2.8 * flicker, 0.35, 0.35, a), 2.0, true)
	for x in [0.0, length]:
		Paint.rrect(self, Rect2(x - 6.0, -10, 12, 20), Color("#3a4559"), 3.0, Paint.INK, 1.5)
		draw_circle(Vector2(x, 0), 3.0, Color(2.5, 0.3, 0.3), true, -1.0, true)
