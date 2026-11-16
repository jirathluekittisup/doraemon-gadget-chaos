class_name AirShot
extends Area2D
## Air Cannon projectile.

var velocity := Vector2.ZERO
var life := 1.4
var _t := 0.0
var _trail: Array[Vector2] = []


func _ready() -> void:
	collision_layer = Game.LAYER_PROJECTILE
	collision_mask = Game.LAYER_WORLD | Game.LAYER_ENEMY | Game.LAYER_PROP
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_trail.push_front(global_position)
	if _trail.size() > 7:
		_trail.pop_back()
	position += velocity * delta
	life -= delta
	_t += delta
	if life <= 0.0:
		queue_free()
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.call("take_hit", 1.0, velocity.normalized(), self, 260.0)
	elif body is Prop:
		(body as Prop).velocity += velocity * 0.35
	Fx.ring(self, global_position, Color(0.8, 1.6, 2.4), 14)
	Fx.burst(self, global_position, Color(0.7, 1.5, 2.4), 8, 180.0)
	queue_free()


func _draw() -> void:
	for i in _trail.size():
		var f := 1.0 - float(i) / _trail.size()
		draw_circle(to_local(_trail[i]), 7.0 * f, Color(0.4, 0.9, 1.6, 0.35 * f), true, -1.0, true)
	draw_circle(Vector2.ZERO, 11.0, Color(0.4, 0.85, 1.5, 0.35), true, -1.0, true)
	draw_circle(Vector2.ZERO, 7.0, Color(0.9, 1.7, 2.6), true, -1.0, true)
	draw_arc(Vector2.ZERO, 9.0, _t * 14.0, _t * 14.0 + PI * 1.3, 12, Color(2.0, 2.4, 2.8), 2.0, true)
