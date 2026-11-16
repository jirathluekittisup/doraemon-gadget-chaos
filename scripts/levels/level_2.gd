extends Level
## Level 2: The Robot Factory.
## Conveyors over an electric floor -> security hall with sweeping cameras (go invisible, take
## the vent under the walkway shrunk, or open a door past) -> crushers and an Armored Robot ->
## assembly line (belts with crushers over them) -> Target Range (optional puzzle) -> laser
## vault (go invisible, shrink under the beam, or open a door past) -> the shielded control
## machine (reach its back with a door, the vent under it, or the catwalk past a laser).
## Destroying it clears the level.
## Golden Bells, one per utility: Door (ledge over the conveyors), Light (walkway vent), Cape
## (security bunker after the security hall). Plus the Target Range bell for Air Cannon + Door.
## The cracked-wall closet at the start holds a dorayaki for the Super Gloves.

var machine: ControlMachine
var targets: Array[TargetSwitch] = []
var bonus_gate: Shutter


func _init() -> void:
	level_name = "Level 2: The Robot Factory"
	room_w = 10220.0
	factory_x = 0.0
	player_start = Vector2(200, FLOOR_Y)
	objectives = [
		[1960.0, "Ride the conveyors over the electric floor."],
		[3020.0, "Get past the security cameras."],
		[5200.0, "Cross the machine room."],
		[6520.0, "Ride the assembly line past the crushers."],
		[8140.0, "Get through the laser vault. Bonus: the Target Range!"],
		[10220.0, "Destroy the control machine: hit it from behind!"],
	]


func build() -> void:
	_build_conveyors()
	_build_security_hall()
	_build_machine_room()
	_build_assembly_line()
	_build_target_range()
	_build_laser_vault()
	_build_control_room()


func _build_conveyors() -> void:
	# Closet with a cracked wall (Gloves bonus).
	solid(Rect2(0, 500, 120, 20), "metal")
	cracked_wall(Rect2(100, 520, 20, 80))
	pickup("dorayaki", Vector2(50, 585))
	add_sign("Find the control machine and shut it down!", Vector2(240, 400))

	electric_floor(380, 1960)
	conveyor(Rect2(400, 520, 300, 20), -60.0)
	conveyor(Rect2(820, 520, 300, 20), 70.0)
	conveyor(Rect2(1240, 520, 300, 20), -70.0)
	conveyor(Rect2(1660, 520, 300, 20), 60.0)
	robot("patrol", Vector2(1390, 520), 1260, 1520)
	pickup("dorayaki", Vector2(1810, 498))
	solid(Rect2(920, 300, 100, 16), "metal")
	bell(Vector2(970, 282), ["anywhere_door"])
	add_sign("Conveyors push you around.\nDon't touch the electric floor!", Vector2(440, 400))


func _build_security_hall() -> void:
	solid(Rect2(2380, -900, 640, 1200), "factory")
	solid(Rect2(2400, 520, 600, 54), "metal")
	var gate := add_shutter(Rect2(2980, 300, 20, 220))
	var spawns := [Vector2(2440, 520), Vector2(2500, 520)]
	var cam_a := security_camera(Vector2(2560, 300), 1.05, 1.75, gate, spawns)
	var cam_b := security_camera(Vector2(2840, 300), 1.4, 2.1, gate, spawns)
	cam_b.sweep_time = 2.6
	cam_a.sweep_time = 3.4
	bell(Vector2(2700, 588), ["small_light"])
	add_sign("SECURITY CAMERAS\nGo invisible, shrink through the vent under\nthe walkway, or open a door past them.", Vector2(2050, 380))


func _build_machine_room() -> void:
	crate(Vector2(4020, FLOOR_Y))
	crusher(3550, 300.0, 0.0)
	crusher(3950, 300.0, 1.3)
	robot("patrol", Vector2(3750, FLOOR_Y), 3650, 3850)
	cape_bell(3040)
	add_sign("Crushers! Time your run,\nor throw a shrunk robot in.", Vector2(3290, 330))
	robot("patrol", Vector2(4250, FLOOR_Y), 4100, 4440)
	solid(Rect2(4500, 220, 500, 300), "factory")
	robot("armored", Vector2(4800, FLOOR_Y), 4540, 4980)
	add_sign("Another Armored Robot.\nYou know what to do!", Vector2(4560, 260), 14, Color.WHITE, Color("#1d2539"))


