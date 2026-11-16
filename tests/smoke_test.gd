extends Node
## Headless smoke test: godot --headless res://tests/smoke_test.tscn

var room: Node2D
var player: Player
var failures := 0


func _ready() -> void:
	Game.save_enabled = false
	await _run()
	await _run_levels()
	await _run_boss()
	await _run_door_rules()
	await _run_new_level_2()
	await _run_bell_rules()
	print("SMOKE TEST DONE, failures: %d" % failures)
	get_tree().quit(failures)


func check(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func load_room(loadout: Array, scene := "res://scenes/test_room.tscn") -> void:
	if room != null:
		room.queue_free()
		await frames(2)
	Game.loadout.assign(loadout)
	room = load(scene).instantiate()
	add_child(room)
	player = room.player
	await frames(5)


func aim_at(world: Vector2) -> void:
	player.aim_override = world
	player.facing = 1 if world.x >= player.global_position.x else -1


func robots() -> Array:
	return get_tree().get_nodes_in_group("enemy").filter(func(r): return is_instance_valid(r) and not r.is_queued_for_deletion())


func robot_near(x: float) -> Robot:
	for r in robots():
		if absf(r.global_position.x - x) < 200.0:
			return r
	return null


func place(pos: Vector2) -> void:
	player.global_position = pos
	player.velocity = Vector2.ZERO
	player.camera.reset_smoothing()
	await frames(3)


func _run() -> void:
	await load_room(["air_cannon", "small_light", "anywhere_door"])
	check(player.gadgets.size() == 3, "player gets 3 gadgets")
	check(Game.is_valid_loadout(["air_cannon", "small_light", "anywhere_door"]), "1 attack + 2 utility is valid")
	check(not Game.is_valid_loadout(["air_cannon", "super_gloves", "small_light"]), "2 attacks is invalid")
	check(not Game.is_valid_loadout(["anywhere_door", "small_light", "invisibility_cape"]), "3 utilities is invalid")
	aim_at(player.center() + Vector2(300, 0))
	await frames(1)
	check(player.aim_dir().x > 0.9, "aim follows mouse")

	# Air Cannon kills a patrol robot in 2 hits.
	var r := robot_near(950)
	r.set_physics_process(false)
	r.global_position = Vector2(700, 600)
	await place(Vector2(500, 600))
	aim_at(r.center())
	player.gadgets[0].try_use()
	await frames(30)
	check(is_instance_valid(r) and r.health == 1.0, "cannon hit 1 -> hp 1")
	player.gadgets[0].cooldown_left = 0
	aim_at(r.center())
	player.gadgets[0].try_use()
	await frames(30)
	check(not is_instance_valid(r) or r.is_queued_for_deletion(), "cannon hit 2 -> patrol robot KO")

	# Armored robot blocks from the front, takes damage from behind.
	var a := robot_near(1520)
	a.set_physics_process(false)
	a.global_position = Vector2(1500, 600)
	a.facing = -1
	check(a.take_hit(1.0, Vector2(1, 0)) == false, "armored blocks front hit")
	check(a.take_hit(1.0, Vector2(-1, 0)) == true and a.health == 1.0, "armored takes hit from behind")
	a.health = 2.0
	a.state = Robot.State.PATROL

	# Small Light strips armor; Gloves grab and throw.
	await place(Vector2(1380, 600))
	aim_at(a.center())
	player.active_slot = 1
	player.gadgets[1].try_use()
	await frames(2)
	check(a.shrunk and not a.armored, "small light shrinks armored robot and strips armor")
	a.set_physics_process(true)
	await place(a.global_position + Vector2(-20, 0))
	check(player.try_grab() and player.held == a, "gloves grab shrunk robot")
	player.throw_held(Vector2(400, -100))
	await frames(40)
	check(not is_instance_valid(a) or a.is_queued_for_deletion() or a.state != Robot.State.HELD, "thrown robot leaves hands")

	# Gloves break the cracked wall.
	await load_room(["super_gloves", "small_light", "anywhere_door"])
	await place(Vector2(960, 440))
	aim_at(Vector2(1100, 400))
	var walls_before := room.get_children().filter(func(n): return n is CrackedWall).size()
	player.active_slot = 0
	player.gadgets[0].try_use()
	await frames(3)
	var walls_after := room.get_children().filter(func(n): return n is CrackedWall and not n.is_queued_for_deletion()).size()
	check(walls_before == 1 and walls_after == 0, "gloves punch breaks cracked wall")

	# Shrunk Doraemon passes under the laser without alarm; normal size trips it.
	var bots_before := robots().size()
	player.set_shrunk(true)
	await place(Vector2(1800, 600))
	await frames(10)
	check(robots().size() == bots_before and not room.shutter.closed, "shrunk Doraemon slips under laser")
	player.set_shrunk(false)
	await frames(10)
	check(robots().size() == bots_before + 2, "visible Doraemon trips laser -> 2 robots spawn")

	# Crusher crushes a robot under it.
	var c := robot_near(2880)
	c.set_physics_process(false)
	c.global_position = Vector2(2620, 600)
	c.set_physics_process(true)
	c.walk_speed = 0.0
	await frames(200)
	check(not is_instance_valid(c) or c.is_queued_for_deletion(), "crusher destroys robot")

	# Cape: laser ignores invisible Doraemon.
	await load_room(["air_cannon", "anywhere_door", "invisibility_cape"])
	player.active_slot = 2
	player.gadgets[2].try_use()
	check(player.is_invisible, "cape makes Doraemon invisible")
	var n := robots().size()
	await place(Vector2(1900, 600))
	await frames(20)
	check(robots().size() == n, "laser ignores invisible Doraemon")

	# Anywhere Door teleports Doraemon.
	await place(Vector2(1650, 600))
	player.reveal()
	var door: AnywhereDoor = player.gadgets[1]
	aim_at(Vector2(1600, 562))
	door.try_use()
	aim_at(Vector2(2340, 572))
	door.alt_cooldown_left = 0
	door.try_alt()
	await frames(20)
	player.global_position = Vector2(1530, 600)
	player.velocity = Vector2(260, 0)
	var went := false
	for i in 60:
		Input.action_press("move_right")
		await frames(1)
		if player.global_position.x > 2330:
			went = true
			break
	Input.action_release("move_right")
	check(went, "walking into orange door exits at blue door past the laser (x=%d)" % player.global_position.x)

	# Loadout menu: picking a second attack swaps it in; a third utility is refused.
	Game.loadout.assign(["air_cannon", "anywhere_door", "small_light"])
	var menu: Control = load("res://scenes/loadout.tscn").instantiate()
	add_child(menu)
	await frames(2)
	menu._cards["super_gloves"].button_pressed = true
	check(menu._selected.has("super_gloves") and not menu._selected.has("air_cannon") and not menu._cards["air_cannon"].button_pressed, "menu swaps attack gadget")
	menu._cards["invisibility_cape"].button_pressed = true
	check(not menu._selected.has("invisibility_cape") and not menu._cards["invisibility_cape"].button_pressed, "menu refuses third utility")
	check(not menu._start.disabled, "start enabled for 1 attack + 2 utility")
	menu._cards["small_light"].button_pressed = false
	check(menu._start.disabled, "start disabled with only 1 utility")
	menu.queue_free()

	# Death restarts.
	player.take_damage(99, player.global_position)
	check(player.health == 0, "player can die")


func walk(action: String, n: int) -> void:
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)


