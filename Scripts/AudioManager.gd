extends Node

const AUDIO_DIR := "res://Assets/Audio/"

const SOUNDS := {
	"slash": "knifeSlice.ogg",
	"heavy": "chop.ogg",
	"hit": "impactPunch_medium_000.ogg",
	"enemy_hurt": "impactSoft_medium_000.ogg",
	"enemy_death": "impactPunch_heavy_000.ogg",
	"dash": "cloth1.ogg",
	"room_clear": "impactPunch_heavy_000.ogg",
}

const POOL_SIZE := 5
var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0

func _ready() -> void:
	for i in POOL_SIZE:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_players.append(voice)

func play(name: String, volume_db: float = -12.0, pitch: float = 1.0) -> void:
	var file: String = SOUNDS.get(name, "")
	if file == "":
		return                          # unknown sound: ignore, never crash
	var stream: AudioStream = load(AUDIO_DIR + file)
	if stream == null:
		return
	var voice: AudioStreamPlayer = null
	for candidate in _players:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null:
		voice = _players[_next_voice]
		_next_voice = (_next_voice + 1) % POOL_SIZE
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = pitch
	voice.play()