func _build_assembly_line() -> void:
	add_sign("Assembly line: mind the crushers!", Vector2(5110, 430))
	electric_floor(5200, 6500)
	conveyor(Rect2(5220, 520, 380, 20), 70.0)
	conveyor(Rect2(5720, 520, 380, 20), -70.0)
	conveyor(Rect2(6220, 520, 280, 20), 80.0)
	for spot in [[5420.0, 0.0], [5940.0, 1.6], [6360.0, 0.8]]:
		crusher(spot[0], 240.0, spot[1]).floor_y = 520.0
	robot("patrol", Vector2(5780, 520), 5740, 5840)
	pickup("dorayaki", Vector2(6460, 498))


func _build_target_range() -> void:
	add_sign("TARGET RANGE (bonus)  Air Cannon + Anywhere Door\nPut a door on a glowing pad, then shoot into your other door.\nShots keep their direction: follow the arrow!", Vector2(6560, 400))

	targets.append(target_tube(7640, 334, -1))
	door_pad(Vector2(7500, 334), 1)

	solid(Rect2(6800, -900, 40, 1320), "factory")
	targets.append(target_tube(6840, 334, 1))
	door_pad(Vector2(6980, 334), -1)

	# Reward room, sealed by a shutter until all three targets are lit.
	solid(Rect2(6990, 520, 100, 20), "metal")
	solid(Rect2(7070, 440, 110, 20), "metal")
	solid(Rect2(7180, 440, 200, 20), "block")
	solid(Rect2(7180, 340, 200, 20), "roof")
	solid(Rect2(7360, 360, 20, 80), "block")
	bonus_gate = add_shutter(Rect2(7180, 360, 20, 80))
	bonus_gate.set_closed(true)
	bell(Vector2(7300, 420), ["anywhere_door", "air_cannon"])
	pickup("dorayaki", Vector2(7240, 420))

	solid(Rect2(7180, -900, 40, 1240), "factory")
	targets.append(target_tube(7180, 270, -1, 2.6))
	door_pad(Vector2(7040, 270), 1)

	for t in targets:
		t.hit.connect(_on_target_hit)


func _on_target_hit() -> void:
	for t in targets:
		if not t.lit:
			return
	bonus_gate.set_closed(false)
	Fx.text(self, "VAULT OPEN!", bonus_gate.global_position + Vector2(0, -30), Color("#9dff9d"))
	Fx.burst(self, bonus_gate.global_position + Vector2(10, 40), Color(0.5, 2.4, 0.9), 20, 260.0)


func _build_laser_vault() -> void:
	solid(Rect2(7640, -900, 500, 1440), "factory")
	var gate := add_shutter(Rect2(8120, 540, 20, 60))
	laser(Vector2(7650, 572), 465.0, gate, [Vector2(7480, FLOOR_Y), Vector2(7550, FLOOR_Y)])
	add_sign("LASER VAULT\nGo invisible, shrink under the beam,\nor open a door past it.", Vector2(7700, 400), 14, Color.WHITE, Color("#7a1f1f"))
	pickup("dorayaki", Vector2(8240, 575))
	robot("patrol", Vector2(8300, FLOOR_Y), 8180, 8380)


func _build_control_room() -> void:
	robot("patrol", Vector2(8520, FLOOR_Y), 8400, 8580)
	# The top step stops 30 px short of the catwalk so a jump can't bonk on its underside.
	solid(Rect2(8560, 520, 100, 20), "metal")
	solid(Rect2(8640, 440, 90, 20), "metal")
	solid(Rect2(8710, 360, 80, 20), "metal")

	# Catwalk over the machine, under a low ceiling, with a laser along it.
	solid(Rect2(8820, -900, 700, 1080), "factory")
	solid(Rect2(8820, 280, 700, 20), "metal")
	var gate := add_shutter(Rect2(9500, 180, 20, 100))
	laser(Vector2(8830, 255), 680.0, gate, [Vector2(8860, 280), Vector2(8920, 280)])

	machine = ControlMachine.new()
	machine.position = Vector2(9120, 300)
	machine.spawn_point = Vector2(9040, FLOOR_Y)
	machine.destroyed.connect(_on_machine_destroyed)
	add_child(machine)
	add_sign("CONTROL MACHINE\nIts shield blocks the front. Get behind it:\nAnywhere Door, the vent underneath (shrunk),\nor the catwalk above (mind the laser).", Vector2(8400, 120))
	decor("cage", Rect2(9780, 470, 96, 130))


func _on_machine_destroyed() -> void:
	await get_tree().create_timer(1.2).timeout
	complete("Control Machine Destroyed!",
		"Nobita: \"Doraemon! Miguel, the Robot Commander, is coming!\"   Next: the boss fight")
