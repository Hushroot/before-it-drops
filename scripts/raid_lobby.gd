# ORIGIN: NEW, written by team.
# BOSS RAID LOBBY: up to 3 players on one screen.
#   PS4 controller: CROSS = join, LEFT/RIGHT (d-pad / stick) = change fighter, CIRCLE = leave, OPTIONS = start
#   Keyboard:       ENTER = join (then ENTER = start), ← → = change fighter, BACKSPACE = leave, ESC = back
extends Node2D

const Characters = preload("res://scripts/characters.gd")
const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const BOSS := "res://scenes/boss_arena.tscn"
const MAX_PLAYERS := 3
const CARD := Vector2(300, 360)
const COLORS := [Color(0.4, 0.8, 1.0), Color(1.0, 0.55, 0.4), Color(0.6, 1.0, 0.5)]

var slots: Array = []          # [{device, char}]  device: -2 keyboard, 0.. = controller
var cards: Array = []
var stick_cd := {}             # device -> cooldown for stick left/right
var ui: CanvasLayer
var hint: Label
var starting := false
var sfx_join: AudioStreamPlayer
var sfx_move: AudioStreamPlayer


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.08, 0.04, 0.12))
	Music.pitch_scale = 1.0
	if not Music.playing:
		Music.play()
	sfx_join = _sfx("res://assets/sounds/power_up.wav")
	sfx_move = _sfx("res://assets/sounds/tap.wav")
	ui = CanvasLayer.new()
	add_child(ui)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.9, 0.2, 0.35))
	grad.set_color(1, Color(0.1, 0.04, 0.18))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	var sky := TextureRect.new()
	sky.texture = gt
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.size = Vector2(1152, 648)
	ui.add_child(sky)
	ui.add_child(_label("BOSS RAID", 48, Color(1, 0.85, 0.3), Vector2(0, 20), 1152))
	ui.add_child(_label("Fight the Hamster Godfather together for the LAST COPY of GTA VI. Your bodies are your teammates' trampolines.", 12, Color.WHITE, Vector2(0, 84), 1152))
	hint = _label("", 16, Color.WHITE, Vector2(0, 560), 1152)
	ui.add_child(hint)
	ui.add_child(_label("PS4: CROSS join - LEFT/RIGHT fighter - CIRCLE leave - OPTIONS start      KEYBOARD: ENTER join/start - A/D - ESC back", 8, Color(1, 1, 1, 0.75), Vector2(0, 604), 1152))
	var x0 := (1152.0 - (CARD.x * 3 + 40 * 2)) / 2.0
	for i in MAX_PLAYERS:
		var card := Panel.new()
		card.position = Vector2(x0 + i * (CARD.x + 40), 120)
		card.size = CARD
		ui.add_child(card)
		cards.append(card)
	_refresh()


