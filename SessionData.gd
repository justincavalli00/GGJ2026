extends Node
## Autoload: holds the mask built by the player and current round.
## Mask builder writes here when starting the day; day scene reads for totem display and results.

var current_round: int = 1
var built_mask_pieces: Array = []  # Array of Mask_Piece_Data (one per slot, null if empty)
# Slot order matches mask builder: Left_Top, Left_Mid, Left_Bottom, Right_Top, Right_Mid, Right_Bottom

const REQUIRED_PER_ROUND: Array = [2, 10, 50, 250, 500, 1000]  # round 1..6

func get_required_followers() -> int:
	var idx := clampi(current_round - 1, 0, REQUIRED_PER_ROUND.size() - 1)
	return REQUIRED_PER_ROUND[idx]

func get_followers_added() -> int:
	var total := 0
	for data in built_mask_pieces:
		if data is Mask_Piece_Data:
			total += data.followers
	return total

func clear_mask() -> void:
	built_mask_pieces.clear()
