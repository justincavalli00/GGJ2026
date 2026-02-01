extends Node
## Autoload: holds the mask built by the player and current round.
## Mask builder writes here when starting the day; day scene reads for totem display and results.

var current_round: int = 1
var built_mask_pieces: Array = []  # Array of Mask_Piece_Data (one per slot, null if empty)
# Slot order matches mask builder: Left_Top, Left_Mid, Left_Bottom, Right_Top, Right_Mid, Right_Bottom

const REQUIRED_PER_ROUND: Array = [2, 10, 50, 250, 500, 1000]  # round 1..6

# 2x3 grid slot indices: 0=Left_Top, 1=Left_Mid, 2=Left_Bottom, 3=Right_Top, 4=Right_Mid, 5=Right_Bottom
# Pairs that share a side (adjacent)
const SLOT_ADJACENCY: Array = [
	[1, 3],       # 0: below, right
	[0, 2, 4],    # 1: above, below, right
	[1, 5],       # 2: above, right
	[0, 4],       # 3: left, below
	[1, 3, 5],    # 4: left, above, below
	[2, 4],       # 5: left, above
]

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
	_log_results_header()
	# Sum raw followers from all pieces
	var total_raw := 0
	for i in range(built_mask_pieces.size()):
		var data = built_mask_pieces[i]
		if data is Mask_Piece_Data:
			total_raw += data.followers
			print("[SessionData]   [slot %d] '%s' type=%d followers=%d (sum=%d)" % [i, data.piece, data.mask_type, data.followers, total_raw])
		else:
			print("[SessionData]   [slot %d] (empty)" % i)
	print("[SessionData]   -> Base total (no multiplier): %d" % total_raw)
	# Round multiplier (e.g. coin flip) and synergy (same-type adjacent pieces)
	var round_mult: float = _get_round_multiplier()
	var synergy_mult: float = _get_synergy_multiplier()
	var factor: float = round_mult * synergy_mult
	var result: int = int(floor(total_raw * factor))
	print("[SessionData]   Multipliers: round=%s x synergy=%s = %s" % [str(round_mult), str(synergy_mult), _multiplier_display(factor)])
	print("[SessionData]   -> Result: floor(%d x %s) = %d" % [total_raw, str(factor), result])
	_log_results_footer()
	_cached_followers_total = result
	_cached_base_followers = total_raw
	_cached_multiplier_display = _multiplier_display(factor)
	if factor != 1.0:
		_cached_followers_breakdown.append("%d x %s → %d" % [total_raw, _cached_multiplier_display, result])
	return result

func _log_results_header() -> void:
	print("[SessionData] ========== RESULTS (follower calculation) ==========")
	print("[SessionData] Mask grid (slot order: Left_Top, Left_Mid, Left_Bottom, Right_Top, Right_Mid, Right_Bottom):")

func _log_results_footer() -> void:
	print("[SessionData] ==================================================")

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
		print("[SessionData]   Round multiplier: no coin-flip pieces -> 1.0")
	else:
		print("[SessionData]   Round multiplier: %s (from %d piece(s))" % [str(factor), flip_index])
	return factor

## Synergy: same-type adjacent groups each give synergy_multiplier^(N-1); multiple groups multiply.
func _get_synergy_multiplier() -> float:
	return _compute_synergy_from_pieces(built_mask_pieces)

## Same synergy logic for an arbitrary pieces array (e.g. current mask in builder). Used by mask builder UI.
func get_synergy_multiplier_for_pieces(pieces: Array) -> float:
	return _compute_synergy_from_pieces(pieces)

func get_synergy_display_for_pieces(pieces: Array) -> String:
	var mult: float = get_synergy_multiplier_for_pieces(pieces)
	return _multiplier_display(mult) + "x"

func _compute_synergy_from_pieces(pieces: Array) -> float:
	# slot_index -> piece data (only filled slots)
	var slot_data: Dictionary = {}
	for i in range(min(pieces.size(), SLOT_ADJACENCY.size())):
		var data = pieces[i]
		if data is Mask_Piece_Data:
			slot_data[i] = data
	if slot_data.size() < 2:
		if slot_data.size() == 1 and pieces == built_mask_pieces:
			print("[SessionData]   Synergy: only 1 piece -> no bonus (1x)")
		return 1.0
	# Find all connected components of same type; each group contributes base^(N-1), multiply together
	var visited: Dictionary = {}
	for slot in slot_data:
		visited[slot] = false
	var total_synergy: float = 1.0
	var is_results_calc: bool = (pieces == built_mask_pieces)
	for start in slot_data:
		if visited[start]:
			continue
		var data: Mask_Piece_Data = slot_data[start]
		var t: int = data.mask_type
		var base: float = data.synergy_multiplier
		var component: Array = []
		var stack: Array = [start]
		while stack.size() > 0:
			var cur: int = stack.pop_back()
			if visited[cur]:
				continue
			var cur_data: Mask_Piece_Data = slot_data[cur]
			if cur_data.mask_type != t:
				continue
			visited[cur] = true
			component.append(cur)
			for adj in SLOT_ADJACENCY[cur]:
				if slot_data.has(adj) and not visited[adj] and slot_data[adj].mask_type == t:
					stack.append(adj)
		if component.size() >= 2:
			var group_mult: float = pow(base, component.size() - 1)
			total_synergy *= group_mult
			if is_results_calc:
				print("[SessionData]   Synergy: type %d slots %s (size %d) base %.1f -> %.1fx (total %.1fx)" % [t, str(component), component.size(), base, group_mult, total_synergy])
	if is_results_calc and total_synergy <= 1.0:
		print("[SessionData]   Synergy: no adjacent same-type -> 1x")
	return total_synergy

func _multiplier_display(factor: float) -> String:
	if factor >= 0.99 and factor <= 1.01:
		return "1"
	if factor >= 1.99 and factor <= 2.01:
		return "2"
	if factor >= 2.99 and factor <= 3.01:
		return "3"
	if factor >= 3.99 and factor <= 4.01:
		return "4"
	if factor >= 7.99 and factor <= 8.01:
		return "8"
	if factor >= 15.99 and factor <= 16.01:
		return "16"
	if factor >= 31.99 and factor <= 32.01:
		return "32"
	if factor >= 0.49 and factor <= 0.51:
		return "0.5"
	if factor >= 0.24 and factor <= 0.26:
		return "0.25"
	# Round to int if close
	var r: int = int(round(factor))
	if abs(float(r) - factor) < 0.02:
		return str(r)
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
