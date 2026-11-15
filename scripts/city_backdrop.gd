# ORIGIN: NEW, written by team. Drawn entirely in code (no image files).
# CITY BACKDROP: a Vice-Slime city with parallax, styled per stage.
#   "docks"   sunset harbor, cranes, palms
#   "streets" pink sunset, dense buildings, neon shop signs, streetlights
#   "roof"    night skyline, stars, moon, lit windows
#   "store"   purple sunset, giant GAMES sign behind the boss
extends ParallaxBackground

const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const W := 1536.0           # pattern width (repeats)
const H := 648.0
const SIGNS := ["GAMES", "24/7", "PIZZA", "MOTEL", "ARCADE", "DONUTS", "VICE", "BOUNCE", "TACOS", "PAWN"]
const NEON := [Color(1.0, 0.3, 0.7), Color(0.3, 0.95, 1.0), Color(1.0, 0.9, 0.3), Color(0.6, 1.0, 0.4), Color(1.0, 0.5, 0.2)]

var style := "streets"
var t := 0.0
var _layers: Array = []


func _ready() -> void:
	layer = -100
	scroll_ignore_camera_zoom = true    # draw in screen pixels, not zoomed with the world camera
	var s: Dictionary = _skies()[style]
	_add_layer(0.0, 0.0, func(ci): _draw_sky(ci, s))
	_add_layer(0.08, 0.02, func(ci): _draw_skyline(ci, s, 11, 0.55, s.far, false))
	_add_layer(0.25, 0.05, func(ci): _draw_buildings(ci, s, 23, 0.42, s.mid))
	_add_layer(0.55, 0.1, func(ci): _draw_near(ci, s, 37))


func _process(delta: float) -> void:
	t += delta
	for l in _layers:
		l.queue_redraw()     # neon flicker + window twinkle


func _skies() -> Dictionary:
	return {
		"docks": {"top": Color(0.10, 0.12, 0.35), "bottom": Color(1.0, 0.55, 0.3), "sun": Color(1.0, 0.8, 0.35), "stars": false,
			"far": Color(0.22, 0.14, 0.32), "mid": Color(0.16, 0.10, 0.24), "near": Color(0.07, 0.05, 0.10), "density": 0.6},
		"streets": {"top": Color(0.20, 0.05, 0.30), "bottom": Color(1.0, 0.35, 0.55), "sun": Color(1.0, 0.65, 0.3), "stars": false,
			"far": Color(0.30, 0.10, 0.35), "mid": Color(0.18, 0.06, 0.24), "near": Color(0.06, 0.03, 0.09), "density": 1.0},
		"roof": {"top": Color(0.02, 0.02, 0.08), "bottom": Color(0.12, 0.10, 0.30), "sun": Color(0.95, 0.95, 0.85), "stars": true,
			"far": Color(0.10, 0.10, 0.22), "mid": Color(0.07, 0.07, 0.16), "near": Color(0.03, 0.03, 0.07), "density": 0.9},
		"store": {"top": Color(0.15, 0.03, 0.25), "bottom": Color(1.0, 0.45, 0.25), "sun": Color(1.0, 0.75, 0.25), "stars": false,
			"far": Color(0.30, 0.08, 0.30), "mid": Color(0.17, 0.05, 0.20), "near": Color(0.06, 0.02, 0.08), "density": 0.8},
	}


func _add_layer(motion: float, motion_y: float, painter: Callable) -> void:
	var pl := ParallaxLayer.new()
	pl.motion_scale = Vector2(motion, motion_y)
	pl.motion_mirroring = Vector2(W, 0) if motion > 0.0 else Vector2.ZERO
	add_child(pl)
	var n := Node2D.new()
	n.draw.connect(func(): painter.call(n))
	pl.add_child(n)
	_layers.append(n)


