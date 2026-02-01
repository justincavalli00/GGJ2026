extends Node
## Autoload: holds the mask built by the player for the current round.
## Mask builder writes here when starting the day; day scene reads for totem display and results.

var built_mask_pieces: Array = []  # Array of Mask_Piece_Data (one per slot, null if empty)
# Slot order matches mask builder: Left_Top, Left_Mid, Left_Bottom, Right_Top, Right_Mid, Right_Bottom

func get_followers_added() -> int:
	var total := 0
	for data in built_mask_pieces:
		if data is Mask_Piece_Data:
			total += data.followers
	return total

func clear_mask() -> void:
	built_mask_pieces.clear()
