extends Node

var _player: AudioStreamPlayer
var _enabled: bool = true

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.stream = load("res://audio/pulsation-132512.mp3") as AudioStream
	_player.finished.connect(_on_finished)
	add_child(_player)
	_player.play()


func _on_finished() -> void:
	if _enabled:
		_player.play()


func is_music_enabled() -> bool:
	return _enabled


func set_music_enabled(enabled: bool) -> void:
	_enabled = enabled
	if _enabled:
		_player.play()
	else:
		_player.stop()


func toggle_music() -> void:
	set_music_enabled(not _enabled)
