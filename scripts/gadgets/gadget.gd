class_name Gadget
extends Node
## Base class for loadout gadgets. LMB calls use(), RMB calls use_alt().

var player: Player
var id := ""
var display_name := ""
var color := Color.WHITE
var cooldown := 0.5
var alt_cooldown := 0.2
var cooldown_left := 0.0
var alt_cooldown_left := 0.0


static func create(gadget_id: String) -> Gadget:
	match gadget_id:
		"air_cannon":
			return AirCannon.new()
		"super_gloves":
			return SuperGloves.new()
		"anywhere_door":
			return AnywhereDoor.new()
		"small_light":
			return SmallLight.new()
		"invisibility_cape":
			return InvisibilityCape.new()
	push_error("Unknown gadget: %s" % gadget_id)
	return null


func _process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	alt_cooldown_left = maxf(0.0, alt_cooldown_left - delta)


func try_use() -> void:
	if cooldown_left > 0.0:
		return
	if use():
		cooldown_left = maxf(cooldown_left, cooldown)


func try_alt() -> void:
	if alt_cooldown_left > 0.0:
		return
	if use_alt():
		alt_cooldown_left = alt_cooldown


## Primary action. Return true if it fired (starts the cooldown).
func use() -> bool:
	return false


## Secondary action. Return true if it fired.
func use_alt() -> bool:
	return false


## Short extra text for the HUD slot.
func get_status() -> String:
	return ""


func cooldown_ratio() -> float:
	return cooldown_left / cooldown if cooldown > 0.0 else 0.0


## Aim preview, drawn on the player's canvas in its local space.
func draw_preview(_canvas: CanvasItem) -> void:
	pass
