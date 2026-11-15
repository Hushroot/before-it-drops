# ORIGIN: NEW, written by team. Uses the Brackeys tileset (CC0).
# BOSS ARENA: the store's rooftop at sunset (Brackeys tiles), where the Hamster Godfather guards the LAST COPY.
extends Node2D

const TILESET = preload("res://assets/world_tileset.tres")
const SlimeKing = preload("res://scripts/slime_king.gd")
const BENCH = preload("res://scenes/checkpoint.tscn")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const RaidCamera = preload("res://scripts/raid_camera.gd")
const CityBackdrop = preload("res://scripts/city_backdrop.gd")

const W := 40          # arena width in tiles
const H := 14          # wall height in tiles
const STONE_TOP := Vector2i(2, 0)     # sand
const STONE := Vector2i(2, 1)
const WALL := Vector2i(5, 1)          # pink brick
const BRICK_TOP := Vector2i(5, 0)
const SUNSET_COL := 2                 # pink/purple sky column in the tileset (rows 9-15)
const WATER_TOP := Vector2i(4, 9)
const WATER := Vector2i(4, 10)

var tilemap: TileMap


func _ready() -> void:
	Music.pitch_scale = 1.15   # boss fight: same track, faster and tenser
	if not Music.playing:
		Music.play()
	_build_room()
	var bench = BENCH.instantiate()
	bench.position = Vector2(4 * 16, 0)
	add_child(bench)
	var king = SlimeKing.new()
	king.position = Vector2(W * 16 * 0.7, 0)
	king.left_x = 2 * 16 + 30
	king.right_x = (W - 2) * 16 - 30
	add_child(king)
	king.add_to_group("raid_focus")
	_setup_raid()


# BOSS RAID: replace the single player with 1-3 co-op players on one shared screen
func _setup_raid() -> void:
	var raid: Array = Engine.get_meta("raid", [])
	if raid.is_empty():
		return
	var solo := get_node_or_null("Player")
	var start := Vector2(56, -2)
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
		# player color tag so you can tell who is who
		var tag := Label.new()
		tag.text = "P%d" % (i + 1)
		tag.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
		tag.add_theme_font_size_override("font_size", 8)
		tag.add_theme_color_override("font_color", [Color(0.4, 0.8, 1.0), Color(1.0, 0.55, 0.4), Color(0.6, 1.0, 0.5)][i % 3])
		tag.add_theme_color_override("font_outline_color", Color.BLACK)
		tag.add_theme_constant_override("outline_size", 3)
		tag.position = Vector2(-6, -44)
		p.add_child(tag)
	var cam = RaidCamera.new()
	cam.arena_rect = Rect2(0, -(H + 2) * 16, W * 16, (H + 2) * 16 + 64)
	add_child(cam)


func _build_room() -> void:
	tilemap = TileMap.new()
	tilemap.tile_set = TILESET
	tilemap.add_layer(-1)   # layer 1 = solid
	add_child(tilemap)
	move_child(tilemap, 0)
	tilemap.add_layer(-1)   # layer 2 = decoration (palms)
	# Vice Slime skyline at sunset with the store's giant GAMES sign
	var bd = CityBackdrop.new()
	bd.style = "store"
	add_child(bd)
	# floor (sand) + walls (brick)
	for x in range(0, W):
		tilemap.set_cell(1, Vector2i(x, 0), 0, STONE_TOP)
		for y in range(1, 4):
			tilemap.set_cell(1, Vector2i(x, y), 0, STONE)
	for y in range(-H, 1):
		for x in [0, 1, W - 2, W - 1]:
			tilemap.set_cell(1, Vector2i(x, y), 0, WALL)

	# floating platforms (pink brick = the old castle)
	for p in [[7, -4, 4], [W - 11, -4, 4], [17, -8, 6]]:
		for x in range(p[0], p[0] + p[2]):
			tilemap.set_cell(1, Vector2i(x, p[1]), 0, BRICK_TOP)
