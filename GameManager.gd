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
	
func _on_slot_clicked(maskSlot):
	if (selected_maskPiece):
		selected_maskPiece.get_parent().remove_child(selected_maskPiece)
		maskSlot.add_child(selected_maskPiece)	



func _on_bttn_start_pressed():
	_drawCards()
