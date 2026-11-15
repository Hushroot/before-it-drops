# ORIGIN: NEW, written by team.
extends CanvasLayer
## Observes every player after movement without modifying gameplay or damage rules.
const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
var flash: ColorRect
var effects: Node2D
var _scene: Node
var _previous := {}
var _flash_tween: Tween

func _ready() -> void:
	layer = 80
	# Later physics callbacks see the launch velocity assigned by player.gd.
	process_physics_priority = 100
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

func _physics_process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(_scene) or _scene != scene:
		_scene = scene
		_previous.clear()
		if is_instance_valid(effects):
			effects.queue_free()
		effects = null
		if scene != null:
			effects = Node2D.new()
			effects.name = "BounceEffects"
			scene.add_child(effects)
	var seen := {}
	for player in get_tree().get_nodes_in_group("player"):
		if player.is_queued_for_deletion():
			continue
		var id := player.get_instance_id()
		seen[id] = true
		var masks: int = player.pmasks
		var vy: float = player.velocity.y
		if _previous.has(id):
			var last: Dictionary = _previous[id]
			if masks < last.masks:
				_damage_flash()
			if not player.is_dead and is_instance_valid(effects):
				if vy <= -400.0 and last.vy > -400.0:
					_body_bounce(player.global_position)
				elif vy <= -295.0 and vy >= -305.0 and last.vy > -295.0 and player.slash_dir == Vector2.DOWN and player.slash_t > 0.0:
					_particles(player.global_position + Vector2(0, 6), 5, Color.WHITE, 0.18)
		_previous[id] = {"masks": masks, "vy": vy}
	for id in _previous.keys():
		if not seen.has(id):
			_previous.erase(id)

func _damage_flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	flash.color.a = 0.3
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.05)
	_flash_tween.tween_property(flash, "color:a", 0.0, 0.0)

func _body_bounce(pos: Vector2) -> void:
	var label := Label.new()
	label.text = "BOING!"
	label.position = pos + Vector2(-20, -35)
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	effects.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 20, 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(label.queue_free)
	_particles(pos + Vector2(0, 6), 12, Color(0.85, 0.8, 0.7), 0.35)

func _particles(pos: Vector2, amount: int, color: Color, lifetime: float) -> void:
	var puff := CPUParticles2D.new()
	puff.position = pos
	puff.amount = amount
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.lifetime = lifetime
	puff.direction = Vector2.UP
	puff.spread = 75.0
	puff.gravity = Vector2(0, 85)
	puff.initial_velocity_min = 18.0
	puff.initial_velocity_max = 45.0
	puff.scale_amount_min = 1.0
	puff.scale_amount_max = 2.0
	puff.color = color
	effects.add_child(puff)
	puff.emitting = true
	# Timer also frees particles on headless renderers where finished can be delayed.
	var timer := get_tree().create_timer(lifetime + 0.15, false)
	timer.timeout.connect(func():
		if is_instance_valid(puff):
			puff.queue_free()
	)