## Walks with real input until Doraemon is within a few px of x.
func walk_to(x: float) -> void:
	for i in 240:
		var dx := x - player.global_position.x
		if absf(dx) < 5.0:
			break
		var action := "move_right" if dx > 0.0 else "move_left"
		Input.action_press(action)
		await frames(1)
		Input.action_release(action)
	player.velocity.x = 0.0
	await frames(2)


## Jumps with real input, steering toward x, and returns once he has landed.
## With rise_first he goes straight up until his feet clear to_y (for holes in a ceiling).
func hop(x: float, to_y: float, rise_first := false) -> void:
	Input.action_press("jump")
	var left_floor := false
	for i in 150:
		await frames(1)
		if not player.is_on_floor():
			left_floor = true
		elif left_floor:
			break
		Input.action_release("move_left")
		Input.action_release("move_right")
		if rise_first and player.global_position.y > to_y - 2.0 and player.velocity.y < 0.0:
			continue
		var dx := x - player.global_position.x
		if absf(dx) > 4.0:
			Input.action_press("move_right" if dx > 0.0 else "move_left")
	Input.action_release("jump")
	Input.action_release("move_left")
	Input.action_release("move_right")
	await frames(3)


func on_ledge(y: float, what: String) -> void:
	check(absf(player.global_position.y - y) < 2.0, "%s (y=%d)" % [what, player.global_position.y])


