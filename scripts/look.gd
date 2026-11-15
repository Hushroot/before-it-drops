# ORIGIN: NEW, written by team.
# LOOK: one art style for everything. Look.outline(sprite) after the sprite is in the tree.
extends RefCounted

const OUTLINE = preload("res://assets/shaders/outline.gdshader")
const GRADE = preload("res://assets/shaders/vice_grade.gdshader")


static func outline(spr: CanvasItem, screen_px := 1.0) -> void:
	if spr == null or not spr.is_inside_tree():
		return
	var m := ShaderMaterial.new()
	m.shader = OUTLINE
	var s: float = absf((spr as Node2D).global_scale.x) if spr is Node2D else 1.0
	m.set_shader_parameter("width", clampf(screen_px / maxf(s, 0.001), 0.5, 40.0))
	spr.material = m


# Full-screen color grade, sits above the world and below the HUD
static func add_grade(parent: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = GRADE
	r.material = m
	layer.add_child(r)
	parent.add_child(layer)
