class_name SuperGloves
extends Gadget
## LMB: 3-punch combo. RMB: grab a crate or shrunk enemy (throwing is handled by the player).

var combo := 0
var _combo_window := 0.0


func _init() -> void:
	cooldown = 0.18
	alt_cooldown = 0.15


func _process(delta: float) -> void:
	super(delta)
	_combo_window = maxf(0.0, _combo_window - delta)
	if _combo_window <= 0.0:
		combo = 0


func use() -> bool:
	combo = combo % 3 + 1
	_combo_window = 0.6
	var f := float(player.facing)
	var reach := 40.0 if combo < 3 else 54.0
	var hit_center := player.center() + Vector2(f * (player.size.x * 0.5 + reach * 0.5), 0)
	var rect := Rect2(hit_center - Vector2(reach * 0.5, 18), Vector2(reach, 36))
	var mask := Game.LAYER_ENEMY | Game.LAYER_WORLD | Game.LAYER_PROP
	var hit := false
	for body in Game.bodies_in_rect(player, rect, mask):
		if body.has_method("take_hit"):
			body.call("take_hit", 1.0, Vector2(f, 0), player, 420.0 if combo == 3 else 200.0)
			hit = true
		elif body.has_method("break_wall"):
			body.call("break_wall")
			hit = true
		elif body is Prop:
			(body as Prop).velocity += Vector2(f * 260.0, -120.0)
			hit = true
	Fx.ring(player, hit_center, Color(1, 0.8, 0.4) if hit else Color(1, 1, 1, 0.5), 8.0 + combo * 4.0)
	if combo == 3:
		Fx.text(player, "POW!", hit_center + Vector2(0, -20), Color("#ff7043"))
		cooldown_left = 0.45
	player.reveal()
	return true


func use_alt() -> bool:
	return player.try_grab()


func get_status() -> String:
	return "Combo %d/3" % combo if combo > 0 else ""


func draw_preview(canvas: CanvasItem) -> void:
	var f := float(player.facing)
	var p := Vector2(f * (player.size.x * 0.5 + 10.0), -player.size.y * 0.5)
	canvas.draw_circle(p, 6.0 * player.size.y / 44.0, Color("#ff7043"))
