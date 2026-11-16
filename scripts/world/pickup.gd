class_name Pickup
extends Area2D
## Dorayaki (heals 1) or Golden Bell (collectible).

signal collected(kind: String)

var kind := "dorayaki"
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Game.LAYER_PLAYER
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	if kind == "dorayaki":
		if not player.heal(1):
			return
		Fx.text(self, "+1 Dorayaki", global_position + Vector2(0, -20), Color("#ffcc80"))
	else:
		Fx.text(self, "Golden Bell!", global_position + Vector2(0, -20), Color("#ffe066"))
	Fx.ring(self, global_position, Color("#ffe066"), 20)
	collected.emit(kind)
	queue_free()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var o := Vector2(0, sin(_t * 3.0) * 3.0)
	draw_circle(o, 20.0, Color(1.0, 0.9, 0.4, 0.12 + 0.06 * sin(_t * 4.0)), true, -1.0, true)
	if kind == "dorayaki":
		Paint.ellipse(self, o + Vector2(0, 4), 15.0, 7.0, Color("#b8672e"), Paint.INK, 1.8)
		Paint.ellipse(self, o + Vector2(0, 1), 14.0, 3.0, Color("#4a2210"), Paint.INK, 0.0)
		Paint.ellipse(self, o + Vector2(0, -3), 15.0, 7.0, Color("#d98a45"), Paint.INK, 1.8)
		Paint.ellipse(self, o + Vector2(-3, -5), 7.0, 2.5, Color("#eba76a"), Paint.INK, 0.0)
	else:
		Paint.circle(self, o, 12.0, Paint.BELL, Paint.INK, 2.0)
		draw_line(o + Vector2(-11, -1), o + Vector2(11, -1), Paint.INK, 1.5, true)
		draw_circle(o + Vector2(0, 5), 2.5, Paint.INK, true, -1.0, true)
		draw_line(o + Vector2(0, 5), o + Vector2(0, 10), Paint.INK, 1.5)
		draw_circle(o + Vector2(-4, -6), 2.5, Color(2.0, 1.9, 1.5), true, -1.0, true)
		var sp := 0.5 + 0.5 * sin(_t * 5.0)
		draw_line(o + Vector2(10, -14), o + Vector2(10, -14 - 8.0 * sp), Color(2.2, 2.0, 1.2), 1.5)
		draw_line(o + Vector2(6, -18 - 4.0 * sp), o + Vector2(14, -18 - 4.0 * sp), Color(2.2, 2.0, 1.2), 1.5)
