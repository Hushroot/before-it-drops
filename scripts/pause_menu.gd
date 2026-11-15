extends CanvasLayer

const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const GAME_SCENES := ["res://scenes/game.tscn", "res://scenes/story_level.tscn", "res://scenes/boss_arena.tscn"]
var overlay: Control
var resume_button: Button
var restart_button: Button
var fighter_button: Button
var controls_button: Button
var controls_card: VBoxContainer
var back_button: Button
var buttons: VBoxContainer
var _scene_id := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_setup_pad_navigation()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.hide()
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.01, 0.04, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	center.add_child(buttons)
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 16
	overlay.theme = theme
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color(1, 0.55, 0.8)
	buttons.add_child(title)
	resume_button = _button("RESUME", close_pause)
	restart_button = _button("RESTART LEVEL", _restart)
	fighter_button = _button("CHANGE FIGHTER", _change_fighter)
	controls_button = _button("CONTROLS", _show_controls)
	var focus_order := [resume_button, restart_button, fighter_button, controls_button]
	for i in focus_order.size():
		var button: Button = focus_order[i]
		var above: Button = focus_order[wrapi(i - 1, 0, focus_order.size())]
		var below: Button = focus_order[wrapi(i + 1, 0, focus_order.size())]
		button.focus_neighbor_top = button.get_path_to(above)
		button.focus_neighbor_bottom = button.get_path_to(below)
		button.focus_previous = button.get_path_to(above)
		button.focus_next = button.get_path_to(below)
	_build_controls(center)
	var hint := Label.new()
	hint.text = "ESC / OPTIONS: resume    CIRCLE: back"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	buttons.add_child(hint)

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(330, 46)
	button.pressed.connect(action)
	buttons.add_child(button)
	return button

func _can_pause() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path in GAME_SCENES

func _input(event: InputEvent) -> void:
	var toggle: bool = (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	var back: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B
	if overlay.visible and (toggle or back):
		var options: bool = event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START
		if controls_card.visible and not options:
			_hide_controls()
		else:
			close_pause()
		get_viewport().set_input_as_handled()
	elif toggle and _can_pause():
		open_pause()
		get_viewport().set_input_as_handled()

func open_pause() -> void:
	if not _can_pause() or get_tree().paused:
		return
	_scene_id = get_tree().current_scene.get_instance_id()
	get_tree().paused = true
	controls_card.hide()
	buttons.show()
	overlay.show()
	resume_button.grab_focus()

func close_pause() -> void:
	controls_card.hide()
	buttons.show()
	overlay.hide()
	get_tree().paused = false

func _process(_delta: float) -> void:

	if overlay.visible:
		var scene := get_tree().current_scene
		if scene == null or scene.get_instance_id() != _scene_id:
			close_pause()

func _restart() -> void:
	close_pause()
	Engine.time_scale = 1.0
	var error := get_tree().reload_current_scene()
	if error != OK:
		push_error("Could not restart level: %d" % error)

func _change_fighter() -> void:
	close_pause()
	Engine.time_scale = 1.0
	var error := get_tree().change_scene_to_file("res://scenes/character_select.tscn")
	if error != OK:
		push_error("Could not change fighter: %d" % error)

func _build_controls(center: CenterContainer) -> void:
	controls_card = VBoxContainer.new()
	controls_card.add_theme_constant_override("separation", 12)
	center.add_child(controls_card)
	var title := Label.new()
	title.text = "CONTROLS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	controls_card.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 10)
	controls_card.add_child(grid)
	var rows := [
		["ACTION", "KEYBOARD", "PS4"],
		["Move / aim", "WASD / arrows", "Stick / d-pad"],
		["Jump (hold for height)", "SPACE", "CROSS"],
		["Strike / up-slash", "J or X / hold UP", "SQUARE / hold UP"],
		["Pogo (in air)", "Hold DOWN + J / X", "DOWN + SQUARE"],
		["Dash", "K / C / SHIFT", "CIRCLE / R1"],
		["Special", "L", "TRIANGLE"],
		["Power shot (33 SOUL)", "I", "R2 / L1"],
		["Pause / resume", "ESC", "OPTIONS"],
		["Confirm / back", "ENTER / ESC", "CROSS / CIRCLE"],
	]
	for row in rows:
		for text in row:
			var label := Label.new()
			label.text = text
			label.add_theme_font_size_override("font_size", 12)
			grid.add_child(label)
	var tips := Label.new()
	tips.text = "SPARK: finger gun   ZOOM: charge   BRAINS: heal\nHit enemies to fill SOUL. Pogo refreshes your air dash."
	tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips.add_theme_font_size_override("font_size", 8)
	controls_card.add_child(tips)
	back_button = Button.new()
	back_button.text = "BACK"
	back_button.custom_minimum_size.y = 42
	back_button.pressed.connect(_hide_controls)
	controls_card.add_child(back_button)
	controls_card.hide()

func _show_controls() -> void:
	buttons.hide()
	controls_card.show()
	back_button.grab_focus()

func _hide_controls() -> void:
	controls_card.hide()
	buttons.show()
	controls_button.grab_focus()

func _setup_pad_navigation() -> void:

	var bindings := {"ui_accept": JOY_BUTTON_A, "ui_up": JOY_BUTTON_DPAD_UP,
		"ui_down": JOY_BUTTON_DPAD_DOWN, "ui_left": JOY_BUTTON_DPAD_LEFT,
		"ui_right": JOY_BUTTON_DPAD_RIGHT}
	for action in bindings:
		var button := InputEventJoypadButton.new()
		button.device = -1
		button.button_index = bindings[action]
		if not InputMap.action_has_event(action, button):
			InputMap.action_add_event(action, button)
	var axes := {"ui_up": [JOY_AXIS_LEFT_Y, -1.0], "ui_down": [JOY_AXIS_LEFT_Y, 1.0],
		"ui_left": [JOY_AXIS_LEFT_X, -1.0], "ui_right": [JOY_AXIS_LEFT_X, 1.0]}
	for action in axes:
		var motion := InputEventJoypadMotion.new()
		motion.device = -1
		motion.axis = axes[action][0]
		motion.axis_value = axes[action][1]
		if not InputMap.action_has_event(action, motion):
			InputMap.action_add_event(action, motion)
