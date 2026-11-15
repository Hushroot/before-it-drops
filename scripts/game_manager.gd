extends Node

const Look = preload("res://scripts/look.gd")

const BodyPad = preload("res://scripts/body_pad.gd")
const ViceLayer = preload("res://scripts/vice_layer.gd")
const Characters = preload("res://scripts/characters.gd")
const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const MAX_BODIES := 3
const MAX_MASKS := 5
const ENEMY_HP := 2

var score = 0
var deaths := 0
var respawn_point := Vector2.ZERO
var dead := false
var player: CharacterBody2D
var players: Array = []


var masks: int:
	get:
		return player.pmasks if player else MAX_MASKS
	set(value):
		if player:
			player.pmasks = value
var max_masks: int:
	get:
		return player.pmax if player else MAX_MASKS
var bodies: Array = []
var hud: Control
var geo_label: Label
var death_label: Label
var death_notifications: VBoxContainer
var heat := 0.0
var soul := 0.0

@onready var score_label = $ScoreLabel


func _ready():
	add_to_group("game_manager")
	_build_hud()
	Look.add_grade(self)
	add_child(ViceLayer.new())
	await get_tree().process_frame
	if not is_inside_tree():
		return
	refresh_players()
	if player:
		respawn_point = player.global_position
	_update_hud()


func refresh_players() -> void:
	players = get_tree().get_nodes_in_group("player").filter(func(p): return not p.is_queued_for_deletion())
	players.sort_custom(func(a, b): return a.player_index < b.player_index)
	player = players[0] if players.size() > 0 else null


func _process(delta: float) -> void:
	heat = maxf(heat - delta * 0.25, 0.0)


func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."
	_update_hud()


func set_checkpoint(pos: Vector2) -> void:
	respawn_point = pos
	for p in players:
		p.pmasks = p.pmax
	_update_hud()
	_toast("BENCH: RESTED")


func player_hit(from_pos: Vector2, hazard := false, who = null) -> void:
	if who == null:
		who = player

	if who == null or who.is_dead or who.has_meta("spawn_guard") or (who.invuln > 0.0 and not hazard):
		return
	who.pmasks -= 1
	_update_hud()
	_shake(4.0)
	if who.pmasks <= 0:
		player_died(true, who)
		return
	who.take_hit(from_pos)
	if hazard:

		who.controllable = false
		await get_tree().create_timer(0.35).timeout
		if is_instance_valid(who) and not who.is_dead:
			who.respawn(who.last_safe)


func player_died(leave_body := true, who = null) -> void:
	if who == null:
		who = player
	if who == null or who.is_dead:
		return
	dead = true
	deaths += 1
	var where: Vector2 = who.global_position
	if who.global_position.y > who.last_safe.y + 60.0:
		where = who.last_safe
	var facing_left: bool = who.animated_sprite.flip_h
	var dropped: int = score
	score = 0
	who.die()
	_notify_death(who)
	_update_hud()
	_shake(8.0)
	Engine.time_scale = 0.5
	await get_tree().create_timer(0.3).timeout
	Engine.time_scale = 1.0
	if leave_body:
		_spawn_body(where, facing_left, dropped, who)
	if players.size() > 1:
		await get_tree().create_timer(1.2).timeout
	who.pmasks = who.pmax
	who.set_meta("spawn_guard", true)
	who.respawn(respawn_point + Vector2(who.player_index * 14, 0))
	_update_hud()

	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	if is_instance_valid(who):
		who.remove_meta("spawn_guard")
	dead = players.any(func(p): return p.is_dead)


func _spawn_body(pos: Vector2, facing_left: bool, geo: int, who = null) -> void:
	if who == null:
		who = player
	var b = BodyPad.new()
	b.frames = who.animated_sprite.sprite_frames
	b.flip = facing_left
	b.sprite_scale = who.base_scale
	var ch: Dictionary = Characters.by_id(who.char_id) if who.char_id != "" else Characters.get_selected()
	b.lying_anim = not ch.is_empty() and not ch.knockdown_rotate
	b.geo = geo
	b.global_position = pos
	get_tree().current_scene.add_child(b)
	bodies.append(b)
	if bodies.size() > MAX_BODIES:
		bodies.pop_front().queue_free()


func reclaim_geo(body) -> void:
	if body.geo <= 0:
		return
	score += body.geo
	_toast("+%d GEO RECLAIMED" % body.geo)
	body.geo = 0
	body.set_reclaimed()
	_update_hud()


