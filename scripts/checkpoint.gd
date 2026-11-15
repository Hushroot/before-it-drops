extends Area2D

var active := false


func _ready() -> void:
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body) -> void:
	if not body.is_in_group("player"):
		return
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		gm.set_checkpoint(global_position)
	active = true
	queue_redraw()


func _draw() -> void:

	var col := Color(1.0, 0.85, 0.3) if active else Color(0.7, 0.7, 0.75)
	draw_rect(Rect2(-10, -8, 20, 3), col)
	draw_rect(Rect2(-10, -16, 3, 8), col)
	draw_rect(Rect2(-9, -5, 2, 5), col)
	draw_rect(Rect2(7, -5, 2, 5), col)
