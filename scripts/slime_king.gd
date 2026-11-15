extends Node2D

const Look = preload("res://scripts/look.gd")

const SLIME_SCENE = preload("res://scenes/slime.tscn")
const KILLZONE_SCENE = preload("res://scenes/killzone.tscn")
const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const Ending = preload("res://scripts/ending.gd")
const Portrait = preload("res://scripts/boss_portrait.gd")

const MAX_HP := 10
const GRAVITY := 900.0
const SIZE := 3.5
const BODY_TEX = preload("res://assets/hamsters/godfather.png")
const MINION_GUARD = "lolli"
const EnemyShot = preload("res://scripts/enemy_shot.gd")
const Guard = preload("res://scripts/guard.gd")


const FINAL_BOSS_TEX := "res://assets/boss/final/body.png"
const FINAL_BOSS_PORTRAIT := "res://assets/boss/final/portrait.png"
const FINAL_BOSS_NAME := "THE VICE QUEEN"
const FINAL_BOSS_LINE := "\"THE LAST COPY? IT WAS ALWAYS MINE.\""

var is_final := false
var boss_name := "THE HAMSTER GODFATHER"
var max_hp := MAX_HP
var body_tex: Texture2D = BODY_TEX
var hp := MAX_HP
var vel := Vector2.ZERO
var state := "sleep"
var state_t := 0.0
var on_floor := true
var left_x := 60.0
var right_x := 580.0
var floor_y := 0.0
var minions: Array = []
var dead := false

var sprite: AnimatedSprite2D
var bar: ColorRect
var bar_bg: ColorRect
var portrait
var sfx_slam: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_clank: AudioStreamPlayer
var gm
var player


func _ready() -> void:
	add_to_group("enemy_target")
	if is_final:
		boss_name = FINAL_BOSS_NAME
		body_tex = load(FINAL_BOSS_TEX)
		max_hp = 14
		hp = max_hp
	floor_y = position.y
	var tmp = SLIME_SCENE.instantiate()
	tmp.free()
	sprite = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_frame("default", body_tex)
	sprite.sprite_frames = sf
	sprite.scale = Vector2(SIZE, SIZE)
	sprite.offset = Vector2(0, -body_tex.get_height() / 2.0)
	sprite.play()
	var holder := Node2D.new()
	holder.scale = Vector2.ONE * (24.0 / body_tex.get_height())
	holder.position = Vector2(0, 4)
	add_child(holder)
	holder.add_child(sprite)
	Look.outline(sprite, 1.0)

	var kz = KILLZONE_SCENE.instantiate()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0 * SIZE
	shape.shape = circle
	shape.position = Vector2(0, -7 * SIZE)
	kz.add_child(shape)
	add_child(kz)
	sfx_slam = _sfx("res://assets/sounds/explosion.wav", -6.0)
	sfx_hit = _sfx("res://assets/sounds/hurt.wav", 0.0)
	sfx_clank = _sfx("res://assets/sounds/tap.wav", 0.0)
	_build_bar()
	await get_tree().process_frame
	gm = get_tree().get_first_node_in_group("game_manager")
	player = get_tree().get_first_node_in_group("player")


func _purple_frames(src: SpriteFrames) -> SpriteFrames:
	var purple: Texture2D = load("res://assets/sprites/slime_purple.png")
	var out := SpriteFrames.new()
	out.remove_animation("default")
	for anim in src.get_animation_names():
		out.add_animation(anim)
		out.set_animation_speed(anim, src.get_animation_speed(anim))
		out.set_animation_loop(anim, src.get_animation_loop(anim))
		for i in src.get_frame_count(anim):
			var tex = src.get_frame_texture(anim, i)
			if tex is AtlasTexture:
				var a := AtlasTexture.new()
				a.atlas = purple
				a.region = tex.region
				tex = a
			out.add_frame(anim, tex, src.get_frame_duration(anim, i))
	return out


