class_name Prop
extends CharacterBody2D
## Crate that can be grabbed and thrown with the Super Gloves. Origin is at the bottom.

const GRAVITY := 1500.0
const MAX_FALL := 900.0

var size := Vector2(32, 32)
var held := false
var thrown := false


func _ready() -> void:
	add_to_group("grabbable")
	collision_layer = Game.LAYER_PROP
	collision_mask = Game.LAYER_WORLD | Game.LAYER_PROP
	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -size.y * 0.5)
	add_child(cs)


func can_grab() -> bool:
	return not held


func on_grabbed() -> void:
	held = true
	thrown = false
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO


func on_released(vel: Vector2) -> void:
	held = false
	collision_layer = Game.LAYER_PROP
	collision_mask = Game.LAYER_WORLD | Game.LAYER_PROP
	velocity = vel
	thrown = vel.length() > 200.0


func get_rect() -> Rect2:
	return Rect2(global_position - Vector2(size.x * 0.5, size.y), size)


func _physics_process(delta: float) -> void:
	if held:
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if is_on_floor() and not thrown:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
	move_and_slide()
	if not thrown:
		return
	for body in Game.bodies_in_rect(self, get_rect(), Game.LAYER_ENEMY):
		if body.has_method("take_hit"):
			body.call("take_hit", 2.0, velocity.normalized(), self, 320.0)
			thrown = false
			velocity = Vector2(-velocity.x * 0.2, -150.0)
			return
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var other := get_slide_collision(i).get_collider()
			if other != null and other.has_method("break_wall"):
				other.call("break_wall")
		thrown = false
		velocity.x *= 0.3


func _draw() -> void:
	var r := Rect2(Vector2(-size.x * 0.5, -size.y), size)
	Paint.rrect(self, r, Color("#c98e4b"), 3.0, Paint.INK, 2.0)
	var inner := r.grow(-5.0)
	draw_rect(inner, Color("#b07535"))
	draw_line(inner.position, inner.end, Color("#d9a464"), 5.0)
	draw_line(inner.position, inner.end, Color("#7a4e20"), 1.0)
	for y in [r.position.y + 3.0, r.end.y - 3.0]:
		draw_line(Vector2(r.position.x + 2, y), Vector2(r.end.x - 2, y), Color("#7a4e20"), 1.5)
