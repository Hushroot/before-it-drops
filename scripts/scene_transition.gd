# ORIGIN: NEW, written by team.
extends CanvasLayer
## Fade through black when scenes change. Watching the current scene here keeps
## the fade working when another script changes scenes directly.
var cover: ColorRect
var _observed: Node
var _tween: Tween
var _leaving := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	cover = ColorRect.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.color = Color(0, 0, 0, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or (is_instance_valid(_observed) and scene == _observed):
		return
	_observed = scene
	scene.tree_exiting.connect(_on_scene_leaving, CONNECT_ONE_SHOT)
	if _leaving:
		_leaving = false
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(cover, "color:a", 1.0, 0.08)
		_tween.tween_property(cover, "color:a", 0.0, 0.18)

func _on_scene_leaving() -> void:
	if not is_inside_tree() or get_tree().root.is_queued_for_deletion():
		return
	_leaving = true
	if _tween:
		_tween.kill()
	# Immediately hide resource loading; the next process frame completes the dip.
	cover.color.a = 0.75
