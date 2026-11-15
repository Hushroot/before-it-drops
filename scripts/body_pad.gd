# ORIGIN: NEW, written by team. Not from the tutorial.
# BODY PAD: what's left when you die (like Hollow Knight's Shade).
# It's solid, it BOUNCES you up, and it holds the GEO you dropped.
# Hit it with your nail (or pogo on it) to take your geo back.
# Created by game_manager.gd. You don't place these by hand.
extends StaticBody2D

const Look = preload("res://scripts/look.gd")   # shared outline style

var frames: SpriteFrames      # the player's sprites (set before adding to the scene)
var flip := false
var sprite_scale := Vector2.ONE
var lying_anim := false       # true = the fighter has its own knockdown frame (no rotation needed)
var geo := 0                  # geo you lost when you died here
var sprite: AnimatedSprite2D
var t := 0.0


func _ready() -> void:
	add_to_group("bounce_pad")
	collision_layer = 1           # same layer as the ground, so the player stands/bounces on it
	collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 6)
	shape.shape = rect
	shape.position = Vector2(0, -3)
	add_child(shape)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.flip_h = flip
	sprite.scale = sprite_scale
	sprite.modulate = Color(0.75, 0.9, 1.0, 0.85)       # ghosty blue
	if lying_anim:
		sprite.animation = "knockdown"
		sprite.frame = 0
		sprite.centered = false
		var tex := frames.get_frame_texture("knockdown", 0)
		sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	elif frames.has_animation("knockdown"):
		sprite.animation = "knockdown"                   # fighter without a lying frame: rotate it
		sprite.rotation_degrees = -90.0 if flip else 90.0
		sprite.position = Vector2(0, -6)
	else:
		sprite.animation = "idle"
		sprite.frame = 0
		sprite.rotation_degrees = -90.0 if flip else 90.0   # lying down
		sprite.position = Vector2(0, -6)
	add_child(sprite)
	Look.outline(sprite, 0.8)

	# pop in
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	t += delta
	if geo > 0:
		queue_redraw()


func _draw() -> void:
	if geo > 0:   # glowing geo above the body until you reclaim it
		var y := -16.0 + sin(t * 4.0) * 2.0
		draw_circle(Vector2(0, y), 4.0, Color(1, 0.85, 0.2, 0.9))
		draw_circle(Vector2(0, y), 7.0, Color(1, 0.85, 0.2, 0.25))


func set_reclaimed() -> void:
	queue_redraw()


# Called by the player when they bounce on (or hit) this body
func squish() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "scale", sprite_scale * Vector2(1.3, 0.6), 0.06)
	tw.tween_property(sprite, "scale", sprite_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Ending: the body gets back up
func stand_up() -> void:
	var tw := create_tween()
	if sprite_scale != Vector2.ONE and sprite.sprite_frames.has_animation("idle"):
		# chosen fighter: switch to the standing idle animation
		sprite.rotation_degrees = 0.0
		sprite.position = Vector2.ZERO
		sprite.play("idle")
		var tex := sprite.sprite_frames.get_frame_texture("idle", 0)
		sprite.centered = false
		sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
		sprite.scale = sprite_scale * Vector2(1.2, 0.8)
		tw.tween_property(sprite, "scale", sprite_scale, 0.35).set_trans(Tween.TRANS_BACK)
	else:
		tw.tween_property(sprite, "rotation_degrees", 0.0, 0.35).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(sprite, "position:y", -12.0, 0.35)
	tw.parallel().tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.35)
