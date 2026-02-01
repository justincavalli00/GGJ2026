extends Control
@export var followers: int = 0
@export var equipableSlots  = [false, false, false, false, false, false]

var hovering: bool = false
var dragging: bool = true

var oldZIndex: int
var id = randi_range(1, 1000)

signal selected(maskPiece)

# Called when the node enters the scene tree for the first time.
func _ready():
	layout_mode = 1		#layout mode = anchors
	anchors_preset = PRESET_FULL_RECT    #anchors preset = full rect
	

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
	panel.get_child(0).text = "Name" + str(id)
	


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("clicked mask")
		selected.emit()