## Climbs every required stairway using only move and jump input.
func check_climbs(loadout: Array) -> void:
	await load_room(loadout, "res://scenes/level_1.tscn")
	await place(Vector2(3705, 600))
	await hop(3640, 520)
	on_ledge(520, "building B: floor to first stair")
	await walk_to(3660)
	await hop(3770, 450)
	on_ledge(450, "building B: first to second stair")
	await walk_to(3735)
	await hop(3640, 380)
	on_ledge(380, "building B: second to top stair")
	await walk_to(3620)
	await hop(3730, 300, true)
	on_ledge(300, "building B: up through the roof hatch")

	await place(Vector2(2340, 600))
	await hop(2440, 520)
	on_ledge(520, "building A: floor to awning 1")
	await walk_to(2470)
	await hop(2540, 440)
	on_ledge(440, "building A: awning 1 to 2")
	await walk_to(2560)
	await hop(2660, 360)
	on_ledge(360, "building A: awning 2 to 3")
	await hop(2760, 300)
	on_ledge(300, "building A: awning 3 to roof")

	await place(Vector2(3225, 600))
	player.global_position.x = 3180 + 100
	await frames(2)
	await hop(3230, 520)
	on_ledge(520, "alley: floor to ledge 1")
	await hop(3330, 440)
	on_ledge(440, "alley: ledge 1 to 2")
	await hop(3230, 360)
	on_ledge(360, "alley: ledge 2 to 3")
	await hop(3150, 300)
	on_ledge(300, "alley: ledge 3 back to roof A")

	await place(Vector2(1190, 600))
	await hop(1300, 520)
	on_ledge(520, "awnings: floor to first")
	await walk_to(1430)
	await hop(1560, 440)
	on_ledge(440, "awnings: first to second")

	await load_room(loadout, "res://scenes/level_2.tscn")
	await place(Vector2(8520, 600))
	await hop(8610, 520)
	on_ledge(520, "control room: floor to step 1")
	await walk_to(8615)
	await hop(8680, 440)
	on_ledge(440, "control room: step 1 to 2")
	await walk_to(8670)
	await hop(8750, 360)
	on_ledge(360, "control room: step 2 to 3")
	await walk_to(8784)
	# The catwalk is the Cape route: seen by the laser, robots spawn on the landing spot.
	player.go_invisible(6.0)
	await hop(8870, 280)
	on_ledge(280, "control room: step 3 to catwalk, from the very edge")
	await place(Vector2(2340, 600))
	await hop(2460, 520)
	on_ledge(520, "security hall: floor to walkway")


func alarm_bots() -> int:
	return get_tree().get_nodes_in_group("alarm_bot").filter(func(r): return is_instance_valid(r) and not r.is_queued_for_deletion()).size()


