extends Control

@onready var lbl_quote: Label = $Panel/VBox_Quote/Lbl_Quote
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var startup_quotes: Array[String] = [
	"Become the leader of your own cult.", 
	"Just keep your subjects happy.",
	"Join us, it will be easy to get out of this one.",
	"Do WHATEVER it takes to keep you subjects happy.", 
	"P.S. You wont need a documentary to leave this cult",
	"Today feels like a good day for coarsening subjects!",
	"Seize the day and take advantage (of them)!",
#	"Today is the day to start the original influencing life of cult leadership.",
	"Go get ‘em oh master, genius, leader…",
	"The folks out here are ready to believe in something."
]

func get_random_message() -> String:
	return startup_quotes.pick_random()


func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)
	lbl_quote.text = get_random_message()

func _input(event):
	if event.is_action_pressed("ui_accept"): 
		lbl_quote.text = get_random_message()




func _on_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://day.tscn")

	pass # Replace with function body.
