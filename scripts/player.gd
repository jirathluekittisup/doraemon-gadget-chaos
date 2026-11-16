class_name Player
extends CharacterBody2D
## Doraemon. Keyboard to move, mouse to aim, 3 gadgets from the loadout. Origin is at the feet.

signal died

const SPEED := 260.0
const ACCEL := 2400.0
const FRICTION := 2800.0
const AIR_CONTROL := 0.7
const JUMP_VELOCITY := -560.0
const GRAVITY := 1500.0
const MAX_FALL := 900.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const THROW_SPEED := 760.0
const NORMAL_SIZE := Vector2(28, 44)
const SHRUNK_SIZE := Vector2(14, 22)

var max_health := 5
var health := 5
var facing := 1
var size := NORMAL_SIZE
var is_shrunk := false
var is_invisible := false
var invisible_left := 0.0
var held: Node2D = null
var gadgets: Array[Gadget] = []
var active_slot := 0
var camera: Camera2D
## When set, used instead of the mouse (headless tests).
var aim_override: Variant = null

var _invuln := 0.0
var _hurt_lock := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _shape := RectangleShape2D.new()
var _cs := CollisionShape2D.new()
var _walk_phase := 0.0
var _moving := 0.0
var _blink_left := 3.0
var _squash := Vector2.ONE
var _was_on_floor := true
var _shake_left := 0.0
var _shake_amount := 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = Game.LAYER_PLAYER
	collision_mask = Game.LAYER_WORLD | Game.LAYER_PROP
	floor_snap_length = 6.0
	_cs.shape = _shape
	add_child(_cs)
	_apply_size(NORMAL_SIZE)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.zoom = Vector2(1.3, 1.3)
	add_child(camera)

	for gadget_id in Game.loadout:
		var g := Gadget.create(gadget_id)
		g.player = self
		g.id = gadget_id
		g.display_name = Game.GADGETS[gadget_id]["name"]
		g.color = Game.GADGETS[gadget_id]["color"]
		add_child(g)
		gadgets.append(g)


func _physics_process(delta: float) -> void:
	_invuln = maxf(0.0, _invuln - delta)
	_hurt_lock = maxf(0.0, _hurt_lock - delta)
	_shake_left = maxf(0.0, _shake_left - delta)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount if _shake_left > 0.0 else Vector2.ZERO
	if is_invisible:
		invisible_left -= delta
		if invisible_left <= 0.0:
			reveal()

	var dir := Input.get_axis("move_left", "move_right")
	var speed := SPEED * (0.8 if is_shrunk else 1.0)
	if _hurt_lock <= 0.0:
		var accel := (ACCEL if dir != 0.0 else FRICTION) * (1.0 if is_on_floor() else AIR_CONTROL)
		velocity.x = move_toward(velocity.x, dir * speed, accel * delta)

	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote -= delta
	_jump_buffer -= delta
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY * (0.8 if is_shrunk else 1.0)
		_jump_buffer = 0.0
		_coyote = 0.0
		_squash = Vector2(0.8, 1.2)
		Fx.burst(self, global_position, Color(0.9, 0.9, 0.85, 0.8), 5, 70.0)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	move_and_slide()
	_animate(delta)

	facing = 1 if aim_point().x >= global_position.x else -1

	if held != null:
		if is_instance_valid(held):
			held.global_position = global_position + Vector2(0, -size.y - 2.0)
		else:
			held = null

	_handle_gadget_input()
	queue_redraw()


