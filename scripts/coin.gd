# ORIGIN: Brackeys tutorial (public domain).
# MODIFIED BY TEAM: find the manager in generated story levels,
# and award each coin once while its pickup animation finishes.
extends Area2D

@onready var game_manager = get_tree().get_first_node_in_group("game_manager")
@onready var animation_player = $AnimationPlayer
var collected := false

func _on_body_entered(body):
	if collected or not body.is_in_group("player") or game_manager == null:
		return
	collected = true
	game_manager.add_point()
	animation_player.play("pickup")