func _run_levels() -> void:
	# The real save may already have levels unlocked; this only changes the in-memory copy.
	Game.selected_level = 1
	Game.unlocked_level = 1
	const L1 := "res://scenes/level_1.tscn"
	const L2 := "res://scenes/level_2.tscn"
	var light_load := ["air_cannon", "small_light", "invisibility_cape"]

	# Level 1
	await load_room(light_load, L1)
	check(room.hud.bells_total == 2, "level 1: Light + Cape loadout counts 2 bells, not 3")
	await place(Vector2(3440, 600))
	await walk("move_right", 40)
	check(player.global_position.x < 3500, "level 1: normal size blocked by building B wall")
	player.set_shrunk(true)
	await walk("move_right", 60)
	check(player.global_position.x > 3530, "level 1: shrunk Doraemon enters building B through the vent")
	player.set_shrunk(false)
	await check_climbs(light_load)
	await load_room(light_load, L1)
	await place(Vector2(5400, 600))
	Input.action_press("jump")
	await walk("move_right", 40)
	Input.action_release("jump")
	await frames(30)
	check(player.global_position.y > 590.0, "level 1: can't hop onto the factory gate roof")
	await place(Vector2(6320, 600))
	Input.action_press("interact")
	await frames(2)
	Input.action_release("interact")
	check(room.finished and Game.selected_level == 2 and Game.unlocked_level >= 2, "level 1 exit clears it and unlocks level 2")

	# Level 2
	await load_room(light_load, L2)
	check(room.hud.bells_total == 2, "level 2: Light + Cape loadout counts 2 bells, not 4")
	await place(Vector2(560, 520))
	var x0 := player.global_position.x
	await frames(30)
	check(player.global_position.x < x0 - 15.0, "level 2: conveyor carries Doraemon (%d -> %d)" % [x0, player.global_position.x])
	var hp := player.health
	await place(Vector2(780, 600))
	await frames(3)
	check(player.health < hp and player.velocity.y < 0.0, "level 2: electric floor zaps and bounces")

	player.health = player.max_health
	player.set_shrunk(true)
	await place(Vector2(2700, 600))
	await frames(260)
	check(alarm_bots() == 0, "level 2: shrunk in the vent, cameras can't see Doraemon")
	player.set_shrunk(false)
	player.gadgets[2].try_use()
	await place(Vector2(2700, 520))
	await frames(200)
	check(alarm_bots() == 0, "level 2: cameras ignore invisible Doraemon")
	player.reveal()
	await frames(260)
	check(alarm_bots() > 0, "level 2: cameras spot visible Doraemon -> alarm")

	await load_room(light_load, L2)
	await place(Vector2(8920, 280))
	await frames(5)
	check(alarm_bots() > 0, "level 2: catwalk laser trips the alarm")
	await load_room(light_load, L2)
	player.set_shrunk(true)
	await place(Vector2(9080, 600))
	await walk("move_right", 70)
	check(player.global_position.x > 9265, "level 2: shrunk Doraemon slips under the machine")
	var m: ControlMachine = room.machine
	check(m.take_hit(1.0, Vector2(1, 0)) == false, "machine shield blocks hits from the front")
	check(m.take_hit(1.0, Vector2(-1, 0)) == true, "machine takes hits from behind")
	for i in 10:
		m.take_hit(1.0, Vector2(-1, 0))
	check(m.is_destroyed(), "machine can be destroyed")
	await frames(90)
	check(room.finished, "destroying the machine clears level 2")


