extends Control
@export var followers: int = 0
@export var equipableSlots  = [false, false, false, false, false, false]
@export var mask_piece_data : Mask_Piece_Data

var hovering: bool = false
var dragging: bool = true

var oldZIndex: int
var id = randi_range(1, 1000)
var _highlight: ColorRect = null
var _close_timer: Timer = null
const TOOLTIP_CLOSE_DELAY := 0.15
const TOOLTIP_WIDTH := 260
const TOOLTIP_HEIGHT := 160

signal selected(maskPiece)

# Called when the node enters the scene tree for the first time.
func _ready():
	layout_mode = 1		#layout mode = anchors
	anchors_preset = PRESET_FULL_RECT    #anchors preset = full rect
	_highlight = get_node_or_null("Highlight")
	if _highlight:
		_highlight.visible = false
	var icon = get_node_or_null("Icon")
	if icon is TextureRect:
		# Fit texture inside container regardless of texture size (no overflow from larger art)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_apply_texture_from_data()
	# Deferred close timer so we can keep tooltip open when hovering over the panel
	_close_timer = Timer.new()
	_close_timer.one_shot = true
	_close_timer.wait_time = TOOLTIP_CLOSE_DELAY
	_close_timer.timeout.connect(_delayed_close_tooltip)
	add_child(_close_timer)
	var panel = get_node("Panel")
	panel.mouse_entered.connect(_on_panel_mouse_entered)
	panel.mouse_exited.connect(_on_panel_mouse_exited)


func _apply_texture_from_data() -> void:
	if mask_piece_data == null:
		return
	var icon = get_node_or_null("Icon")
	if icon is TextureRect and mask_piece_data.mask_piece_sprite != null:
		icon.texture = mask_piece_data.mask_piece_sprite
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_mouse_entered():
	_close_timer.stop()
	oldZIndex = z_index
	z_index = 21
	scale.x = 1.2
	scale.y = 1.2
	_togglePanel(true)

func _on_mouse_exited():
	_close_timer.start()

func _on_panel_mouse_entered():
	_close_timer.stop()
	_togglePanel(true)

func _on_panel_mouse_exited():
	_close_timer.start()

func _delayed_close_tooltip():
	z_index = oldZIndex
	scale.x = 1
	scale.y = 1
	_togglePanel(false)
	

func _is_in_offerings() -> bool:
	var n = get_parent()
	while n:
		if n.name == "HBox_Offering" or n.name == "Panel_Offerings":
			return true
		n = n.get_parent()
	return false

func _is_tooltip_on_left() -> bool:
	# Mask grid: left column = VBox_Left, right column = VBox_Right
	var n = get_parent()
	while n:
		if n.name == "VBox_Left":
			return true
		if n.name == "VBox_Right":
			return false
		n = n.get_parent()
	# Other (shouldn't happen if offerings handled): use global position
	var viewport_width = get_viewport().get_visible_rect().size.x
	var center_x = get_global_rect().get_center().x
	return center_x < viewport_width * 0.5

func _apply_tooltip_side(panel: Control) -> void:
	if _is_in_offerings():
		# Offerings: tooltip above the piece (centered)
		panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
		panel.offset_left = -TOOLTIP_WIDTH / 2
		panel.offset_top = -TOOLTIP_HEIGHT
		panel.offset_right = TOOLTIP_WIDTH / 2
		panel.offset_bottom = -20
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		panel.grow_vertical = Control.GROW_DIRECTION_END
		return
	var on_left := _is_tooltip_on_left()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT if on_left else Control.PRESET_TOP_RIGHT)
	if on_left:
		panel.offset_left = -TOOLTIP_WIDTH
		panel.offset_top = -TOOLTIP_HEIGHT
		panel.offset_right = 0
		panel.offset_bottom = -20
	else:
		panel.offset_left = 0
		panel.offset_top = -TOOLTIP_HEIGHT
		panel.offset_right = TOOLTIP_WIDTH
		panel.offset_bottom = -20
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN if on_left else Control.GROW_DIRECTION_END
	panel.grow_vertical = Control.GROW_DIRECTION_END

func _togglePanel(value):
	var panel = get_node("Panel")
	panel.visible = value
	if not value:
		return
	_apply_tooltip_side(panel)
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
	if mask_piece_data.effect != "":
		tooltip_text += "\n" + mask_piece_data.effect
	panel.get_child(0).text = tooltip_text
	


func set_selected(is_selected: bool) -> void:
	if _highlight:
		_highlight.visible = is_selected


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("clicked mask")
		selected.emit()

func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit()
