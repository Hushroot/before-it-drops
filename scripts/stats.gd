extends Node
## Run totals survive scene changes. Call reset() when starting a new run.
## start_time is monotonic seconds; subtract it from Time.get_ticks_msec() / 1000.0.

const LevelStats = preload("res://scripts/level_stats.gd")

var total_deaths: int = 0
var total_geo: int = 0
var start_time: float = 0.0


func _ready() -> void:
	reset()
	get_tree().node_added.connect(_on_node_added)


func reset() -> void:
	total_deaths = 0
	total_geo = 0
	start_time = Time.get_ticks_msec() / 1000.0


func _on_node_added(node: Node) -> void:
	# GameManager joins its group in _ready(), after node_added is emitted.
	node.ready.connect(_on_node_ready.bind(node), CONNECT_ONE_SHOT)


func _on_node_ready(node: Node) -> void:
	if not node.is_in_group("game_manager"):
		return
	var tracker := LevelStats.new()
	tracker.name = "LevelStats"
	tracker.stats = self
	tracker.game_manager = node
	node.add_child(tracker)
