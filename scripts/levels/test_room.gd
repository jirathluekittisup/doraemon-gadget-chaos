extends Level
## Training Room: a sandbox that exercises every gadget, both robot types and the factory hazards.
## Main path: patrol robot -> armored robot -> laser corridor -> crusher -> exit.
## Bonus: dorayaki behind a cracked wall (Gloves). Golden Bells, one per utility: high ledge (Door),
## vent room (Light), security bunker before the exit (Cape).

var shutter: Shutter


func _init() -> void:
	level_name = "Training Room"
	room_w = 3600.0
	factory_x = 1720.0
	objectives = [
		[1250.0, "Chase the robots toward the factory."],
		[1720.0, "Get past the Armored Robot."],
		[2330.0, "Sneak past the security laser."],
		[3600.0, "Dodge the crusher and reach the EXIT."],
	]


func build() -> void:
	# Platforms up to the Gloves bonus room.
	solid(Rect2(560, 520, 160, 20), "roof")
	solid(Rect2(780, 440, 200, 20), "roof")
	solid(Rect2(980, 340, 240, 20), "roof")
	solid(Rect2(980, 440, 240, 20), "block")
	solid(Rect2(1200, 360, 20, 80), "block")
	cracked_wall(Rect2(980, 360, 20, 80))

	# Security corridor: 60 px tall, laser 28 px above the floor.
	solid(Rect2(1720, -900, 600, 1440), "factory")
	shutter = add_shutter(Rect2(2300, 540, 20, 60))
	laser(Vector2(1730, 572), 565.0, shutter, [Vector2(1580, FLOOR_Y), Vector2(1650, FLOOR_Y)])

	# High ledge for the Door bonus.
	solid(Rect2(2380, 330, 140, 20), "metal")
	crusher(2620)

	# Vent room for the Small Light bonus: 26 px gap under its left wall.
	solid(Rect2(3400, 360, 200, 20), "metal")
	solid(Rect2(3400, 380, 20, 194), "metal")
	exit_door(3300)

	crate(Vector2(420, FLOOR_Y))
	crate(Vector2(2480, FLOOR_Y))
	robot("patrol", Vector2(950, FLOOR_Y), 760, 1180)
	robot("armored", Vector2(1520, FLOOR_Y), 1300, 1690)
	robot("patrol", Vector2(2900, 520), 2720, 3140)
	pickup("dorayaki", Vector2(1110, 420))
	bell(Vector2(2450, 312), ["anywhere_door"])
	bell(Vector2(3510, 586), ["small_light"])
	cape_bell(2700)

	add_sign("Crate: grab with Super Gloves (RMB), throw with LMB", Vector2(160, 470))
	add_sign("Cracked wall: punch it, or throw a crate into it", Vector2(800, 290))
	add_sign("Armored Robot blocks from the front.\nHit it from behind, shrink it, or sneak past.", Vector2(1280, 400))
	add_sign("ROBOT FACTORY", Vector2(1890, 300), 26, Color("#f2c230"), Color("#1d2539"))
	add_sign("SECURITY LASER: go invisible, shrink under it,\nor open an Anywhere Door past it.", Vector2(1765, 420), 14, Color.WHITE, Color("#7a1f1f"))
	add_sign("Golden Bell up high: try the Anywhere Door", Vector2(2330, 260))
	add_sign("Crusher: time your run,\nor throw a shrunk robot in", Vector2(2360, 450))
	add_sign("Vent: only a shrunk Doraemon fits", Vector2(3360, 300))
