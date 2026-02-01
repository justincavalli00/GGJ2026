extends Control

const MASK_DATA_PATH := "res://mask_data/"

@export var drawCount : int
var MaskScene
var selected_maskPiece: Control = null
var _mask_piece_data_list: Array[Mask_Piece_Data] = []
var current_round: int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	MaskScene = preload("res://mask_piece.tscn")
	_load_mask_piece_data()
	_drawCards()

	var all_slots = []
	all_slots += $Panel_Mask/HBox_Mask/VBox_Left.get_children()
	all_slots += $Panel_Mask/HBox_Mask/VBox_Right.get_children()
	for maskSlot in all_slots:
		maskSlot.clicked.connect(_on_slot_clicked.bind(maskSlot))
		
	_UpdateEffects()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _load_mask_piece_data():
	_mask_piece_data_list.clear()
	var dir = DirAccess.open(MASK_DATA_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension() == "tres":
				var data = load(MASK_DATA_PATH + file_name) as Mask_Piece_Data
				if data:
					_mask_piece_data_list.append(data)
			file_name = dir.get_next()
		dir.list_dir_end()

func generate_mask_piece() -> Control:
	if _mask_piece_data_list.is_empty():
		push_warning("GameManager: No mask piece data in " + MASK_DATA_PATH)
		return MaskScene.instantiate()
	var round_flag := 1 << (current_round - 1)
	var pool: Array[Mask_Piece_Data] = []
	for data in _mask_piece_data_list:
		if (data.available_in_round & round_flag) != 0:
			pool.append(data)
	if pool.is_empty():
		push_warning("GameManager: No mask pieces available for round %d, using full list" % current_round)
		pool.append_array(_mask_piece_data_list)
	var maskPiece = MaskScene.instantiate()
	var data = pool[randi() % pool.size()]
	maskPiece.mask_piece_data = data
	return maskPiece

func _drawCards():
	for x in range(1, drawCount + 1):
		var maskPiece = generate_mask_piece()
		var offering = get_node("Panel_Offerings/HBox_Offering/Offering_" + str(x))
		offering.add_child(maskPiece)
	
	for offering in $Panel_Offerings/HBox_Offering.get_children():
		var maskPiece = offering.get_child(0)
		if maskPiece != null:
			maskPiece.selected.connect(_on_maskPiece_selected.bind(maskPiece))
		
func _on_maskPiece_selected(maskPiece):
	# Clear highlight on previously selected piece
	if selected_maskPiece and is_instance_valid(selected_maskPiece):
		if selected_maskPiece.has_method("set_selected"):
			selected_maskPiece.set_selected(false)
	# Select the clicked piece (from offering or from a slot) for repositioning
	selected_maskPiece = maskPiece
	if maskPiece.has_method("set_selected"):
		maskPiece.set_selected(true)
	
func _on_slot_clicked(maskSlot):
	if selected_maskPiece:
		# Clear highlight
		if selected_maskPiece.has_method("set_selected"):
			selected_maskPiece.set_selected(false)
		var old_parent = selected_maskPiece.get_parent()
		# If target slot already has a piece, swap: move it to selected piece's old slot
		if maskSlot.get_child_count() > 0:
			var existing_piece = maskSlot.get_child(0)
			maskSlot.remove_child(existing_piece)
			old_parent.add_child(existing_piece)
		old_parent.remove_child(selected_maskPiece)
		maskSlot.add_child(selected_maskPiece)
		selected_maskPiece = null
		_UpdateEffects()

func _on_bttn_start_pressed():
	get_tree().change_scene_to_file("res://day.tscn")

func _UpdateEffects():
	var all_slots = []
	all_slots += $Panel_Mask/HBox_Mask/VBox_Left.get_children()
	all_slots += $Panel_Mask/HBox_Mask/VBox_Right.get_children()
	
	var followers = 0
	var timeInDay = 0
	var heretics = 0
	var offerings = 0
	
	for maskSlot in all_slots:
		# A mask piece is in the slot
		var piece = maskSlot.get_child(0)
		if piece != null and piece.mask_piece_data != null:
			followers += piece.mask_piece_data.followers
			timeInDay += piece.mask_piece_data.time_in_day
			heretics += piece.mask_piece_data.heretics
			offerings += piece.mask_piece_data.offerings
	
	$Panel_Effects/VBox_Effects/Lbl_Effect_1.text = "Followers: " + str(followers)
	$Panel_Effects/VBox_Effects/Lbl_Effect_2.text = "Time In Day: " + str(timeInDay)
	$Panel_Effects/VBox_Effects/Lbl_Effect_3.text = "Heretics: " + str(heretics)
	$Panel_Effects/VBox_Effects/Lbl_Effect_4.text = "Offerings: " + str(offerings)
	$Panel_Effects/VBox_Effects/Lbl_Current_Round.text = "Current Round: " + str(current_round)
