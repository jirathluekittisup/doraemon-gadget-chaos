class_name SecurityCamera
extends Node2D
## Ceiling camera whose view cone sweeps back and forth. A visible Doraemon inside the cone with
## a clear line of sight trips the alarm. Node position is the mount point on the ceiling.

signal tripped(pos: Vector2)

const RANGE := 340.0
const HALF_ANGLE := 0.3

## Sweep limits in radians (0 = right, PI/2 = straight down).
var sweep_from := 1.2
var sweep_to := 1.95
var sweep_time := 3.2
var angle := 1.57
var _t := 0.0
var _cooldown := 0.0
var _seeing := false
var _cone := PackedVector2Array()


func _physics_process(delta: float) -> void:
	_t += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	angle = lerpf(sweep_from, sweep_to, 0.5 - 0.5 * cos(_t * TAU / sweep_time))
	_seeing = _sees_player()
	if _seeing and _cooldown <= 0.0:
		_cooldown = 4.0
		tripped.emit(global_position)
	_update_cone()
	queue_redraw()


func _lens() -> Vector2:
	return global_position + Vector2.from_angle(angle) * 16.0


func _sees_player() -> bool:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null or p.is_invisible or p.health <= 0:
		return false
	var lens := _lens()
	var space := get_world_2d().direct_space_state
	for pt in [p.center(), p.global_position + Vector2(0, -3), p.global_position + Vector2(0, -p.size.y + 3)]:
		var d: Vector2 = pt - lens
		if d.length() > RANGE or absf(angle_difference(angle, d.angle())) > HALF_ANGLE:
			continue
		var q := PhysicsRayQueryParameters2D.create(lens, pt, Game.LAYER_WORLD)
		if space.intersect_ray(q).is_empty():
			return true
	return false


## View cone clipped against walls, in local space.
func _update_cone() -> void:
	var lens := _lens()
	var space := get_world_2d().direct_space_state
	_cone = PackedVector2Array([to_local(lens)])
	for i in 13:
		var a := angle - HALF_ANGLE + HALF_ANGLE * 2.0 * i / 12.0
		var end := lens + Vector2.from_angle(a) * RANGE
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(lens, end, Game.LAYER_WORLD))
		_cone.append(to_local(hit["position"] if not hit.is_empty() else end))


func _draw() -> void:
	var alert := _seeing or _cooldown > 0.0
	if _cone.size() > 2:
		draw_colored_polygon(_cone, Color(1, 0.2, 0.2, 0.22) if alert else Color(1, 0.95, 0.55, 0.14))
		draw_polyline(_cone, Color(1, 0.3, 0.3, 0.5) if alert else Color(1, 0.95, 0.6, 0.3), 1.5, true)
	Paint.rrect(self, Rect2(-10, -6, 20, 10), Color("#3a4559"), 3.0, Paint.INK, 1.5)
	draw_set_transform(Vector2.ZERO, angle)
	Paint.rrect(self, Rect2(-4, -7, 24, 14), Color("#d9dee6"), 4.0, Paint.INK, 1.8)
	Paint.circle(self, Vector2(18, 0), 5.0, Color("#1d2539"), Paint.INK, 1.2)
	var blink := alert or int(_t * 2.0) % 2 == 0
	draw_circle(Vector2(18, 0), 2.6, Color(2.6, 0.3, 0.25) if blink else Color(0.5, 0.1, 0.1), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
