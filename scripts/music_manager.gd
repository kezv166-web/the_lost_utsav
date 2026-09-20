extends Node

## MusicManager – global singleton autoload
## Controls background music across all scenes with smooth crossfades and seamless continuation.
##
## Tracks:
##   - "outdoor"  : usal-sound.mp3 (Outdoor castle exterior)
##   - "l1_upper" : usal-sound.mp3 (Upper Level 1 inner fortress hall)
##   - "l1_lower" : Om Gan Ganapataye Namah.mp3 (Lower Level 1 underground maze)
##   - "l3_boss"  : Gajamukha_Rise_and_Blaze.ogg (Last level / Level 3 Asur boss fight)

const TRACKS: Dictionary = {
	"outdoor"  : "res://assets/sounds/usal-sound.mp3",
	"l1_upper" : "res://assets/sounds/usal-sound.mp3",
	"l1_lower" : "res://assets/sounds/Om Gan Ganapataye Namah.mp3",
	"l3_boss"  : "res://assets/sounds/Gajamukha_Rise_and_Blaze.ogg",
}

const FADE_OUT_TIME: float = 0.9
const FADE_IN_TIME:  float = 1.2
const DEFAULT_VOLUME_DB: float = -6.0

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active: AudioStreamPlayer     # currently audible player
var _current_key: String = ""
var _current_path: String = ""
var _fade_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player_a = _make_player("MusicA")
	_player_b = _make_player("MusicB")
	_active = _player_a

func _make_player(node_name: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.name = node_name
	p.bus = "Master"
	p.volume_db = -80.0
	p.autoplay = false
	p.finished.connect(_on_player_finished.bind(p))
	add_child(p)
	return p

func _on_player_finished(p: AudioStreamPlayer) -> void:
	if p == _active and _current_key != "":
		p.play()

## Play a named track.
## If the target path is already actively playing, seamlessly keep playing.
func play(track_key: String) -> void:
	if not _player_a:
		_player_a = _make_player("MusicA")
		_player_b = _make_player("MusicB")
		_active = _player_a

	if not TRACKS.has(track_key):
		push_warning("[MusicManager] Unknown track key: " + track_key)
		return

	var path: String = TRACKS[track_key]
	
	# If already playing this exact file, seamlessly continue without interruption
	if _current_path == path and _active.playing:
		_current_key = track_key
		return

	_current_key = track_key
	_current_path = path

	var stream = load(path)
	if not stream:
		push_error("[MusicManager] Failed to load audio: " + path)
		return

	# Ensure looping is enabled on the stream resource
	if "loop" in stream:
		stream.loop = true

	# Pick the idle player as the incoming player
	var incoming: AudioStreamPlayer = _player_b if _active == _player_a else _player_a
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	# Kill any running fade tween
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween().set_parallel(true)
	# Fade out the current player
	_fade_tween.tween_property(_active, "volume_db", -80.0, FADE_OUT_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Fade in the incoming player
	_fade_tween.tween_property(incoming, "volume_db", DEFAULT_VOLUME_DB, FADE_IN_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var old := _active
	_active = incoming
	_fade_tween.chain().tween_callback(func():
		old.stop()
		old.volume_db = -80.0
	)

## Fade out and stop music.
func stop() -> void:
	_current_key = ""
	_current_path = ""
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_active, "volume_db", -80.0, FADE_OUT_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_fade_tween.tween_callback(func():
		_player_a.stop()
		_player_b.stop()
	)

func get_current_track() -> String:
	return _current_key

func is_playing() -> bool:
	return _active != null and _active.playing
