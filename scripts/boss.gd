class_name Boss
extends CharacterBody2D
## Robot Commander Miguel. Origin is at the feet.
## His energy shield blocks every hit from the front. Ways to hurt him:
## - hit his back (get there with a door, invisible, or by slipping under him while shrunk),
## - drop things on him from above (lob a Mini Bot over the shield with the Super Gloves),
## - hit him while he is dazed after charging into a wall (shield down).
## He flattens into a low bull-rush when he charges, so a full jump clears him and lands Doraemon
## behind him. Back hits stagger him, so getting behind him is worth several hits.
## Below half health he turns faster, charges harder and summons more Mini Bots.

signal defeated

enum State { WALK, WINDUP, CHARGE, DAZED, SUMMON, DEAD }

const GRAVITY := 1500.0
const SIZE := Vector2(96, 134)
## Gap between his body and the floor: Doraemon fits under him only while shrunk.
const LEG_GAP := 30.0
## Height of his bull-rush: a held jump clears this.
const CHARGE_HEIGHT := 70.0
const CHARGE_SQUASH := 0.45

var display_name := "MIGUEL, ROBOT COMMANDER"
var max_health := 24.0
var health := 24.0
var facing := -1
var state := State.WALK
var phase_two := false

var _state_left := 2.5
var _summon_left := 5.0
var _turn_delay := 0.0
var _behind_total := 0.0
var _windup_total := 0.85
var _wander_dir := -1
var _t := 0.0
var _flash := 0.0
var _walk_phase := 0.0
var _player: Player


func _ready() -> void:
	add_to_group("boss")
	collision_layer = Game.LAYER_ENEMY
	collision_mask = Game.LAYER_WORLD
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -SIZE.y * 0.5)
	add_child(cs)


func center() -> Vector2:
	return global_position + Vector2(0, -SIZE.y * 0.6)


## The part of him that hurts on contact: his body, not the gap between his legs.
func body_rect() -> Rect2:
	if state == State.CHARGE:
		return Rect2(global_position + Vector2(-SIZE.x * 0.5, -CHARGE_HEIGHT), Vector2(SIZE.x, CHARGE_HEIGHT - LEG_GAP))
	return Rect2(global_position + Vector2(-SIZE.x * 0.5, -SIZE.y), Vector2(SIZE.x, SIZE.y - LEG_GAP))


func _physics_process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	if state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		queue_redraw()
		return
	_summon_left -= delta
	_state_left -= delta
	match state:
		State.WALK:
			_walk(delta)
		State.WINDUP:
			velocity.x = 0.0
			if _state_left <= 0.0:
				state = State.CHARGE
				Fx.text(self, "CHARGE!", center() + Vector2(0, -90), Color("#ff6b4a"))
		State.CHARGE:
			velocity.x = facing * (580.0 if phase_two else 480.0)
			if is_on_wall():
				_crash()
		State.DAZED:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _state_left <= 0.0:
				_enter_walk()
		State.SUMMON:
			velocity.x = 0.0
			if _state_left <= 0.0:
				_summon()
				_enter_walk()
	move_and_slide()
	_walk_phase += absf(velocity.x) * delta * 0.06
	_contact_damage()
	modulate = Color(2.2, 2.2, 2.2) if _flash > 0.0 else Color.WHITE
	queue_redraw()


func _sees_player() -> bool:
	return _player != null and not _player.is_invisible and _player.health > 0


func _enter_walk() -> void:
	state = State.WALK
	_state_left = randf_range(1.0, 1.6) if phase_two else randf_range(1.4, 2.2)
	_turn_delay = 0.0
	_behind_total = 0.0


