class_name Robot
extends CharacterBody2D
## Patrol Robot, Armored Robot and the boss's Mini Bots. Origin is at the feet.

enum State { PATROL, CHASE, HELD, THROWN, STUNNED }

const GRAVITY := 1500.0
const MAX_FALL := 900.0
const SIGHT_RANGE := 300.0
const LOSE_RANGE := 480.0
const SHRINK_TIME := 10.0

var armored := false
## Mini Bots are small and weak, and can always be grabbed and thrown.
var is_mini := false
var max_health := 2.0
var health := 2.0
var facing := -1
var patrol_min := -INF
var patrol_max := INF
var walk_speed := 70.0
var chase_speed := 150.0
var stun_time := 0.35
var base_size := Vector2(36, 40)
var size := Vector2(36, 40)
var state := State.PATROL
var shrunk := false

var _shrink_left := 0.0
var _stun_left := 0.0
var _turn_after_stun := 0
var _flash := 0.0
var _walk_phase := 0.0
var _t := 0.0
var _dead := false
var _player: Player
var _shape := RectangleShape2D.new()
var _cs := CollisionShape2D.new()


func setup(kind: String, pos: Vector2, range_min: float, range_max: float) -> Robot:
	position = pos
	patrol_min = range_min
	patrol_max = range_max
	if kind == "armored":
		armored = true
		base_size = Vector2(44, 50)
		walk_speed = 55.0
		chase_speed = 110.0
		stun_time = 0.8
	elif kind == "mini":
		is_mini = true
		base_size = Vector2(24, 26)
		max_health = 1.0
		walk_speed = 85.0
		chase_speed = 150.0
	health = max_health
	size = base_size
	return self


func _ready() -> void:
	add_to_group("enemy")
	if is_mini:
		add_to_group("grabbable")
	collision_layer = Game.LAYER_ENEMY
	collision_mask = Game.LAYER_WORLD | Game.LAYER_PROP
	_cs.shape = _shape
	add_child(_cs)
	_apply_size()


func _apply_size() -> void:
	_shape.size = size
	_cs.position = Vector2(0, -size.y * 0.5)
	queue_redraw()


func center() -> Vector2:
	return global_position + Vector2(0, -size.y * 0.5)


func get_rect() -> Rect2:
	return Rect2(global_position - Vector2(size.x * 0.5, size.y), size)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_flash = maxf(0.0, _flash - delta)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	if state == State.HELD:
		queue_redraw()
		return
	if shrunk:
		_shrink_left -= delta
		if _shrink_left <= 0.0:
			_try_grow()
	match state:
		State.PATROL:
			_patrol(delta)
		State.CHASE:
			_chase(delta)
		State.THROWN:
			_thrown(delta)
		State.STUNNED:
			_stunned(delta)
	if state == State.PATROL or state == State.CHASE:
		_contact_damage()
	_t += delta
	_walk_phase += absf(velocity.x) * delta * 0.16
	modulate = Color(2.5, 2.5, 2.5) if _flash > 0.0 else Color.WHITE
	queue_redraw()


func _fall(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)


func _speed_mult() -> float:
	return 0.5 if shrunk else 1.0


func _turn() -> void:
	facing = -facing
	velocity.x = 0.0


func _ground_ahead() -> bool:
	var from := global_position + Vector2(facing * (size.x * 0.5 + 4.0), -4.0)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 28), Game.LAYER_WORLD | Game.LAYER_PROP)
	return not get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _can_see_player() -> bool:
	if shrunk or _player == null or _player.is_invisible or _player.health <= 0:
		return false
	var d := _player.center() - center()
	if absf(d.y) > 90.0 or d.length() > SIGHT_RANGE:
		return false
	if signf(d.x) != facing and absf(d.x) > 50.0:
		return false
	var q := PhysicsRayQueryParameters2D.create(center(), _player.center(), Game.LAYER_WORLD)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _patrol(delta: float) -> void:
	_fall(delta)
	velocity.x = move_toward(velocity.x, facing * walk_speed * _speed_mult(), 600.0 * delta)
	move_and_slide()
	if is_on_floor():
		var out_of_range := (facing < 0 and global_position.x < patrol_min) or (facing > 0 and global_position.x > patrol_max)
		if is_on_wall() or out_of_range or not _ground_ahead():
			_turn()
	if _can_see_player():
		state = State.CHASE


