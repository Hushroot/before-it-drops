# ORIGIN: NEW, written by team. Terrain perception shared by enemy AI.
extends RefCounted
## Queries terrain now, rather than using last tick's direction-dependent ray cache.
const FOOT_MARGIN := 2.0
const GRAVITY := 700.0

static func _ray(actor: Node2D, from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.collide_with_areas = false
	return actor.get_world_2d().direct_space_state.intersect_ray(query)

static func surface(actor: Node2D, feet: Vector2) -> Dictionary:
	var hit := _ray(actor, feet + Vector2(0, -4), feet + Vector2(0, 6))
	return hit if not hit.is_empty() and hit.normal.y < -0.5 else {}

static func hazardous(actor: Node2D, feet: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = feet + Vector2(0, -2)
	query.collision_mask = 1
	query.collide_with_bodies = false
	query.collide_with_areas = true
	for hit in actor.get_world_2d().direct_space_state.intersect_point(query, 32):
		if hit.collider.get("instant_kill") == true or hit.collider.get("leaves_body") == false:
			return true
	return false

static func _wall(actor: Node2D, from: Vector2, to_x: float, height: float) -> bool:
	if is_equal_approx(from.x, to_x):
		return false
	for y in [-6.0, -height * 0.7]:
		var hit := _ray(actor, from + Vector2(0, y), Vector2(to_x, from.y + y))
		if not hit.is_empty() and absf(hit.normal.x) > 0.5:
			return true
	return false

static func _trace_walk(actor: Node2D, direction: float, distance: float, height: float) -> Dictionary:
	var feet := actor.global_position
	var slices := maxi(1, int(ceil(absf(distance) / 4.0)))
	var step := absf(distance) / slices * direction
	for i in slices:
		var next := feet + Vector2(step, 0)
		var ahead := next + Vector2(direction * FOOT_MARGIN, 0)
		var ground := surface(actor, next)
		var edge := surface(actor, ahead)
		var body_front := next.x + direction * maxf(4.0, height * 0.3)
		if ground.is_empty() or edge.is_empty() or _wall(actor, feet, body_front, height):
			return {}
		next.y = ground.position.y
		if hazardous(actor, next) or hazardous(actor, Vector2(ahead.x, edge.position.y)):
			return {}
		feet = next
	return {"position": feet}

static func walk(actor: Node2D, direction: float, distance: float, height: float, turn := true) -> Dictionary:
	var facing := signf(direction)
	if facing == 0.0:
		return {"position": actor.global_position, "direction": direction, "blocked": true}
	var target := _trace_walk(actor, facing, distance, height)
	var blocked := target.is_empty()
	if blocked and turn:
		facing = -facing
		target = _trace_walk(actor, facing, distance, height)
	return {"position": actor.global_position if target.is_empty() else target.position,
		"direction": facing, "blocked": blocked}

static func flight(actor: Node2D, feet: Vector2, velocity: Vector2, delta: float, height: float) -> Dictionary:
	var next := feet + velocity * delta
	var body_front := next.x + signf(velocity.x) * maxf(4.0, height * 0.3)
	var wall := _wall(actor, feet, body_front, height)
	if wall:
		next.x = feet.x
		velocity.x = 0.0
	var landed := false
	if velocity.y >= 0.0:
		# Sweep the whole fall distance: a short probe can skip a platform entirely.
		var hit := _ray(actor, Vector2(next.x, feet.y - 2), Vector2(next.x, next.y + 2))
		if not hit.is_empty() and hit.normal.y < -0.5:
			next.y = hit.position.y
			velocity.y = 0.0
			landed = true
	return {"position": next, "velocity": velocity, "landed": landed, "wall": wall}

static func safe_hop(actor: Node2D, direction: float, speed: float, jump: float, height: float) -> bool:
	if direction == 0.0:
		return false
	var start := actor.global_position
	var feet := start
	var velocity := Vector2(direction * speed, jump)
	# Simulate against real terrain before committing to the jump. Gaps may be
	# crossed only when the landing is safe, at approximately the same height.
	for i in 90:
		velocity.y += GRAVITY / 60.0
		velocity.x = direction * speed * (1.6 if velocity.y < 0.0 else 1.0)
		var step := flight(actor, feet, velocity, 1.0 / 60.0, height)
		if step.wall:
			return false
		feet = step.position
		velocity = step.velocity
		if step.landed:
			return absf(feet.y - start.y) <= 6.0 and not hazardous(actor, feet) \
				and not surface(actor, feet + Vector2(FOOT_MARGIN, 0)).is_empty() \
				and not surface(actor, feet - Vector2(FOOT_MARGIN, 0)).is_empty()
	return false

static func has_sight(actor: Node2D, target: Node2D, height: float) -> bool:
	return _ray(actor, actor.global_position - Vector2(0, height * 0.65),
		target.global_position - Vector2(0, 10)).is_empty()