func _run_boss() -> void:
	const BOSS := "res://scenes/boss_arena.tscn"
	# Doors don't carry Miguel, even while he charges straight through one.
	await load_room(["air_cannon", "anywhere_door", "small_light"], BOSS)
	var b: Boss = room.boss
	var door: AnywhereDoor = player.gadgets[1]
	await place(Vector2(160, 600))
	aim_at(Vector2(640, 562))
	door._place(true)
	aim_at(Vector2(200, 300))
	door._place(false)
	await frames(20)
	b.global_position = Vector2(1000, 600)
	b.facing = -1
	b.state = Boss.State.CHARGE
	var crossed := false
	for i in 120:
		await frames(1)
		if b.global_position.x < 600.0:
			crossed = true
			break
	check(crossed and b.global_position.y > 590.0, "Miguel charges through an Anywhere Door without being carried (y=%d)" % b.global_position.y)

	await load_room(["super_gloves", "small_light", "invisibility_cape"], BOSS)
	b = room.boss
	check(b != null and room.hud.boss == b, "boss arena has Miguel and his health bar")
	b.set_physics_process(false)
	b.facing = -1
	check(b.take_hit(1.0, Vector2(1, 0)) == false, "Miguel's shield blocks hits from the front")
	check(b.take_hit(1.0, Vector2(-1, 0)) == true, "Miguel takes hits on his back")
	check(b.take_hit(1.0, Vector2(0.4, 0.9)) == true, "Miguel takes hits dropped on him from above")
	b.state = Boss.State.DAZED
	check(b.take_hit(1.0, Vector2(1, 0)) == true, "dazed Miguel has no shield")
	b.state = Boss.State.WALK
	b.health = b.max_health
	b.set_physics_process(true)

	# Shrunk Doraemon fits under him; normal size gets hurt.
	b.global_position = Vector2(700, 600)
	b.velocity = Vector2.ZERO
	player.set_shrunk(true)
	var hp := player.health
	await place(Vector2(700, 600))
	await frames(10)
	check(player.health == hp, "shrunk Doraemon slips under Miguel unhurt")
	player.set_shrunk(false)
	await place(Vector2(700, 600))
	await frames(3)
	check(player.health < hp, "touching Miguel at normal size hurts")

	# Invisible: he loses track and never turns around.
	await load_room(["super_gloves", "small_light", "invisibility_cape"], BOSS)
	b = room.boss
	b.facing = -1
	player.gadgets[2].try_use()
	await place(Vector2(1150, 600))
	await frames(120)
	check(b.facing == -1 or b.global_position.x > 1100, "invisible Doraemon gets behind Miguel without him turning")

	# Charge into a wall -> dazed.
	await load_room(["super_gloves", "small_light", "invisibility_cape"], BOSS)
	b = room.boss
	await place(Vector2(450, 440))
	b.state = Boss.State.WINDUP
	b._state_left = 0.1
	var dazed := false
	for i in 200:
		await frames(1)
		if b.state == Boss.State.DAZED:
			dazed = true
			break
	check(dazed, "Miguel's charge crashes into the wall and dazes him")

	# Dazed: no contact damage, so Doraemon can walk through to his back.
	hp = player.health
	await place(b.global_position)
	b.state = Boss.State.DAZED
	b._state_left = 1.0
	await frames(20)
	check(player.health == hp, "walking through dazed Miguel doesn't hurt")

	# Behind him there's time for a run of hits, not just one or two.
	await load_room(["air_cannon", "small_light", "invisibility_cape"], BOSS)
	b = room.boss
	b.global_position = Vector2(700, 600)
	b.facing = -1
	b.state = Boss.State.WALK
	b._state_left = 99.0
	await place(Vector2(900, 600))
	var hits := 0
	for i in 400:
		await frames(1)
		if b.facing != -1:
			break
		if i % 21 == 0:
			hits += 1 if b.take_hit(1.0, Vector2(-1, 0)) else 0
	check(hits >= 8, "one trip behind Miguel is worth a run of cannon hits (%d)" % hits)

	# Real input: a held jump clears his charge and lands behind him unhurt.
	for side_run in 2:
		await load_room(["air_cannon", "small_light", "invisibility_cape"], BOSS)
		b = room.boss
		if side_run == 1:
			b.phase_two = true
		b.global_position = Vector2(1000, 600)
		b.facing = -1
		await place(Vector2(500, 600))
		b.state = Boss.State.WINDUP
		b._windup_total = 0.3
		b._state_left = 0.3
		hp = player.health
		var trigger := 62.0 + (580.0 if b.phase_two else 480.0) * 0.24
		var jumped := false
		for i in 200:
			await frames(1)
			if not jumped and b.state == Boss.State.CHARGE and b.global_position.x - player.global_position.x < trigger:
				jumped = true
				Input.action_press("jump")
			if jumped and b.global_position.x < player.global_position.x - 70.0:
				break
		Input.action_release("jump")
		await frames(15)
		check(player.health == hp and b.global_position.x < player.global_position.x, "jumping over the charge is safe and lands behind him (phase_two=%s)" % b.phase_two)

	await load_room(["super_gloves", "small_light", "invisibility_cape"], BOSS)
	b = room.boss
	b.state = Boss.State.DAZED
	b._state_left = 3.0

	# Mini Bots: summoned, grabbable, and a lobbed one bonks him.
	b._summon()
	await frames(30)
	var minis := get_tree().get_nodes_in_group("minibot").filter(func(r): return is_instance_valid(r) and not r.is_queued_for_deletion())
	check(minis.size() >= 2, "Miguel summons Mini Bots")
	var bot: Robot = minis[0]
	bot.global_position = Vector2(520, 600)
	await place(Vector2(500, 600))
	check(player.try_grab(), "Super Gloves grab a Mini Bot")
	b.state = Boss.State.WALK
	var before := b.health
	b.global_position = Vector2(player.global_position.x + 220.0, 600)
	b.facing = -1
	b.set_physics_process(false)
	player.throw_held(Vector2(300, -650))
	for i in 90:
		await frames(1)
		if b.health < before:
			break
	check(b.health < before, "a Mini Bot lobbed over the shield damages Miguel (bot at %s)" % [bot.global_position if is_instance_valid(bot) else "gone"])
	b.set_physics_process(true)

	b.health = 1.0
	b.take_hit(1.0, Vector2(-1, 0))
	await frames(260)
	check(room.finished and room.cage.opened, "beating Miguel frees Nobita and clears the boss")


