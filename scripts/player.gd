extends CharacterBody2D

const Look = preload("res://scripts/look.gd")

const Characters = preload("res://scripts/characters.gd")
const Projectile = preload("res://scripts/projectile.gd")
const SOUL_COST := 33.0


const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const BOUNCE_VELOCITY = -420.0
const BOUNCE_BOOST = 1.2
const POGO_VELOCITY = -300.0
const DASH_SPEED = 330.0
const DASH_TIME = 0.16
const DASH_COOLDOWN = 0.45
const ATTACK_COOLDOWN = 0.32
const KNOCKBACK = Vector2(160, -170)


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var controllable := true
var facing := 1
var invuln := 0.0
var attack_cd := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var can_air_dash := true
var stun := 0.0
var last_safe := Vector2.ZERO
var safe_t := 0.0
var slash_t := 0.0
var slash_dir := Vector2.RIGHT
var speed_mult := 1.0
var reach := 1.0
var power := 1
var custom_char := false
var base_scale := Vector2.ONE
var attack_anim_t := 0.0

var device := -1
var prefix := ""
var char_id := ""
var player_index := 0
var pmasks := 5
var pmax := 5
var is_dead := false
var special_cd := 0.0
var charging := false
var charge_hits := {}

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
var sfx_jump: AudioStreamPlayer
var sfx_hurt: AudioStreamPlayer
var sfx_bounce: AudioStreamPlayer
var sfx_slash: AudioStreamPlayer


func _ready():
	add_to_group("player")
	_setup_inputs()
	_apply_character()
	last_safe = global_position
	sfx_jump = _make_sfx("res://assets/sounds/jump.wav")
	sfx_hurt = _make_sfx("res://assets/sounds/hurt.wav")
	sfx_bounce = _make_sfx("res://assets/sounds/power_up.wav")
	sfx_slash = _make_sfx("res://assets/sounds/tap.wav")


func _act(action: String) -> String:
	return prefix + action


const PAD := {
	"move_left": [[JOY_AXIS_LEFT_X, -1.0], JOY_BUTTON_DPAD_LEFT],
	"move_right": [[JOY_AXIS_LEFT_X, 1.0], JOY_BUTTON_DPAD_RIGHT],
	"move_up": [[JOY_AXIS_LEFT_Y, -1.0], JOY_BUTTON_DPAD_UP],
	"move_down": [[JOY_AXIS_LEFT_Y, 1.0], JOY_BUTTON_DPAD_DOWN],
	"jump": [JOY_BUTTON_A],
	"attack": [JOY_BUTTON_X],
	"dash": [JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER],
	"special": [JOY_BUTTON_Y],
	"power": [[JOY_AXIS_TRIGGER_RIGHT, 1.0], JOY_BUTTON_LEFT_SHOULDER],
}


static func _add_pad_events(base: String, action: String, dev: int) -> void:
	for binding in PAD[base]:
		var event: InputEvent
		if binding is Array:
			event = InputEventJoypadMotion.new()
			event.axis = binding[0]
			event.axis_value = binding[1]
		else:
			event = InputEventJoypadButton.new()
			event.button_index = binding
		event.device = dev
		InputMap.action_add_event(action, event)


