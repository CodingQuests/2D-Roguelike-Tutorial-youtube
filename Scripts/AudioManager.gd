extends Node

const AUDIO_DIR := "res://Assets/Audio/"
const POOL_SIZE := 16

const MUSIC := {
	"calm": "music_calm.wav",
	"combat": "music_combat.wav",
}
const MUSIC_DB := 0.0

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
	"pickup": ["handleCoins.ogg", "handleCoins2.ogg"],
	"upgrade": ["metalLatch.ogg"],
	"click": ["click1.ogg", "click2.ogg", "click3.ogg"],
}
const VARIATION := {
	"slash": 0.1, "hit": 0.12, "enemy_hurt": 0.12, "heavy": 0.08,
	"enemy_death": 0.1, "dash": 0.08,
}
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
const BUS_BASE_DB := {"master": 0.0, "sfx": -4.0, "music": -12.0}
var _music_streams: Dictionary = {}
var _music_player: AudioStreamPlayer
var _current_music: String = ""

var _duck_token: int = 0
var _music_tween: Tween
var _duck_tween: Tween
var _music_gain := -60.0:
	set(value):
		_music_gain = value
		_update_music_volume()
var _duck_gain := 0.0:
	set(value):
		_duck_gain = value
		_update_music_volume()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)
	_preload_streams()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)
	for key in MUSIC:
		if not ResourceLoader.exists(AUDIO_DIR + MUSIC[key]):
			push_warning("Missing music file: " + AUDIO_DIR + MUSIC[key])
			continue
		var m := load(AUDIO_DIR + MUSIC[key])
		if m != null:
			_music_streams[key] = m
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
				push_warning("Missing SFX file: " + AUDIO_DIR + file)
				continue
			var s := load(AUDIO_DIR + file)
			if s != null:
				loaded.append(s)
		_streams[key] = loaded
func _update_music_volume() -> void:
	if is_instance_valid(_music_player):
		_music_player.volume_db = _music_gain + _duck_gain
	
func play_music(name: String, fade: float = 1.2) -> void:
	if name == _current_music:
		return                        # already playing — don't restart it
	var stream: AudioStream = _music_streams.get(name)   # loaded once, in _ready()
	if stream == null:
		return
	_current_music = name
	# Kill any fade already running. Ignore time scale, so a track change
	# during slow-mo runs in real time.
	if is_instance_valid(_music_tween): _music_tween.kill()
	var tw := create_tween()
	_music_tween = tw
	tw.set_ignore_time_scale(true)
	# Something already playing: fade down to -60 over half the time, swap the
	# stream in a callback, then fade back up over the other half.
	if _music_player.playing:
		tw.tween_property(self, "_music_gain", -60.0, fade * 0.5)
		tw.tween_callback(func() -> void:
			_music_player.stream = stream
			_music_player.play()
		)
	else:
		# Nothing playing: skip the fade-down, start silent and come up.
		_music_player.stream = stream
		_music_player.play()
		_music_gain = -60.0
	tw.tween_property(self, "_music_gain", MUSIC_DB, fade * 0.5)

func duck_music(amount_db: float, duration: float) -> void:
	# Bump the token and keep a copy. The copy is this call's ticket.
	_duck_token += 1
	var token := _duck_token
	# Kill any duck already running, then drop fast: 0.12 s. minf(0.0, ...) so a
	# positive number can't boost the music.
	if is_instance_valid(_duck_tween): _duck_tween.kill()
	_duck_tween = create_tween().set_ignore_time_scale(true)
	_duck_tween.tween_property(self, "_duck_gain", minf(0.0, amount_db), 0.12)
	# Timer args: duration, keep counting while paused, not physics, ignore time
	# scale. A duck during slow-mo lasts real seconds, not stretched ones.
	await get_tree().create_timer(duration, true, false, true).timeout
	# Only restore if the token still matches. A newer duck owns the recovery.
	if token == _duck_token:
		if is_instance_valid(_duck_tween): _duck_tween.kill()
		_duck_tween = create_tween().set_ignore_time_scale(true)
		# Slower on the way back up, 0.35 s, so the music eases in instead of popping.
		_duck_tween.tween_property(self, "_duck_gain", 0.0, 0.35)

func apply_mix(settings: Dictionary) -> void:
	for key in BUS_BASE_DB:
		# capitalize() gives Master and Music. It would give Sfx, so that one
		# is spelled out by hand.
		var bus := AudioServer.get_bus_index(String(key).capitalize())
		if key == "sfx":
			bus = AudioServer.get_bus_index("SFX")     # not "Sfx"
		# bus < 0: the layout doesn't have that bus. Skip it rather than error.
		if bus < 0:
			continue
		# Slider value, 1.0 by default, clamped. Mute at zero, otherwise the
		# authored level plus the slider converted to decibels.
		var value := clampf(float(settings.get(key, 1.0)), 0.0, 1.0)
		AudioServer.set_bus_mute(bus, value <= 0.0)
		AudioServer.set_bus_volume_db(bus,
			float(BUS_BASE_DB[key]) + linear_to_db(maxf(value, 0.0001)))
			
