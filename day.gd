extends Node2D

#TODO: Play start animation
#TODO: Play the FIND THE HERETIC
#TODO: Play 10 second timer
#TODO: Show panel results after timer
#TODO: go to mask builder

@export_category("Day Properties")
@export var time_left:float = 12
@onready var timer := Timer.new()
var required_followers:int=0


@onready var lbl_goal: Label = $Canvas/Margin_Goal/VBox_Goal/Lbl_Goal
@onready var lbl_time_left: Label = $Canvas/Margin_Goal/VBox_Goal/Lbl_Time_Left
@onready var pnl_results: Panel = $Canvas/Margin_Goal/Pnl_Results
@onready var lbl_gained: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Lbl_Gained
@onready var lbl_heretics: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Lbl_Heretics
@onready var lbl_lost: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Lbl_Lost
@onready var lbl_total: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Lbl_Total
@onready var bttn_next: Button = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Bttn_Next
@onready var anim_goal: AnimationPlayer = $Canvas/Margin_Goal/VBox_Goal/Anim_Goal

func _ready() -> void:
	bttn_next.pressed.connect(Pressed_Next)
	pnl_results.visible = false
	timer.wait_time = time_left
	timer.one_shot = true
	timer.timeout.connect(Show_Results)
	add_child(timer)
	timer.start()
	
	pass


func _process(delta: float) -> void:
	lbl_time_left.text = str(round(int(timer.time_left)))

func Start_Day():
	print("day started")
	pass
	
func Pressed_Next():
	print("Pressed Next in Results!")
	get_tree().change_scene_to_file("res://mask_builder.tscn")

	pass
		
func Show_Results():
	pnl_results.visible = true
	pass
	
func Build_Mask():
	pass
	
