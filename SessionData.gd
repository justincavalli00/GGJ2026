extends Node
## Autoload: holds the mask built by the player and current round.
## Mask builder writes here when starting the day; day scene reads for totem display and results.

var current_round: int = 1
var built_mask_pieces: Array = []  # Array of Mask_Piece_Data (one per slot, null if empty)
# Slot order matches mask builder: Left_Top, Left_Mid, Left_Bottom, Right_Top, Right_Mid, Right_Bottom

const REQUIRED_PER_ROUND: Array = [2, 10, 50, 250, 500, 1000]  # round 1..6

var _cached_followers_total: int = -999
var _cached_base_followers: int = -999
var _cached_multiplier_display: String = ""
var _cached_followers_breakdown: Array[String] = []

func get_required_followers() -> int:
	var idx := clampi(current_round - 1, 0, REQUIRED_PER_ROUND.size() - 1)
	return REQUIRED_PER_ROUND[idx]

func clear_followers_cache() -> void:
	_cached_followers_total = -999
	_cached_base_followers = -999
	_cached_multiplier_display = ""
	_cached_followers_breakdown.clear()

func get_followers_added() -> int:
	if _cached_followers_total != -999:
		return _cached_followers_total
	_cached_followers_breakdown.clear()
	print("[SessionData] --- Follower calculation ---")
	# Sum raw followers from all pieces
	var total_raw := 0
	for i in range(built_mask_pieces.size()):
		var data = built_mask_pieces[i]
		if data is Mask_Piece_Data:
			total_raw += data.followers
			print("[SessionData]   Piece %d '%s': followers=%d (running sum=%d)" % [i, data.piece, data.followers, total_raw])
	print("[SessionData]   Base total (no multiplier): %d" % total_raw)
	# One round multiplier (e.g. coin flip from piece with multiplier_random)
	var factor: float = _get_round_multiplier()
	var result: int = int(floor(total_raw * factor))
	print("[SessionData]   Final factor: %s -> result: floor(%d * %s) = %d" % [_multiplier_display(factor), total_raw, str(factor), result])
	print("[SessionData] --- End calculation ---")
	_cached_followers_total = result
	_cached_base_followers = total_raw
	_cached_multiplier_display = _multiplier_display(factor)
	if factor != 1.0:
		_cached_followers_breakdown.append("%d x %s → %d" % [total_raw, _cached_multiplier_display, result])
	return result

func _get_round_multiplier() -> float:
	var factor: float = 1.0
	var flip_index: int = 0
	for data in built_mask_pieces:
		if data is Mask_Piece_Data and data.multiplier_random.size() > 0:
			var piece_mult: float = data.get_follower_multiplier()
			factor *= piece_mult
			var mult_str: String = _multiplier_display(piece_mult)
			print("[SessionData]   Coin flip %d '%s': %sx -> factor now %s" % [flip_index, data.piece, mult_str, str(factor)])
			flip_index += 1
	if flip_index == 0:
		print("[SessionData]   No coin-flip pieces, factor stays 1.0")
	return factor

func _multiplier_display(factor: float) -> String:
	if factor >= 1.99 and factor <= 2.01:
		return "2"
	if factor >= 2.99 and factor <= 3.01:
		return "3"
	if factor >= 3.99 and factor <= 4.01:
		return "4"
	if factor >= 0.49 and factor <= 0.51:
		return "0.5"
	if factor >= 0.24 and factor <= 0.26:
		return "0.25"
	if factor >= 0.99 and factor <= 1.01:
		return "1"
	return str(factor)

func get_followers_breakdown() -> Array[String]:
	if _cached_followers_total == -999:
		get_followers_added()
	return _cached_followers_breakdown

func get_base_followers() -> int:
	if _cached_followers_total == -999:
		get_followers_added()
	return _cached_base_followers

func get_multiplier_display() -> String:
	if _cached_followers_total == -999:
		get_followers_added()
	return _cached_multiplier_display if _cached_multiplier_display != "" else "1"

func clear_mask() -> void:
	built_mask_pieces.clear()
	clear_followers_cache()
