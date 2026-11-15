extends CanvasLayer

const GAME_TITLE := "BEFORE IT DROPS"
const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const MEMES := [
	"GTA VI drops Nov 19. This dropped today.",
	"Respawned at hospital. Insurance denied.",
	"Slimes don't pay taxes in Vice Slime.",
	"Ah sh*t, here we bounce again.",
]

var gm
var stars := 0
var custom_title := ""
var custom_line := ""
var stars_ctrl: Control
var t := 0.0


func _ready() -> void:
	add_to_group("vice_layer")
	layer = 10

	var tint := CanvasModulate.new()
	tint.color = Color(1.0, 0.9, 0.95)
	get_tree().current_scene.add_child.call_deferred(tint)

	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.35, 0.6, 0.28))
	grad.set_color(1, Color(1.0, 0.6, 0.3, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var sky := TextureRect.new()
	sky.texture = gt
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sky.size = Vector2(1152, 260)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(sky)

	stars_ctrl = Control.new()
	stars_ctrl.position = Vector2(1152 - 200, 14)
	stars_ctrl.draw.connect(_draw_stars)
	add_child(stars_ctrl)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	gm = get_tree().get_first_node_in_group("game_manager")
	title_card()


func _process(delta: float) -> void:
	t += delta
	if gm == null:
		return
	var new_stars := clampi(int(gm.heat / 2.0), 0, 5)
	if new_stars > stars:
		_flash_text("SLIME ALERT +1", Color(1, 0.85, 0.3), 16, Vector2(0, -170))
	stars = new_stars
	stars_ctrl.queue_redraw()


func _draw_stars() -> void:
	stars_ctrl.draw_string(FONT, Vector2(0, 10), "SLIME ALERT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	for i in 5:
		var c := Vector2(14 + i * 30, 30)
		var on := i < stars
		var blink := on and stars >= 3 and int(t * 6) % 2 == 0
		var col := Color(1, 0.85, 0.2) if on and not blink else Color(1, 1, 1, 0.25)
		_star(c, 11.0, Color.BLACK)
		_star(c, 9.0, col)


func _star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var rr := r if k % 2 == 0 else r * 0.45
		var a := -PI / 2 + k * PI / 5
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	stars_ctrl.draw_colored_polygon(pts, col)


func mission_passed() -> void:
	Sfx.play("mission_passed", 0.0, 0.0)
	_flash_text("MISSION PASSED", Color(1, 0.8, 0.2), 48, Vector2(0, -40), 2.4)
	_flash_text("RESPECT +", Color.WHITE, 20, Vector2(0, 20), 2.4)


func title_card() -> void:
	if custom_title != "":
		_flash_text(custom_title, Color(1, 0.8, 0.3), 32, Vector2(0, -60), 3.0)
		_flash_text(custom_line, Color.WHITE, 12, Vector2(0, -10), 3.0)
		_flash_text(MEMES.pick_random(), Color(1, 0.6, 0.85), 8, Vector2(0, 20), 3.0)
		return
	_flash_text(GAME_TITLE, Color(1, 0.45, 0.75), 56, Vector2(0, -60), 2.6)
	_flash_text(MEMES.pick_random(), Color.WHITE, 12, Vector2(0, 10), 2.6)


func _flash_text(text: String, col: Color, size: int, offset: Vector2, life := 1.2) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", maxi(4, size / 6))
	l.size = Vector2(1152, size + 10)
	l.pivot_offset = l.size / 2
	l.position = Vector2(0, 324 - size / 2) + offset
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(life)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)
	return l