func _walk(delta: float) -> void:
	if not _sees_player():
		# Lost track of Doraemon: wander and never turn toward him.
		if is_on_wall():
			_wander_dir = -_wander_dir
		facing = _wander_dir
		velocity.x = move_toward(velocity.x, facing * 50.0, 400.0 * delta)
		if _state_left <= 0.0:
			_state_left = 1.0
		return
	var dx := _player.global_position.x - global_position.x
	var want := 1 if dx > 0.0 else -1
	if want != facing:
		# Doraemon got behind him: he takes a moment to turn around.
		_turn_delay += delta
		_behind_total += delta
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if _turn_delay > (1.2 if phase_two else 1.8) or _behind_total > (3.0 if phase_two else 4.0):
			facing = want
			_turn_delay = 0.0
			_behind_total = 0.0
			_state_left = minf(_state_left, 0.9)
			Fx.text(self, "!", center() + Vector2(0, -90), Color("#ff6b4a"))
		return
	_turn_delay = 0.0
	_behind_total = 0.0
	_wander_dir = facing
	var speed := 110.0 if phase_two else 70.0
	velocity.x = move_toward(velocity.x, facing * speed if absf(dx) > 150.0 else 0.0, 500.0 * delta)
	if _state_left <= 0.0:
		if _summon_left <= 0.0:
			state = State.SUMMON
			_state_left = 0.7
			_summon_left = 7.0 if phase_two else 9.0
			Fx.text(self, "MINI BOTS, ATTACK!", center() + Vector2(0, -90), Color("#ffc58f"))
		else:
			state = State.WINDUP
			_windup_total = 0.6 if phase_two else 0.85
			_state_left = _windup_total


func _crash() -> void:
	state = State.DAZED
	_state_left = 2.8
	velocity.x = -facing * 160.0
	Fx.burst(self, global_position + Vector2(facing * SIZE.x * 0.5, -SIZE.y * 0.5), Color(2.2, 1.8, 0.8), 20, 320.0)
	Fx.text(self, "CRASH! Shield down!", center() + Vector2(0, -90), Color("#ffd23f"))
	if _player != null:
		_player.shake(8.0, 0.35)


func _summon() -> void:
	var level := get_parent() as Level
	if level == null:
		return
	var count := 3 if phase_two else 2
	var alive := get_tree().get_nodes_in_group("minibot").size()
	for i in mini(count, 3 - alive):
		var at := Vector2(global_position.x + facing * (SIZE.x * 0.5 + 20.0 + i * 30.0), Level.FLOOR_Y)
		at.x = clampf(at.x, 40.0, level.room_w - 40.0)
		var bot := level.robot("mini", at, 40.0, level.room_w - 40.0, facing)
		bot.add_to_group("minibot")
		bot.velocity = Vector2(facing * 200.0, -300.0)
		Fx.ring(self, bot.center(), Color(2.0, 1.2, 0.5), 18)


func _contact_damage() -> void:
	# While he is dazed Doraemon can walk straight through him to reach his back.
	if _player == null or _player.health <= 0 or _player.is_invisible or state == State.DAZED:
		return
	if body_rect().intersects(_player.get_rect()):
		_player.take_damage(2 if state == State.CHARGE and phase_two else 1, center())


func shrink() -> void:
	Fx.text(self, "Too big to shrink!", center() + Vector2(0, -90), Color("#ffd54f"))


func is_shield_up() -> bool:
	return state != State.DAZED and state != State.DEAD


## Returns true if the hit landed.
func take_hit(amount: float, dir: Vector2, source: Node = null, _knock := 0.0) -> bool:
	if state == State.DEAD:
		return false
	var from_front := dir.x != 0.0 and signf(dir.x) == -facing
	# Anything coming down steeply, or arriving above his shoulders, has cleared the shield.
	var from_above := dir.y > 0.6
	var src := source as Node2D
	if src != null and not src is Player and src.global_position.y < global_position.y - SIZE.y + 24.0:
		from_above = true
	if is_shield_up() and from_front and not from_above:
		Fx.text(self, "BLOCKED", center() + Vector2(facing * 70.0, -40), Color(0.8, 0.9, 1))
		Fx.ring(self, global_position + Vector2(facing * (SIZE.x * 0.5 + 16.0), -SIZE.y * 0.55), Color(0.6, 1.6, 2.4), 30)
		return false
	health -= amount
	_flash = 0.12
	Fx.burst(self, center(), Color(2.2, 1.4, 0.5), 12, 260.0)
	if from_above:
		Fx.text(self, "BONK!", center() + Vector2(0, -80), Color("#ffd23f"))
	if not phase_two and health <= max_health * 0.5:
		phase_two = true
		Fx.text(self, "MIGUEL IS FURIOUS!", center() + Vector2(0, -110), Color("#ff6b4a"))
	if health <= 0.0:
		_die()
	elif state == State.WALK:
		# A hit on the back staggers him and buys more time before he turns around.
		_turn_delay = maxf(0.0, _turn_delay - 0.2)
	return true


