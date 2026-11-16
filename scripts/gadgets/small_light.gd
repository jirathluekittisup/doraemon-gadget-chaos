class_name SmallLight
extends Gadget
## LMB: beam that shrinks the first enemy it hits. RMB: shrink or grow Doraemon.

const RANGE := 420.0


func _init() -> void:
	cooldown = 0.7
	alt_cooldown = 0.4


func use() -> bool:
	var from := player.center()
	var to := from + player.aim_dir() * RANGE
	var q := PhysicsRayQueryParameters2D.create(from, to, Game.LAYER_WORLD | Game.LAYER_ENEMY)
	var hit := player.get_world_2d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		to = hit["position"]
		var collider: Object = hit["collider"]
		if collider.has_method("shrink"):
			collider.call("shrink")
	Fx.line(player, from, to, Color(1, 0.95, 0.4), 5.0)
	return true


func use_alt() -> bool:
	return player.set_shrunk(not player.is_shrunk)


func get_status() -> String:
	return "You: small" if player.is_shrunk else ""


func draw_preview(canvas: CanvasItem) -> void:
	var o := Vector2(0, -player.size.y * 0.5)
	canvas.draw_line(o, o + player.aim_dir() * RANGE, Color(1, 0.95, 0.4, 0.18), 2.0)
