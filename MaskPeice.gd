extends Control
@export var followers: int = 0
@export var equipableSlots  = [false, false, false, false, false, false]
@export var mask_piece_data : Mask_Piece_Data

var hovering: bool = false
var dragging: bool = true

var oldZIndex: int
var id = randi_range(1, 1000)
var _highlight: ColorRect = null

signal selected(maskPiece)

# Called when the node enters the scene tree for the first time.
func _ready():
	layout_mode = 1		#layout mode = anchors
	anchors_preset = PRESET_FULL_RECT    #anchors preset = full rect
	_highlight = get_node_or_null("Highlight")
	if _highlight:
		_highlight.visible = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_mouse_entered():
	oldZIndex = z_index
	z_index = 21
	scale.x = 1.2
	scale.y = 1.2
	_togglePanel(true)
	
func _on_mouse_exited():
	z_index = oldZIndex
	scale.x = 1
	scale.y = 1
	_togglePanel(false)
	

func _togglePanel(value):
	var panel = get_node("Panel")	
	panel.visible = value
	if mask_piece_data == null:
		panel.get_child(0).text = "Unknown piece"
		return
	var tooltip_text = mask_piece_data.piece
	if mask_piece_data.heretics != 0:
		tooltip_text += "\n" + "Heretics: " + str(mask_piece_data.heretics)
	if mask_piece_data.time_in_day != 0:
		tooltip_text += "\n" + "Time In Day: " + str(mask_piece_data.time_in_day)
	if mask_piece_data.followers != 0:
		tooltip_text += "\n" + "Followers: " + str(mask_piece_data.followers)
	if mask_piece_data.offerings != 0:
		tooltip_text += "\n" + "Offerings: " + str(mask_piece_data.offerings)
	panel.get_child(0).text = tooltip_text
	


func set_selected(is_selected: bool) -> void:
	if _highlight:
		_highlight.visible = is_selected


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("clicked mask")
		selected.emit()
