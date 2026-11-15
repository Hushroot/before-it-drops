# ORIGIN: NEW, written by team.
# PROJECTILE: power shots and SPARK's finger-gun sparks. Flies straight, hits each enemy once.
extends Node2D

var velocity := Vector2.ZERO
var power := 1                 # damage
var armor_break := true        # damages the boss from the side
var pierce := false            # keeps flying after a hit
var radius := 6.0
var color := Color(0.6, 0.9, 1.0)
var life := 1.2
var owner_player: Node2D
var hit_list := {}


func _physics_process(delta: float) -> void:
	life -= delta
	position += velocity * delta
	queue_redraw()
	if life <= 0.0:
		queue_free()
		return
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var collider = hit.collider
		if collider == null:
			continue
		if collider is TileMap or (collider is StaticBody2D and not collider.is_in_group("bounce_pad")):
			queue_free()      # hit a wall
			return
		if collider.get_script() and collider.get_script().resource_path.ends_with("killzone.gd"):
			var enemy = collider.get_parent()
			if enemy == get_tree().current_scene or hit_list.has(enemy):
				continue
			hit_list[enemy] = true
			var gm = get_tree().get_first_node_in_group("game_manager")
			if gm:
				gm.hit_enemy(enemy, self)
			if not pierce:
				queue_free()
				return


func _draw() -> void:
	var alpha := clampf(life * 3.0, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius + 3.0, Color(color, 0.3 * alpha))
	draw_circle(Vector2.ZERO, radius, Color(color, alpha))
	draw_line(Vector2.ZERO, -velocity.normalized() * radius * 3.0, Color(color, 0.5 * alpha), radius)
