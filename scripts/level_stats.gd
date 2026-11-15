extends Node


var stats: Node
var game_manager: Node
var _saved: bool = false


func _exit_tree() -> void:


	if _saved or not is_instance_valid(stats) or not is_instance_valid(game_manager):
		return
	_saved = true
	stats.total_deaths += int(game_manager.deaths)
	stats.total_geo += int(game_manager.score)
