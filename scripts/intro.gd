extends Control

const Levels = preload("res://scripts/levels.gd")
const FIRST_LEVEL := "res://scenes/story_level.tscn"
const SELECT_SCREEN := "res://scenes/character_select.tscn"
const SECONDS_PER_CHARACTER := 0.035

@onready var content: VBoxContainer = $Margin/Content
@onready var story: Label = $Margin/Content/Story
@onready var progress: Label = $Margin/Content/Progress
@onready var prompt: Label = $Margin/Content/Prompt

var line_index := 0
var leaving := false
var reveal: Tween


func _ready() -> void:
	resized.connect(_fit_text)
	_fit_text()
	_show_line()


func _fit_text() -> void:
	var font_size := 32 if size.x >= 1000 else (24 if size.x >= 700 else 16)
	story.add_theme_font_size_override("font_size", font_size)


func _show_line() -> void:
	story.text = Levels.STORY[line_index]
	story.visible_characters = 0
	progress.text = "%02d / %02d" % [line_index + 1, Levels.STORY.size()]
	prompt.text = "Press any key / CROSS to reveal"
	reveal = create_tween()
	reveal.tween_property(story, "visible_characters", story.get_total_character_count(),
		story.text.length() * SECONDS_PER_CHARACTER)
	reveal.finished.connect(_line_revealed)


func _line_revealed() -> void:
	story.visible_characters = -1
	prompt.text = "Press any key / CROSS to start" if line_index == Levels.STORY.size() - 1 \
		else "Press any key / CROSS to continue"


func _advance() -> void:
	if reveal.is_running():
		reveal.kill()
		_line_revealed()
	elif line_index < Levels.STORY.size() - 1:
		line_index += 1
		_show_line()
	else:
		_leave(FIRST_LEVEL)


func _leave(scene: String) -> void:
	leaving = true
	if reveal.is_running():
		reveal.kill()
	var fade := create_tween()
	fade.tween_property(content, "modulate:a", 0.0, 0.25)
	fade.tween_callback(func():
		if scene == FIRST_LEVEL:
			Engine.set_meta("level_index", 1)
			Engine.set_meta("raid", [])
		get_tree().change_scene_to_file(scene)
	)


func _unhandled_input(event: InputEvent) -> void:
	if leaving:
		return
	var advance := false
	var back := false
	if event is InputEventKey and event.pressed and not event.echo:
		back = event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE
		advance = not back
	elif event is InputEventJoypadButton and event.pressed:
		advance = event.button_index == JOY_BUTTON_A
		back = event.button_index == JOY_BUTTON_B
	elif event is InputEventMouseButton and event.pressed:
		advance = event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		advance = event.pressed
	if back or advance:
		get_viewport().set_input_as_handled()
		if back:
			_leave(SELECT_SCREEN)
		else:
			_advance()
