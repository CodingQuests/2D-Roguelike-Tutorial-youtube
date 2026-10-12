extends Node

const AUDIO_DIR := "res://Assets/Audio/"
const POOL_SIZE := 16

const SOUNDS := {
	"slash": ["knifeSlice.ogg", "knifeSlice2.ogg"],
	"heavy": ["chop.ogg"],
	"hit": ["impactPunch_medium_000.ogg", "impactPunch_medium_001.ogg",
			"impactPunch_medium_002.ogg", "impactPunch_medium_003.ogg"],
	"enemy_hurt": ["impactSoft_medium_000.ogg", "impactSoft_medium_001.ogg"],
	"enemy_death": ["impactPunch_heavy_000.ogg", "impactPunch_heavy_001.ogg"],
	"dash": ["cloth1.ogg", "cloth2.ogg", "cloth3.ogg", "cloth4.ogg"],
	"telegraph": ["metalClick.ogg"],
	"room_clear": ["impactBell_heavy_000.ogg"],
	"door_open": ["doorOpen_1.ogg", "doorOpen_2.ogg"],
	"door_close": ["doorClose_1.ogg", "doorClose_2.ogg"],
}
const VARIATION := {
	"slash": 0.1, "hit": 0.12, "enemy_hurt": 0.12, "heavy": 0.08,
	"enemy_death": 0.1, "dash": 0.08,
}
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)
	_preload_streams()
	
func play(name: String, volume_db: float = 0.0, pitch: float = -1.0) -> void:
	var variants: Array = _streams.get(name, [])
	if variants.is_empty():
		return                        # unknown sound: silently ignore
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = variants.pick_random()
	p.volume_db = volume_db
	if pitch > 0.0:
		p.pitch_scale = pitch
	else:
		var v: float = VARIATION.get(name, 0.04)
		p.pitch_scale = 1.0 + randf_range(-v, v)
	p.play()
	
func _preload_streams() -> void:
	for key in SOUNDS:
		var loaded: Array = []
		for file in SOUNDS[key]:
			if not ResourceLoader.exists(AUDIO_DIR + file):
				continue
			var s := load(AUDIO_DIR + file)
			if s != null:
				loaded.append(s)
		_streams[key] = loaded