func _setup_inputs() -> void:
	if device == -2:

		prefix = "kb_"
		var keys := {
			"move_left": [KEY_A, KEY_LEFT],
			"move_right": [KEY_D, KEY_RIGHT],
			"move_up": [KEY_W, KEY_UP],
			"move_down": [KEY_S, KEY_DOWN],
			"jump": [KEY_SPACE],
			"attack": [KEY_J, KEY_X],
			"dash": [KEY_K, KEY_C, KEY_SHIFT],
			"special": [KEY_L],
			"power": [KEY_I],
		}
		for action in keys:
			if not InputMap.has_action(prefix + action):
				InputMap.add_action(prefix + action)
				for key in keys[action]:
					var event := InputEventKey.new()
					event.physical_keycode = key
					InputMap.action_add_event(prefix + action, event)
		return
	if device >= 0:

		prefix = "p%d_" % device
		for action in PAD:
			if not InputMap.has_action(prefix + action):
				InputMap.add_action(prefix + action, 0.4)
				_add_pad_events(action, prefix + action, device)
		return
	var keys := {
		"attack": [KEY_J, KEY_X],
		"dash": [KEY_K, KEY_C, KEY_SHIFT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"special": [KEY_L],
		"power": [KEY_I],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in keys[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action, event)

	if not InputMap.has_meta("pads_added"):
		InputMap.set_meta("pads_added", true)
		for action in PAD:
			if InputMap.has_action(action):
				_add_pad_events(action, action, -1)


func _apply_character() -> void:
	var fighter: Dictionary = Characters.by_id(char_id) if char_id != "" else Characters.get_selected()
	pmax = fighter.get("masks", 5)
	pmasks = pmax
	if fighter.is_empty():
		base_scale = animated_sprite.scale
		return
	custom_char = true
	speed_mult = fighter.speed
	reach = fighter.reach
	power = fighter.get("power", 1)
	animated_sprite.sprite_frames = Characters.build_frames(fighter)
	animated_sprite.position = Vector2.ZERO
	animated_sprite.scale = Vector2.ONE * Characters.SPRITE_SCALE
	base_scale = animated_sprite.scale
	animated_sprite.play("idle")
	Characters.fit_sprite(animated_sprite)
	Look.outline(animated_sprite, 0.8)


func _make_sfx(path: String) -> AudioStreamPlayer:
	var sound := AudioStreamPlayer.new()
	sound.stream = load(path)
	add_child(sound)
	return sound


func _physics_process(delta):
	invuln = maxf(invuln - delta, 0.0)
	attack_cd = maxf(attack_cd - delta, 0.0)
	dash_cd = maxf(dash_cd - delta, 0.0)
	slash_t = maxf(slash_t - delta, 0.0)
	attack_anim_t = maxf(attack_anim_t - delta, 0.0)
	special_cd = maxf(special_cd - delta, 0.0)
	stun = maxf(stun - delta, 0.0)
	animated_sprite.modulate.a = 0.45 if (invuln > 0.0 and int(invuln * 20) % 2 == 0) else 1.0
	queue_redraw()
	if not controllable:
		return


	if dash_t > 0.0:
		dash_t -= delta
		velocity = Vector2(facing * DASH_SPEED * (1.15 if charging else 1.0), 0)
		move_and_slide()
		if charging:
			_charge_hits()
			if dash_t <= 0.0:
				charging = false
		return


	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		can_air_dash = true
		_track_safe_ground(delta)

	if stun > 0.0:
		move_and_slide()
		return


	if Input.is_action_just_pressed(_act("jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sfx_jump.pitch_scale = 1.0
		sfx_jump.play()

	if Input.is_action_just_released(_act("jump")) and velocity.y < -120.0:
		velocity.y = -120.0


	var direction = Input.get_axis(_act("move_left"), _act("move_right"))


	if direction > 0:
		animated_sprite.flip_h = false
		facing = 1
	elif direction < 0:
		animated_sprite.flip_h = true
		facing = -1

	if Input.is_action_just_pressed(_act("dash")) and dash_cd <= 0.0 and (is_on_floor() or can_air_dash):
		dash_t = DASH_TIME
		dash_cd = DASH_COOLDOWN
		if not is_on_floor():
			can_air_dash = false
		sfx_jump.pitch_scale = 1.6
		sfx_jump.play()
		return

	if Input.is_action_just_pressed(_act("attack")) and attack_cd <= 0.0:
		_attack()
	if Input.is_action_just_pressed(_act("special")):
		_special()
	if Input.is_action_just_pressed(_act("power")):
		_power_shot()


	if custom_char and attack_anim_t > 0.0:
		animated_sprite.play("attack")
	elif is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	if custom_char:
		Characters.fit_sprite(animated_sprite)


	if direction:
		velocity.x = direction * SPEED * speed_mult
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * speed_mult)

	move_and_slide()
	_check_bounce()


func _track_safe_ground(delta: float) -> void:
	safe_t -= delta
	if safe_t > 0.0:
		return
	safe_t = 0.2
	for i in get_slide_collision_count():
		var other = get_slide_collision(i).get_collider()
		if other and other.is_in_group("bounce_pad"):
			return
	last_safe = global_position


func _attack() -> void:
	attack_cd = ATTACK_COOLDOWN
	var dir := Vector2(facing, 0)
	if not is_on_floor() and Input.is_action_pressed(_act("move_down")):
		dir = Vector2.DOWN
	elif Input.is_action_pressed(_act("move_up")):
		dir = Vector2.UP
	slash_dir = dir
	slash_t = 0.12
	attack_anim_t = 0.25
	sfx_slash.play()

	var rect := RectangleShape2D.new()
	var offset := Vector2.ZERO
	if dir == Vector2.DOWN:
		rect.size = Vector2(18, 24)
		offset = Vector2(0, 10)
	elif dir == Vector2.UP:
		rect.size = Vector2(16, 18)
		offset = Vector2(0, -26)
	else:
		rect.size = Vector2(22 * reach, 14)
		offset = Vector2(facing * (4 + 11 * reach), -8)

	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = rect
	q.transform = Transform2D(0.0, global_position + offset)
	q.collide_with_areas = true
	q.collide_with_bodies = true
	q.exclude = [get_rid()]
	var hits := get_world_2d().direct_space_state.intersect_shape(q, 16)

	var gm = get_tree().get_first_node_in_group("game_manager")
	var hit_something := false
	var done := {}
	for h in hits:
		var col = h.collider
		if col == null or done.has(col):
			continue
		done[col] = true
		if col.is_in_group("bounce_pad"):
			hit_something = true
			if gm:
				gm.reclaim_geo(col)
			col.squish()
		elif col.get_script() and col.get_script().resource_path.ends_with("killzone.gd"):
			hit_something = true
			var enemy = col.get_parent()
			if enemy != get_tree().current_scene and gm:
				gm.hit_enemy(enemy, self)

	var center := global_position + offset
	for s in get_tree().get_nodes_in_group("enemy_shot"):
		if (
			not s.reflected
			and absf(s.global_position.x - center.x) < rect.size.x / 2 + 8
			and absf(s.global_position.y - center.y) < rect.size.y / 2 + 8
		):
			s.reflect(self)
			hit_something = true
	if hit_something:
		if dir == Vector2.DOWN:
			velocity.y = POGO_VELOCITY
			can_air_dash = true
			invuln = maxf(invuln, 0.15)
			sfx_bounce.pitch_scale = 1.3
			sfx_bounce.play()
			_squash()
		elif dir.x != 0:
			velocity.x = -facing * (60.0 if power > 1 else 120.0)


func _power_shot() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm == null:
		return
	if gm.soul < SOUL_COST:
		gm._toast("NEED SOUL: hit enemies first")
		return
	gm.soul -= SOUL_COST
	gm._update_hud()
	_fire(Vector2(facing, 0), 3, 380.0, true, true, 8.0, Color(0.55, 0.85, 1.0))
	velocity.x -= facing * 90.0
	sfx_bounce.pitch_scale = 0.7
	sfx_bounce.play()
	attack_anim_t = 0.3


func _fire(dir: Vector2, dmg: int, spd: float, pierce: bool, armor: bool, r: float, col: Color) -> void:
	var shot = Projectile.new()
	shot.velocity = dir * spd
	shot.power = dmg
	shot.pierce = pierce
	shot.armor_break = armor
	shot.radius = r
	shot.color = col
	shot.owner_player = self
	shot.global_position = global_position + Vector2(facing * 12, -10)
	get_tree().current_scene.add_child(shot)


func _special() -> void:
	if special_cd > 0.0:
		return
	var c: Dictionary = Characters.by_id(char_id) if char_id != "" else Characters.get_selected()
	var gm = get_tree().get_first_node_in_group("game_manager")
	match c.get("id", ""):
		"spark":
			special_cd = 2.5
			attack_anim_t = 0.45
			for i in 3:
				_fire(Vector2(facing, randf_range(-0.08, 0.08)).normalized(), 1, 420.0, false, false, 4.0, Color(1.0, 0.7, 0.2))
				sfx_slash.pitch_scale = 1.6
				sfx_slash.play()
				await get_tree().create_timer(0.09).timeout
		"zoom":
			special_cd = 3.0
			charging = true
			charge_hits.clear()
			dash_t = 0.3
			invuln = maxf(invuln, 0.35)
			attack_anim_t = 0.35
			if gm:
				gm._toast("SHOULDER CHARGE!")
		"brains":
			if pmasks >= pmax:
				if gm:
					gm._toast("Already at full masks")
				return
			special_cd = 10.0
			pmasks += 1
			if gm:
				gm._toast("BIG BRAIN HEAL +1")
				gm._update_hud()
			sfx_bounce.pitch_scale = 1.5
			sfx_bounce.play()
		_:
			if gm:
				gm._toast("This fighter has no special")


func _charge_hits() -> void:
	var q := PhysicsShapeQueryParameters2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 18)
	q.shape = rect
	q.transform = Transform2D(0.0, global_position + Vector2(facing * 10, -9))
	q.collide_with_areas = true
	q.exclude = [get_rid()]
	var gm = get_tree().get_first_node_in_group("game_manager")
	for h in get_world_2d().direct_space_state.intersect_shape(q, 8):
		var col = h.collider
		if col and col.get_script() and col.get_script().resource_path.ends_with("killzone.gd"):
			var enemy = col.get_parent()
			if enemy != get_tree().current_scene and not charge_hits.has(enemy) and gm:
				charge_hits[enemy] = true
				gm.hit_enemy(enemy, self)


func _check_bounce() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var other = c.get_collider()
		if other and other.is_in_group("bounce_pad") and c.get_normal().y < -0.5:
			velocity.y = BOUNCE_VELOCITY
			if Input.is_action_pressed(_act("jump")):
				velocity.y *= BOUNCE_BOOST
			can_air_dash = true
			other.squish()
			sfx_bounce.pitch_scale = randf_range(0.95, 1.15)
			sfx_bounce.play()
			_squash()
			return


func _squash() -> void:
	var tw := create_tween()
	animated_sprite.scale = base_scale * Vector2(0.7, 1.35)
	tw.tween_property(animated_sprite, "scale", base_scale, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	if slash_t <= 0.0:
		return
	var a := slash_t / 0.12
	var col := Color(1, 1, 1, a)
	if slash_dir == Vector2.DOWN:
		draw_arc(Vector2(0, 2), 14.0, deg_to_rad(20), deg_to_rad(160), 12, col, 3.0)
	elif slash_dir == Vector2.UP:
		draw_arc(Vector2(0, -16), 14.0, deg_to_rad(200), deg_to_rad(340), 12, col, 3.0)
	else:
		var c := Vector2(facing * (6 + 8 * (reach - 1.0)), -8)
		var start := -60.0 if facing > 0 else 120.0
		draw_arc(c, 14.0, deg_to_rad(start), deg_to_rad(start + 120.0), 12, col, 3.0)


func take_hit(from_pos: Vector2) -> void:
	invuln = 1.0
	stun = 0.2
	var side := 1.0 if global_position.x >= from_pos.x else -1.0
	velocity = Vector2(KNOCKBACK.x * side, KNOCKBACK.y)
	animated_sprite.modulate = Color(1, 0.5, 0.5)
	if custom_char:
		animated_sprite.play("hurt")
		Characters.fit_sprite(animated_sprite)
	create_tween().tween_property(animated_sprite, "modulate", Color.WHITE, 0.3)
	sfx_hurt.play()


func die() -> void:
	is_dead = true
	controllable = false
	velocity = Vector2.ZERO
	collision.set_deferred("disabled", true)
	animated_sprite.modulate = Color(1, 0.4, 0.4)
	animated_sprite.pause()
	sfx_hurt.play()


func respawn(pos: Vector2) -> void:
	is_dead = false
	global_position = pos
	velocity = Vector2.ZERO
	dash_t = 0.0
	stun = 0.0
	collision.set_deferred("disabled", false)
	animated_sprite.modulate = Color.WHITE
	controllable = true
	invuln = 0.8