func _chase(delta: float) -> void:
	_fall(delta)
	var lost := _player == null or _player.is_invisible or _player.health <= 0 or shrunk \
		or center().distance_to(_player.center()) > LOSE_RANGE
	if lost:
		state = State.PATROL
		Fx.text(self, "?", center() + Vector2(0, -size.y * 0.8), Color(0.9, 0.9, 1))
		move_and_slide()
		return
	var dx := _player.global_position.x - global_position.x
	if absf(dx) > 8.0:
		facing = 1 if dx > 0.0 else -1
	var target := facing * chase_speed * _speed_mult()
	if absf(dx) <= 8.0 or (is_on_floor() and not _ground_ahead()):
		target = 0.0
	velocity.x = move_toward(velocity.x, target, 900.0 * delta)
	move_and_slide()


func _stunned(delta: float) -> void:
	_fall(delta)
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	move_and_slide()
	_stun_left -= delta
	if _stun_left <= 0.0 and is_on_floor():
		if _turn_after_stun != 0:
			facing = _turn_after_stun
			_turn_after_stun = 0
		state = State.PATROL


func _thrown(delta: float) -> void:
	_fall(delta)
	move_and_slide()
	for body in Game.bodies_in_rect(self, get_rect(), Game.LAYER_ENEMY, [get_rid()]):
		if body != self and body.has_method("take_hit"):
			body.call("take_hit", 2.0, velocity.normalized(), self, 320.0)
			_impact()
			return
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var other := get_slide_collision(i).get_collider()
			if other != null and other.has_method("break_wall"):
				other.call("break_wall")
		_impact()


func _impact() -> void:
	Fx.ring(self, center(), Color(1, 0.9, 0.6), 18)
	health -= 1.0
	if health <= 0.0:
		die()
		return
	state = State.STUNNED
	_stun_left = 0.6
	velocity.x *= 0.3


func _contact_damage() -> void:
	if shrunk or _player == null or _player.is_invisible or _player.health <= 0:
		return
	if get_rect().intersects(_player.get_rect()):
		_player.take_damage(1, center())


## Returns true if the hit landed (false if blocked by armor).
func take_hit(amount: float, dir: Vector2, _source: Node = null, knock := 240.0) -> bool:
	if _dead or state == State.HELD:
		return false
	if armored and not shrunk and dir.x != 0.0 and signf(dir.x) == -facing:
		Fx.text(self, "BLOCKED", center() + Vector2(0, -size.y * 0.7), Color(0.8, 0.85, 1))
		Fx.ring(self, center() + Vector2(facing * size.x * 0.5, 0), Color(0.8, 0.85, 1), 14)
		velocity.x = dir.x * 120.0
		return false
	health -= amount
	_flash = 0.12
	Fx.burst(self, center() - dir.normalized() * size.x * 0.4, Color(2.0, 1.7, 0.8), 8, 220.0)
	velocity = Vector2(signf(dir.x) * knock, -160.0)
	if health <= 0.0:
		die()
		return true
	if dir.x != 0.0 and state != State.THROWN:
		_turn_after_stun = -int(signf(dir.x))
	if state != State.THROWN:
		state = State.STUNNED
		_stun_left = stun_time
	return true


func shrink() -> void:
	if _dead or state == State.HELD:
		return
	if not shrunk:
		shrunk = true
		size = base_size * 0.5
		health = minf(health, 1.0)
		_apply_size()
		add_to_group("grabbable")
		if armored:
			armored = false
			Fx.text(self, "ARMOR OFF!", center() + Vector2(0, -30), Color("#ffd54f"))
		else:
			Fx.text(self, "Shrunk!", center() + Vector2(0, -30), Color("#ffd54f"))
		if state == State.CHASE:
			state = State.PATROL
	_shrink_left = SHRINK_TIME