func _animate(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		_squash = Vector2(1.25, 0.78)
		Fx.burst(self, global_position, Color(0.9, 0.9, 0.85, 0.8), 6, 80.0)
	_was_on_floor = on_floor
	_moving = clampf(absf(velocity.x) / SPEED, 0.0, 1.0) if on_floor else 0.0
	_walk_phase += delta * 15.0 * _moving
	_squash = _squash.lerp(Vector2.ONE, minf(1.0, 12.0 * delta))
	_blink_left -= delta
	if _blink_left < -0.12:
		_blink_left = randf_range(2.0, 4.5)


func _handle_gadget_input() -> void:
	for i in gadgets.size():
		if Input.is_action_just_pressed("slot_%d" % (i + 1)):
			active_slot = i
	if held != null:
		if Input.is_action_just_pressed("use_gadget"):
			throw_held(throw_velocity())
			reveal()
		elif Input.is_action_just_pressed("alt_gadget"):
			drop_held()
		return
	var g := active_gadget()
	if g == null:
		return
	if Input.is_action_just_pressed("use_gadget"):
		g.try_use()
	if Input.is_action_just_pressed("alt_gadget"):
		g.try_alt()


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or gadgets.is_empty():
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		active_slot = wrapi(active_slot - 1, 0, gadgets.size())
	elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		active_slot = wrapi(active_slot + 1, 0, gadgets.size())


func active_gadget() -> Gadget:
	return gadgets[active_slot] if active_slot < gadgets.size() else null


func center() -> Vector2:
	return global_position + Vector2(0, -size.y * 0.5)


func get_rect() -> Rect2:
	return Rect2(global_position - Vector2(size.x * 0.5, size.y), size)


func aim_point() -> Vector2:
	return aim_override if aim_override != null else get_global_mouse_position()


func aim_dir() -> Vector2:
	var d := aim_point() - center()
	return d.normalized() if d.length() > 1.0 else Vector2(facing, 0)


func throw_velocity() -> Vector2:
	return aim_dir() * THROW_SPEED + Vector2(velocity.x * 0.3, -140.0)


func _apply_size(s: Vector2) -> void:
	size = s
	_shape.size = s
	_cs.position = Vector2(0, -s.y * 0.5)


func _has_room(s: Vector2) -> bool:
	var r := Rect2(global_position - Vector2(s.x * 0.5 - 1.0, s.y + 1.0), s - Vector2(2, 2))
	return Game.bodies_in_rect(self, r, Game.LAYER_WORLD | Game.LAYER_PROP).is_empty()


func set_shrunk(value: bool) -> bool:
	if value == is_shrunk:
		return true
	if not value and not _has_room(NORMAL_SIZE):
		Fx.text(self, "No room to grow!", center() + Vector2(0, -24), Color(1, 0.8, 0.4))
		return false
	if value:
		drop_held()
	is_shrunk = value
	_apply_size(SHRUNK_SIZE if value else NORMAL_SIZE)
	Fx.ring(self, center(), Color("#ffd54f"), 26)
	return true


func shake(amount: float, duration: float) -> void:
	_shake_amount = amount
	_shake_left = duration


func go_invisible(duration: float) -> void:
	is_invisible = true
	invisible_left = duration
	modulate.a = 0.3
	Fx.text(self, "Invisible!", center() + Vector2(0, -36), Color("#d1c4e9"))


func reveal() -> void:
	if not is_invisible:
		return
	is_invisible = false
	invisible_left = 0.0
	modulate.a = 1.0
	Fx.text(self, "Visible", center() + Vector2(0, -36), Color("#d1c4e9"))


func take_damage(amount: int, from_pos: Vector2) -> void:
	if _invuln > 0.0 or health <= 0:
		return
	health = maxi(0, health - amount)
	_invuln = 1.0
	_hurt_lock = 0.25
	var away := signf(global_position.x - from_pos.x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * 320.0, -260.0)
	drop_held()
	Fx.text(self, "-%d" % amount, center() + Vector2(0, -30), Color(1, 0.4, 0.4))
	if health <= 0:
		set_physics_process(false)
		queue_redraw()
		died.emit()


func heal(amount: int) -> bool:
	if health >= max_health:
		return false
	health = mini(max_health, health + amount)
	return true


func try_grab() -> bool:
	if held != null:
		return false
	if is_shrunk:
		Fx.text(self, "Too small to lift!", center() + Vector2(0, -24), Color(1, 0.8, 0.4))
		return false
	var best: Node2D = null
	var best_d := 64.0
	var hands := global_position + Vector2(facing * 20.0, -10.0)
	for n in get_tree().get_nodes_in_group("grabbable"):
		var node := n as Node2D
		if node == null or not node.call("can_grab"):
			continue
		var d := node.global_position.distance_to(hands)
		if d < best_d:
			best_d = d
			best = node
	if best == null:
		Fx.text(self, "Nothing to grab", center() + Vector2(0, -24), Color(0.9, 0.9, 0.9))
		return false
	held = best
	best.call("on_grabbed")
	return true


func throw_held(vel: Vector2) -> void:
	if held == null:
		return
	if is_instance_valid(held):
		held.call("on_released", vel)
	held = null


func drop_held() -> void:
	throw_held(Vector2(facing * 60.0, -40.0))


func _draw() -> void:
	if health > 0:
		if held != null:
			_draw_throw_arc()
		elif active_gadget() != null:
			active_gadget().draw_preview(self)
	if _invuln > 0.0 and health > 0 and int(_invuln * 16.0) % 2 == 0:
		return
	_draw_doraemon()


func _draw_throw_arc() -> void:
	var p := Vector2(0, -size.y - 18.0)
	var v := throw_velocity()
	for i in 14:
		var t := i * 0.05
		var pt := p + v * t + Vector2(0, 0.5 * GRAVITY * t * t)
		draw_circle(pt, 2.5, Color(1, 1, 1, 0.75 - i * 0.05))


func _draw_doraemon() -> void:
	var k := size.y / 50.0
	if is_on_floor():
		Paint.shadow(self, Vector2.ZERO, 15.0 * k)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing * k * _squash.x, k * _squash.y))
	Paint.doraemon(self, _walk_phase, _moving, not is_on_floor(), _blink_left < 0.0, health <= 0)
	draw_set_transform(Vector2.ZERO)
