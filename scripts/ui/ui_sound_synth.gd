class_name UISoundSynth
extends Node

# Procedural UI Sound Synthesizer using AudioStreamWAV
# Generates lightweight, crisp audio in memory with 0 external dependencies.
# Guaranteed 100% compatibility with Linux, WebGL/WASM, and Desktop.

static var _instance: UISoundSynth = null
var _player: AudioStreamPlayer = null

var _snd_hover: AudioStreamWAV = null
var _snd_click: AudioStreamWAV = null
var _snd_tab: AudioStreamWAV = null
var _snd_open: AudioStreamWAV = null
var _snd_close: AudioStreamWAV = null

static func get_instance(parent: Node) -> UISoundSynth:
	if _instance and is_instance_valid(_instance):
		return _instance
	var synth = UISoundSynth.new()
	synth.name = "UISoundSynth"
	parent.add_child(synth)
	_instance = synth
	return synth

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_generate_all_sounds()

func _generate_all_sounds() -> void:
	_snd_hover = _create_beep(880.0, 1100.0, 0.045, 0.15)
	_snd_click = _create_thud(440.0, 180.0, 0.065, 0.35)
	_snd_tab = _create_beep(600.0, 750.0, 0.04, 0.2)
	_snd_open = _create_sweep(350.0, 700.0, 0.12, 0.25)
	_snd_close = _create_sweep(650.0, 320.0, 0.10, 0.22)

func play_hover() -> void:
	_play(_snd_hover)

func play_click() -> void:
	_play(_snd_click)

func play_tab() -> void:
	_play(_snd_tab)

func play_open() -> void:
	_play(_snd_open)

func play_close() -> void:
	_play(_snd_close)

func _play(stream: AudioStreamWAV) -> void:
	if not _player or not stream:
		return
	_player.stream = stream
	_player.play()

func _create_beep(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2) # 16-bit mono = 2 bytes per sample
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerp(start_freq, end_freq, t)
		phase += (freq * TAU) / float(sample_rate)
		if phase > TAU:
			phase -= TAU
		
		# Smooth attack & decay envelope
		var envelope: float = sin(t * PI) * volume
		var sample_val: float = sin(phase) * envelope
		var int_val: int = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		
		# Write 16-bit little endian
		data[i * 2] = int_val & 0xFF
		data[i * 2 + 1] = (int_val >> 8) & 0xFF
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _create_thud(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerp(start_freq, end_freq, t * t)
		phase += (freq * TAU) / float(sample_rate)
		if phase > TAU:
			phase -= TAU
		
		var envelope: float = (1.0 - t) * (1.0 - t) * volume
		var sample_val: float = sin(phase) * envelope
		var int_val: int = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		
		data[i * 2] = int_val & 0xFF
		data[i * 2 + 1] = (int_val >> 8) & 0xFF
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _create_sweep(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerp(start_freq, end_freq, t)
		phase += (freq * TAU) / float(sample_rate)
		if phase > TAU:
			phase -= TAU
			
		var env: float = (sin(t * PI)) * volume
		var sample_val: float = sin(phase) * env
		var int_val: int = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		
		data[i * 2] = int_val & 0xFF
		data[i * 2 + 1] = (int_val >> 8) & 0xFF
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
