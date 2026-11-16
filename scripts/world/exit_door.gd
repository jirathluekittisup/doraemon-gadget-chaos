class_name ExitDoor
extends Area2D
## Level exit. Doraemon stands in front and presses interact. Origin is at the bottom.

signal entered

var _player_near := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = Game.LAYER_PLAYER
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60, 90)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -45)
	add_child(cs)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_near = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_near = false


func _process(_delta: float) -> void:
	if _player_near and Input.is_action_just_pressed("interact"):
		entered.emit()
	queue_redraw()


func _draw() -> void:
	Paint.rrect(self, Rect2(-42, -112, 84, 112), Color("#4b5a72"), 6.0, Paint.INK, 2.0)
	Paint.rrect(self, Rect2(-32, -100, 64, 100), Color("#1d2539"), 3.0, Paint.INK, 2.0)
	draw_line(Vector2(0, -100), Vector2(0, 0), Paint.INK, 2.0)
	for y in [-80.0, -55.0, -30.0]:
		draw_line(Vector2(-28, y), Vector2(28, y), Color("#2c3650"), 2.0)
	Paint.rrect(self, Rect2(-30, -138, 60, 22), Color("#0f3d22"), 5.0, Paint.INK, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-19, -121), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.6, 2.2, 0.9))
	if _player_near:
		Paint.rrect(self, Rect2(-44, -172, 88, 26), Color.WHITE, 10.0, Paint.INK, 2.0)
		draw_string(font, Vector2(-36, -153), "Press E", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Paint.INK)
