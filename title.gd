extends Control
@onready var bttn_start: Button = $MarginContainer/VBoxContainer/VBoxContainer/Bttn_Start
@onready var bttn_credits: Button = $MarginContainer/VBoxContainer/VBoxContainer/Bttn_Credits
@onready var bttn_music: Button = $MarginContainer/VBoxContainer/VBoxContainer/Bttn_Music

func _ready():
	bttn_start.pressed.connect(Pressed_Start)
	bttn_credits.pressed.connect(Pressed_Credits)
	bttn_music.pressed.connect(_on_music_pressed)
	_update_music_button_text()

func _on_music_pressed():
	BackgroundMusic.toggle_music()
	_update_music_button_text()

func _update_music_button_text():
	bttn_music.text = "Music: %s" % ("On" if BackgroundMusic.is_music_enabled() else "Off")

func Pressed_Start():
	get_tree().change_scene_to_file("res://day.tscn")

func Pressed_Credits():
	get_tree().change_scene_to_file("res://mask_builder.tscn")
