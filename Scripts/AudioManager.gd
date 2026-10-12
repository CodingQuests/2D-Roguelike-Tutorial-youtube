extends Node

const AUDIO_DIR := "res://Assets/Audio/"

const SOUNDS := {
	"slash": "knifeSlice.ogg",
	"heavy": "chop.ogg",
	"hit": "impactPunch_medium_000.ogg",
	"enemy_hurt": "impactSoft_medium_000.ogg",
	"enemy_death": "impactPunch_heavy_000.ogg",
	"dash": "cloth1.ogg",
}

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	
func play(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var file: String = SOUNDS.get(name, "")
	if file == "":
		return                          # unknown sound: ignore, never crash
	var stream: AudioStream = load(AUDIO_DIR + file)
	if stream == null:
		return
	_player.stream = stream
	_player.volume_db = volume_db
	_player.pitch_scale = pitch
	_player.play()
