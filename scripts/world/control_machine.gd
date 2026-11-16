class_name ControlMachine
extends StaticBody2D
## The robot army's control mechanism. Its energy shield blocks every hit from the front (left);
## only hits on its back (traveling left) do damage. There is a 26 px vent gap underneath.
## Position is the top-left corner of the machine body.

signal destroyed

var size := Vector2(140, 274)
var max_health := 8.0
var health := 8.0
## Where the machine sends Patrol Robots out while it is running.
var spawn_point := Vector2.ZERO
var spawn_every := 7.0
var _spawn_left := 4.0
var _t := 0.0
var _flash := 0.0
var _dead := false
var _cs := CollisionShape2D.new()


func _ready() -> void:
	add_to_group("machine")
	collision_layer = Game.LAYER_WORLD | Game.LAYER_ENEMY
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	_cs.shape = shape
	_cs.position = size * 0.5
	add_child(_cs)


func _physics_process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta)
	if not _dead and spawn_point != Vector2.ZERO:
		_spawn_left -= delta
		if _spawn_left <= 0.0:
			_spawn_left = spawn_every
			var level := get_parent() as Level
			if level != null and get_tree().get_nodes_in_group("machine_bot").size() < 2:
				var r := level.robot("patrol", spawn_point, spawn_point.x - 260.0, spawn_point.x + 10.0)
				r.add_to_group("machine_bot")
				Fx.ring(self, r.center(), Color(2.0, 0.5, 0.3), 26)
	queue_redraw()


func is_destroyed() -> bool:
	return _dead


func take_hit(amount: float, dir: Vector2, _source: Node = null, _knock := 0.0) -> bool:
	if _dead:
		return false
	if dir.x > 0.2:
		Fx.text(self, "SHIELDED", global_position + Vector2(-10, size.y * 0.4), Color("#9be7ff"))
		Fx.ring(self, global_position + Vector2(-8, size.y * 0.5), Color(0.6, 1.6, 2.4), 30)
		return false
	health -= amount
	_flash = 0.12
	Fx.burst(self, global_position + Vector2(size.x, size.y * 0.45), Color(2.2, 1.4, 0.5), 12, 240.0)
	if health <= 0.0:
		_explode()
	return true


func _explode() -> void:
	_dead = true
	_cs.set_deferred("disabled", true)
	for i in 5:
		var p := global_position + Vector2(randf() * size.x, randf() * size.y)
		Fx.ring(self, p, Color(2.4, 1.2, 0.4), 40)
		Fx.burst(self, p, Color(2.4, 1.3, 0.5), 16, 320.0)
	Fx.text(self, "SYSTEM DOWN!", global_position + Vector2(size.x * 0.5, -20), Color("#ffd23f"))
	destroyed.emit()


func _draw() -> void:
	if _dead:
		_draw_wreck()
		return
	var body := Rect2(Vector2.ZERO, size)
	var steel := Color("#46536e") if _flash <= 0.0 else Color(2.0, 2.0, 2.0)
	for lx in [10.0, size.x - 26.0]:
		Paint.rrect(self, Rect2(lx, size.y - 4.0, 16, 30), Color("#2a3245"), 2.0, Paint.INK, 1.5)
	Paint.rrect(self, body, steel, 10.0, Paint.INK, 2.5)
	Paint.rrect(self, Rect2(14, 16, size.x - 28, 60), Color("#1d2539"), 6.0, Paint.INK, 2.0)
	for i in 6:
		var on := int(_t * 6.0 + i) % 3 != 0
		draw_circle(Vector2(30.0 + i * 16.0, 36), 4.0, Color(0.3, 2.0, 0.8) if on else Color(0.1, 0.3, 0.15), true, -1.0, true)
	var bars := [0.4, 0.8, 0.6, 0.9, 0.5]
	for i in bars.size():
		var h: float = 18.0 * (0.5 + 0.5 * sin(_t * 3.0 + i * 1.3)) * bars[i]
		draw_rect(Rect2(28.0 + i * 18.0, 70.0 - h, 10, h), Color(1.8, 1.4, 0.4))
	var core := Vector2(size.x * 0.5, size.y * 0.55)
	var pulse := 0.8 + 0.2 * sin(_t * 5.0)
	Paint.circle(self, core, 34.0, Color("#2a3245"), Paint.INK, 2.5)
	draw_circle(core, 24.0 * pulse, Color(2.4, 0.9, 0.3), true, -1.0, true)
	draw_circle(core, 12.0, Color(3.0, 2.2, 1.2), true, -1.0, true)
	for i in 3:
		var y := size.y - 70.0 + i * 18.0
		Paint.rrect(self, Rect2(16, y, size.x - 32, 10), Color("#5a6884"), 4.0, Paint.INK, 1.5)
	# Back panel (weak point) on the right.
	Paint.rrect(self, Rect2(size.x - 12.0, 90, 16, 110), Color("#c0392b"), 4.0, Paint.INK, 2.0)
	draw_circle(Vector2(size.x - 4.0, 145), 4.0, Color(2.6, 0.4, 0.3) if int(_t * 3.0) % 2 == 0 else Color(0.6, 0.1, 0.1), true, -1.0, true)
	# Energy shield on the front.
	var shimmer := 0.7 + 0.3 * sin(_t * 7.0)
	Paint.ellipse(self, Vector2(-14, size.y * 0.5), 12.0, size.y * 0.52, Color(0.3, 0.9, 1.6, 0.3 * shimmer), Color(0, 0, 0, 0), 0.0)
	Paint.ring(self, Vector2(-14, size.y * 0.5), 12.0, size.y * 0.52, Color(0.5, 1.6, 2.6, shimmer), 2.5)
	# Health bar.
	var bar := Rect2(14, 82, size.x - 28, 10)
	Paint.rrect(self, bar, Color("#0c1430"), 5.0, Paint.INK, 1.5)
	if health > 0.0:
		var fill := Rect2(bar.position + Vector2(2, 2), Vector2((bar.size.x - 4.0) * health / max_health, 6))
		draw_style_box(Paint.box(Color("#ff5a3c"), 3.0, Color(0, 0, 0, 0), 0.0), fill)


func _draw_wreck() -> void:
	var base := Rect2(0, size.y - 40.0, size.x, 66)
	Paint.rrect(self, base, Color("#353f55"), 6.0, Paint.INK, 2.0)
	draw_line(Vector2(20, size.y - 30.0), Vector2(70, size.y - 10.0), Paint.INK, 2.0)
	draw_line(Vector2(90, size.y - 34.0), Vector2(120, size.y), Paint.INK, 2.0)
	for i in 3:
		var p := Vector2(30.0 + i * 40.0, size.y - 50.0 - fposmod(_t * 40.0 + i * 30.0, 90.0))
		draw_circle(p, 10.0 + fposmod(_t * 10.0 + i * 7.0, 14.0), Color(0.5, 0.5, 0.55, 0.35), true, -1.0, true)
