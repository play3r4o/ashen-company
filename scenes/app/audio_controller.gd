class_name AshenAudioController
extends Node

@export var camp_music: AudioStream
@export var moor_music: AudioStream
@export var strike_sfx: AudioStream
@export var guard_sfx: AudioStream
@export var pickup_sfx: AudioStream
@export var hurt_sfx: AudioStream

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_players: Array[AudioStreamPlayer] = [
	$SfxPlayer01,
	$SfxPlayer02,
	$SfxPlayer03,
	$SfxPlayer04,
]

var current_music: String = ""
var sfx_cursor: int = 0
var sfx_throttle: float = 0.0


func _ready() -> void:
	music_player.finished.connect(_restart_music)


func _process(delta: float) -> void:
	sfx_throttle = maxf(0.0, sfx_throttle - delta)


func play_music(music_id: String) -> void:
	var stream: AudioStream = camp_music if music_id == "camp" else moor_music if music_id == "moor" else null
	if stream == null:
		push_error("Unknown or unassigned authored music stream '%s'" % music_id)
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
	sfx_throttle = throttle
	var player: AudioStreamPlayer = sfx_players[sfx_cursor % sfx_players.size()]
	sfx_cursor += 1
	player.stream = stream
	player.play()


func apply_volumes(music: float, sfx: float) -> void:
	music_player.volume_db = linear_to_db(maxf(0.001, music))
	music_player.stream_paused = music <= 0.001
	for player: AudioStreamPlayer in sfx_players:
		player.volume_db = linear_to_db(maxf(0.001, sfx))


func shutdown() -> void:
	music_player.stop()
	music_player.stream = null
	for player: AudioStreamPlayer in sfx_players:
		player.stop()
		player.stream = null


func _restart_music() -> void:
	if music_player.stream != null:
		music_player.play()