func hit_enemy(enemy: Node, by: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.has_meta("dying"):
		return
	heat += 1.0
	var pw = by.get("power")
	Sfx.play("smash" if pw != null and int(pw) > 1 else "hit", -2.0)
	if by.is_in_group("player"):
		soul = minf(soul + 11.0, 99.0)
		_update_hud()
	if enemy.has_method("on_nail_hit"):
		enemy.on_nail_hit(by)
		return
	damage_enemy(enemy, by)


func damage_enemy(enemy: Node, by: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.has_meta("dying"):
		return
	var power: int = by.get("power") if by.get("power") != null else 1
	var hp: int = enemy.get_meta("hp", ENEMY_HP) - power
	enemy.set_meta("hp", hp)
	var tw := enemy.create_tween()
	enemy.modulate = Color(3, 3, 3)
	tw.tween_property(enemy, "modulate", Color.WHITE, 0.15)
	if enemy is Node2D:
		var knockback := 6.0 * power * power * signf(enemy.global_position.x - by.global_position.x)
		if enemy.has_method("take_knockback"):
			enemy.take_knockback(knockback)
		else:
			enemy.position.x += knockback
	if power > 1:
		_shake(5.0)
		_toast("SMASH!")
	if hp <= 0:
		enemy.set_meta("dying", true)
		Sfx.play("enemy_down", -4.0, 0.0)
		score += 2
		_update_hud()
		_shake(3.0)
		var t2 := enemy.create_tween()
		t2.tween_property(enemy, "scale", Vector2(1.4, 0.2), 0.15)
		t2.tween_callback(enemy.queue_free)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	hud = Control.new()
	hud.position = Vector2(12, 10)
	hud.draw.connect(_draw_masks)
	layer.add_child(hud)
	geo_label = _make_label(16, Vector2(12, 34))
	layer.add_child(geo_label)
	death_label = _make_label(16, Vector2(12, 56))
	layer.add_child(death_label)
	var notification_root := Control.new()
	notification_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notification_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(notification_root)
	death_notifications = VBoxContainer.new()
	notification_root.add_child(death_notifications)
	death_notifications.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	death_notifications.offset_left = -292
	death_notifications.offset_right = -12
	death_notifications.offset_top = 84
	death_notifications.add_theme_constant_override("separation", 6)
	death_notifications.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_hud()


func _notify_death(who: CharacterBody2D) -> void:
	if death_notifications == null:
		return

	while death_notifications.get_child_count() >= 3:
		var oldest := death_notifications.get_child(0)
		death_notifications.remove_child(oldest)
		oldest.queue_free()
	var notice := PanelContainer.new()
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.07, 0.09, 0.9)
	style.border_color = Color(0.95, 0.3, 0.35)
	style.border_width_left = 3
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	notice.add_theme_stylebox_override("panel", style)
	var label := _make_label(12, Vector2.ZERO)
	label.text = "Player %d died." % (who.player_index + 1) if players.size() > 1 else "You died."
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_child(label)
	death_notifications.add_child(notice)
	var tw := notice.create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(notice, "modulate:a", 0.0, 0.25)
	tw.tween_callback(notice.queue_free)


func _make_label(size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.position = pos
	return l


const P_COLORS := [Color(0.4, 0.8, 1.0), Color(1.0, 0.55, 0.4), Color(0.6, 1.0, 0.5)]

func _draw_masks() -> void:
	var list: Array = players if players.size() > 0 else [null]
	for row in list.size():
		var p = list[row]
		var y := 10.0 + row * 26.0
		var x0 := 10.0
		if list.size() > 1 and p:
			var c: Dictionary = Characters.by_id(p.char_id)
			hud.draw_string(FONT, Vector2(0, y + 5), "P%d %s" % [row + 1, c.get("name", "")], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, P_COLORS[row % 3])
			x0 = 92.0
		if row == 0:
			_draw_soul(x0)
		var mx: int = p.pmax if p else MAX_MASKS
		var cur: int = p.pmasks if p else MAX_MASKS
		for i in mx:
			var c := Vector2(x0 + i * 22, y)
			var full: bool = i < cur and not (p != null and p.is_dead)
			hud.draw_circle(c, 9.0, Color.BLACK)
			hud.draw_circle(c, 7.0, Color(0.95, 0.95, 1.0) if full else Color(0.25, 0.25, 0.3))
			if full:
				hud.draw_circle(c + Vector2(-3, -1), 1.6, Color.BLACK)
				hud.draw_circle(c + Vector2(3, -1), 1.6, Color.BLACK)


func _draw_soul(x0: float) -> void:
	var x := x0 + 7 * 22 + 6
	hud.draw_string(FONT, Vector2(x, 6), "SOUL", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.7, 0.9, 1))
	hud.draw_rect(Rect2(x + 36, -2, 99, 12), Color.BLACK)
	hud.draw_rect(Rect2(x + 37, -1, soul, 10), Color(0.55, 0.85, 1.0))
	for k in [33, 66]:
		hud.draw_line(Vector2(x + 37 + k, -1), Vector2(x + 37 + k, 9), Color.BLACK, 1.0)


func _update_hud() -> void:
	if hud:
		hud.queue_redraw()
	var rows: int = maxi(players.size(), 1)
	if geo_label:
		geo_label.position.y = 34 + (rows - 1) * 26
		geo_label.text = "GEO %d" % score
	if death_label:
		death_label.position.y = 56 + (rows - 1) * 26
		death_label.text = "Deaths: %d" % deaths if deaths > 0 else ""


func _shake(amount: float) -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var tw := cam.create_tween()
	for i in 4:
		tw.tween_property(cam, "offset", Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.03)


func _toast(text: String) -> void:
	if player == null:
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	get_tree().current_scene.add_child(l)
	l.global_position = player.global_position + Vector2(-40, -40)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 20, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)
