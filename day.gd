extends Node2D

@export_category("Day Properties")
@export var time_left:float = 12
@onready var timer := Timer.new()

@export_category("Follower Properties")
@export var follower_count : int = 0
@export var follower_req:int=0
@export var move_duration : float


const FOLLOWER = preload("uid://dyhajxfwyll2q")

@onready var lbl_goal: Label = $Canvas/Margin_Goal/VBox_Goal/Lbl_Goal
@onready var lbl_time_left: Label = $Canvas/Margin_Goal/VBox_Goal/Lbl_Time_Left
@onready var pnl_results: Panel = $Canvas/Margin_Goal/Pnl_Results
@onready var lbl_gained: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Lbl_Gained
@onready var lbl_heretics: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Lbl_Heretics
@onready var lbl_lost: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Lbl_Lost
@onready var lbl_total: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Lbl_Total
@onready var bttn_next: Button = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Bttn_Next
@onready var anim_goal: AnimationPlayer = $Canvas/Margin_Goal/VBox_Goal/Anim_Goal
@onready var spawn: Node2D = $Followers/Spawn
@onready var group: Node2D = $Followers/Group



func _ready() -> void:
	bttn_next.pressed.connect(Pressed_Next)
	pnl_results.visible = false
	timer.wait_time = time_left
	timer.one_shot = true
	timer.timeout.connect(Show_Results)
	add_child(timer)
	timer.start()
	Spawn_Followers()
	
	pass


func Spawn_Followers() -> void:
	# Get all spawn and group markers
	var spawn_markers = spawn.get_children().filter(func(child): return child is Marker2D)
	var group_markers = group.get_children().filter(func(child): return child is Marker2D)
	
	# Safety check
	if spawn_markers.is_empty() or group_markers.is_empty():
		push_error("Missing markers!")
		return
		
	# Spawn each follower
	for i in range(follower_count):
		# Pick random spawn position
		var random_spawn = spawn_markers.pick_random() as Marker2D
		
		# Pick random group destination
		var random_group = group_markers.pick_random() as Marker2D
		
		# Instantiate follower
		var follower = FOLLOWER.instantiate()
		add_child(follower)
		follower.add_to_group("followers")  # Important for flocking!

		# Set initial position
		follower.global_position = random_spawn.global_position
		
		# Enable flocking during movement
		follower.Set_Target(random_group.global_position)

		
		# Tween to destination
		var tween = create_tween()
		tween.tween_property(follower, "global_position", random_group.global_position, move_duration)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)



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
	
