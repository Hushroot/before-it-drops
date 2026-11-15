# ORIGIN: NEW, written for the title screen.
extends Control

@onready var title: Label = $SafeArea/Center/Content/Heading/Title
@onready var play_button: Button = $SafeArea/Center/Content/Buttons/Play
@onready var quit_button: Button = $SafeArea/Center/Content/Buttons/Quit
@onready var subtitle: Label = $SafeArea/Center/Content/Heading/Subtitle

var _starting: bool = false


func _ready() -> void:
	play_button.grab_focus()
	resized.connect(_fit_title)
	_fit_title()
	var content: Control = $SafeArea/Center/Content
	content.modulate.a = 0.0
	create_tween().tween_property(content, "modulate:a", 1.0, 0.6)
	if not Music.playing:
		Music.play()
	if OS.has_feature("web"):
		quit_button.disabled = true
		quit_button.tooltip_text = "Close this tab to quit."


func _fit_title() -> void:
	var font_size := clampi(int((size.x - 48.0) / 12.0) / 8 * 8, 24, 64)
	if size.y < 480.0:
		font_size = mini(font_size, 32)
	title.add_theme_font_size_override("font_size", font_size)


func _on_play_pressed() -> void:
	if _starting:
		return
	_starting = true
	play_button.disabled = true
	quit_button.disabled = true
	var level_path := "res://scenes/character_select.tscn"   # title -> CHOOSE YOUR FIGHTER
	Stats.reset()
	var error := get_tree().change_scene_to_file(level_path)
	if error != OK:
		_starting = false
		play_button.disabled = false
		quit_button.disabled = OS.has_feature("web")
		subtitle.text = "Couldn't start the game. Please try again."
		play_button.grab_focus()
		push_error("Unable to open %s (error %d)." % [level_path, error])


func _on_quit_pressed() -> void:
	if _starting or OS.has_feature("web"):
		return
	_starting = true
	play_button.disabled = true
	quit_button.disabled = true
	Music.stop()
	# Give Godot 4.3's audio thread time to release playback before shutdown.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
