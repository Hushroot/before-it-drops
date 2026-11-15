extends Control

const BOX := 84.0
const MOODS := ["idle", "smug", "angry", "squashed", "enraged", "defeated"]

var base_mood := "idle"
var mood := "idle"
var mood_t := 0.0
var t := 0.0
var shake := 0.0
var squash := 1.0
var art := {}
var placeholder: Texture2D


func _ready() -> void:
	custom_minimum_size = Vector2(BOX, BOX)
	size = Vector2(BOX, BOX)
	for m in MOODS:
		var path := "res://assets/boss/portrait_%s.png" % m
		if ResourceLoader.exists(path):
			art[m] = load(path)


func set_placeholder(tex: Texture2D) -> void:
	placeholder = tex


func react(new_mood: String, duration := 0.6) -> void:
	if mood == "defeated":
		return
	mood = new_mood
	mood_t = duration
	if new_mood == "squashed":
		squash = 0.45
	elif new_mood in ["angry", "enraged"]:
		shake = 4.0
	queue_redraw()


func set_base(new_base: String) -> void:
	base_mood = new_base
	if mood_t <= 0.0:
		mood = new_base


func _process(delta: float) -> void:
	t += delta
	shake = maxf(shake - delta * 20.0, 0.0)
	squash = lerpf(squash, 1.0, 1.0 - exp(-8.0 * delta))
	if mood_t > 0.0:
		mood_t -= delta
		if mood_t <= 0.0 and mood != "defeated":
			mood = base_mood
	queue_redraw()


func _draw() -> void:

	draw_rect(Rect2(Vector2.ZERO, Vector2(BOX, BOX)), Color.BLACK)
	var bg := Color(0.18, 0.08, 0.22) if mood != "enraged" else Color(0.35, 0.05, 0.1)
	draw_rect(Rect2(Vector2(3, 3), Vector2(BOX - 6, BOX - 6)), bg)
	var jitter := Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	var c := Vector2(BOX / 2, BOX / 2) + jitter

	draw_set_transform(c + Vector2(0, (1.0 - squash) * BOX * 0.3), 0.0, Vector2(2.0 - squash, squash))
	var inner := BOX - 12.0
	var rect := Rect2(Vector2(-inner / 2, -inner / 2), Vector2(inner, inner))
	if art.has(mood):
		draw_texture_rect(art[mood], rect, false)
	else:
		_draw_placeholder(rect)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var border := {"idle": Color(0.75, 0.4, 1.0), "smug": Color(1, 0.85, 0.3), "angry": Color(1, 0.3, 0.3),
		"squashed": Color.WHITE, "enraged": Color(1, 0.1, 0.2), "defeated": Color(0.4, 0.4, 0.4)}
	draw_rect(Rect2(Vector2(1, 1), Vector2(BOX - 2, BOX - 2)), border.get(mood, Color.WHITE), false, 2.0)


func _draw_placeholder(rect: Rect2) -> void:
	var tint := Color.WHITE
	if mood == "enraged":
		tint = Color(1.0, 0.6, 0.7)
	elif mood == "defeated":
		tint = Color(0.5, 0.5, 0.55)
	if placeholder:
		draw_texture_rect(placeholder, rect, false, tint)
	var s := rect.size.x / 24.0
	var eye_y := rect.position.y + 15.5 * s
	var lx := rect.position.x + 9.0 * s
	var rx := rect.position.x + 15.0 * s
	var ink := Color(0.05, 0.02, 0.08)
	match mood:
		"idle":
			pass
		"smug":
			draw_line(Vector2(lx - 2 * s, eye_y - 3 * s), Vector2(lx + 2 * s, eye_y - 2.5 * s), ink, s)
			draw_line(Vector2(rx - 2 * s, eye_y - 2.5 * s), Vector2(rx + 2 * s, eye_y - 3.5 * s), ink, s)
			draw_line(Vector2(lx, eye_y + 3.5 * s), Vector2(rx + s, eye_y + 2.5 * s), ink, s)
		"angry", "enraged":
			draw_line(Vector2(lx - 2 * s, eye_y - 4 * s), Vector2(lx + 2 * s, eye_y - 2 * s), ink, s * 1.2)
			draw_line(Vector2(rx + 2 * s, eye_y - 4 * s), Vector2(rx - 2 * s, eye_y - 2 * s), ink, s * 1.2)
			draw_rect(Rect2(Vector2(lx, eye_y + 2.5 * s), Vector2(rx - lx, 1.5 * s)), Color.WHITE)
		"squashed":
			for x in [lx, rx]:
				draw_line(Vector2(x - 1.5 * s, eye_y - 1.5 * s), Vector2(x + 1.5 * s, eye_y), ink, s)
				draw_line(Vector2(x - 1.5 * s, eye_y + 1.5 * s), Vector2(x + 1.5 * s, eye_y), ink, s)
		"defeated":
			for x in [lx, rx]:
				draw_line(Vector2(x - 1.5 * s, eye_y - 1.5 * s), Vector2(x + 1.5 * s, eye_y + 1.5 * s), ink, s)
				draw_line(Vector2(x + 1.5 * s, eye_y - 1.5 * s), Vector2(x - 1.5 * s, eye_y + 1.5 * s), ink, s)
