extends Node
## Added automatically by Stats to each game manager, including future levels.

var stats: Node
var game_manager: Node
var _saved: bool = false


func _exit_tree() -> void:
	# Children exit before their parent, so the manager's final count is readable.
	# This also runs on reloads and while paused, without depending on a frame poll.
	if _saved or not is_instance_valid(stats) or not is_instance_valid(game_manager):
		return
	_saved = true
	stats.total_deaths += int(game_manager.deaths)
	stats.total_geo += int(game_manager.score)
