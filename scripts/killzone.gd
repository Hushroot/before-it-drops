# ORIGIN: Brackeys tutorial (human-written): Area2D that hurts on touch.
# MODIFIED BY TEAM: now costs 1 MASK instead of reloading the level (Hollow Knight style).
#   leaves_body = true  -> enemy (slime): knockback + lose a mask
#   leaves_body = false -> hazard (spikes, pits): lose a mask + respawn at last safe ground
#   instant_kill = true -> DEATH SPIKES: you die right away and your body stays HERE (for "die on purpose" puzzles)
extends Area2D

@export var leaves_body := true
@export var instant_kill := false

@onready var timer = $Timer


func _on_body_entered(body):
	if body.is_in_group("player"):
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm == null:
			return
		if instant_kill:
			gm.player_died(true, body)
		else:
			gm.player_hit(global_position, not leaves_body, body)


func _on_timer_timeout():
	pass   # kept so the old signal connection in killzone.tscn still works
