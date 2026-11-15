# ORIGIN: NEW, written by team. Tiles, coins, benches = Brackeys (CC0).
# STORY LEVEL: builds the level from the text map in levels.gd (level number = Engine meta "level_index").
extends Node2D

const Levels = preload("res://scripts/levels.gd")
const Guard = preload("res://scripts/guard.gd")
const Rival = preload("res://scripts/rival.gd")
const TILESET = preload("res://assets/world_tileset.tres")
const KILLZONE = preload("res://scenes/killzone.tscn")
const COIN = preload("res://scenes/coin.tscn")
const BENCH = preload("res://scenes/checkpoint.tscn")
const PLATFORM = preload("res://scenes/platform.tscn")
const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const BOSS := "res://scenes/boss_arena.tscn"
const CityBackdrop = preload("res://scripts/city_backdrop.gd")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const RaidCamera = preload("res://scripts/raid_camera.gd")

const TILES := {
	"grass": [Vector2i(0, 0), Vector2i(0, 1)],
	"brick": [Vector2i(5, 0), Vector2i(5, 1)],
	"stone": [Vector2i(8, 0), Vector2i(8, 1)],
	"sand": [Vector2i(2, 0), Vector2i(2, 1)],
}
const SKY := {"day": 0, "sunset": 2, "night": 3}     # background color column in the Brackeys tileset

var index := 1
var data: Dictionary
var tilemap: TileMap
var width := 0
var height := 0
var done := false


func _ready() -> void:
	Music.pitch_scale = 1.0
	if not Music.playing:
		Music.play()
	index = int(Engine.get_meta("level_index", 1))
	index = clampi(index, 1, Levels.LEVELS.size())
	data = Levels.LEVELS[index - 1]
	_build()
	_setup_coop()
	var vice = get_tree().get_first_node_in_group("vice_layer")
	if vice:
		vice.custom_title = data.title
		vice.custom_line = data.line


func _build() -> void:
	var rows: Array = data.map
	height = rows.size()
	for row in rows:
		width = maxi(width, row.length())
	tilemap = TileMap.new()
	tilemap.tile_set = TILESET
	tilemap.add_layer(-1)
	add_child(tilemap)
	move_child(tilemap, 0)
	# Vice Slime city in the background (parallax)
	var backdrop = CityBackdrop.new()
	backdrop.style = data.get("backdrop", "streets")
	add_child(backdrop)
	var pair: Array = TILES.get(data.tiles, TILES.grass)
	var spike_run := -1
	for y in height:
		var line: String = rows[y]
		for x in width:
			var cell := "."
			if x < line.length():
				cell = line[x]
			var above: String = rows[y - 1][x] if y > 0 and x < rows[y - 1].length() else "."
			var pos := Vector2(x * 16 + 8, (y + 1) * 16)
			match cell:
				"#":
					tilemap.set_cell(1, Vector2i(x, y), 0, pair[0] if above != "#" else pair[1])
				"P":
					var player = get_node_or_null("Player")
					if player:
						player.position = pos
				"B":
					var bench = BENCH.instantiate()
					bench.position = pos
					add_child(bench)
				"C":
					var coin = COIN.instantiate()
					coin.position = pos - Vector2(0, 8)
					add_child(coin)
					coin.owner = self
				"g", "h", "f":
					var guard = Guard.new()
					guard.kind = {"g": "lolli", "h": "smug", "f": "flame"}[cell]
					guard.position = pos
					add_child(guard)
				"s", "t", "o", "L":
					var rival = Rival.new()
					rival.kind = {"s": "scalper", "t": "streamer", "o": "preorder", "L": "line_cutter"}[cell]
					rival.position = pos
					add_child(rival)
				"=":
					if x % 2 == 0:
						var platform = PLATFORM.instantiate()
						platform.position = Vector2(x * 16 + 16, y * 16 + 4)
						add_child(platform)
				"E":
					_make_exit(pos)
			if cell in "123456789" and data.signs.has(cell):
				_make_sign(pos, data.signs[cell])
			# death spikes: one killzone per run of X
			if cell == "X" and spike_run < 0:
				spike_run = x
			if cell != "X" and spike_run >= 0:
				_make_spikes(spike_run, x - 1, y)
				spike_run = -1
		if spike_run >= 0:
			_make_spikes(spike_run, width - 1, y)
			spike_run = -1
	# falling off the bottom = pit hazard (lose a mask, back to the edge)
	var pit = KILLZONE.instantiate()
	pit.leaves_body = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width * 16 + 400, 32)
	shape.shape = rect
	pit.add_child(shape)
	pit.position = Vector2(width * 8, (height + 3) * 16)
	add_child(pit)
	# camera limits
	var camera: Camera2D = get_node_or_null("Player/Camera2D")
	if camera:
		camera.limit_left = 0
		camera.limit_right = width * 16
		camera.limit_top = -64
		camera.limit_bottom = height * 16