func _sfx(path: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	add_child(p)
	return p


func _label(text: String, size: int, col: Color, pos: Vector2, width: float) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", maxi(4, size / 5))
	l.position = pos
	l.size = Vector2(width, size + 8)
	return l


func _slot_of(device: int) -> int:
	for i in slots.size():
		if slots[i].device == device:
			return i
	return -1


func _refresh() -> void:
	for i in MAX_PLAYERS:
		var card: Panel = cards[i]
		for ch in card.get_children():
			ch.queue_free()
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(10)
		if i < slots.size():
			var s: Dictionary = slots[i]
			var c: Dictionary = Characters.LIST[s.char]
			sb.bg_color = Color(0.1, 0.05, 0.15, 0.9)
			sb.border_color = COLORS[i]
			sb.set_border_width_all(4)
			card.add_child(_label("P%d" % (i + 1), 24, COLORS[i], Vector2(0, 12), CARD.x))
			card.add_child(_label("KEYBOARD" if s.device == -2 else "CONTROLLER %d" % (s.device + 1), 8, Color(1, 1, 1, 0.7), Vector2(0, 44), CARD.x))
			var spr := AnimatedSprite2D.new()
			spr.sprite_frames = Characters.build_frames(c)
			spr.scale = Vector2.ONE * 4.5
			spr.position = Vector2(CARD.x / 2, 270)
			spr.play("taunt")
			spr.frame_changed.connect(func(): Characters.fit_sprite(spr))
			card.add_child(spr)
			Characters.fit_sprite(spr)
			card.add_child(_label("<  %s  >" % c.name, 16, Color(1, 0.85, 0.3), Vector2(0, 286), CARD.x))
			card.add_child(_label(c.perk, 8, Color(0.6, 1, 0.7), Vector2(10, 316), CARD.x - 20))
		else:
			sb.bg_color = Color(0.05, 0.03, 0.08, 0.6)
			sb.border_color = Color(0.4, 0.3, 0.5)
			sb.set_border_width_all(2)
			card.add_child(_label("P%d" % (i + 1), 24, Color(1, 1, 1, 0.3), Vector2(0, 12), CARD.x))
			card.add_child(_label("Press CROSS\nto join", 16, Color(1, 1, 1, 0.6), Vector2(0, 150), CARD.x))
		card.add_theme_stylebox_override("panel", sb)
	if slots.is_empty():
		hint.text = "Waiting for players..."
	else:
		hint.text = "%d player%s ready - press OPTIONS / ENTER to FIGHT" % [slots.size(), "" if slots.size() == 1 else "s"]


func _join(device: int) -> void:
	if _slot_of(device) >= 0 or slots.size() >= MAX_PLAYERS:
		return
	slots.append({"device": device, "char": slots.size() % Characters.LIST.size()})
	sfx_join.play()
	_refresh()


func _leave(device: int) -> void:
	var i := _slot_of(device)
	if i >= 0:
		slots.remove_at(i)
		_refresh()


func _cycle(device: int, dir: int) -> void:
	var i := _slot_of(device)
	if i < 0:
		return
	slots[i].char = wrapi(slots[i].char + dir, 0, Characters.LIST.size())
	sfx_move.play()
	_refresh()


func _start() -> void:
	if slots.is_empty() or starting:
		return
	starting = true
	var raid: Array = []
	for s in slots:
		raid.append({"device": s.device, "char": Characters.LIST[s.char].id})
	Engine.set_meta("raid", raid)
	Engine.set_meta("character", raid[0].char)
	sfx_join.play()
	await get_tree().create_timer(0.4).timeout
	# co-op plays the whole story together: Level 1 -> 2 -> 3 -> the Godfather
	Engine.set_meta("level_index", 1)
	Engine.set_meta("total_deaths", 0)
	get_tree().change_scene_to_file("res://scenes/story_level.tscn")


func _input(event: InputEvent) -> void:
	if starting:
		return
	if event is InputEventJoypadButton and event.pressed:
		var d: int = event.device
		match event.button_index:
			JOY_BUTTON_A:
				_join(d)
			JOY_BUTTON_B:
				_leave(d)
			JOY_BUTTON_DPAD_LEFT:
				_cycle(d, -1)
			JOY_BUTTON_DPAD_RIGHT:
				_cycle(d, 1)
			JOY_BUTTON_START:
				if _slot_of(d) < 0:
					_join(d)
				_start()
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X:
		var d: int = event.device
		if absf(event.axis_value) > 0.6 and Time.get_ticks_msec() > stick_cd.get(d, 0):
			stick_cd[d] = Time.get_ticks_msec() + 250
			_cycle(d, 1 if event.axis_value > 0 else -1)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ENTER, KEY_KP_ENTER:
				if _slot_of(-2) < 0:
					_join(-2)
				else:
					_start()
			KEY_LEFT, KEY_A:
				_cycle(-2, -1)
			KEY_RIGHT, KEY_D:
				_cycle(-2, 1)
			KEY_BACKSPACE:
				_leave(-2)
			KEY_ESCAPE:
				get_tree().change_scene_to_file("res://scenes/character_select.tscn")
