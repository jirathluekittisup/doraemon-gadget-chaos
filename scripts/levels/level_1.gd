extends Level
## Level 1: The Chaotic Neighborhood.
## Streets (combat) -> climb to the rooftops -> rooftop gap (Door across, or drop down and shrink
## through the vent into the next building) -> street -> Armored Robot in the factory gate tunnel
## (Door behind it, shrink it, or sneak past invisible).
## Golden Bells, one per utility: Door (ledge on top of the billboard), Light (vent room in
## building A), Cape (security bunker on the street before the factory gate). The cracked-wall storeroom on the awnings
## holds a dorayaki for the Super Gloves.


func _init() -> void:
	level_name = "Level 1: The Chaotic Neighborhood"
	room_w = 6600.0
	factory_x = 6060.0
	objectives = [
		[2300.0, "Fight or dodge the robots in the street."],
		[3200.0, "Climb up onto the rooftops."],
		[4300.0, "Cross the gap: Anywhere Door, or the vent down below."],
		[5470.0, "Head for the Robot Factory."],
		[6600.0, "Get past the Armored Robot and enter the factory."],
	]


func build() -> void:
	_build_streets()
	_build_rooftops()
	_build_factory_gate()


func _build_streets() -> void:
	add_sign("Robots kidnapped Nobita!\nHead right to the Robot Factory.", Vector2(40, 380))
	crate(Vector2(380, FLOOR_Y))
	robot("patrol", Vector2(760, FLOOR_Y), 560, 980)
	solid(Rect2(1060, 540, 60, 60), "block")
	add_sign("Robots hurt on contact.\nBlast them, punch them, or jump past.", Vector2(1140, 380))

	# Shop awnings, then a locked storeroom on top (Gloves bonus).
	solid(Rect2(1250, 520, 200, 20), "roof")
	solid(Rect2(1520, 440, 200, 20), "roof")
	pickup("dorayaki", Vector2(1620, 415))
	solid(Rect2(1720, 440, 200, 20), "block")
	solid(Rect2(1720, 340, 200, 20), "roof")
	solid(Rect2(1900, 360, 20, 80), "block")
	cracked_wall(Rect2(1720, 360, 20, 80))
	pickup("dorayaki", Vector2(1820, 420))
	add_sign("Cracked wall: Super Gloves can break it", Vector2(1620, 270))
	robot("patrol", Vector2(1400, FLOOR_Y), 1200, 1500)
	robot("patrol", Vector2(1850, FLOOR_Y), 1650, 2150)


func _build_rooftops() -> void:
	# Awnings up to building A.
	solid(Rect2(2380, 520, 120, 20), "roof")
	solid(Rect2(2500, 440, 120, 20), "roof")
	solid(Rect2(2600, 360, 100, 20), "roof")
	add_sign("Climb the awnings to the roof", Vector2(2180, 430))

	# Building A: solid apartment block with a vent room on the ground floor (Light bonus).
	solid(Rect2(2700, 300, 500, 220), "building")
	decor("interior", Rect2(2720, 520, 180, 80))
	solid(Rect2(2700, 520, 20, 54), "building")
	solid(Rect2(2900, 520, 300, 80), "building")
	bell(Vector2(2810, 586), ["small_light"])
	decor("ac_unit", Rect2(2780, 266, 54, 34))
	decor("water_tank", Rect2(3060, 220, 80, 80))
	robot("patrol", Vector2(3000, 300), 2760, 3150)

	# Alley between the buildings: ledges climb back up to building A only.
	solid(Rect2(3200, 520, 60, 20), "metal")
	solid(Rect2(3300, 440, 60, 20), "metal")
	solid(Rect2(3200, 360, 60, 20), "metal")
	add_sign("Too far to jump!\nOpen an Anywhere Door across,\nor drop down and shrink into the vent.", Vector2(3215, 150))

	# Building B: hollow, entered by the vent under its left wall; stairs lead to a roof hatch.
	decor("interior", Rect2(3520, 320, 760, 280))
	solid(Rect2(3500, 300, 60, 20), "block")
	solid(Rect2(3680, 300, 620, 20), "block")
	solid(Rect2(3500, 320, 20, 254), "building")
	solid(Rect2(4280, 320, 20, 280), "building")
	solid(Rect2(3540, 520, 140, 20), "metal")
	solid(Rect2(3720, 450, 120, 20), "metal")
	solid(Rect2(3540, 380, 140, 20), "metal")
	pickup("dorayaki", Vector2(3980, 580))
	add_sign("Grow back to normal size (RMB)\nto climb up to the roof hatch", Vector2(3860, 470))
	add_sign("Vent: shrink to fit", Vector2(3420, 530), 13)
	decor("ac_unit", Rect2(4100, 266, 54, 34))
	robot("patrol", Vector2(3950, 300), 3730, 4240)


func _build_factory_gate() -> void:
	decor("billboard", Rect2(4560, 150, 260, 450))
	solid(Rect2(4630, 140, 120, 16), "metal")
	bell(Vector2(4690, 120), ["anywhere_door"])
	crate(Vector2(4820, FLOOR_Y))
	robot("patrol", Vector2(4700, FLOOR_Y), 4420, 4850)
	cape_bell(4880)
	robot("patrol", Vector2(5100, 520), 4900, 5320)

	# Factory gate: an 80 px tall tunnel guarded by an Armored Robot. Too low to jump over it.
	solid(Rect2(5480, 220, 560, 300), "factory")
	add_sign("ROBOT FACTORY", Vector2(5640, 270), 26, Color("#f2c230"), Color("#1d2539"))
	add_sign("The Armored Robot guards the gate.\nGet behind it, shrink it, or sneak past invisible.", Vector2(5130, 320))
	robot("armored", Vector2(5800, FLOOR_Y), 5520, 6010)
	exit_door(6320)
