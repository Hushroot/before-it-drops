# ORIGIN: NEW, written by team. Reuses existing fighter artwork.
extends Node
## Presentation only: give standing-pose sheets a readable walking stride.
const WalkPose = preload("res://scripts/fighter_walk_pose.gd")

func _process(_delta: float) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if player.is_queued_for_deletion() or not player.custom_char:
			continue
		var sprite: AnimatedSprite2D = player.animated_sprite
		if not sprite.has_node("WalkPose"):
			var pose := WalkPose.new()
			pose.name = "WalkPose"
			sprite.add_child(pose)
