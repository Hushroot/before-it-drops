extends Node2D

const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
var velocity := Vector2.ZERO
var life := 2.5
var spin := 0.0
var gravity := 0.0
var reflected := false
var power := 2
var armor_break := true
var by_player: Node2D = null


func _ready() -> void:
	add_to_group("enemy_shot")


func reflect(p: Node2D) -> void:
	if reflected:
		return
	reflected = true
	by_player = p
	var sfx = get_node_or_null("/root/Sfx")
	if sfx:
		sfx.play("parry", 0.0, 0.0)
	life = 2.0
	gravity = 0.0
	var target := _nearest_enemy()
	if target:
		velocity = (target.global_position + Vector2(0, -10) - global_position).normalized() * 320.0
	else:
		velocity = -velocity.normalized() * 320.0
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		gm._shake(2.0)
		gm._toast("BOUNCED BACK!")
		gm.soul = minf(gm.soul + 11.0, 99.0)


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var nearest_distance := 400.0
	for enemy in get_tree().get_nodes_in_group("enemy_target"):
		if not is_instance_valid(enemy) or enemy.has_meta("dying"):
			continue
		var distance: float = enemy.global_position.distance_to(global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			best = enemy
	return best


func _physics_process(delta: float) -> void:
	life -= delta
	spin += delta * (25.0 if reflected else 10.0)
	velocity.y += gravity * delta
	position += velocity * delta
	queue_redraw()
	if life <= 0.0:
		queue_free()
		return
	var gm = get_tree().get_first_node_in_group("game_manager")
	if reflected:

		var query := PhysicsShapeQueryParameters2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 10.0
		query.shape = circle
		query.transform = Transform2D(0.0, global_position)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		for hit in get_world_2d().direct_space_state.intersect_shape(query, 8):
			var collider = hit.collider
			if collider and collider.get_script() and collider.get_script().resource_path.ends_with("killzone.gd"):
				var enemy = collider.get_parent()
				if enemy != get_tree().current_scene and gm and not enemy.has_meta("dying"):
					gm.hit_enemy(enemy, self)
					gm._shake(4.0)
					queue_free()
					return
		return
	for p in get_tree().get_nodes_in_group("player"):
		if not p.is_dead and p.global_position.distance_to(global_position + Vector2(0, 6)) < 10.0:
			if gm:
				gm.player_hit(global_position, false, p)
			queue_free()
			return


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, sin(spin) * 0.5, Vector2.ONE)
	var bg := Color(1, 0.8, 0.2) if reflected else Color(1, 0.95, 0.6)
	if reflected:
		draw_circle(Vector2.ZERO, 11.0, Color(1, 0.85, 0.3, 0.35))
	draw_rect(Rect2(-7, -4, 14, 8), bg)
	draw_rect(Rect2(-7, -4, 14, 8), Color(0.3, 0.2, 0.1), false, 1.0)
	draw_string(FONT, Vector2(-6, 3), "$$$", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.2, 0.5, 0.2))
