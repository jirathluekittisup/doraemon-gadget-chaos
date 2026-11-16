class_name Level
extends Node2D
## Shared level setup: backdrop, glow, HUD, player, alarms, death and completion.
## Subclasses set the fields below in _init() and place everything in build().

const FLOOR_Y := 600.0

var level_name := "Level"
var room_w := 3600.0
## World x where the neighborhood ends and the factory interior begins (0 = all factory).
var factory_x := INF
var player_start := Vector2(120, FLOOR_Y)
## [max_x, text] pairs for the HUD objective box.
var objectives: Array = []
var camera_zoom := 1.3
## How far below the floor the camera may show.
var camera_bottom_pad := 150.0

var player: Player
var hud: Hud
## Security bunkers from cape_bell(): {"x", "bell", "gate"}.
var cape_bunkers: Array[Dictionary] = []
var finished := false
var _shutter_timers := {}


func _ready() -> void:
	if not Game.is_valid_loadout(Game.loadout):
		Game.loadout.assign(Game.DEFAULT_LOADOUT)

	var backdrop := Backdrop.new()
	backdrop.factory_x = factory_x
	backdrop.room_w = room_w
	backdrop.floor_y = FLOOR_Y
	add_child(backdrop)
	_add_glow()

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.level_name = level_name
	layer.add_child(hud)

	var ground := solid(Rect2(-40, FLOOR_Y, room_w + 80, 200), "ground")
	ground.factory_x = factory_x
	solid(Rect2(-40, -900, 40, 1700), "boundary")
	solid(Rect2(room_w, -900, 40, 1700), "boundary")

	build()

	player = Player.new()
	player.position = player_start
	add_child(player)
	player.died.connect(_on_player_died)
	player.camera.limit_left = 0
	player.camera.limit_right = int(room_w)
	player.camera.limit_top = -320
	player.camera.limit_bottom = int(FLOOR_Y + camera_bottom_pad)
	player.camera.zoom = Vector2(camera_zoom, camera_zoom)
	player.camera.reset_smoothing()
	hud.player = player
	hud.objectives = objectives


## Override to place the level's geometry, enemies and pickups.
func build() -> void:
	pass


func _add_glow() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.1
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


# --- Building blocks ---------------------------------------------------------------------------

func solid(rect: Rect2, style := "block") -> Solid:
	var s := Solid.new().setup(rect, style)
	add_child(s)
	return s


func cracked_wall(rect: Rect2) -> CrackedWall:
	var w := CrackedWall.new()
	w.setup(rect)
	add_child(w)
	return w


func conveyor(rect: Rect2, speed: float) -> Solid:
	var s := Solid.new().setup(rect, "conveyor")
	s.belt_speed = speed
	add_child(s)
	return s


func add_shutter(rect: Rect2) -> Shutter:
	var s := Shutter.new()
	s.setup(rect)
	add_child(s)
	s.set_closed(false)
	return s


func decor(kind: String, rect: Rect2) -> Decor:
	var d := Decor.new()
	d.kind = kind
	d.position = rect.position
	d.size = rect.size
	add_child(d)
	return d


func crate(pos: Vector2) -> Prop:
	var c := Prop.new()
	c.position = pos
	add_child(c)
	return c


func robot(kind: String, pos: Vector2, range_min: float, range_max: float, facing := -1) -> Robot:
	var r := Robot.new().setup(kind, pos, range_min, range_max)
	r.facing = facing
	add_child(r)
	return r


func pickup(kind: String, pos: Vector2) -> Pickup:
	var p := Pickup.new()
	p.kind = kind
	p.position = pos
	p.collected.connect(_on_collected)
	add_child(p)
	return p


## A Golden Bell that needs the given gadgets. It only counts toward the HUD total when the
## loadout has them, so the total is what this loadout can actually collect.
func bell(pos: Vector2, needs: Array) -> Pickup:
	var b := pickup("bell", pos)
	if needs.all(func(id): return Game.loadout.has(id)):
		hud.bells_total += 1
	return b


## Security bunker starting at x: a low building (its roof is part of the path) whose entrance
## tunnel has a laser along the floor. A visible Doraemon, at any size, trips it and the shutter
## slams before he reaches the bell room; a jammer stops Anywhere Doors inside. Only the
## Invisibility Cape gets this bell.
func cape_bell(x: float) -> Pickup:
	decor("interior", Rect2(x, 540, 440, 60))
	solid(Rect2(x, 520, 460, 20), "metal")
	solid(Rect2(x + 440, 540, 20, 60), "metal")
	var gate := add_shutter(Rect2(x + 280, 540, 20, 60))
	laser(Vector2(x + 6, 590), 268.0, gate, [])
	var jammer := DoorJammer.new()
	jammer.position = Vector2(x, 520)
	jammer.size = Vector2(460, 80)
	add_child(jammer)
	var b := bell(Vector2(x + 370, 584), ["invisibility_cape"])
	cape_bunkers.append({"x": x, "bell": b, "gate": gate})
	add_sign("Security bunker: the laser shuts the door\nand doors are jammed. Sneak in invisible!", Vector2(x + 40, 420))
	return b