func freeze_robots() -> void:
	for r in robots():
		r.set_physics_process(false)


## Line of sight: sealed rooms are closed to doors, every required door route still works.
func _run_door_rules() -> void:
	var loadout := ["air_cannon", "anywhere_door", "small_light"]
	await load_room(loadout, "res://scenes/level_1.tscn")
	freeze_robots()
	var door: AnywhereDoor = player.gadgets[1]

	await place(Vector2(1690, 440))
	check(not door.can_see(Vector2(1820, 400)), "door: can't see into the cracked-wall storeroom")
	await place(Vector2(2600, 600))
	check(not door.can_see(Vector2(2810, 570)), "door: can't see into building A's vent room")
	await place(Vector2(2200, 600))
	check(not door.can_see(Vector2(2810, 596)), "door: can't peek through the vent gap from far away")
	await place(Vector2(3190, 300))
	check(door.can_see(Vector2(3550, 262)), "door: can see across the rooftop gap")
	await place(Vector2(5470, 600))
	check(door.can_see(Vector2(5990, 562)), "door: can see down the factory gate tunnel")

	# Real route to the billboard bell: blue door in the air beside the ledge, walk into pink.
	await place(Vector2(4440, 600))
	aim_at(Vector2(4600, 80))
	check(door._place(false), "door: can place beside the billboard ledge")
	aim_at(Vector2(4520, 562))
	check(door._place(true), "door: can place on the street")
	await frames(20)
	await walk("move_right", 60)
	check(room.hud.bells == 1, "door: billboard bell reachable through the doors (bells=%d, y=%d)" % [room.hud.bells, player.global_position.y])

	await load_room(loadout, "res://scenes/level_2.tscn")
	freeze_robots()
	door = player.gadgets[1]
	await place(Vector2(200, 600))
	check(not door.can_see(Vector2(50, 570)), "door: can't see into the cracked-wall closet")
	await place(Vector2(2300, 600))
	check(not door.can_see(Vector2(2700, 590)), "door: can't peek into the walkway vent")
	await place(Vector2(2415, 520))
	aim_at(Vector2(3100, 470))
	check(door._place(false), "door: security hall can be crossed from the walkway's edge")
	await place(Vector2(9070, 600))
	check(door.can_see(Vector2(9320, 562)), "door: can reach behind the control machine")
	await place(Vector2(600, 520))
	check(door.can_see(Vector2(970, 262)), "door: conveyor ledge bell can be seen from the first belt")


