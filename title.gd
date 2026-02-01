extends Control
@onready var bttn_start: Button = $MarginContainer/VBoxContainer/VBoxContainer/Bttn_Start
@onready var bttn_credits: Button = $MarginContainer/VBoxContainer/VBoxContainer/Bttn_Credits
@onready var bttn_music: Button = $MarginContainer/VBoxContainer/VBoxContainer/Bttn_Music
@onready var lbl_seed: Label = $MarginContainer/VBoxContainer/VBoxContainer/Lbl_Seed
@onready var bttn_random_seed: Button = $MarginContainer/VBoxContainer/VBoxContainer/HBox_Seed/Bttn_RandomSeed
@onready var bttn_win_seed: Button = $MarginContainer/VBoxContainer/VBoxContainer/HBox_Seed/Bttn_WinSeed

func _ready():
	bttn_start.pressed.connect(Pressed_Start)
	bttn_credits.pressed.connect(Pressed_Credits)
	bttn_music.pressed.connect(_on_music_pressed)
	bttn_random_seed.pressed.connect(_on_random_seed_pressed)
	bttn_win_seed.pressed.connect(_on_win_seed_pressed)
	_update_music_button_text()
	_update_seed_label()

func _on_music_pressed():
	BackgroundMusic.toggle_music()
	_update_music_button_text()

func _update_music_button_text():
	bttn_music.text = "Music: %s" % ("On" if BackgroundMusic.is_music_enabled() else "Off")

func _update_seed_label():
	if SessionData.current_seed == 0:
		lbl_seed.text = "Seed: random"
	else:
		lbl_seed.text = "Seed: %d" % SessionData.current_seed

func _on_random_seed_pressed():
	SessionData.current_seed = randi_range(1, 2147483647)
	_update_seed_label()

func _on_win_seed_pressed():
	SessionData.current_seed = SessionData.WIN_SEED
	_update_seed_label()

func Pressed_Start():
	get_tree().change_scene_to_file("res://day.tscn")

func Pressed_Credits():
	SessionData.apply_seed()
	get_tree().change_scene_to_file("res://mask_builder.tscn")