func crusher(x: float, top_y := 300.0, phase := 0.0) -> Crusher:
	var c := Crusher.new()
	c.position = Vector2(x, 0)
	c.top_y = top_y
	c.phase = phase
	add_child(c)
	return c


func door_pad(pos: Vector2, shot_dir: int) -> DoorPad:
	var d := DoorPad.new()
	d.position = pos
	d.shot_dir = shot_dir
	add_child(d)
	return d


## A target at the end of a short tube, centered on y, with its back against x.
## face: -1 opens to the left, 1 opens to the right.
func target_tube(x: float, y: float, face: int, open_period := 0.0) -> TargetSwitch:
	var tube_x := x - 80.0 if face < 0 else x
	solid(Rect2(tube_x, y - 34.0, 80, 14), "metal")
	solid(Rect2(tube_x, y + 20.0, 80, 14), "metal")
	var t := TargetSwitch.new()
	t.face = face
	t.open_period = open_period
	t.position = Vector2(x - TargetSwitch.SIZE.x if face < 0 else x, y - TargetSwitch.SIZE.y * 0.5)
	add_child(t)
	return t


func electric_floor(x0: float, x1: float) -> ElectricFloor:
	var e := ElectricFloor.new()
	e.position = Vector2(x0, FLOOR_Y)
	e.width = x1 - x0
	add_child(e)
	return e


## A laser tripwire; tripping it closes `gate` for a while and sends robots from `spawns`.
func laser(pos: Vector2, length: float, gate: Shutter, spawns: Array) -> SecurityLaser:
	var l := SecurityLaser.new()
	l.position = pos
	l.length = length
	l.tripped.connect(alarm.bind(gate, spawns))
	add_child(l)
	return l


## A sweeping security camera; same alarm as laser().
func security_camera(pos: Vector2, sweep_from: float, sweep_to: float, gate: Shutter, spawns: Array) -> SecurityCamera:
	var c := SecurityCamera.new()
	c.position = pos
	c.sweep_from = sweep_from
	c.sweep_to = sweep_to
	c.tripped.connect(alarm.bind(gate, spawns))
	add_child(c)
	return c


func exit_door(x: float) -> ExitDoor:
	var e := ExitDoor.new()
	e.position = Vector2(x, FLOOR_Y)
	e.entered.connect(complete)
	add_child(e)
	return e


func add_sign(text: String, pos: Vector2, font_size := 14, col := Paint.INK, bg := Color(1, 1, 1, 0.92)) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.z_index = 5
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	var sb := Paint.box(bg, 8.0, Paint.INK, 2.0, 4.0).duplicate() as StyleBoxFlat
	sb.set_content_margin_all(8)
	l.add_theme_stylebox_override("normal", sb)
	add_child(l)
	return l


# --- Alarms, death, completion -----------------------------------------------------------------

func alarm(_pos: Vector2, gate: Shutter, spawns: Array) -> void:
	if finished or player.health <= 0:
		return
	Fx.text(self, "ALARM!", player.center() + Vector2(0, -50), Color(1, 0.3, 0.3))
	if gate != null and not gate.closed and not gate.get_global_rect().intersects(player.get_rect()):
		gate.set_closed(true)
	if gate != null and gate.closed:
		# Each new trip keeps it shut, so it can't reopen while Doraemon is still in view.
		_shutter_timers[gate] = 5.0
	var alive := get_tree().get_nodes_in_group("alarm_bot").size()
	for i in mini(spawns.size(), 4 - alive):
		var at: Vector2 = spawns[i]
		var r := robot("patrol", at, at.x - 200.0, at.x + 200.0)
		r.add_to_group("alarm_bot")
		r.facing = 1 if player.global_position.x > at.x else -1
		r.state = Robot.State.CHASE
		Fx.ring(self, r.center(), Color(2.0, 0.4, 0.3), 24)


func _process(delta: float) -> void:
	for gate in _shutter_timers.keys():
		_shutter_timers[gate] -= delta
		if _shutter_timers[gate] <= 0.0:
			_shutter_timers.erase(gate)
			if is_instance_valid(gate):
				gate.set_closed(false)


func _on_collected(kind: String) -> void:
	if kind == "bell":
		hud.bells += 1


func _on_player_died() -> void:
	hud.show_message("Game Over", "Restarting with the same loadout...")
	await get_tree().create_timer(1.5).timeout
	Game.restart_level()


func complete(title := "Level Clear!", extra := "") -> void:
	if finished:
		return
	finished = true
	player.set_physics_process(false)
	Game.on_level_complete()
	var sub := "Golden Bells %d / %d" % [hud.bells, hud.bells_total]
	if extra != "":
		sub = extra + "\n" + sub
	hud.show_message(title, sub + "   ·   Enter: continue   ·   R: replay")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		Game.restart_level()
	elif finished and event.is_action_pressed("confirm"):
		Game.open_loadout()
	elif event.is_action_pressed("back"):
		Game.open_loadout()
