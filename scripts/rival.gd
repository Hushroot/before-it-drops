extends Node2D

const KILLZONE_SCENE = preload("res://scenes/killzone.tscn")
const EnemyShot = preload("res://scripts/enemy_shot.gd")
const Navigation = preload("res://scripts/enemy_navigation.gd")
const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const STATS := {
	"scalper": {"hp": 3, "speed": 26.0, "h": 26.0},
	"streamer": {"hp": 3, "speed": 58.0, "h": 26.0},
	"preorder": {"hp": 4, "speed": 20.0, "h": 26.0},
	"line_cutter": {"hp": 14, "speed": 0.0, "h": 40.0},
}
const LINES := {
	"scalper": ["$499. Final offer.", "Retail is for losers.", "I got 40 copies, bro."],
	"streamer": ["Chat, he's actually cooked.", "W streamer, L you.", "Smash that follow!"],
	"preorder": ["I preordered in 2013!", "Receipt says I'm first.", "Back of the line, pal."],
	"line_cutter": ["I was here first, bro.", "Line? What line?", "Nobody gets in."],
}

var kind := "scalper"
var dir := 1.0
var t := 0.0
var talk_t := 2.0
var shoot_t := 2.0
var state := "walk"
var state_t := 1.5
var art: Node2D
var max_hp := 1
var _warmup := 2
var vel_y := 0.0


func _ready() -> void:
	add_to_group("enemy_target")
	var s: Dictionary = STATS[kind]
	max_hp = s.hp
	set_meta("hp", s.hp)
	if kind == "line_cutter":
		add_to_group("gatekeeper")
	art = Node2D.new()
	art.draw.connect(_draw_art)
	add_child(art)
	var kz = KILLZONE_SCENE.instantiate()
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(s.h * 0.5, s.h * 0.85)
	shape.shape = r
	shape.position = Vector2(0, -s.h * 0.45)
	kz.add_child(shape)
	add_child(kz)
	t = randf() * 5.0


func _physics_process(delta: float) -> void:
	if has_meta("dying"):
		return
	if _warmup > 0:
		_warmup -= 1
		return
	t += delta
	art.queue_redraw()
	var s: Dictionary = STATS[kind]
	var ground := Navigation.surface(self, global_position)
	if ground.is_empty():
		vel_y += Navigation.GRAVITY * delta
		var fall := Navigation.flight(self, global_position, Vector2(0, vel_y), delta, s.h)
		global_position = fall.position
		vel_y = fall.velocity.y
		return
	global_position.y = ground.position.y
	vel_y = 0.0
	var p = _nearest_player(260.0)

	match kind:
		"line_cutter":
			_line_cutter(delta, p)
		"streamer":
			if randf() < 0.01:
				dir = -dir
			_walk(s.speed * delta)
		_:
			if kind == "preorder" and p:
				var distance: float = p.global_position.x - global_position.x
				if absf(distance) > 8.0:
					dir = signf(distance)
					_walk(s.speed * delta, false)
			else:
				_walk(s.speed * delta)

	if kind == "scalper" and p and Navigation.has_sight(self, p, s.h):
		shoot_t -= delta
		if shoot_t <= 0.0:
			shoot_t = 2.2
			var shot = EnemyShot.new()
			shot.global_position = global_position + Vector2(0, -18)
			var to: Vector2 = (p.global_position + Vector2(0, -10) - shot.global_position).normalized()
			shot.velocity = to * 150.0
			get_parent().add_child(shot)

	if p:
		talk_t -= delta
		if talk_t <= 0.0:
			talk_t = randf_range(4.0, 7.0)
			say(LINES[kind].pick_random())


func _walk(distance: float, turn := true) -> bool:
	var step := Navigation.walk(self, dir, distance, STATS[kind].h, turn)
	global_position = step.position
	dir = step.direction
	return step.blocked


func take_knockback(distance: float) -> void:

	var step := Navigation.walk(self, signf(distance), absf(distance), STATS[kind].h, false)
	global_position = step.position