func _die() -> void:
	state = State.DEAD
	collision_layer = 0
	for minibot in get_tree().get_nodes_in_group("minibot"):
		if is_instance_valid(minibot):
			minibot.die()
	if _player != null:
		_player.shake(10.0, 1.0)
	for i in 6:
		var p := global_position + Vector2(randf_range(-50, 50), -randf_range(20, 140))
		Fx.ring(self, p, Color(2.4, 1.2, 0.4), 50)
		Fx.burst(self, p, Color(2.4, 1.3, 0.5), 18, 360.0)
	Fx.text(self, "MIGUEL DEFEATED!", center() + Vector2(0, -110), Color("#ffd23f"))
	defeated.emit()


# --- Art ---------------------------------------------------------------------------------------

func _draw() -> void:
	Paint.shadow(self, Vector2.ZERO, 58.0)
	var shake := Vector2.ZERO
	if state == State.WINDUP:
		shake = Vector2(randf_range(-2, 2), randf_range(-1, 1))
	var squash := 1.0
	if state == State.WINDUP:
		squash = lerpf(CHARGE_SQUASH, 1.0, clampf(_state_left / _windup_total, 0.0, 1.0))
	elif state == State.CHARGE:
		squash = CHARGE_SQUASH
	draw_set_transform(shake, 0.0, Vector2(facing * (2.0 - squash * 0.9 - 0.1), squash))
	if state == State.DEAD:
		_draw_wreck()
	else:
		_draw_miguel()
	draw_set_transform(Vector2.ZERO)
	if state == State.DAZED:
		for i in 4:
			var a := _t * 5.0 + i * TAU / 4.0
			draw_circle(Vector2(cos(a) * 30.0, -SIZE.y - 40.0 + sin(a) * 6.0), 4.0, Color(2.2, 2.0, 0.5), true, -1.0, true)
	elif state == State.WINDUP:
		Paint.rrect(self, Rect2(-14, -SIZE.y - 72, 28, 28), Color.WHITE, 10.0, Paint.INK, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-5, -SIZE.y - 50), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ff3b30"))


