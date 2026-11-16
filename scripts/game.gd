extends Node
## Global state and helpers (autoload "Game").

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_PROP := 8
const LAYER_PROJECTILE := 16

const LOADOUT_SCENE := "res://scenes/loadout.tscn"
const PROGRESS_PATH := "user://progress.cfg"
## Index 0 is the Training Room (always open); clearing a level unlocks the next one.
## "bells" lists the gadgets each Golden Bell needs, so the loadout screen can say how many
## bells a loadout can reach.
const UTILITY_BELLS := [["anywhere_door"], ["small_light"], ["invisibility_cape"]]
const LEVELS := [
	{"name": "Training Room", "short": "Training", "scene": "res://scenes/test_room.tscn",
		"bells": UTILITY_BELLS},
	{"name": "Level 1: The Chaotic Neighborhood", "short": "Level 1", "scene": "res://scenes/level_1.tscn",
		"bells": UTILITY_BELLS},
	{"name": "Level 2: The Robot Factory", "short": "Level 2", "scene": "res://scenes/level_2.tscn",
		"bells": UTILITY_BELLS + [["anywhere_door", "air_cannon"]]},
	{"name": "Boss: Robot Commander Miguel", "short": "Boss", "scene": "res://scenes/boss_arena.tscn",
		"bells": []},
]

const GADGET_ORDER := ["air_cannon", "super_gloves", "anywhere_door", "small_light", "invisibility_cape"]
const DEFAULT_LOADOUT := ["air_cannon", "anywhere_door", "small_light"]
const GADGETS := {
	"air_cannon": {
		"name": "Air Cannon",
		"type": "attack",
		"color": Color("#4fc3f7"),
		"desc": "Fires an air blast toward the cursor. Safe ranged damage and knockback.",
		"help": "LMB: fire air blast at cursor",
	},
	"super_gloves": {
		"name": "Super Gloves",
		"type": "attack",
		"color": Color("#ff7043"),
		"desc": "3-punch combo up close. Grab and throw crates and shrunk enemies. Breaks cracked walls.",
		"help": "LMB: punch combo  ·  RMB: grab  (holding: LMB throw, RMB drop)",
	},
	"anywhere_door": {
		"name": "Anywhere Door",
		"type": "utility",
		"color": Color("#ff6fb5"),
		"desc": "Places two linked doors where you can see. Carries Doraemon, shots, thrown objects and enemies.",
		"help": "LMB: place pink door  ·  RMB: place blue door",
	},
	"small_light": {
		"name": "Small Light",
		"type": "utility",
		"color": Color("#ffd54f"),
		"desc": "Shrink enemies to weaken them and strip armor, or shrink yourself to fit through vents.",
		"help": "LMB: shrink enemy  ·  RMB: shrink / grow yourself",
	},
	"invisibility_cape": {
		"name": "Invisibility Cape",
		"type": "utility",
		"color": Color("#b39ddb"),
		"desc": "Invisible for 6 seconds. Enemies and security sensors lose track of you.",
		"help": "LMB: go invisible for 6s  ·  RMB: reveal early",
	},
}

var loadout: Array[String] = []
var selected_level := 1
var unlocked_level := 1
## Tests turn this off so they never touch the player's saved progress.
var save_enabled := true


func _ready() -> void:
	loadout.assign(DEFAULT_LOADOUT)
	_load_progress()
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_W, KEY_SPACE, KEY_UP])
	_add_keys("interact", [KEY_E, KEY_S, KEY_DOWN])
	_add_keys("slot_1", [KEY_1])
	_add_keys("slot_2", [KEY_2])
	_add_keys("slot_3", [KEY_3])
	_add_keys("restart", [KEY_R])
	_add_keys("back", [KEY_ESCAPE])
	_add_keys("confirm", [KEY_ENTER, KEY_KP_ENTER])
	_add_mouse("use_gadget", MOUSE_BUTTON_LEFT)
	_add_mouse("alt_gadget", MOUSE_BUTTON_RIGHT)


func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func _add_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func is_valid_loadout(ids: Array) -> bool:
	if ids.size() != 3:
		return false
	for id in ids:
		if not GADGETS.has(id):
			return false
	return count_type(ids, "attack") == 1 and count_type(ids, "utility") == 2


func count_type(ids: Array, type: String) -> int:
	var n := 0
	for id in ids:
		if GADGETS[id]["type"] == type:
			n += 1
	return n


func start_level() -> void:
	get_tree().change_scene_to_file(LEVELS[selected_level]["scene"])


## How many of a level's Golden Bells the given gadgets can reach.
func reachable_bells(level_index: int, ids: Array) -> int:
	var n := 0
	for needs in LEVELS[level_index]["bells"]:
		if needs.all(func(id): return ids.has(id)):
			n += 1
	return n


func is_unlocked(index: int) -> bool:
	return index == 0 or index <= unlocked_level


## Called by a level when it is cleared: unlocks and selects the next level.
func on_level_complete() -> void:
	if selected_level >= 1 and selected_level + 1 < LEVELS.size():
		unlocked_level = maxi(unlocked_level, selected_level + 1)
		selected_level += 1
		_save_progress()


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROGRESS_PATH) == OK:
		unlocked_level = clampi(int(cfg.get_value("progress", "unlocked_level", 1)), 1, LEVELS.size() - 1)
		selected_level = unlocked_level


func _save_progress() -> void:
	if not save_enabled:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_level", unlocked_level)
	cfg.save(PROGRESS_PATH)


func open_loadout() -> void:
	get_tree().change_scene_to_file(LOADOUT_SCENE)


func restart_level() -> void:
	get_tree().reload_current_scene()


## Physics bodies overlapping a global-space rectangle.
func bodies_in_rect(from: Node2D, rect: Rect2, mask: int, exclude: Array = []) -> Array:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, rect.get_center())
	q.collision_mask = mask
	var ex: Array[RID] = []
	ex.assign(exclude)
	q.exclude = ex
	var out := []
	for hit in from.get_world_2d().direct_space_state.intersect_shape(q, 16):
		out.append(hit["collider"])
	return out


func point_blocked(from: Node2D, pos: Vector2, mask: int) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = pos
	q.collision_mask = mask
	return not from.get_world_2d().direct_space_state.intersect_point(q, 1).is_empty()
