class_name DoorPad
extends Node2D
## Glowing spot that an Anywhere Door snaps onto. The arrow shows which way a shot must leave
## the door to reach the target.

const SNAP_RADIUS := 56.0

## Direction a shot needs to travel from here: 1 right, -1 left.
var shot_dir := 1
var _t := 0.0


func _ready() -> void:
	add_to_group("door_pad")
	z_index = -2


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var a := 0.55 + 0.25 * sin(_t * 4.0)
	var r := Rect2(-Portal.SIZE * 0.5, Portal.SIZE)
	draw_style_box(Paint.box(Color(1.0, 0.45, 0.8, 0.14), 4.0, Color(1.6, 0.7, 1.3, a), 2.0), r)
	var nudge := fposmod(_t * 18.0, 12.0)
	var f := float(shot_dir)
	var x0 := f * (Portal.SIZE.x * 0.5 + 6.0 + nudge)
	var tip := Vector2(x0 + f * 18.0, 0)
	draw_line(Vector2(x0, 0), tip, Color(1.6, 0.8, 1.4, a), 3.0, true)
	draw_line(tip, tip + Vector2(-f * 8.0, -7.0), Color(1.6, 0.8, 1.4, a), 3.0, true)
	draw_line(tip, tip + Vector2(-f * 8.0, 7.0), Color(1.6, 0.8, 1.4, a), 3.0, true)