func _line_cutter(delta: float, p) -> void:
	state_t -= delta
	match state:
		"walk":
			if p:
				dir = signf(p.global_position.x - global_position.x)
			_walk(20.0 * delta, false)
			if state_t <= 0.0 and p:
				state = "tell"
				state_t = 0.6
				say("!!")
		"tell":
			if state_t <= 0.0:
				state = "charge"
				state_t = 1.1
		"charge":
			var blocked := _walk(210.0 * delta, false) if state_t > 0.0 else false
			if blocked or state_t <= 0.0:
				state = "stunned"
				state_t = 1.2
				var gm = get_tree().get_first_node_in_group("game_manager")
				if gm and blocked:
					gm._shake(5.0)
		"stunned":
			if state_t <= 0.0:
				state = "walk"
				state_t = randf_range(1.2, 2.0)


func on_nail_hit(by: Node2D) -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm == null:
		return
	if kind == "preorder":
		var from_above: bool = by.global_position.y < global_position.y - 22.0
		var from_front: bool = signf(by.global_position.x - global_position.x) == signf(dir) or dir == 0.0
		var brute: bool = by.get("power") != null and by.power > 1
		if from_front and not from_above and not brute:
			say("RECEIPT BLOCK!")
			if by.get("velocity") != null:
				by.velocity.x = 160.0 * signf(by.global_position.x - global_position.x)
			return
	if kind == "line_cutter" and state == "stunned":
		gm.damage_enemy(self, by)
	gm.damage_enemy(self, by)
	if kind == "line_cutter" and int(get_meta("hp", 0)) <= 0:
		gm._toast("THE DOOR IS OPEN!")


func say(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color(1, 1, 0.8))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(160, 12)
	get_parent().add_child(l)
	l.global_position = global_position + Vector2(-80, -STATS[kind].h - 18)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 10, 1.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.8).set_delay(0.8)
	tw.tween_callback(l.queue_free)


func _nearest_player(max_d: float):
	var best = null
	var bd := max_d
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_dead:
			continue
		var d: float = p.global_position.distance_to(global_position)
		if d < bd:
			bd = d
			best = p
	return best


