extends Camera2D

const MAX_ZOOM := 3.0
const MIN_ZOOM := 1.6
const MARGIN := Vector2(90, 70)

var arena_rect := Rect2(0, -240, 640, 300)


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 4.0
	limit_left = int(arena_rect.position.x)
	limit_right = int(arena_rect.end.x)
	limit_top = int(arena_rect.position.y)
	limit_bottom = int(arena_rect.end.y)
	make_current()


func _process(delta: float) -> void:
	var positions: Array = []
	for player in get_tree().get_nodes_in_group("player"):
		if not player.is_dead:
			positions.append(player.global_position + Vector2(0, -16))
	for boss in get_tree().get_nodes_in_group("raid_focus"):
		if not boss.get("dead"):
			positions.append(boss.global_position + Vector2(0, -30))
	if positions.is_empty():
		return
	var box := Rect2(positions[0], Vector2.ZERO)
	for point in positions:
		box = box.expand(point)
	box = box.grow_individual(MARGIN.x, MARGIN.y, MARGIN.x, MARGIN.y)
	global_position = box.get_center()
	var view := get_viewport_rect().size
	var target_zoom := minf(view.x / box.size.x, view.y / box.size.y)
	target_zoom = clampf(target_zoom, MIN_ZOOM, MAX_ZOOM)
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), 1.0 - exp(-3.0 * delta))