func _sfx(path: String, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.volume_db = db
	add_child(p)
	return p


func phase() -> int:
	return 2 if hp <= max_hp / 2 else 1


func _physics_process(delta: float) -> void:
	if dead or player == null:
		return
	player = _nearest_player()
	state_t -= delta
	var to_player: float = player.global_position.x - global_position.x

	match state:
		"sleep":

			if absf(to_player) < 170.0:
				_toast((boss_name + ": " + FINAL_BOSS_LINE) if is_final else "THE HAMSTER GODFATHER: \"THE LAST COPY IS MINE.\"  (Strike his $$$ tags back at him!)", Color(0.85, 0.55, 1.0))
				portrait.react("smug", 1.5)
				state = "idle"
				state_t = 1.0
				bar.get_parent().visible = true
		"idle":
			sprite.flip_h = to_player < 0
			if state_t <= 0.0:
				_hop(to_player)
		"air":
			vel.y += GRAVITY * delta
			position += vel * delta
			if position.x < left_x or position.x > right_x:
				position.x = clampf(position.x, left_x, right_x)
				vel.x = -vel.x * 0.5
			if position.y >= floor_y and vel.y > 0:
				position.y = floor_y
				_slam()


	if state == "idle":
		var s := 1.0 + sin(Time.get_ticks_msec() / 120.0) * 0.04
		sprite.scale = Vector2(SIZE * s, SIZE / s)


func _hop(to_player: float) -> void:
	state = "air"
	var p2 := phase() == 2
	var dist := clampf(to_player, -220.0, 220.0)
	var air_time := 0.9 if not p2 else 0.75
	vel = Vector2(dist / air_time, -GRAVITY * air_time * 0.5)
	if p2 and randf() < 0.35:
		vel.y *= 1.35
	sprite.scale = Vector2(SIZE * 1.3, SIZE * 0.7)
	create_tween().tween_property(sprite, "scale", Vector2(SIZE * 0.85, SIZE * 1.2), 0.15)


func _slam() -> void:
	state = "idle"
	state_t = 1.1 if phase() == 1 else 0.6
	vel = Vector2.ZERO
	sprite.scale = Vector2(SIZE * 1.4, SIZE * 0.6)
	create_tween().tween_property(sprite, "scale", Vector2(SIZE, SIZE), 0.3).set_trans(Tween.TRANS_ELASTIC)
	sfx_slam.play()
	portrait.react("angry", 0.4)
	if gm:
		gm._shake(6.0)

	for p in get_tree().get_nodes_in_group("player"):
		if not p.is_dead and p.is_on_floor() and absf(p.global_position.x - global_position.x) < 90.0:
			gm.player_hit(global_position, false, p)
	_dust()

	var tags := 1 if phase() == 1 else 2
	for i in tags:
		var target = _nearest_player()
		if target == null:
			break
		var shot = EnemyShot.new()
		shot.global_position = global_position + Vector2(0, -14.0 * SIZE)
		var dx: float = target.global_position.x - shot.global_position.x + (i * 40.0 - 20.0) * float(tags - 1)
		shot.gravity = 260.0
		shot.life = 3.0
		shot.velocity = Vector2(clampf(dx / 1.1, -260.0, 260.0), -150.0)
		get_parent().add_child(shot)
		Sfx.play("throw", -6.0)

	minions = minions.filter(func(m): return is_instance_valid(m))
	if phase() == 2 and minions.size() < 3 and randf() < 0.6:
		var m = Guard.new()
		m.kind = MINION_GUARD
		m.position = Vector2((left_x + right_x) / 2.0 + randf_range(-10, 10), floor_y)
		_toast("BACKUP OUT OF THE STORE!", Color(1, 0.6, 0.85))
		get_parent().add_child(m)
		minions.append(m)


func _nearest_player():
	var best = player
	var bd := INF
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_dead or p.is_queued_for_deletion():
			continue
		var d: float = absf(p.global_position.x - global_position.x)
		if d < bd:
			bd = d
			best = p
	return best


func on_nail_hit(by: Node2D) -> void:
	if dead:
		return
	var from_above: bool = by.global_position.y < global_position.y - 9.0 * SIZE
	var power: int = by.get("power") if by.get("power") != null else 1
	var brute: bool = (power > 1 or by.get("armor_break") == true) and not from_above
	if not from_above and not brute:

		sfx_clank.pitch_scale = 0.6
		sfx_clank.play()
		_toast("CLANK! Strike from above!", Color.WHITE)
		portrait.react("smug", 0.8)
		by.velocity.x = 220.0 * signf(by.global_position.x - global_position.x)
		return
	var before := hp
	hp -= power
	_update_bar()
	if brute:
		_toast("ARMOR BROKEN!", Color(1, 0.6, 0.2))
		portrait.react("angry", 0.5)
		position.x = clampf(position.x + 24.0 * signf(global_position.x - by.global_position.x), left_x, right_x)
		by.velocity.x = 160.0 * signf(by.global_position.x - global_position.x)
	else:
		portrait.react("squashed", 0.5)
	sfx_hit.play()
	sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(sprite, "modulate", Color(1.0, 0.6, 0.7) if hp <= max_hp / 2 else Color.WHITE, 0.2)
	if gm:
		gm._shake(3.0)
	if before > max_hp / 2 and hp <= max_hp / 2:
		_toast(boss_name + " IS FURIOUS", Color(1, 0.4, 0.4))
		portrait.set_base("enraged")
		portrait.react("enraged", 1.0)
		sprite.modulate = Color(1.0, 0.4, 0.6)
	if hp <= 0:
		_die()


func _die() -> void:
	dead = true
	var chain_final: bool = not is_final and ResourceLoader.exists(FINAL_BOSS_TEX)
	Sfx.play("mission_passed" if chain_final else "victory", 0.0, 0.0)
	portrait.react("defeated", 0.0)
	for m in minions:
		if is_instance_valid(m):
			m.queue_free()
	Engine.time_scale = 0.3
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(SIZE * 2.0, SIZE * 0.1), 0.6)
	tw.parallel().tween_property(sprite, "modulate:a", 0.0, 0.6)
	_dust()
	_dust()
	if gm:
		gm.score += 20
		gm._update_hud()
		gm._shake(10.0)
	await get_tree().create_timer(0.6 * 0.3).timeout
	Engine.time_scale = 1.0
	await get_tree().create_timer(1.2).timeout
	bar.get_parent().visible = false
	if chain_final:
		_toast("BUT WAIT... " + FINAL_BOSS_NAME + " WANTS THE LAST COPY TOO", Color(1, 0.5, 0.8))
		if gm:
			for p in gm.players:
				p.pmasks = p.pmax
			gm._update_hud()
		await get_tree().create_timer(2.0).timeout
		var fb = get_script().new()
		fb.is_final = true
		fb.position = Vector2((left_x + right_x) / 2.0, floor_y)
		fb.left_x = left_x
		fb.right_x = right_x
		get_parent().add_child(fb)
		fb.add_to_group("raid_focus")
		queue_free()
		return
	var e = Ending.new()
	get_parent().add_child(e)
	e.play(gm, player)


