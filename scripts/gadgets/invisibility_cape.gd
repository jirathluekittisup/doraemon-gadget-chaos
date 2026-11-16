class_name InvisibilityCape
extends Gadget
## LMB: invisible for 6 seconds. Attacking or RMB ends it early.

const DURATION := 6.0


func _init() -> void:
	cooldown = 10.0
	alt_cooldown = 0.2


func use() -> bool:
	if player.is_invisible:
		return false
	player.go_invisible(DURATION)
	return true


func use_alt() -> bool:
	if not player.is_invisible:
		return false
	player.reveal()
	return true


func get_status() -> String:
	if player.is_invisible:
		return "Invisible %.1fs" % player.invisible_left
	if cooldown_left > 0.0:
		return "Recharging %.1fs" % cooldown_left
	return "Ready"
