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
@onready var totem_face: Node2D = $Totem/Face


func _ready() -> void:
	bttn_next.pressed.connect(Pressed_Next)
	pnl_results.visible = false
	_build_totem_face()
	timer.wait_time = time_left
	timer.one_shot = true
	timer.timeout.connect(Show_Results)
	add_child(timer)
	timer.start()
	Spawn_Followers()
	pass


func _build_totem_face() -> void:
	# Display the player's built mask on the totem (visual only, no interaction).
	# Slot order: Left_Top, Left_Mid, Left_Bottom, Right_Top, Right_Mid, Right_Bottom
	# 2x3 vertical grid, each cell fixed size; same expand/stretch as mask_piece
	const CELL_W := 160
	const CELL_H := 160
	# Top-left position per slot (2 cols x 3 rows), centered so grid center is at (0,0)
	var slot_positions := [
		Vector2(-CELL_W, -CELL_H * 3 / 2),      # left, top
		Vector2(-CELL_W, -CELL_H / 2),         # left, mid
		Vector2(-CELL_W, CELL_H / 2),          # left, bottom
		Vector2(0, -CELL_H * 3 / 2),           # right, top
		Vector2(0, -CELL_H / 2),               # right, mid
		Vector2(0, CELL_H / 2),                 # right, bottom
	]
	for i in range(min(SessionData.built_mask_pieces.size(), slot_positions.size())):
		var data = SessionData.built_mask_pieces[i]
		if data is Mask_Piece_Data and data.mask_piece_sprite != null:
			var rect := TextureRect.new()
			rect.texture = data.mask_piece_sprite
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			rect.position = slot_positions[i]
			rect.size = Vector2(CELL_W, CELL_H)
			rect.custom_minimum_size = Vector2(CELL_W, CELL_H)
			totem_face.add_child(rect)


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
		
func Show_Results() -> void:
	var followers_added: int = SessionData.get_followers_added()
	lbl_gained.text = "Followers added: %d" % followers_added
	pnl_results.visible = true
	
func Build_Mask():
	pass
	