# ---------------- painters ----------------
func _draw_sky(ci: Node2D, s: Dictionary) -> void:
	var bands := 24
	for i in bands:
		var k := float(i) / float(bands - 1)
		ci.draw_rect(Rect2(0, H * k * 0.85, 1400, H / bands + 2), s.top.lerp(s.bottom, k))
	ci.draw_rect(Rect2(0, H * 0.85, 1400, H * 0.2), s.bottom)
	if s.stars:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in 90:
			var p := Vector2(rng.randf() * 1400, rng.randf() * H * 0.6)
			var tw := 0.5 + 0.5 * sin(t * 2.0 + i)
			ci.draw_circle(p, 1.0 + rng.randf(), Color(1, 1, 1, 0.4 + 0.5 * tw))
		ci.draw_circle(Vector2(900, 120), 46, s.sun)
		ci.draw_circle(Vector2(920, 110), 40, s.top.lerp(s.bottom, 0.15))
	else:
		# retro sun with stripes
		var c := Vector2(760, H * 0.62)
		ci.draw_circle(c, 150, Color(s.sun, 0.25))
		ci.draw_circle(c, 120, s.sun)
		for i in 6:
			var y := c.y + 20 + i * 16
			ci.draw_rect(Rect2(c.x - 130, y, 260, 4 + i), s.bottom.lerp(s.top, 0.15))


