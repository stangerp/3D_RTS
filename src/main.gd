extends Node


var _last_idx = -1


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("request_jump"):
		var requester = _get_requester()
		requester.request_jump()
	if event.is_action_pressed("camera_freeze"):
		Events.emit_signal("toggle_camera_freeze_requested")


func _get_requester() -> JumpRequester:
	var requesters = get_tree().get_nodes_in_group("jump_requesters")
	var num_requesters = requesters.size()
	var new_idx = randi() % num_requesters
	
	if new_idx == _last_idx:
		new_idx = (new_idx + 1) % num_requesters
	_last_idx = new_idx
	
	return requesters[new_idx]
