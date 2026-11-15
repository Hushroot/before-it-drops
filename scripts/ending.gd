# ORIGIN: NEW, written by team.
# ENDING: after the boss dies, every body you left behind STANDS UP. "They all got back up."
extends Node

const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")


func play(gm, player) -> void:
	var vice = get_tree().get_first_node_in_group("vice_layer")
	if vice:
		vice.mission_passed()
	await get_tree().create_timer(2.5).timeout
	# all your old bodies stand up, one by one
	var bodies: Array = gm.bodies.filter(func(b): return is_instance_valid(b))
	var sfx := AudioStreamPlayer.new()
	sfx.stream = load("res://assets/sounds/power_up.wav")
	add_child(sfx)
	var i := 0
	for b in bodies:
		b.stand_up()
		sfx.pitch_scale = 0.8 + i * 0.08
		sfx.play()
		i += 1
		await get_tree().create_timer(0.25).timeout

	var total: int = gm.deaths + int(Engine.get_meta("total_deaths", 0))
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.6, 1.0)
	var lines := []
	if total > 0:
		lines = [
			("THE VICE QUEEN FALLS." if ResourceLoader.exists("res://assets/boss/final/body.png") else "THE GODFATHER FALLS."),
			"You got the LAST COPY of GTA VI.",
			"",
			"You fell %d times." % total,
			"They all got back up.",
			"",
			"Every fall got you higher.",
			"",
			"[R] play again",
		]
	else:
		lines = [
			("THE VICE QUEEN FALLS." if ResourceLoader.exists("res://assets/boss/final/body.png") else "THE GODFATHER FALLS."),
			"You got the LAST COPY of GTA VI.",
			"",
			"You never fell once.",
			"...show-off.",
			"",
			"[R] play again",
		]
	var center := CenterContainer.new()
	layer.add_child(center)
	center.position = Vector2.ZERO
	center.size = get_viewport().get_visible_rect().size
	var box := VBoxContainer.new()
	center.add_child(box)
	for line in lines:
		var l := Label.new()
		l.text = line
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", FONT)
		l.add_theme_font_size_override("font_size", 24)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 8)
		l.modulate.a = 0.0
		box.add_child(l)
		create_tween().tween_property(l, "modulate:a", 1.0, 0.6)
		await get_tree().create_timer(0.45).timeout


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		Engine.set_meta("total_deaths", 0)
		get_tree().reload_current_scene()