## Miguel facing right, feet at the origin.
func _draw_miguel() -> void:
	var plate := Color("#3d4c9e") if not phase_two else Color("#5a3d9e")
	var light := Color("#6274d0") if not phase_two else Color("#8a62d0")
	var dark := Color("#232b5c")
	var sw := sin(_walk_phase)
	var eye := Color(3.0, 0.4, 0.3) if state in [State.WINDUP, State.CHARGE] or phase_two else Color(2.0, 0.3, 0.25)
	if state == State.DAZED:
		eye = Color(0.6, 0.5, 0.2)

	# Back arm, legs.
	Paint.limb(self, Vector2(-30, -100), Vector2(-46, -62), 14.0, dark)
	for lx in [-24.0, 22.0]:
		var step: float = sw * 6.0 * (1.0 if lx > 0.0 else -1.0)
		Paint.limb(self, Vector2(lx, -LEG_GAP - 6.0), Vector2(lx + step, -8), 12.0, dark)
		Paint.rrect(self, Rect2(lx + step - 14.0, -12, 30, 12), Color("#1a2046"), 4.0, Paint.INK, 2.0)

	# Torso.
	Paint.rrect(self, Rect2(-48, -SIZE.y, 96, SIZE.y - LEG_GAP), plate, 18.0, Paint.INK, 3.0)
	Paint.rrect(self, Rect2(-30, -112, 64, 54), light, 10.0, Paint.INK, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-12, -72), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#ffd23f"))
	for i in 3:
		draw_line(Vector2(-40, -54 + i * 8.0), Vector2(40, -54 + i * 8.0), dark, 3.0)
	# Weak spot on his back.
	Paint.rrect(self, Rect2(-56, -112, 12, 60), Color("#c0392b"), 4.0, Paint.INK, 2.0)
	var blink := int(_t * 3.0) % 2 == 0
	draw_circle(Vector2(-50, -82), 4.0, Color(2.6, 0.4, 0.3) if blink else Color(0.6, 0.1, 0.1), true, -1.0, true)

	# Shoulders and head.
	Paint.circle(self, Vector2(-44, -122), 20.0, light, Paint.INK, 2.5)
	Paint.rrect(self, Rect2(-24, -SIZE.y - 34, 52, 38), dark, 10.0, Paint.INK, 2.5)
	Paint.rrect(self, Rect2(-14, -SIZE.y - 24, 40, 12), Color("#0d1226"), 4.0, Paint.INK, 1.5)
	draw_line(Vector2(-8, -SIZE.y - 18), Vector2(22, -SIZE.y - 18), eye, 4.0, true)
	# Commander crest.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -SIZE.y - 34), Vector2(-10, -SIZE.y - 54), Vector2(2, -SIZE.y - 40),
		Vector2(14, -SIZE.y - 56), Vector2(22, -SIZE.y - 34),
	]), Color("#ffd23f"))
	draw_polyline(PackedVector2Array([
		Vector2(-18, -SIZE.y - 34), Vector2(-10, -SIZE.y - 54), Vector2(2, -SIZE.y - 40),
		Vector2(14, -SIZE.y - 56), Vector2(22, -SIZE.y - 34),
	]), Paint.INK, 2.0, true)
	Paint.circle(self, Vector2(46, -122), 22.0, light, Paint.INK, 2.5)

	# Front arm: a big fist.
	var fist := Vector2(54, -70) if state != State.CHARGE else Vector2(70, -96)
	Paint.limb(self, Vector2(40, -108), fist, 16.0, plate)
	Paint.circle(self, fist, 14.0, dark, Paint.INK, 2.5)

	# Energy shield in front.
	if is_shield_up():
		var pulse := 0.75 + 0.25 * sin(_t * 7.0)
		var c := Vector2(SIZE.x * 0.5 + 18.0, -SIZE.y * 0.52)
		Paint.ellipse(self, c, 12.0, SIZE.y * 0.5, Color(0.3, 0.9, 1.6, 0.3 * pulse), Color(0, 0, 0, 0), 0.0)
		Paint.ring(self, c, 12.0, SIZE.y * 0.5, Color(0.5, 1.6, 2.6, pulse), 3.0)
	elif state == State.DAZED and int(_t * 16.0) % 3 == 0:
		var c2 := Vector2(SIZE.x * 0.5 + 18.0, -SIZE.y * 0.52)
		Paint.ring(self, c2, 12.0, SIZE.y * 0.5, Color(0.5, 1.6, 2.6, 0.3), 1.5)

	if state == State.CHARGE:
		for i in 4:
			var y := -110.0 + i * 24.0
			draw_line(Vector2(-60.0 - i * 6.0, y), Vector2(-110.0 - i * 6.0, y), Color(1, 1, 1, 0.5), 3.0)


func _draw_wreck() -> void:
	Paint.rrect(self, Rect2(-60, -46, 120, 46), Color("#2c3560"), 12.0, Paint.INK, 3.0)
	Paint.rrect(self, Rect2(-24, -70, 52, 30), Color("#232b5c"), 10.0, Paint.INK, 2.5)
	draw_line(Vector2(-14, -55), Vector2(16, -55), Color(0.4, 0.1, 0.1), 3.0)
	for i in 3:
		var p := Vector2(-30.0 + i * 30.0, -60.0 - fposmod(_t * 40.0 + i * 25.0, 90.0))
		draw_circle(p, 10.0 + fposmod(_t * 10.0 + i * 6.0, 14.0), Color(0.5, 0.5, 0.55, 0.35), true, -1.0, true)
