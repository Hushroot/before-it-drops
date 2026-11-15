extends RefCounted

const SPRITE_SCALE := 0.62

const LIST := [
	{
		"id": "spark", "name": "SPARK", "tagline": "The finger gun is loaded.",
		"perk": "LONG REACH: nail hits 40% further",
		"special": "FINGER GUN: 3 sparks",
		"speed": 1.0, "masks": 5, "reach": 1.4, "power": 1,
		"anims": {"idle": ["idle", 6], "run": ["idle", 12], "jump": ["block", 1], "attack": ["punch", 14],
			"hurt": ["hurt", 1], "taunt": ["taunt", 6], "knockdown": ["hurt", 1]},
		"knockdown_rotate": true,
	},
	{
		"id": "zoom", "name": "ZOOM", "tagline": "Hits like a truck.",
		"perk": "BRUTE FORCE: double damage, smashes enemies back, breaks boss armor",
		"special": "SHOULDER CHARGE: unstoppable dash",
		"speed": 1.0, "masks": 5, "reach": 1.0, "power": 2,
		"anims": {"idle": ["idle", 6], "run": ["run", 12], "jump": ["run", 1], "attack": ["punch", 16],
			"hurt": ["block", 1], "taunt": ["taunt", 6], "knockdown": ["knockdown", 1]},
		"knockdown_rotate": false,
	},
	{
		"id": "brains", "name": "BRAINS", "tagline": "Calculated every bounce.",
		"perk": "TANK: 6 masks instead of 5",
		"special": "BIG BRAIN HEAL: +1 mask",
		"speed": 1.0, "masks": 6, "reach": 1.0, "power": 1,
		"anims": {"idle": ["idle", 6], "run": ["run", 12], "jump": ["run", 1], "attack": ["punch", 16],
			"hurt": ["block", 1], "taunt": ["taunt", 6], "knockdown": ["knockdown", 1]},
		"knockdown_rotate": false,
	},
]


static func by_id(id: String) -> Dictionary:
	for fighter in LIST:
		if fighter.id == id:
			return fighter
	return {}


static func get_selected() -> Dictionary:
	var id: String = Engine.get_meta("character", "")
	for fighter in LIST:
		if fighter.id == id:
			return fighter
	return {}


static func frame_count(id: String, sheet_anim: String) -> int:
	var count := 0
	while ResourceLoader.exists("res://assets/characters/%s/%s_%d.png" % [id, sheet_anim, count]):
		count += 1
	return count


static func build_frames(c: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim in c.anims:
		var sheet: String = c.anims[anim][0]
		var fps: float = c.anims[anim][1]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, fps)
		var count := frame_count(c.id, sheet)
		var only_one: bool = anim in ["jump", "hurt", "knockdown"]
		frames.set_animation_loop(anim, not only_one)
		var used_frames := count
		if only_one:
			used_frames = 1
		for i in used_frames:
			var frame := i

			if anim == "knockdown" and not c.knockdown_rotate:
				frame = count - 1
			frames.add_frame(anim, load("res://assets/characters/%s/%s_%d.png" % [c.id, sheet, frame]))
	return frames


static func fit_sprite(sprite: AnimatedSprite2D) -> void:
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
