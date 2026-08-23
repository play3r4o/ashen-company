class_name AshenAudioController
extends Node

@export var camp_music: AudioStream
@export var moor_music: AudioStream
@export var strike_sfx: AudioStream
@export var guard_sfx: AudioStream
@export var pickup_sfx: AudioStream
@export var hurt_sfx: AudioStream

@onready var music_player: AudioStreamPlayer = AshenSceneBindings.required(self, &"MusicPlayer", "AudioController") as AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

var current_music: String = ""
var sfx_cursor: int = 0
var sfx_throttle: float = 0.0


func _ready() -> void:
	for role: StringName in [&"SfxPlayer01", &"SfxPlayer02", &"SfxPlayer03", &"SfxPlayer04"]:
		var player := AshenSceneBindings.optional(self, role) as AudioStreamPlayer
		if player != null:
			sfx_players.append(player)
	if music_player != null:
		music_player.finished.connect(_restart_music)
	set_process(false)


func _exit_tree() -> void:
	# Own the teardown beside the players themselves. During an engine/app quit,
	# relying only on the parent coordinator's exit callback can happen after the
	# audio branch has already begun leaving the tree, retaining a WAV playback
	# resource until process shutdown.
	shutdown()


func _process(delta: float) -> void:
	sfx_throttle = maxf(0.0, sfx_throttle - delta)
	if is_zero_approx(sfx_throttle):
		set_process(false)


func play_music(music_id: String) -> void:
	var stream: AudioStream = camp_music if music_id == "camp" else moor_music if music_id == "moor" else null
	if stream == null:
		push_error("Unknown or unassigned authored music stream '%s'" % music_id)
		return
	if music_player == null:
		return
	if current_music == music_id and music_player.playing:
		return
	current_music = music_id
	music_player.stream = stream
	music_player.play()


func play_sfx(sfx_id: String, throttle: float = 0.06) -> void:
	var stream: AudioStream
	match sfx_id:
		"strike": stream = strike_sfx
		"guard": stream = guard_sfx
		"pickup": stream = pickup_sfx
		"hurt": stream = hurt_sfx
		_:
			push_error("Unknown authored sound effect '%s'" % sfx_id)
			return
	if stream == null:
		push_error("Authored sound effect '%s' has no assigned stream" % sfx_id)
		return
	if sfx_throttle > 0.0:
		return
	if sfx_players.is_empty():
		return
	sfx_throttle = maxf(0.0, throttle)
	set_process(sfx_throttle > 0.0)
	var player: AudioStreamPlayer = sfx_players[sfx_cursor % sfx_players.size()]
	sfx_cursor += 1
	player.stream = stream
	player.play()


func apply_volumes(music: float, sfx: float) -> void:
	if music_player != null:
		music_player.volume_db = linear_to_db(maxf(0.001, music))
		music_player.stream_paused = music <= 0.001
	for player: AudioStreamPlayer in sfx_players:
		player.volume_db = linear_to_db(maxf(0.001, sfx))


func shutdown() -> void:
	if music_player != null:
		music_player.stop()
		music_player.stream = null
	for player: AudioStreamPlayer in sfx_players:
		player.stop()
		player.stream = null
	# Release the exported stream references as well. This keeps editor/headless
	# shutdown from retaining AudioStreamWAV resources after the players stop.
	camp_music = null
	moor_music = null
	strike_sfx = null
	guard_sfx = null
	pickup_sfx = null
	hurt_sfx = null


func _restart_music() -> void:
	if music_player != null and music_player.stream != null:
		music_player.play()
