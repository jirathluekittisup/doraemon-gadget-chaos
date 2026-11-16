extends Level
## Boss: Robot Commander Miguel, in a one-screen arena. Nobita hangs in a cage above.
## Miguel's shield blocks the front. Get behind him (door, invisible, or under him while shrunk),
## lob his own Mini Bots over the shield with the Super Gloves, or hit him while he's dazed
## after charging into a wall. He crouches low to charge, so a held jump clears him.

var boss: Boss
var cage: Decor


func _init() -> void:
	level_name = "Boss: Robot Commander Miguel"
	room_w = 1280.0
	factory_x = 0.0
	player_start = Vector2(160, FLOOR_Y)
	camera_zoom = 1.0
	camera_bottom_pad = 190.0
	objectives = [[INF, "Jump over Miguel's charge, then hit his back!"]]


func build() -> void:
	solid(Rect2(0, 520, 110, 20), "metal")
	solid(Rect2(140, 440, 170, 20), "metal")
	solid(Rect2(1170, 520, 110, 20), "metal")
	solid(Rect2(970, 440, 170, 20), "metal")
	solid(Rect2(560, 330, 160, 20), "metal")
	cage = decor("cage", Rect2(592, 200, 96, 130))
	pickup("dorayaki", Vector2(225, 415))
	pickup("dorayaki", Vector2(1055, 415))
	add_sign("His shield blocks the front!\nJump over his charge when he crouches,\nthen hit his back while he's dazed.", Vector2(360, 380))

	boss = Boss.new()
	boss.position = Vector2(960, FLOOR_Y)
	boss.defeated.connect(_on_boss_defeated)
	add_child(boss)
	hud.boss = boss


func _on_boss_defeated() -> void:
	await get_tree().create_timer(2.0).timeout
	cage.opened = true
	Fx.burst(self, cage.global_position + cage.size * 0.5, Color(2.2, 2.0, 0.8), 24, 300.0)
	await get_tree().create_timer(1.0).timeout
	complete("Nobita Rescued!", "Nobita: \"You did it, Doraemon! Let's go home for dorayaki!\"   THE END")
