extends Node2D

const Characters = preload("res://scripts/characters.gd")
const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const GAME_TITLE := "BEFORE IT DROPS"
const SUBTITLE := "We got GTA VI before release day."
const FIRST_LEVEL := "res://scenes/story_level.tscn"
const INTRO := "res://scenes/intro.tscn"
const FALLBACK_LEVEL := "res://scenes/game.tscn"
const BOSS := "res://scenes/boss_arena.tscn"
const RAID_LOBBY := "res://scenes/raid_lobby.tscn"
const CARD := Vector2(300, 380)
const PREVIEW_SCALE := 5.0

var selected := 0
var cards: Array = []
var sprites: Array = []
var t := 0.0
var sfx_move: AudioStreamPlayer
var sfx_pick: AudioStreamPlayer
var starting := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.08, 0.04, 0.12))
	Music.pitch_scale = 1.0
	if not Music.playing:
		Music.play()
	sfx_move = _sfx("res://assets/sounds/tap.wav")
	sfx_pick = _sfx("res://assets/sounds/power_up.wav")
	var last: String = Engine.get_meta("character", "")
	for i in Characters.LIST.size():
		if Characters.LIST[i].id == last:
			selected = i
	_build()
	_select(selected, false)


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


func _build() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.35, 0.6))
	grad.set_color(1, Color(0.12, 0.05, 0.2))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	var sky := TextureRect.new()
	sky.texture = gt
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.size = Vector2(1152, 648)
	ui.add_child(sky)
	ui.add_child(_label(GAME_TITLE, 48, Color(1, 0.5, 0.8), Vector2(0, 24), 1152))
	ui.add_child(_label(SUBTITLE, 12, Color(1, 0.9, 0.5), Vector2(0, 76), 1152))
	ui.add_child(_label("CHOOSE YOUR FIGHTER", 24, Color.WHITE, Vector2(0, 96), 1152))

	var total := CARD.x * Characters.LIST.size() + 40.0 * (Characters.LIST.size() - 1)
	var x0 := (1152.0 - total) / 2.0
	for i in Characters.LIST.size():
		var c: Dictionary = Characters.LIST[i]
		var card := Panel.new()
		card.position = Vector2(x0 + i * (CARD.x + 40), 140)
		card.size = CARD
		card.pivot_offset = CARD / 2
		card.gui_input.connect(_on_card_input.bind(i))
		card.mouse_entered.connect(func():
			if not starting:
				_select(i))
		ui.add_child(card)
		cards.append(card)
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = Characters.build_frames(c)
		spr.scale = Vector2.ONE * PREVIEW_SCALE
		spr.position = Vector2(CARD.x / 2, 250)
		spr.play("idle")
		card.add_child(spr)
		sprites.append(spr)
		card.add_child(_label(c.name, 24, Color(1, 0.85, 0.3), Vector2(0, 262), CARD.x))
		card.add_child(_label(c.tagline, 12, Color(0.9, 0.9, 1), Vector2(10, 296), CARD.x - 20))
		card.add_child(_label(c.perk, 8, Color(0.6, 1, 0.7), Vector2(10, 322), CARD.x - 20))
		card.add_child(_label("SPECIAL: " + c.special, 8, Color(1, 0.75, 0.4), Vector2(10, 350), CARD.x - 20))
	ui.add_child(_label("< >  pick      ENTER / CROSS  play      B  boss fight      R / OPTIONS  BOSS RAID (co-op)", 12, Color.WHITE, Vector2(0, 562), 1152))
	ui.add_child(_label("Every death gets you higher.", 12, Color(1, 1, 1, 0.7), Vector2(0, 600), 1152))


func _select(i: int, sound := true) -> void:
	if i == selected and sound:
		return
	selected = i
	if sound:
		sfx_move.play()
	for k in cards.size():
		var on := k == selected
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.05, 0.15, 0.85) if on else Color(0.05, 0.03, 0.08, 0.7)
		sb.border_color = Color(1, 0.85, 0.3) if on else Color(0.4, 0.3, 0.5)
		sb.set_border_width_all(4 if on else 2)
		sb.set_corner_radius_all(10)
		cards[k].add_theme_stylebox_override("panel", sb)
		var tw := create_tween()
		tw.tween_property(cards[k], "scale", Vector2.ONE * (1.06 if on else 0.94), 0.15)
		cards[k].modulate = Color.WHITE if on else Color(0.7, 0.7, 0.8)
		sprites[k].play("taunt" if on else "idle")


func _process(delta: float) -> void:
	t += delta
	for spr in sprites:
		Characters.fit_sprite(spr)

	if sprites.size() > 0:
		sprites[selected].position.y = 250 - absf(sin(t * 4.0)) * 6.0


func _unhandled_input(event: InputEvent) -> void:
	if starting:
		return

	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				_select(wrapi(selected - 1, 0, cards.size()))
			JOY_BUTTON_DPAD_RIGHT:
				_select(wrapi(selected + 1, 0, cards.size()))
			JOY_BUTTON_A:
				_start(_first_level())
			JOY_BUTTON_START:
				get_tree().change_scene_to_file(RAID_LOBBY)
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_LEFT, KEY_A:
			_select(wrapi(selected - 1, 0, cards.size()))
		KEY_RIGHT, KEY_D:
			_select(wrapi(selected + 1, 0, cards.size()))
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_J:
			_start(_first_level())
		KEY_B:
			_start(BOSS)
		KEY_R:
			starting = true
			get_tree().change_scene_to_file(RAID_LOBBY)


func _on_card_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not starting:
		_select(i)
		_start(_first_level())


func _first_level() -> String:
	if ResourceLoader.exists(INTRO):
		return INTRO
	return FIRST_LEVEL if ResourceLoader.exists(FIRST_LEVEL) else FALLBACK_LEVEL


func _start(scene: String) -> void:
	starting = true
	Engine.set_meta("character", Characters.LIST[selected].id)
	Engine.set_meta("raid", [])
	Engine.set_meta("level_index", 1)
	Engine.set_meta("total_deaths", 0)
	sfx_pick.play()
	var tw := create_tween()
	tw.tween_property(cards[selected], "scale", Vector2.ONE * 1.15, 0.12)
	tw.tween_property(cards[selected], "scale", Vector2.ONE * 1.06, 0.12)
	tw.tween_interval(0.35)
	tw.tween_callback(func(): get_tree().change_scene_to_file(scene))