func _dust() -> void:
	var p := CPUParticles2D.new()
	p.position = position
	p.one_shot = true
	p.amount = 24
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 80.0
	p.gravity = Vector2(0, 300)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 160.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.8, 0.6, 1.0)
	get_parent().add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _build_bar() -> void:
	var layer := CanvasLayer.new()
	layer.visible = false
	add_child(layer)
	var name_l := Label.new()
	name_l.text = boss_name
	name_l.add_theme_font_override("font", FONT)
	name_l.add_theme_font_size_override("font_size", 16)
	name_l.add_theme_color_override("font_outline_color", Color.BLACK)
	name_l.add_theme_constant_override("outline_size", 6)
	name_l.position = Vector2(376, 560)
	layer.add_child(name_l)
	bar_bg = ColorRect.new()
	bar_bg.color = Color(0, 0, 0, 0.7)
	bar_bg.position = Vector2(376, 584)
	bar_bg.size = Vector2(400, 12)
	layer.add_child(bar_bg)
	bar = ColorRect.new()
	bar.color = Color(0.75, 0.4, 1.0)
	bar.position = Vector2(378, 586)
	bar.size = Vector2(396, 8)
	layer.add_child(bar)
	portrait = Portrait.new()
	portrait.position = Vector2(282, 524)
	portrait.set_placeholder(sprite.sprite_frames.get_frame_texture(sprite.animation, 0))
	layer.add_child(portrait)
	if is_final:
		var ptex: Texture2D = load(FINAL_BOSS_PORTRAIT) if ResourceLoader.exists(FINAL_BOSS_PORTRAIT) else body_tex
		for m in portrait.MOODS:
			var mp := "res://assets/boss/final/portrait_%s.png" % m
			portrait.art[m] = load(mp) if ResourceLoader.exists(mp) else ptex
	_update_bar()


func _update_bar() -> void:
	if bar:
		bar.size.x = 396.0 * float(maxi(hp, 0)) / float(max_hp)


func _toast(text: String, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	get_parent().add_child(l)
	l.global_position = global_position + Vector2(-60, -16 * SIZE - 20)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 16, 1.2)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.2)
	tw.tween_callback(l.queue_free)
