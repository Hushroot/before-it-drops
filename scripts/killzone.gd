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
	pass
