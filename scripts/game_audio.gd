extends Node

const SAMPLE_RATE := 22050
const MAX_ACTIVE_VOICES := 16
const SOUND_PROFILES := {
	"attack": [520.0, 170.0, 0.12, 0.24, 0.32],
	"monster_hit": [240.0, 95.0, 0.09, 0.18, 0.28],
	"player_hit": [180.0, 68.0, 0.2, 0.32, 0.5],
	"dodge": [920.0, 1380.0, 0.11, 0.0, 0.24],
	"skill_1": [430.0, 180.0, 0.2, 0.12, 0.36],
	"skill_2": [620.0, 280.0, 0.27, 0.0, 0.36],
	"skill_3": [280.0, 920.0, 0.34, 0.08, 0.38],
	"skill_4": [760.0, 110.0, 0.48, 0.2, 0.44],
	"monster_death": [160.0, 48.0, 0.24, 0.3, 0.35],
	"experience": [880.0, 1320.0, 0.09, 0.0, 0.22],
	"potion": [440.0, 880.0, 0.2, 0.0, 0.3],
	"gold": [1180.0, 1760.0, 0.15, 0.0, 0.25],
	"level_up": [520.0, 1040.0, 0.42, 0.0, 0.34],
	"card_pick": [680.0, 1060.0, 0.14, 0.0, 0.25],
	"death": [220.0, 55.0, 0.5, 0.1, 0.4],
}

var _random := RandomNumberGenerator.new()
var _voices: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}


func _ready() -> void:
	_random.randomize()


func play_sfx(sound_id: String) -> void:
	if not GameData.sound_enabled:
		return
	if not SOUND_PROFILES.has(sound_id):
		push_error("등록되지 않은 효과음입니다: %s" % sound_id)
		return
	if _voices.size() >= MAX_ACTIVE_VOICES:
		return

	var profile: Array = SOUND_PROFILES[sound_id]
	if not _streams.has(sound_id):
		_streams[sound_id] = _build_tone(profile)
	var voice := AudioStreamPlayer.new()
	voice.stream = _streams[sound_id]
	voice.volume_db = linear_to_db(float(profile[4]))
	voice.process_mode = Node.PROCESS_MODE_ALWAYS
	voice.finished.connect(_on_voice_finished.bind(voice))
	add_child(voice)
	_voices.append(voice)
	voice.play()


func _build_tone(profile: Array) -> AudioStreamWAV:
	var start_frequency := float(profile[0])
	var end_frequency := float(profile[1])
	var duration := float(profile[2])
	var noise_amount := float(profile[3])
	var sample_count := int(SAMPLE_RATE * duration)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)

	for index in range(sample_count):
		var time := float(index) / SAMPLE_RATE
		var progress := time / duration
		var phase := (
			TAU
			* (start_frequency * time + 0.5 * (end_frequency - start_frequency) * time * progress)
		)
		var tone := sin(phase) * 0.82 + sin(phase * 2.0) * 0.18
		var noise := _random.randf_range(-1.0, 1.0) * noise_amount
		var attack_envelope := minf(1.0, time / 0.006)
		var release_envelope := pow(1.0 - progress, 1.5)
		var sample := clampf((tone + noise) * attack_envelope * release_envelope, -1.0, 1.0)
		samples.encode_s16(index * 2, int(sample * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream


func _on_voice_finished(voice: AudioStreamPlayer) -> void:
	_voices.erase(voice)
	voice.queue_free()
