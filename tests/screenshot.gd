extends Node
## Renders a few screenshots: godot res://tests/screenshot.tscn -- <out_dir>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var menu: Control = load("res://scenes/loadout.tscn").instantiate()
	add_child(menu)
	await _settle(10)
	_shot(out + "/loadout.png")
	menu.queue_free()
	Game.loadout.assign(["super_gloves", "anywhere_door", "small_light"])
	var room: Node2D = load("res://scenes/test_room.tscn").instantiate()
	add_child(room)
	var p: Player = room.player
	await _settle(5)
	p.global_position = Vector2(1250, 600)
	var door: Gadget = p.gadgets[1]
	p.aim_override = Vector2(1120, 562)
	door.try_use()
	p.aim_override = Vector2(1340, 470)
	door.try_alt()
	await _settle(5)
	for spot in [[Vector2(1180, 600), "room_doors"], [Vector2(450, 600), "room_start"], [Vector2(1400, 600), "room_armored"], [Vector2(2000, 600), "room_laser"], [Vector2(2560, 600), "room_crusher"], [Vector2(3250, 600), "room_vent"]]:
		p.global_position = spot[0]
		p.aim_override = spot[0] + Vector2(160, -60)
		p.camera.reset_smoothing()
		await _settle(25)
		_shot(out + "/" + spot[1] + ".png")
	room.queue_free()
	await _tour("res://scenes/level_1.tscn", out, [
		[Vector2(500, 600), "l1_street"], [Vector2(1600, 430), "l1_awnings"], [Vector2(3050, 300), "l1_gap"],
		[Vector2(3800, 600), "l1_building"], [Vector2(4700, 600), "l1_billboard"], [Vector2(5050, 520), "l1_bunker"], [Vector2(5650, 600), "l1_gate"],
	])
	await _tour("res://scenes/level_2.tscn", out, [
		[Vector2(900, 520), "l2_conveyors"], [Vector2(2560, 520), "l2_cameras"], [Vector2(3700, 600), "l2_crushers"],
		[Vector2(5900, 520), "l2_assembly"], [Vector2(7000, 600), "l2_range_a"], [Vector2(7450, 600), "l2_range_b"],
		[Vector2(7900, 600), "l2_vault"], [Vector2(8920, 600), "l2_machine"], [Vector2(9620, 600), "l2_nobita"],
	])
	Game.loadout.assign(["super_gloves", "anywhere_door", "small_light"])
	var arena: Node2D = load("res://scenes/boss_arena.tscn").instantiate()
	add_child(arena)
	await _settle(240)
	arena.player.global_position = Vector2(420, 600)
	arena.boss._summon()
	await _settle(40)
	_shot(out + "/boss.png")
	arena.boss.state = Boss.State.CHARGE
	arena.boss.global_position.x = 800.0
	arena.boss.facing = -1
	await _settle(6)
	_shot(out + "/boss_charge.png")
	arena.boss.state = Boss.State.DAZED
	arena.boss._state_left = 5.0
	await _settle(10)
	_shot(out + "/boss_dazed.png")
	get_tree().quit()


func _tour(scene: String, out: String, spots: Array) -> void:
	Game.loadout.assign(["air_cannon", "anywhere_door", "invisibility_cape"])
	var level: Node2D = load(scene).instantiate()
	add_child(level)
	var p: Player = level.player
	for spot in spots:
		p.global_position = spot[0]
		p.velocity = Vector2.ZERO
		p.aim_override = spot[0] + Vector2(160, -60)
		p.camera.reset_smoothing()
		await _settle(30)
		_shot(out + "/" + spot[1] + ".png")
	level.queue_free()
	await _settle(2)

func _settle(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if get_viewport().use_hdr_2d:
		img.convert(Image.FORMAT_RGBA8)
		img.linear_to_srgb()
	img.save_png(path)
