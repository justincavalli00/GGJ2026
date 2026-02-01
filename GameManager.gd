extends Control

const MASK_DATA_PATH := "res://mask_data/"

@export var drawCount : int
var MaskScene
var selected_maskPiece: Control = null
var _mask_piece_data_list: Array[Mask_Piece_Data] = []
var current_round: int = 1
var _session: Node = null  # SessionData autoload, set in _ready()

# Called when the node enters the scene tree for the first time.
func _ready():
	_session = get_node_or_null("/root/SessionData")
	if _session == null:
		push_error("GameManager: SessionData autoload not found")
	else:
		current_round = _session.current_round
	MaskScene = preload("res://mask_piece.tscn")
	_load_mask_piece_data()
	_drawCards()

	var all_slots = _get_all_mask_slots()
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

func _get_all_mask_slots() -> Array:
	var all_slots: Array = []
	all_slots.append_array($Panel_Mask/HBox_Mask/VBox_Left.get_children())
	all_slots.append_array($Panel_Mask/HBox_Mask/VBox_Right.get_children())
	return all_slots

func _drawCards():
	var all_slots := _get_all_mask_slots()
	# Restore mask from previous round (persistent across rounds on win)
	var built: Array = _session.built_mask_pieces if _session else []
	for i in range(min(built.size(), all_slots.size())):
		var data = built[i]
		if data is Mask_Piece_Data:
			var mask_piece = MaskScene.instantiate()
			mask_piece.mask_piece_data = data
			var slot = all_slots[i]
			slot.add_child(mask_piece)
	# Each round: 3 new offerings
	for x in range(1, drawCount + 1):
		var mask_piece = generate_mask_piece()
		var offering = get_node("Panel_Offerings/HBox_Offering/Offering_" + str(x))
		offering.add_child(mask_piece)
	# Connect selected signal for all pieces (mask + offerings)
	for slot in all_slots:
		if slot.get_child_count() > 0:
			var piece = slot.get_child(0)
			if piece.has_signal("selected"):
				piece.selected.connect(_on_maskPiece_selected.bind(piece))
	for offering in $Panel_Offerings/HBox_Offering.get_children():
		if offering.get_child_count() > 0:
			var piece = offering.get_child(0)
			if piece.has_signal("selected"):
				piece.selected.connect(_on_maskPiece_selected.bind(piece))
		
func _is_placed(piece: Control) -> bool:
	if piece == null:
		return false
	var parent = piece.get_parent()
	return parent != null and parent.get_parent() is VBoxContainer

func _is_in_offering(piece: Control) -> bool:
	if piece == null:
		return false
	var parent = piece.get_parent()
	return parent != null and parent.get_parent() is HBoxContainer

func _on_maskPiece_selected(maskPiece):
	# Clicking a different piece while one is selected
	if selected_maskPiece and selected_maskPiece != maskPiece:
		# Both placed on mask: swap their slots
		if _is_placed(selected_maskPiece) and _is_placed(maskPiece):
			var parent_a = selected_maskPiece.get_parent()
			var parent_b = maskPiece.get_parent()
			parent_a.remove_child(selected_maskPiece)
			parent_b.remove_child(maskPiece)
			parent_a.add_child(maskPiece)
			parent_b.add_child(selected_maskPiece)
			if selected_maskPiece.has_method("set_selected"):
				selected_maskPiece.set_selected(false)
			selected_maskPiece = null
			_UpdateEffects()
			return
		# Selected from offering, clicked placed piece: replace (offering piece goes to mask, placed piece is removed)
		if _is_in_offering(selected_maskPiece) and _is_placed(maskPiece):
			var offering_slot = selected_maskPiece.get_parent()
			var mask_slot = maskPiece.get_parent()
			mask_slot.remove_child(maskPiece)
			maskPiece.queue_free()
			offering_slot.remove_child(selected_maskPiece)
			mask_slot.add_child(selected_maskPiece)
			if selected_maskPiece.has_method("set_selected"):
				selected_maskPiece.set_selected(false)
			selected_maskPiece = null
			_UpdateEffects()
			return
		# Otherwise (e.g. selected placed, clicked offering): just select the clicked piece below
	# Clicking the same piece again: deselect
	if selected_maskPiece == maskPiece:
		if selected_maskPiece.has_method("set_selected"):
			selected_maskPiece.set_selected(false)
		selected_maskPiece = null
		return
	# No selection or new selection: select the clicked piece
	if selected_maskPiece and is_instance_valid(selected_maskPiece):
		if selected_maskPiece.has_method("set_selected"):
			selected_maskPiece.set_selected(false)
	selected_maskPiece = maskPiece
	if maskPiece.has_method("set_selected"):
		maskPiece.set_selected(true)
	
func _on_slot_clicked(maskSlot):
	if selected_maskPiece:
		# Clear highlight
		if selected_maskPiece.has_method("set_selected"):
			selected_maskPiece.set_selected(false)
		var old_parent = selected_maskPiece.get_parent()
		# If target slot already has a piece: from offering = replace (old piece goes to offering); from mask = swap slots
		if maskSlot.get_child_count() > 0:
			var existing_piece = maskSlot.get_child(0)
			maskSlot.remove_child(existing_piece)
			old_parent.add_child(existing_piece)  # offering slot or mask slot
		old_parent.remove_child(selected_maskPiece)
		maskSlot.add_child(selected_maskPiece)
		selected_maskPiece = null
		_UpdateEffects()

func _on_bttn_start_pressed():
	if _session == null:
		return
	# Store built mask for day scene (totem display + results)
	_session.built_mask_pieces.clear()
	_session.clear_followers_cache()
	var all_slots = _get_all_mask_slots()
	for maskSlot in all_slots:
		var piece = maskSlot.get_child(0) if maskSlot.get_child_count() > 0 else null
		var data: Mask_Piece_Data = piece.mask_piece_data if piece != null and piece.get("mask_piece_data") != null else null
		_session.built_mask_pieces.append(data)
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