func _draw_art() -> void:
	var f := -1.0 if dir < 0 else 1.0
	var bob := absf(sin(t * 8.0)) * 1.5 if kind != "line_cutter" or state == "walk" else 0.0
	var outline := Color(0.08, 0.05, 0.1)
	match kind:
		"scalper":
			_legs(Color(0.2, 0.2, 0.25), bob)
			_rect(-7, -20 - bob, 14, 12, Color(0.45, 0.45, 0.5), outline)
			for i in 5:
				_rect(-f * 9 - 5, -22 - i * 5 - bob, 9, 5, [Color(0.9, 0.3, 0.4), Color(0.3, 0.6, 1), Color(1, 0.8, 0.2), Color(0.4, 0.9, 0.5), Color(0.8, 0.4, 1)][i], outline)
			_head(Color(0.85, 0.65, 0.5), bob)
			_rect(-6, -29 - bob, 12, 3, Color(0.15, 0.15, 0.2), null)
			_rect(-f * 6 - 3, -28 - bob, 4, 2, Color(0.15, 0.15, 0.2), null)
			_rect(-4 + f, -25 - bob, 8, 2, Color(0.05, 0.05, 0.05), null)
			_rect(f * 6 - 2, -16 - bob, 5, 6, Color(1, 0.3, 0.6), outline)
			art.draw_string(FONT, Vector2(f * 6 - 2, -11 - bob), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		"streamer":
			var glow := 0.6 + 0.4 * sin(t * 6.0)
			art.draw_arc(Vector2(0, -24 - bob), 11, 0, TAU, 24, Color(1, 1, 1, glow), 2.0)
			_legs(Color(0.15, 0.15, 0.2), bob)
			_rect(-7, -20 - bob, 14, 12, Color(0.55, 0.25, 0.85), outline)
			_head(Color(0.95, 0.75, 0.6), bob)
			art.draw_arc(Vector2(0, -24 - bob), 6, PI, TAU, 10, Color(0.1, 0.1, 0.1), 2.0)
			_rect(f * 5, -26 - bob, 3, 4, Color(0.1, 0.1, 0.1), null)
			art.draw_line(Vector2(f * 6, -14 - bob), Vector2(f * 16, -30 - bob), Color(0.2, 0.2, 0.2), 1.5)
			_rect(f * 16 - 2, -34 - bob, 4, 6, Color(0.1, 0.1, 0.15), Color(0.4, 0.9, 1))
			if int(t * 2.0) % 2 == 0:
				art.draw_string(FONT, Vector2(-14, -40 - bob), "W W W", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.4, 1, 0.5))
			else:
				art.draw_string(FONT, Vector2(-10, -40 - bob), "L L", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.4, 0.4))
		"preorder":
			_legs(Color(0.3, 0.25, 0.2), bob)
			_rect(-7, -20 - bob, 14, 12, Color(0.25, 0.6, 0.35), outline)
			_head(Color(0.8, 0.6, 0.45), bob)
			art.draw_rect(Rect2(-5 + f, -26 - bob, 4, 3), Color.BLACK, false, 1.0)
			art.draw_rect(Rect2(1 + f, -26 - bob, 4, 3), Color.BLACK, false, 1.0)
			_rect(f * 6 - 3, -27 - bob, 7, 24, Color(0.97, 0.97, 0.92), outline)
			for i in 6:
				art.draw_line(Vector2(f * 6 - 1, -23 + i * 3 - bob), Vector2(f * 6 + 2, -23 + i * 3 - bob), Color(0.5, 0.5, 0.5), 1.0)
		"line_cutter":
			var shake := Vector2(randf_range(-1, 1), 0) if state == "tell" else Vector2.ZERO
			art.position = shake
			art.draw_line(Vector2(-6, -12), Vector2(-8, 0), outline, 5.0)
			art.draw_line(Vector2(6, -12), Vector2(8, 0), outline, 5.0)
			_rect(-12, -32, 24, 21, Color(0.85, 0.15, 0.2), outline)
			_rect(-1, -32, 2, 21, Color.WHITE, null)
			_rect(-14, -26, 28, 5, Color(0.75, 0.1, 0.15), outline)
			art.draw_circle(Vector2(0, -38), 8, outline)
			art.draw_circle(Vector2(0, -38), 7, Color(0.7, 0.5, 0.35))
			_rect(-6 + f * 2, -41, 12, 3, Color(0.05, 0.05, 0.05), null)
			_rect(-7, -46, 14, 3, Color(0.1, 0.1, 0.1), null)
			if state == "stunned":
				for i in 3:
					var a := t * 6.0 + i * TAU / 3.0
					art.draw_circle(Vector2(cos(a) * 9, -48 + sin(a) * 3), 2, Color(1, 0.9, 0.3))

			var hp: int = get_meta("hp", max_hp)
			art.draw_string(FONT, Vector2(-34, -60), "THE LINE CUTTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.5, 0.5))
			art.draw_rect(Rect2(-24, -56, 48, 4), Color.BLACK)
			art.draw_rect(Rect2(-23, -55, 46.0 * hp / max_hp, 2), Color(1, 0.3, 0.3))


func _legs(col: Color, bob: float) -> void:
	var swing := sin(t * 8.0) * 3.0 if kind != "line_cutter" else 0.0
	art.draw_line(Vector2(-3, -8 - bob), Vector2(-3 + swing, 0), col, 3.0)
	art.draw_line(Vector2(3, -8 - bob), Vector2(3 - swing, 0), col, 3.0)


func _head(skin: Color, bob: float) -> void:
	art.draw_circle(Vector2(0, -24 - bob), 6, Color(0.08, 0.05, 0.1))
	art.draw_circle(Vector2(0, -24 - bob), 5, skin)


func _rect(x: float, y: float, w: float, h: float, col: Color, outline) -> void:
	if outline != null:
		art.draw_rect(Rect2(x - 1, y - 1, w + 2, h + 2), outline)
	art.draw_rect(Rect2(x, y, w, h), col)
