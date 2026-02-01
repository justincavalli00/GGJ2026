extends Control
@onready var bttn_start: Button = $MarginContainer/VBoxContainer/VBoxContainer/Bttn_Start
@onready var bttn_credits: Button = $MarginContainer/VBoxContainer/VBoxContainer/Bttn_Credits

func _ready():
	bttn_start.pressed.connect(Pressed_Start)
	
func Pressed_Start():
	get_tree().change_scene_to_file("res://day.tscn")
