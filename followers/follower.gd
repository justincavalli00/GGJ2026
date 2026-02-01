extends Node2D

var target_position: Vector2
var personal_space: float = 250.0  # Minimum distance from others
var move_speed : float = 20.0

func _process(delta: float) -> void:
	# Move toward target
	var direction = (target_position - global_position).normalized()
	
	# Check nearby followers and push away if too close
	var push_away = Vector2.ZERO
	var followers = get_tree().get_nodes_in_group("followers")
	
	for follower in followers:
		if follower == self:
			continue
		
		var distance = global_position.distance_to(follower.global_position)
		
		# If too close, push away
		if distance < personal_space and distance > 0:
			var away = (global_position - follower.global_position).normalized()
			push_away += away * (personal_space - distance) / personal_space
	
	# Combine target direction with push away
	var final_direction = (direction + push_away).normalized()
	global_position += final_direction * move_speed * delta  # Adjust speed as needed

func Set_Target(pos: Vector2):
	target_position = pos
