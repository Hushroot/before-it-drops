extends Node

const DIR := "res://assets/sounds/kenney/"
const SOUNDS := {
	"hit": ["hit_0.ogg", "hit_1.ogg", "hit_2.ogg", "hit_3.ogg", "hit_4.ogg"],
	"smash": ["smash_0.ogg", "smash_1.ogg", "smash_2.ogg"],
	"enemy_down": ["enemy_down.ogg"],
	"parry": ["parry.ogg"],
	"throw": ["throw.wav"],
	"bounced": ["bounced.ogg"],
	"mission_passed": ["mission_passed.ogg"],
	"victory": ["victory.ogg"],
}
var streams := {}
var pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound_name in SOUNDS:
		var variants: Array = []
		for file in SOUNDS[sound_name]:
			var stream = load(DIR + file)
			if stream:
				variants.append(stream)
		streams[sound_name] = variants
	for i in 10:
		var sound := AudioStreamPlayer.new()
		add_child(sound)
		pool.append(sound)


func play(name: String, db := 0.0, wobble := 0.08) -> void:
	var variants: Array = streams.get(name, [])
	if variants.is_empty():
		return
	var sound: AudioStreamPlayer = null
	for player in pool:
		if not player.playing:
			sound = player
			break
	if sound == null:
		sound = pool[0]
	sound.stream = variants.pick_random()
	sound.volume_db = db
	sound.pitch_scale = 1.0 + randf_range(-wobble, wobble)
	sound.play()