func _draw_skyline(ci: Node2D, s: Dictionary, seed: int, height_frac: float, col: Color, _lit: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var x := 0.0
	while x < W:
		var w := rng.randf_range(40, 110)
		var h := rng.randf_range(0.25, 1.0) * H * height_frac
		ci.draw_rect(Rect2(x, H - h, w + 1, h), col)
		if rng.randf() < 0.25:   # antenna
			ci.draw_line(Vector2(x + w / 2, H - h), Vector2(x + w / 2, H - h - 30), col, 2.0)
			ci.draw_circle(Vector2(x + w / 2, H - h - 30), 2.5, Color(1, 0.2, 0.2, 0.6 + 0.4 * sin(t * 3.0 + x)))
		x += w + rng.randf_range(0, 12)


func _draw_buildings(ci: Node2D, s: Dictionary, seed: int, height_frac: float, col: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var x := 0.0
	while x < W:
		var w := rng.randf_range(70, 160)
		var h := rng.randf_range(0.35, 1.0) * H * height_frac
		var top := H - h
		ci.draw_rect(Rect2(x, top, w, h), col)
		ci.draw_rect(Rect2(x, top, w, 4), col.lightened(0.15))
		# windows
		var wy := top + 14
		while wy < H - 10:
			var wx := x + 8
			while wx < x + w - 12:
				if rng.randf() < 0.45 * s.density:
					var on := rng.randf() < 0.85 or int(t * 0.5 + wx) % 7 != 0
					if on:
						ci.draw_rect(Rect2(wx, wy, 6, 8), Color(1.0, 0.85, 0.5, 0.75) if rng.randf() < 0.7 else Color(0.5, 0.9, 1.0, 0.7))
				wx += 14
			wy += 18
		# neon sign
		if rng.randf() < 0.55 * s.density:
			var text: String = SIGNS[rng.randi() % SIGNS.size()]
			var nc: Color = NEON[rng.randi() % NEON.size()]
			var flick := 1.0 if int(t * 8.0 + x) % 23 != 0 else 0.3
			var sy := top + rng.randf_range(20, 60)
			var fs := 16
			var tw := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var sx := x + (w - tw) / 2
			ci.draw_rect(Rect2(sx - 6, sy - fs - 4, tw + 12, fs + 10), Color(nc, 0.15 * flick))
			ci.draw_rect(Rect2(sx - 6, sy - fs - 4, tw + 12, fs + 10), Color(nc, 0.9 * flick), false, 2.0)
			ci.draw_string(FONT, Vector2(sx, sy), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(nc, flick))
		x += w + rng.randf_range(4, 30)
	# the store's giant sign
	if style == "store":
		_storefront(ci)


func _draw_near(ci: Node2D, s: Dictionary, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var col: Color = s.near
	var x := 30.0
	while x < W:
		var kind := rng.randf()
		if style == "docks" and kind < 0.3:
			_crane(ci, x, col)
			x += 260
		elif kind < 0.6:
			_palm(ci, x, rng.randf_range(170, 260), col, rng)
			x += rng.randf_range(120, 220)
		else:
			_streetlight(ci, x, col)
			x += rng.randf_range(140, 240)


func _palm(ci: Node2D, x: float, h: float, col: Color, rng: RandomNumberGenerator) -> void:
	var base := Vector2(x, H)
	var top := Vector2(x + rng.randf_range(-30, 30), H - h)
	var pts := PackedVector2Array()
	for i in 9:
		var k := i / 8.0
		pts.append(base.lerp(top, k) + Vector2(sin(k * PI) * 18, 0))
	ci.draw_polyline(pts, col, 9.0)
	for f in 7:
		var a := -PI / 2 + (f - 3) * 0.55 + sin(t * 1.2 + x) * 0.05
		var tip := top + Vector2(cos(a), sin(a)) * 70 + Vector2(0, 30)
		var mid := top + Vector2(cos(a), sin(a)) * 38 + Vector2(0, -6)
		ci.draw_colored_polygon(PackedVector2Array([top, mid + Vector2(0, -8), tip, mid + Vector2(0, 8)]), col)


func _streetlight(ci: Node2D, x: float, col: Color) -> void:
	ci.draw_line(Vector2(x, H), Vector2(x, H - 150), col, 5.0)
	ci.draw_line(Vector2(x, H - 150), Vector2(x + 34, H - 150), col, 5.0)
	var glow := 0.55 + 0.1 * sin(t * 5.0 + x)
	ci.draw_circle(Vector2(x + 34, H - 144), 26, Color(1.0, 0.85, 0.5, 0.12 * glow))
	ci.draw_circle(Vector2(x + 34, H - 145), 6, Color(1.0, 0.9, 0.6, glow))


func _crane(ci: Node2D, x: float, col: Color) -> void:
	ci.draw_rect(Rect2(x, H - 300, 14, 300), col)
	ci.draw_rect(Rect2(x - 40, H - 300, 200, 12), col)
	ci.draw_line(Vector2(x + 140, H - 288), Vector2(x + 140, H - 200), col, 2.0)
	ci.draw_rect(Rect2(x + 128, H - 200, 24, 18), col)
	ci.draw_circle(Vector2(x + 7, H - 306), 3, Color(1, 0.2, 0.2, 0.5 + 0.5 * sin(t * 3.0)))


# THE GAME STORE (boss arena): the side of the store, code-drawn. Opponents walk out of its door.
func _storefront(ci: Node2D) -> void:
	var x0 := 250.0
	var x1 := 1110.0
	var top := 120.0
	var ground := 560.0
	var nc := Color(1.0, 0.3, 0.75)
	var glow := 0.8 + 0.2 * sin(t * 4.0)
	# building + bricks
	ci.draw_rect(Rect2(x0, top, x1 - x0, ground - top), Color(0.36, 0.22, 0.30))
	for row in int((ground - top) / 14.0):
		var y := top + row * 14.0
		var off := 0.0 if row % 2 == 0 else 14.0
		var bx := x0 + off
		while bx < x1:
			ci.draw_rect(Rect2(bx, y, 27, 13), Color(0.42, 0.26, 0.34))
			bx += 28.0
	ci.draw_rect(Rect2(x0 - 10, top - 14, x1 - x0 + 20, 16), Color(0.22, 0.12, 0.20))   # roof ledge
	# neon GAMES sign
	ci.draw_rect(Rect2(500, 136, 360, 84), Color(0.08, 0.02, 0.1))
	ci.draw_rect(Rect2(500, 136, 360, 84), Color(nc, glow), false, 5.0)
	ci.draw_string(FONT, Vector2(536, 200), "GAMES", HORIZONTAL_ALIGNMENT_LEFT, -1, 56, Color(nc, glow))
	ci.draw_string(FONT, Vector2(552, 216), "LAST COPY INSIDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.9, 0.3, glow))
	# striped awning
	var aw_y := 250.0
	var sx := x0 + 20.0
	var i := 0
	while sx < x1 - 20.0:
		var c := Color(1.0, 0.35, 0.6) if i % 2 == 0 else Color(0.98, 0.93, 0.88)
		ci.draw_rect(Rect2(sx, aw_y, 30, 34), c)
		ci.draw_circle(Vector2(sx + 15, aw_y + 34), 15.0, c)       # scalloped edge
		sx += 30.0
		i += 1
	ci.draw_rect(Rect2(x0 + 20, aw_y - 6, x1 - x0 - 40, 8), Color(0.25, 0.12, 0.2))
	# two shop windows full of game boxes + the door in the middle
	var door_x := (x0 + x1) / 2.0 - 45.0
	for wxv in [x0 + 50.0, door_x + 140.0]:
		var wx: float = wxv
		var ww := 300.0
		var wr := Rect2(wx, 320, ww, 170)
		ci.draw_rect(wr, Color(0.12, 0.10, 0.22))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(wx)
		for shelf in 3:
			var shy := 360.0 + shelf * 50.0
			ci.draw_rect(Rect2(wx + 8, shy, ww - 16, 5), Color(0.55, 0.35, 0.25))
			var bx2: float = wx + 14.0
			while bx2 < wx + ww - 26.0:
				var h := rng.randf_range(24, 34)
				var bc := Color.from_hsv(rng.randf(), 0.6, 0.85)
				ci.draw_rect(Rect2(bx2, shy - h, 16, h), bc)
				ci.draw_rect(Rect2(bx2 + 2, shy - h + 3, 12, 6), Color(1, 1, 1, 0.5))    # label
				bx2 += 20.0
		# glass shine
		ci.draw_line(Vector2(wx + 30, 330), Vector2(wx + 90, 480), Color(1, 1, 1, 0.12), 10.0)
		ci.draw_rect(wr, Color(0.2, 0.1, 0.15), false, 6.0)
	# door (opponents come out of here)
	ci.draw_rect(Rect2(door_x, 330, 90, ground - 330), Color(0.07, 0.04, 0.10))
	ci.draw_rect(Rect2(door_x, 330, 90, ground - 330), Color(0.2, 0.1, 0.15), false, 6.0)
	ci.draw_rect(Rect2(door_x + 14, 350, 62, 26), Color(0.1, 0.5, 0.2))
	ci.draw_string(FONT, Vector2(door_x + 20, 369), "OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 1.0, 0.6, glow))
	# warm hanging lamps
	for lx in [x0 + 130.0, door_x + 45.0, x1 - 130.0]:
		ci.draw_line(Vector2(lx, 284), Vector2(lx, 302), Color(0.1, 0.05, 0.08), 2.0)
		ci.draw_circle(Vector2(lx, 310), 22.0, Color(1.0, 0.6, 0.2, 0.18 * glow))
		ci.draw_circle(Vector2(lx, 310), 8.0, Color(1.0, 0.65, 0.25))
	# potted plants
	for px in [x0 + 20.0, door_x - 30.0, door_x + 108.0, x1 - 40.0]:
		ci.draw_rect(Rect2(px, ground - 30, 22, 30), Color(0.55, 0.32, 0.2))
		ci.draw_circle(Vector2(px + 11, ground - 44), 18.0, Color(0.25, 0.55, 0.3))
		ci.draw_circle(Vector2(px + 4, ground - 56), 11.0, Color(0.32, 0.65, 0.35))
