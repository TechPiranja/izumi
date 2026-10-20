## One-off tool that synthesizes the soft, cozy sound effects into res://audio/.
## Music-box bells and gentle bubble sounds, all from sine waves.
## Run it from the project folder:
##   godot --headless --path . --script tools/gen_sfx.gd
extends SceneTree

const MIX_RATE := 44100
const OUT_DIR := "res://audio/"

# Pentatonic notes (no half steps), so everything sounds friendly together.
const C5 := 523.25
const D5 := 587.33
const E5 := 659.25
const G5 := 783.99
const A5 := 880.0
const C6 := 1046.5
const D6 := 1174.7
const E6 := 1318.5
const G6 := 1568.0
const A6 := 1760.0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	# A soft rising "pwip", like a bubble.
	_save("jump", _echo(_bubble(380.0, 640.0, 0.11, 0.45), 0.07, 0.25, 2))

	# Two sparkles on a quick upward glide.
	var air := _bubble(560.0, 1250.0, 0.16, 0.3)
	air = _overlay(air, _bell(E6, 0.35, 0.28), 0.05)
	air = _overlay(air, _bell(A6, 0.4, 0.22), 0.1)
	_save("air_jump", _echo(air, 0.09, 0.3, 3))

	# A quiet, round "pop" instead of a thud.
	_save("land", _bubble(210.0, 95.0, 0.1, 0.5))

	# A little music box run upwards.
	var orb := _bell(G5, 0.5, 0.4)
	orb = _overlay(orb, _bell(C6, 0.5, 0.4), 0.07)
	orb = _overlay(orb, _bell(E6, 0.5, 0.38), 0.14)
	orb = _overlay(orb, _bell(G6, 0.7, 0.35), 0.21)
	_save("orb", _echo(orb, 0.12, 0.35, 3))

	# A single tiny bell.
	_save("tick", _echo(_bell(C6, 0.3, 0.3), 0.1, 0.3, 2))

	# A short, happy music box melody with a long, shimmering tail.
	var melody := _bell(C5, 0.8, 0.4)
	melody = _overlay(melody, _bell(E5, 0.8, 0.4), 0.1)
	melody = _overlay(melody, _bell(G5, 0.8, 0.4), 0.2)
	melody = _overlay(melody, _bell(C6, 0.9, 0.4), 0.3)
	melody = _overlay(melody, _bell(E6, 1.2, 0.4), 0.42)
	melody = _overlay(melody, _bell(G6, 1.4, 0.3), 0.54)
	_save("milestone", _echo(melody, 0.18, 0.4, 4))

	# A soft, low sinking "wuuum" when the lights go out.
	var dark := _bubble(320.0, 70.0, 0.45, 0.55)
	dark = _overlay(dark, _bell(C5 * 0.5, 0.6, 0.25), 0.05)
	_save("dark", _echo(dark, 0.15, 0.3, 3))

	# Bright bells running upwards when everything is visible again.
	var cure := _bell(G5, 0.6, 0.35)
	cure = _overlay(cure, _bell(C6, 0.6, 0.35), 0.06)
	cure = _overlay(cure, _bell(E6, 0.6, 0.35), 0.12)
	cure = _overlay(cure, _bell(A6, 0.8, 0.3), 0.18)
	_save("cure", _echo(cure, 0.14, 0.35, 3))

	# Four soft bells sinking down, a gentle "aww" instead of a harsh game over sound.
	var over := _bell(G5, 0.7, 0.35)
	over = _overlay(over, _bell(E5, 0.7, 0.35), 0.16)
	over = _overlay(over, _bell(D5, 0.8, 0.35), 0.32)
	over = _overlay(over, _bell(C5, 1.2, 0.35), 0.5)
	_save("game_over", _echo(over, 0.2, 0.35, 3))

	# A soft sonar "pooong" with echoes coming back.
	var ping := _bubble(900.0, 640.0, 0.2, 0.4)
	ping = _overlay(ping, _bell(E6, 0.4, 0.2), 0.02)
	_save("ping", _echo(ping, 0.24, 0.45, 3))

	# A gentle "bwoop-ding" for the box sliding in.
	var toast := _bubble(420.0, 780.0, 0.12, 0.3)
	toast = _overlay(toast, _bell(D6, 0.5, 0.3), 0.08)
	_save("toast", _echo(toast, 0.1, 0.3, 2))
	quit()


func _save(sfx_name: String, samples: PackedFloat32Array) -> void:
	samples = _limit(samples, 0.8)
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	var err := stream.save_to_wav(OUT_DIR + sfx_name + ".wav")
	print("%s: %s (%d samples)" % [sfx_name, "ok" if err == OK else "error %d" % err, samples.size()])


## A bell / music box note: a sine plus a few quieter overtones that fade out faster.
func _bell(freq: float, duration: float, volume: float) -> PackedFloat32Array:
	# Overtone ratio, loudness, and how fast it fades (per second).
	var partials := [[1.0, 1.0, 5.0], [2.0, 0.35, 9.0], [3.0, 0.15, 14.0], [4.1, 0.07, 20.0]]
	var count := int(duration * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	for i in count:
		var t := float(i) / MIX_RATE
		var sample := 0.0
		for p in partials:
			sample += p[1] * sin(TAU * freq * p[0] * t) * exp(-p[2] * t)
		out[i] = sample * volume * _edges(i, count)
	return out


## A round "bloop": a sine that glides from `f0` to `f1` with a soft start and end.
func _bubble(f0: float, f1: float, duration: float, volume: float) -> PackedFloat32Array:
	var count := int(duration * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		# Glide fast at first, then settle (ease out).
		phase += lerpf(f0, f1, 1.0 - pow(1.0 - t, 2.0)) / MIX_RATE
		var envelope := sin(PI * pow(t, 0.6))
		out[i] = sin(TAU * phase) * volume * envelope
	return out


## Fades in and out over a few milliseconds, so there are no clicks.
func _edges(i: int, count: int) -> float:
	var fade := int(0.004 * MIX_RATE)
	return minf(minf(float(i) / fade, float(count - i) / (fade * 4)), 1.0)


## Adds `extra` on top of `base`, starting `start` seconds in.
func _overlay(base: PackedFloat32Array, extra: PackedFloat32Array, start: float) -> PackedFloat32Array:
	var offset := int(start * MIX_RATE)
	var out := base.duplicate()
	if out.size() < offset + extra.size():
		out.resize(offset + extra.size())
	for i in extra.size():
		out[offset + i] += extra[i]
	return out


## Soft repeats that get quieter, like a small room.
func _echo(samples: PackedFloat32Array, delay: float, gain: float, taps: int) -> PackedFloat32Array:
	var step := int(delay * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(samples.size() + step * taps)
	for tap in taps + 1:
		var level := pow(gain, tap)
		for i in samples.size():
			out[i + step * tap] += samples[i] * level
	return out


## Scales everything down if it would get louder than `peak`.
func _limit(samples: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var loudest := 0.0
	for s in samples:
		loudest = maxf(loudest, absf(s))
	if loudest <= peak:
		return samples
	var out := samples.duplicate()
	for i in out.size():
		out[i] *= peak / loudest
	return out
