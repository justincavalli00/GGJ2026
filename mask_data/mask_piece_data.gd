class_name Mask_Piece_Data extends Resource

@export_category("Mask Piece Properties")
@export var piece : String
@export var followers : int
@export_flags("Top Left", "Top Right", "Middle Left", "Middle Right", "Bottom Left", "Bottom Right") var position : int
@export var time_in_day : float
@export var heretics : int
@export var offerings : int
@export var mask_piece_sprite: Texture2D
@export_flags("Round 1", "Round 2", "Round 3", "Round 4", "Round 5", "Round 6") var available_in_round : int
@export var effect : String = ""
@export var mask_type : int = 0
## Multiplier applied to follower count at result time. null/0 = none, 2 = 2x, 3 = 3x, -2 = half.
@export var multiplier: int = 0
## If non-empty, one value is chosen at random each round as multiplier (e.g. [ -2, 2 ] for 50% half, 50% double).
@export var multiplier_random: Array = []

func get_follower_multiplier() -> float:
	var value: int = 0
	if multiplier_random.size() > 0:
		value = multiplier_random[randi() % multiplier_random.size()]
	elif multiplier != 0:
		value = multiplier
	else:
		return 1.0
	match value:
		2: return 2.0
		3: return 3.0
		-2: return 0.5
		_: return 1.0
