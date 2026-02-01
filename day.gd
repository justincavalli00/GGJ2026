extends Node2D

@export_category("Day Properties")
@export var time_left:float = 12
@onready var timer := Timer.new()

@export_category("Follower Properties")
@export var follower_count : int = 0
@export var follower_req:int=0
@export var move_duration : float

@export var heretic_count : int = 1

## Sum of followers from all mask pieces (base total, before round/synergy multipliers). Set from SessionData in _ready().
var current_followers: int = 0
## Base heretic_count + sum of heretics from all mask pieces. Set in _ready().
var current_heretics: int = 0
## Number of (non-heretic) followers clicked/smitten this day. Subtracted from base before multiplier.
var followers_smitten: int = 0

const FOLLOWER = preload("uid://dyhajxfwyll2q")

@onready var lbl_goal: Label = $Canvas/Margin_Goal/VBox_Goal/Lbl_Goal
@onready var lbl_time_left: Label = $Canvas/Margin_Goal/VBox_Goal/Lbl_Time_Left
@onready var pnl_results: Panel = $Canvas/Margin_Goal/Pnl_Results
@onready var lbl_required_num: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/HBoxContainer/Lbl_Required_Num
@onready var lbl_total_num: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/HBoxContainer4/Lbl_Total_Num
@onready var bttn_next: Button = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/Bttn_Next
@onready var lbl_flip_results: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/HBoxContainer5/Lbl_Flip_Results
@onready var lbl_base_mask_num: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/HBoxContainer2/Lbl_Base_Mask_Num
@onready var lbl_mask_multi_num: Label = $Canvas/Margin_Goal/Pnl_Results/VBox_Results/HBoxContainer5/Lbl_Mask_Multi_Num
var _session: Node = null  # SessionData autoload, set in _ready()
var lbl_gained: Label = null  # optional; set in _ready() if node exists
var lbl_smitten_num: Label = null  # optional; set in _ready() if node exists
@onready var anim_goal: AnimationPlayer = $Canvas/Margin_Goal/VBox_Goal/Anim_Goal
@onready var spawn: Node2D = $Followers/Spawn
@onready var group: Node2D = $Followers/Group
@onready var totem_face: Node2D = $Totem/Face

var _last_printed_second: int = -1


func _ready() -> void:
	_session = get_node_or_null("/root/SessionData")
	if _session == null:
		push_error("day: SessionData autoload not found")
	else:
		current_followers = _session.get_base_followers()
	lbl_gained = get_node_or_null("Canvas/Margin_Goal/Pnl_Results/VBox_Results/Lbl_Gained")
	lbl_smitten_num = get_node_or_null("Canvas/Margin_Goal/Pnl_Results/VBox_Results/HBox_Smitten/Lbl_Smitten_Num")
	bttn_next.pressed.connect(Pressed_Next)
	pnl_results.visible = false
	_build_totem_face()
	# Sum time_in_day from all built mask pieces into the day timer
	var time_from_mask: float = 0.0
	var heretics_from_mask: int = 0
	if _session:
		for data in _session.built_mask_pieces:
			if data is Mask_Piece_Data:
				time_from_mask += data.time_in_day
				heretics_from_mask += data.heretics
	timer.wait_time = time_left + time_from_mask
	current_heretics = heretic_count + heretics_from_mask
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
	var pieces: Array = _session.built_mask_pieces if _session else []
	for i in range(min(pieces.size(), slot_positions.size())):
		var data = pieces[i]
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
	for i in range(current_followers):
		# Pick random spawn position
		var random_spawn = spawn_markers.pick_random() as Marker2D
		
		# Pick random group destination
		var random_group = group_markers.pick_random() as Marker2D
		
		# Instantiate follower
		var follower = FOLLOWER.instantiate()
		add_child(follower)
		follower.add_to_group("followers")  # Important for flocking!

		# Add click signal handler for follower (pass node so we can remove it when smitten)
		follower.clicked.connect(on_follower_clicked.bind(follower))

		# Set initial position
		follower.global_position = random_spawn.global_position
		
		# Enable flocking during movement
		follower.Set_Target(random_group.global_position)

		
		# Tween to destination
		var tween = create_tween()
		tween.tween_property(follower, "global_position", random_group.global_position, move_duration)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
	
	# Spawn each heretic
	for x in range(current_heretics):
		# Pick random spawn position
		var random_spawn = spawn_markers.pick_random() as Marker2D
		
		# Pick random group destination
		var random_group = group_markers.pick_random() as Marker2D
		
		# Instantiate heretic
		var heretic = FOLLOWER.instantiate()
		# set to is heretic
		heretic.IsHeretic = true
		heretic.modulate = Color(1, 1, 1, .7)
		add_child(heretic)
		heretic.add_to_group("followers")  # Important for flocking!

		# Add click signal handler for follower
		heretic.clicked.connect(on_heretic_clicked.bind(heretic))

		# Set initial position
		heretic.global_position = random_spawn.global_position
		
		# Enable flocking during movement
		heretic.Set_Target(random_group.global_position)

		
		# Tween to destination
		var tween = create_tween()
		tween.tween_property(heretic, "global_position", random_group.global_position, move_duration)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
	
func _process(_delta: float) -> void:
	var sec_left: int = int(round(timer.time_left))
	lbl_time_left.text = str(sec_left)
	if sec_left != _last_printed_second:
		_last_printed_second = sec_left
		print("Time left: ", sec_left)

func Start_Day():
	print("day started")
	pass
	
func Pressed_Next() -> void:
	if _session == null:
		return
	var total: int = _session.get_followers_added_with_smitten(followers_smitten)
	var required: int = _session.get_required_followers()
	if total >= required:
		# Win: next round, mask persists
		_session.current_round += 1
		get_tree().change_scene_to_file("res://mask_builder.tscn")
	else:
		# Loss: reset round and mask
		_session.current_round = 1
		_session.clear_mask()
		get_tree().change_scene_to_file("res://mask_builder.tscn")

func Show_Results() -> void:
	if _session == null:
		pnl_results.visible = true
		return
	var total: int = _session.get_followers_added_with_smitten(followers_smitten)
	var required: int = _session.get_required_followers()
	if lbl_required_num:
		lbl_required_num.text = str(required)
	if lbl_total_num:
		lbl_total_num.text = str(total)
	if lbl_base_mask_num:
		lbl_base_mask_num.text = str(_session.get_base_followers())
	if lbl_smitten_num:
		lbl_smitten_num.text = str(followers_smitten)
	if lbl_mask_multi_num:
		lbl_mask_multi_num.text = _session.get_multiplier_display()
	if lbl_gained:
		lbl_gained.text = "Followers added: %d" % total
	if lbl_flip_results:
		var breakdown: Array = _session.get_followers_breakdown_with_smitten(followers_smitten)
		var lines := ""
		for i in range(breakdown.size()):
			if i > 0:
				lines += "\n"
			lines += str(breakdown[i])
		lbl_flip_results.text = lines
	if bttn_next:
		bttn_next.text = "Continue" if total >= required else "New Game"
	pnl_results.visible = true
	
func Build_Mask():
	pass
	
func on_follower_clicked(follower_node):
	follower_node.queue_free()
	followers_smitten += 1

func on_heretic_clicked(heretic):
	heretic.queue_free()
	current_heretics -= 1
	if current_heretics <= 0:
		Show_Results()
	print("heretic clicked")
