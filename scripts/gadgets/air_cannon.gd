class_name AirCannon
extends Gadget

const SHOT_SPEED := 720.0


func _init() -> void:
	cooldown = 0.35


func use() -> bool:
	var dir := player.aim_dir()
	var shot := AirShot.new()
	shot.velocity = dir * SHOT_SPEED
	player.get_parent().add_child(shot)
	shot.global_position = player.center() + dir * 18.0
	player.reveal()
	return true


func draw_preview(canvas: CanvasItem) -> void:
	var o := Vector2(0, -player.size.y * 0.5)
	var d := player.aim_dir()
	for i in 6:
		canvas.draw_circle(o + d * (28.0 + i * 18.0), 2.5, Color(0.6, 0.9, 1.0, 0.8 - i * 0.12))
