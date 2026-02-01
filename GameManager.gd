extends Control

@export var drawCount : int
var MaskScene
var selected_maskPiece: Control = null

# Called when the node enters the scene tree for the first time.
func _ready():
	MaskScene = preload("res://mask_piece.tscn")
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

func _drawCards():
	for x in range(1, drawCount + 1):
		var maskPiece = MaskScene.instantiate()
		var offering = get_node("Panel_Offerings/HBox_Offering/Offering_" + str(x))
		offering.add_child(maskPiece)
	
	for offering in $Panel_Offerings/HBox_Offering.get_children():
		var maskPiece = offering.get_child(0)
		if maskPiece != null:
			maskPiece.selected.connect(_on_maskPiece_selected.bind(maskPiece))
		
func _on_maskPiece_selected(maskPiece):
	# if selecting mask from offering
	if maskPiece.get_parent().get_parent() is HBoxContainer:
		selected_maskPiece = maskPiece
	
	# swapping mask piece
	if maskPiece.get_parent().get_parent() is VBoxContainer and selected_maskPiece:
		var maskSlot = maskPiece.get_parent()
		maskSlot.remove_child(maskPiece)
		selected_maskPiece.get_parent().remove_child(selected_maskPiece)
		maskSlot.add_child(selected_maskPiece)
		_UpdateEffects()
	
func _on_slot_clicked(maskSlot):
	if (selected_maskPiece):
		selected_maskPiece.get_parent().remove_child(selected_maskPiece)
		maskSlot.add_child(selected_maskPiece)
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
		if maskSlot.get_child(0) != null:
			followers += maskSlot.get_child(0).mask_piece_data.followers
			timeInDay += maskSlot.get_child(0).mask_piece_data.time_in_day
			heretics += maskSlot.get_child(0).mask_piece_data.heretics
			offerings += maskSlot.get_child(0).mask_piece_data.offerings
	
	$Panel_Effects/VBox_Effects/Lbl_Effect_1.text = "Followers: " + str(followers)
	$Panel_Effects/VBox_Effects/Lbl_Effect_2.text = "Time In Day: " + str(timeInDay)
	$Panel_Effects/VBox_Effects/Lbl_Effect_3.text = "Heretics: " + str(heretics)
	$Panel_Effects/VBox_Effects/Lbl_Effect_4.text = "Offerings: " + str(offerings)
