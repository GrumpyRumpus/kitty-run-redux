extends AudioStreamPlayer

var menu_track := preload("res://assets/music/flowerbed_fields.ogg")
var game_track := preload("res://assets/music/happy_tune.mp3")


func _ready() -> void:
	bus = &"Music"
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_track.loop = true
	game_track.loop = true


func play_track(track: AudioStream) -> void:
	if stream == track and playing:
		return
	stream = track
	play()


func play_menu() -> void:
	play_track(menu_track)


func play_game() -> void:
	play_track(game_track)
