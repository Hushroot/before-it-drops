extends Node2D

const Look = preload("res://scripts/look.gd")
const Navigation = preload("res://scripts/enemy_navigation.gd")

const KILLZONE_SCENE = preload("res://scenes/killzone.tscn")
const STATS := {
	"lolli": {"hp": 2, "speed": 28.0, "height": 22.0, "hop": false},
	"smug": {"hp": 3, "speed": 46.0, "height": 24.0, "hop": false},
	"flame": {"hp": 5, "speed": 34.0, "height": 30.0, "hop": true},
}

var kind := "lolli"
var dir := 1.0
var vel_y := 0.0
var hop_t := 1.5
var sprite: Sprite2D
var t := 0.0
var _warmup := 2


func _ready() -> void:
	add_to_group("enemy_target")
	var s: Dictionary = STATS[kind]
	set_meta("hp", s.hp)
	var tex: Texture2D = load("res://assets/hamsters/%s.png" % kind)
	sprite = Sprite2D.new()
	sprite.texture = tex
	var sc: float = s.height / tex.get_height()
	sprite.scale = Vector2(sc, sc)
	sprite.offset = Vector2(0, -tex.get_height() / 2.0)
	add_child(sprite)
	Look.outline(sprite, 0.8)

	var kz = KILLZONE_SCENE.instantiate()
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(s.height * 0.6, s.height * 0.75)
	shape.shape = r
	shape.position = Vector2(0, -s.height * 0.4)
	kz.add_child(shape)
	add_child(kz)
	t = randf() * 10.0


func _physics_process(delta: float) -> void:
	if has_meta("dying"):
		return

	if _warmup > 0:
		_warmup -= 1
		return
	t += delta
	var s: Dictionary = STATS[kind]
	var ground := Navigation.surface(self, global_position)
	var grounded := vel_y >= 0.0 and not ground.is_empty()
	if grounded:
		global_position.y = ground.position.y
		vel_y = 0.0
	if s.hop:
		hop_t -= delta
	if s.hop and grounded:
		var p = _nearest_player()
		if p and hop_t <= 0.0:
			var toward := signf(p.global_position.x - global_position.x)
			if Navigation.safe_hop(self, toward, s.speed, -230.0, s.height):
				hop_t = randf_range(1.2, 2.0)
				dir = toward
				vel_y = -230.0
				grounded = false
			else:
				hop_t = 0.35
	if grounded:
		var step := Navigation.walk(self, dir, s.speed * delta, s.height)
		global_position = step.position
		dir = step.direction
	else:
		vel_y += Navigation.GRAVITY * delta
		var air_speed: float = s.speed * (1.6 if vel_y < 0.0 else 1.0)
		var step := Navigation.flight(self, global_position, Vector2(dir * air_speed, vel_y), delta, s.height)
		global_position = step.position
		vel_y = step.velocity.y
	sprite.flip_h = dir > 0

	var w := 1.0 + sin(t * 10.0) * 0.06
	var base: float = s.height / sprite.texture.get_height()
	sprite.scale = Vector2(base * w, base / w)


func take_knockback(distance: float) -> void:

	var step := Navigation.walk(self, signf(distance), absf(distance), STATS[kind].height, false)
	global_position = step.position


func _floor_below() -> bool:
	return not Navigation.surface(self, global_position).is_empty()


func _nearest_player():
	var best = null
	var bd := 220.0
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_dead:
			continue
		var d: float = p.global_position.distance_to(global_position)
		if d < bd:
			bd = d
			best = p
	return best