func _make_spikes(x0: int, x1: int, y: int) -> void:
	var kz = KILLZONE.instantiate()
	kz.instant_kill = true
	var sh := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	var w := (x1 - x0 + 1) * 16
	r.size = Vector2(w - 4, 5)
	sh.shape = r
	kz.add_child(sh)
	kz.position = Vector2(x0 * 16 + w / 2.0, (y + 1) * 16 - 2.5)
	add_child(kz)
	var art := Node2D.new()
	art.position = Vector2(x0 * 16, (y + 1) * 16)
	art.draw.connect(func():
		for i in (x1 - x0 + 1) * 2:
			var bx := i * 8.0
			art.draw_colored_polygon(PackedVector2Array([Vector2(bx, 0), Vector2(bx + 4, -7), Vector2(bx + 8, 0)]), Color(0.85, 0.85, 0.9))
			art.draw_line(Vector2(bx + 4, -7), Vector2(bx + 8, 0), Color(0.4, 0.4, 0.5), 1.0))
	add_child(art)


func _make_sign(pos: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # long signs wrap upward instead of running into the next sign
	l.size = Vector2(150, 12)
	add_child(l)
	var lines: int = maxi(1, l.get_line_count())
	l.size = Vector2(150, 12 * lines)
	l.position = pos - Vector2(75, 14 + 12 * (lines - 1))


func _make_exit(pos: Vector2) -> void:
	var a := Area2D.new()
	a.collision_mask = 2
	var sh := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20, 40)
	sh.shape = r
	sh.position = Vector2(0, -20)
	a.add_child(sh)
	a.position = pos
	a.body_entered.connect(_on_exit)
	add_child(a)
	var door := Node2D.new()
	door.draw.connect(func():
		door.draw_rect(Rect2(-9, -30, 18, 30), Color(0.15, 0.08, 0.05))
		door.draw_rect(Rect2(-7, -28, 14, 28), Color(1.0, 0.75, 0.3) if index == Levels.LEVELS.size() else Color(0.45, 0.25, 0.12))
		door.draw_circle(Vector2(4, -14), 1.5, Color(1, 0.9, 0.4)))
	a.add_child(door)
	_make_sign(pos - Vector2(0, 30), data.exit)


func _on_exit(body) -> void:
	if done or not body.is_in_group("player"):
		return
	# the Line Cutter blocks the door until he's beaten
	var blockers := get_tree().get_nodes_in_group("gatekeeper").filter(func(n): return is_instance_valid(n) and not n.has_meta("dying"))
	if blockers.size() > 0:
		blockers[0].say("Nobody gets in. Beat me first.")
		return
	done = true
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		Engine.set_meta("total_deaths", int(Engine.get_meta("total_deaths", 0)) + gm.deaths)
	var vice = get_tree().get_first_node_in_group("vice_layer")
	if vice:
		vice.mission_passed()
	await get_tree().create_timer(2.2).timeout
	if index < Levels.LEVELS.size():
		Engine.set_meta("level_index", index + 1)
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(BOSS)


# CO-OP STORY: if the raid lobby picked 2-3 players, they play the levels together on one shared screen
func _setup_coop() -> void:
	var raid: Array = Engine.get_meta("raid", [])
	if raid.size() < 2:
		return
	var solo := get_node_or_null("Player")
	var start := Vector2(56, 0)
	if solo:
		start = solo.position
		solo.remove_from_group("player")
		solo.queue_free()
	for i in raid.size():
		var p = PLAYER_SCENE.instantiate()
		p.device = raid[i].device
		p.char_id = raid[i].char
		p.player_index = i
		p.position = start + Vector2(i * 18, 0)
		add_child(p)
		var tag := Label.new()
		tag.text = "P%d" % (i + 1)
		tag.add_theme_font_override("font", FONT)
		tag.add_theme_font_size_override("font_size", 8)
		tag.add_theme_color_override("font_color", [Color(0.4, 0.8, 1.0), Color(1.0, 0.55, 0.4), Color(0.6, 1.0, 0.5)][i % 3])
		tag.add_theme_color_override("font_outline_color", Color.BLACK)
		tag.add_theme_constant_override("outline_size", 3)
		tag.position = Vector2(-6, -44)
		p.add_child(tag)
	var cam = RaidCamera.new()
	cam.arena_rect = Rect2(0, -64, width * 16, height * 16 + 128)
	add_child(cam)