## Fires the Air Cannon flat in the given direction.
func fire(dir: float) -> void:
	aim_at(player.center() + Vector2(dir * 300.0, 0))
	await frames(1)
	player.gadgets[0].cooldown_left = 0.0
	player.gadgets[0].try_use()


func _run_new_level_2() -> void:
	const L2 := "res://scenes/level_2.tscn"
	var loadout := ["air_cannon", "anywhere_door", "small_light"]
	await load_room(loadout, L2)
	freeze_robots()
	var door: AnywhereDoor = player.gadgets[1]

	# Belts: real jumps across every gap.
	for leg in [[680.0, 860.0], [1100.0, 1280.0], [1520.0, 1700.0], [5580.0, 5760.0], [6085.0, 6260.0]]:
		await place(Vector2(leg[0], 520))
		await hop(leg[1], 520)
		on_ledge(520, "belts: jump from x=%d to the next belt" % leg[0])

	var hp := player.health
	var crusher_hit := false
	await place(Vector2(5420, 520))
	for i in 200:
		await frames(1)
		player.global_position = Vector2(5420, 520)
		if player.health < hp:
			crusher_hit = true
			break
	check(crusher_hit, "assembly line: crusher reaches the belt")
	player.health = player.max_health

	# Vault: normal size trips the laser, shrunk slips under, a door can see past it.
	await place(Vector2(7620, 600))
	check(door.can_see(Vector2(8160, 570)), "laser vault: a door can see past it")
	player.set_shrunk(true)
	await walk("move_right", 120)
	check(player.global_position.x > 7900 and alarm_bots() == 0, "laser vault: shrunk Doraemon slips under the beam (x=%d)" % player.global_position.x)
	player.set_shrunk(false)
	await frames(5)
	check(alarm_bots() > 0, "laser vault: normal size trips the alarm")

	# Target Range, with real shots through real doors.
	await load_room(loadout, L2)
	freeze_robots()
	door = player.gadgets[1]
	var t: Array[TargetSwitch] = room.targets
	await place(Vector2(6950, 600))
	check(not door.can_see(Vector2(7280, 400)), "target range: reward room is sealed to doors")
	await place(Vector2(7420, 600))
	aim_at(Vector2(7560, 310))
	await frames(1)
	player.gadgets[0].try_use()
	await frames(40)
	check(not t[0].lit, "target 1: a direct shot can't reach it")

	aim_at(Vector2(7520, 320))
	check(door._place(false) and door.portal_b.global_position == Vector2(7500, 334), "target 1: blue door snaps to the pad")
	aim_at(Vector2(7480, 578))
	check(door._place(true), "target 1: pink door placed")
	await frames(20)
	await fire(-1.0)
	await frames(50)
	check(not t[0].lit, "target 1: shooting the wrong way misses")
	await fire(1.0)
	await frames(50)
	check(t[0].lit, "target 1: shot through the doors hits it")

	await place(Vector2(6950, 600))
	aim_at(Vector2(6980, 334))
	check(door._place(false), "target 2: blue door on the pad")
	aim_at(Vector2(6900, 578))
	check(door._place(true), "target 2: pink door placed")
	await frames(20)
	await fire(-1.0)
	await frames(50)
	check(t[1].lit, "target 2: firing left through the doors hits it")
	check(room.bonus_gate.closed, "reward room stays shut until all targets are lit")

	aim_at(Vector2(7040, 250))
	check(door._place(false), "target 3: blue door on the pad")
	aim_at(Vector2(7000, 578))
	check(door._place(true), "target 3: pink door placed")
	await frames(20)
	for i in 400:
		if not t[2].is_open():
			break
		await frames(1)
	await fire(1.0)
	await frames(40)
	check(not t[2].lit, "target 3: bounces off while its shutter is closed")
	for i in 400:
		if t[2].is_open():
			break
		await frames(1)
	await fire(1.0)
	await frames(40)
	check(t[2].lit and not room.bonus_gate.closed, "target 3: timed shot lights it and opens the reward room")

	await frames(3)
	door.portal_a.queue_free()
	door.portal_b.queue_free()
	await frames(2)
	var bells: int = room.hud.bells
	await place(Vector2(6960, 600))
	await hop(7030, 520)
	on_ledge(520, "reward room: floor to step 1")
	await walk_to(7050)
	await hop(7120, 440)
	on_ledge(440, "reward room: step 1 to 2")
	await walk("move_right", 60)
	check(room.hud.bells == bells + 1, "reward room: walk in and collect the bell")


