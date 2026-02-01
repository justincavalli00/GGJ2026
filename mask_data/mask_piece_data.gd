class_name Mask_Piece_Data extends Resource

@export_category("Mask Piece Properties")
@export var piece : String
@export var followers : int
@export_flags("Top Left", "Top Right", "Middle Left", "Middle Right", "Bottom Left", "Bottom Right") var position : int
@export var time_in_day : float
@export var heretics : int
@export var offerings : int
@export var mask_piece_sprite: Texture2D
@export var effect :String
@export_enum("Unassigned", "Wooden", "Iron", "Cursed") var mask_type:int

#DONE: ADD TYPE
