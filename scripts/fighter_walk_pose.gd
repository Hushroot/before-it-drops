# ORIGIN: NEW, written by team. No generated textures or gameplay edits.
extends Node2D
## Animate the existing frame's legs around the hips while preserving the upper pose.
## The original sprite handles every non-walking state, including combat and death.
const STRIDE_DISTANCE := 52.0
var phase := 0.0
var walking := false
var sprite: AnimatedSprite2D
var player: CharacterBody2D
var _original_alpha := 1.0

func _ready() -> void:
	sprite = get_parent() as AnimatedSprite2D
	player = sprite.get_parent() as CharacterBody2D
	_original_alpha = sprite.self_modulate.a
	use_parent_material = true # retain the team's outline and hit/invulnerability tint
	hide()

func _process(delta: float) -> void:
	walking = player.controllable and not player.is_dead and player.is_on_floor() \
		and absf(player.velocity.x) > 5.0 and sprite.animation == &"run" \
		and player.dash_t <= 0.0 and player.attack_anim_t <= 0.0 and player.stun <= 0.0
	visible = walking
	sprite.self_modulate.a = 0.0 if walking else _original_alpha
	if walking:
		phase = fmod(phase + absf(player.velocity.x) * delta * TAU / STRIDE_DISTANCE, TAU)
		scale.x = -1.0 if sprite.flip_h else 1.0
		queue_redraw()
	else:
		phase = 0.0

func _draw() -> void:
	if not walking:
		return
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return
	var size := texture.get_size()
	var waist := floorf(size.y * 0.60)
	var half := floorf(size.x * 0.5)
	var offset := Vector2(-size.x * 0.5, -size.y)
	# Draw the legs first. The torso overlaps their top two pixels to hide seams.
	for leg in 2:
		var wave := sin(phase + PI * leg)
		var source := Rect2(half * leg, waist, half if leg == 0 else size.x - half, size.y - waist)
		var hip := Vector2(size.x * (0.38 if leg == 0 else 0.62), waist)
		var lift := Vector2(0, -maxf(0.0, wave) * 1.5)
		draw_set_transform(offset + hip + lift, wave * 0.32)
		draw_texture_rect_region(texture, Rect2(source.position - hip, source.size), source)
	var bob := -absf(sin(phase * 2.0)) * 1.0
	var pivot := Vector2(size.x * 0.5, waist)
	draw_set_transform(offset + pivot + Vector2(0, bob), 0.035)
	draw_texture_rect_region(texture, Rect2(-pivot, Vector2(size.x, waist + 2.0)),
		Rect2(Vector2.ZERO, Vector2(size.x, waist + 2.0)))
	draw_set_transform(Vector2.ZERO)