## Each map's security bunker: only the Cape gets its bell.
func _run_bell_rules() -> void:
	var cape_load := ["air_cannon", "small_light", "invisibility_cape"]
	for level in ["res://scenes/test_room.tscn", "res://scenes/level_1.tscn", "res://scenes/level_2.tscn"]:
		var tag: String = level.get_file()
		await load_room(cape_load, level)
		check(room.cape_bunkers.size() == 1, "%s: one security bunker" % tag)
		var x: float = room.cape_bunkers[0]["x"]

		freeze_robots()
		var start: int = room.hud.bells
		await place(Vector2(x - 40.0, 600))
		await walk("move_right", 150)
		check(room.hud.bells == start and room.cape_bunkers[0]["gate"].closed, "%s: visible Doraemon trips the laser and the shutter slams" % tag)
		await frames(400)
		check(room.cape_bunkers[0]["gate"].closed, "%s: shutter stays shut while he stands in the laser" % tag)

		await load_room(cape_load, level)
		freeze_robots()
		player.set_shrunk(true)
		await place(Vector2(x - 30.0, 600))
		await walk("move_right", 180)
		check(room.hud.bells == start, "%s: shrunk Doraemon is caught too" % tag)

		await load_room(["air_cannon", "anywhere_door", "small_light"], level)
		freeze_robots()
		var door: AnywhereDoor = player.gadgets[1]
		await place(Vector2(x - 120.0, 600))
		aim_at(Vector2(x + 370.0, 568))
		check(not door._place(false), "%s: Anywhere Door is jammed inside the bunker" % tag)
		aim_at(Vector2(x + 100.0, 568))
		check(not door._place(false), "%s: ...and inside its tunnel" % tag)

		await load_room(cape_load, level)
		freeze_robots()
		await place(Vector2(x - 40.0, 600))
		player.gadgets[2].try_use()
		await walk("move_right", 150)
		check(room.hud.bells == start + 1, "%s: invisible Doraemon walks in and takes the bell" % tag)
		await walk("move_left", 150)
		check(player.global_position.x < x, "%s: ...and walks back out" % tag)

	# The HUD total in each level matches what the loadout screen promises.
	for loadout in [["air_cannon", "anywhere_door", "small_light"], ["super_gloves", "small_light", "invisibility_cape"], ["air_cannon", "anywhere_door", "invisibility_cape"]]:
		for i in 3:
			await load_room(loadout, Game.LEVELS[i]["scene"])
			check(room.hud.bells_total == Game.reachable_bells(i, loadout), "%s with %s: HUD shows %d bells" % [Game.LEVELS[i]["short"], loadout, room.hud.bells_total])

	var door_light := ["air_cannon", "anywhere_door", "small_light"]
	check(Game.reachable_bells(1, door_light) == 2, "level 1: any two utilities reach 2 of 3 bells")
	check(Game.reachable_bells(2, ["super_gloves", "small_light", "invisibility_cape"]) == 2, "level 2: Gloves + Light + Cape reach 2 bells")
	check(Game.reachable_bells(2, ["air_cannon", "anywhere_door", "invisibility_cape"]) == 3, "level 2: Air Cannon + Door also reach the Target Range bell")
	check(Game.reachable_bells(2, ["super_gloves", "anywhere_door", "small_light"]) == 2, "level 2: Gloves + Door miss the Target Range bell")
