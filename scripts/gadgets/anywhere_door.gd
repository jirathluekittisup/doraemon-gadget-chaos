class_name AnywhereDoor
extends Gadget
## LMB places the pink door, RMB the blue door. Both must be placed for the pair to work.
## Doors only go where Doraemon can see, so sealed rooms stay closed to them.

const MAX_RANGE := 700.0
const COLOR_A := Color("#ff4fd8")
const COLOR_B := Color("#36b4ff")

var portal_a: Portal
var portal_b: Portal


func _init() -> void:
	cooldown = 0.25
	alt_cooldown = 0.25


func use() -> bool:
	return _place(true)


func use_alt() -> bool:
	return _place(false)


func _target() -> Vector2:
	var c := player.center()
	var target := c + (player.aim_point() - c).limit_length(MAX_RANGE)
	for pad in player.get_tree().get_nodes_in_group("door_pad"):
		if target.distance_to(pad.global_position) < DoorPad.SNAP_RADIUS:
			return pad.global_position
	return target


func _place(first: bool) -> bool:
	var pos := _target()
	if Game.point_blocked(player, pos, Game.LAYER_WORLD):
		Fx.text(player, "Blocked!", pos, Color(1, 0.6, 0.3))
		return false
	if not can_see(pos):
		Fx.text(player, "Can't see there!", pos, Color(1, 0.6, 0.3))
		return false
	if is_jammed(pos):
		Fx.text(player, "Jammed!", pos, Color(1, 0.6, 0.3))
		return false
	var p := portal_a if first else portal_b
	if p == null or not is_instance_valid(p):
		p = Portal.new()
		p.color = COLOR_A if first else COLOR_B
		player.get_parent().add_child(p)
		if first:
			portal_a = p
		else:
			portal_b = p
	p.global_position = pos
	p.opened()
	if portal_a != null and portal_b != null and is_instance_valid(portal_a) and is_instance_valid(portal_b):
		portal_a.linked = portal_b
		portal_b.linked = portal_a
	return true


## True if Doraemon has a clear view of a door at pos: chest to door, and head to the top of the
## door, so a low vent gap isn't enough to peek through. The control machine doesn't block the
## view, or there would be no way to put a door behind it.
func can_see(pos: Vector2) -> bool:
	var space := player.get_world_2d().direct_space_state
	var exclude: Array[RID] = []
	for machine in player.get_tree().get_nodes_in_group("machine"):
		exclude.append(machine.get_rid())
	var head := player.global_position + Vector2(0, -player.size.y + 4.0)
	for ray in [[player.center(), pos], [head, pos + Vector2(0, -28)]]:
		var q := PhysicsRayQueryParameters2D.create(ray[0], ray[1], Game.LAYER_WORLD, exclude)
		if not space.intersect_ray(q).is_empty():
			return false
	return true


## True if a door at pos would overlap a door jammer's area.
func is_jammed(pos: Vector2) -> bool:
	var r := Rect2(pos - Portal.SIZE * 0.5, Portal.SIZE)
	for jammer in player.get_tree().get_nodes_in_group("door_jammer"):
		if (jammer as DoorJammer).get_global_rect().intersects(r):
			return true
	return false


func get_status() -> String:
	var a := portal_a != null and is_instance_valid(portal_a)
	var b := portal_b != null and is_instance_valid(portal_b)
	return "Pink %s · Blue %s" % ["✓" if a else "–", "✓" if b else "–"]


func draw_preview(canvas: CanvasItem) -> void:
	var local := _target() - player.global_position
	var r := Rect2(local - Portal.SIZE * 0.5, Portal.SIZE)
	var target := _target()
	if Game.point_blocked(player, target, Game.LAYER_WORLD) or not can_see(target) or is_jammed(target):
		canvas.draw_style_box(Paint.box(Color(1, 0.2, 0.2, 0.14), 3.0, Color(1, 0.3, 0.3, 0.75), 2.0), r)
		canvas.draw_line(r.position, r.end, Color(1, 0.3, 0.3, 0.75), 2.0, true)
		canvas.draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), Color(1, 0.3, 0.3, 0.75), 2.0, true)
		return
	canvas.draw_style_box(Paint.box(Color(1, 0.55, 0.78, 0.18), 3.0, Color(1, 0.6, 0.85, 0.7), 2.0), r)