func _try_grow() -> void:
	var r := Rect2(global_position - Vector2(base_size.x * 0.5 - 1.0, base_size.y + 1.0), base_size - Vector2(2, 2))
	if not Game.bodies_in_rect(self, r, Game.LAYER_WORLD).is_empty():
		_shrink_left = 0.5
		return
	shrunk = false
	size = base_size
	_apply_size()
	remove_from_group("grabbable")
	Fx.text(self, "Back to size", center() + Vector2(0, -30), Color(0.9, 0.9, 0.9))


func die() -> void:
	if _dead:
		return
	_dead = true
	Fx.ring(self, center(), Color(2.0, 1.2, 0.4), 34)
	Fx.burst(self, center(), Color(2.0, 1.1, 0.4), 18, 300.0)
	Fx.burst(self, center(), Color(0.75, 0.8, 0.88), 10, 200.0)
	Fx.text(self, "KO!", center() + Vector2(0, -20), Color(1, 0.8, 0.3))
	if _player != null and is_instance_valid(_player) and _player.held == self:
		_player.held = null
	queue_free()


func can_grab() -> bool:
	return (shrunk or is_mini) and not _dead and state != State.HELD and state != State.THROWN


func on_grabbed() -> void:
	state = State.HELD
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO


func on_released(vel: Vector2) -> void:
	collision_layer = Game.LAYER_ENEMY
	collision_mask = Game.LAYER_WORLD | Game.LAYER_PROP
	velocity = vel
	if vel.length() > 200.0:
		state = State.THROWN
	else:
		state = State.STUNNED
		_stun_left = 0.4


func _draw() -> void:
	# Art is designed 40 units tall (Patrol, Mini) or 50 (Armored).
	var k := size.y / (50.0 if base_size.y > 45.0 else 40.0)
	if is_on_floor():
		Paint.shadow(self, Vector2.ZERO, size.x * 0.55)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing * k, k))
	var bob := absf(sin(_walk_phase)) * 1.2
	if base_size.y > 45.0:
		_draw_armored(sin(_walk_phase), bob)
	else:
		_draw_patrol(sin(_walk_phase), bob)
	draw_set_transform(Vector2.ZERO)
	_draw_status_icon()


func _eye_color() -> Color:
	if state == State.CHASE:
		return Color(2.6, 0.35, 0.25)
	if state == State.STUNNED or state == State.THROWN:
		return Color(1.0, 0.8, 0.2)
	return Color(1.4, 0.25, 0.2)


## Patrol Robot facing right, feet at the origin, 40 units tall.
func _draw_patrol(sw: float, bob: float) -> void:
	var white := Color("#ffc58f") if is_mini else Color("#eef2f7")
	var steel := Color("#9aa7b8")
	var dark := Color("#3a4559")
	Paint.limb(self, Vector2(-5, -12), Vector2(-5.0 - sw * 4.0, -4), 4.0, steel)
	Paint.rrect(self, Rect2(-10.0 - sw * 4.0, -5, 11, 5), dark, 2.0, Paint.INK, 1.5)
	Paint.limb(self, Vector2(-8, -22 - bob), Vector2(-12.0 - sw * 3.0, -13 - bob), 3.5, steel)
	Paint.rrect(self, Rect2(-13, -28 - bob, 26, 17), white, 6.0, Paint.INK, 1.8)
	Paint.rrect(self, Rect2(-7, -24 - bob, 12, 9), Color("#c3cedb"), 3.0, Paint.INK, 1.2)
	draw_circle(Vector2(-1, -19.5 - bob), 2.0, _eye_color(), true, -1.0, true)
	Paint.limb(self, Vector2(5, -12), Vector2(5.0 + sw * 4.0, -4), 4.0, steel)
	Paint.rrect(self, Rect2(1.0 + sw * 4.0, -5, 11, 5), dark, 2.0, Paint.INK, 1.5)
	draw_line(Vector2(-2, -40 - bob), Vector2(-4, -46 - bob), Paint.INK, 1.5, true)
	draw_circle(Vector2(-4, -46 - bob), 2.2, Color(1.8, 0.3, 0.25), true, -1.0, true)
	Paint.circle(self, Vector2(1, -32 - bob), 10.5, white, Paint.INK, 1.8)
	Paint.rrect(self, Rect2(-2, -36 - bob, 13, 7.5), Color("#243049"), 3.0, Paint.INK, 1.2)
	draw_circle(Vector2(7, -32.3 - bob), 2.4, _eye_color(), true, -1.0, true)
	Paint.limb(self, Vector2(7, -22 - bob), Vector2(12.0 + sw * 3.0, -14 - bob), 3.5, steel)
	Paint.circle(self, Vector2(12.0 + sw * 3.0, -14 - bob), 3.0, dark, Paint.INK, 1.2)


## Armored Robot facing right, feet at the origin, 50 units tall.
func _draw_armored(sw: float, bob: float) -> void:
	var plate := Color("#4b5ea8")
	var plate_light := Color("#7083cc")
	var dark := Color("#283462")
	Paint.limb(self, Vector2(-7, -14), Vector2(-7.0 - sw * 3.0, -5), 6.0, dark)
	Paint.rrect(self, Rect2(-14.0 - sw * 3.0, -6, 14, 6), dark, 2.0, Paint.INK, 1.5)
	Paint.circle(self, Vector2(-14, -33 - bob), 8.0, plate, Paint.INK, 1.8)
	Paint.rrect(self, Rect2(-16, -40 - bob, 32, 27), plate, 8.0, Paint.INK, 2.0)
	Paint.rrect(self, Rect2(-9, -35 - bob, 18, 14), plate_light, 4.0, Paint.INK, 1.4)
	draw_circle(Vector2(0, -28 - bob), 3.0, _eye_color(), true, -1.0, true)
	Paint.limb(self, Vector2(7, -14), Vector2(7.0 + sw * 3.0, -5), 6.0, dark)
	Paint.rrect(self, Rect2(0.0 + sw * 3.0, -6, 14, 6), dark, 2.0, Paint.INK, 1.5)
	Paint.rrect(self, Rect2(-9, -52 - bob, 20, 14), dark, 5.0, Paint.INK, 1.8)
	Paint.rrect(self, Rect2(-3, -48 - bob, 13, 5.5), Color("#141b30"), 2.0, Paint.INK, 0.0)
	draw_line(Vector2(0, -45.2 - bob), Vector2(9, -45.2 - bob), _eye_color(), 2.4, true)
	Paint.circle(self, Vector2(13, -33 - bob), 8.5, plate_light, Paint.INK, 1.8)
	if armored:
		var pulse := 0.75 + 0.25 * sin(_t * 6.0)
		Paint.rrect(self, Rect2(15, -48 - bob, 9, 42), Color("#9fb4d8"), 4.0, Paint.INK, 2.0)
		Paint.ellipse(self, Vector2(24, -27 - bob), 5.0, 24.0, Color(0.3, 0.9, 1.6, 0.35 * pulse), Color(0, 0, 0, 0), 0.0)
		Paint.ring(self, Vector2(24, -27 - bob), 5.0, 24.0, Color(0.5, 1.5, 2.4, pulse), 2.0)
	else:
		Paint.limb(self, Vector2(10, -28 - bob), Vector2(18.0 + sw * 3.0, -18 - bob), 5.0, plate)
		draw_line(Vector2(-12, -38 - bob), Vector2(-4, -30 - bob), Paint.INK, 1.2, true)


func _draw_status_icon() -> void:
	var text := ""
	var col := Color.WHITE
	if state == State.CHASE:
		text = "!"
		col = Color("#ff3b30")
	elif state == State.STUNNED or state == State.THROWN:
		for i in 3:
			var a := _t * 6.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 10.0, -size.y - 6.0 + sin(a) * 3.0), 2.5, Color(2.0, 1.8, 0.4), true, -1.0, true)
		return
	elif shrunk:
		text = "%d" % ceili(_shrink_left)
		col = Color("#b38f00")
	if text == "":
		return
	var top := -size.y - 30.0
	Paint.rrect(self, Rect2(-10, top, 20, 21), Color.WHITE, 8.0, Paint.INK, 1.8)
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(font, Vector2(-w * 0.5, top + 17.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col)
