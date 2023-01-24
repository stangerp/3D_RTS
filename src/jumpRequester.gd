extends Spatial
class_name JumpRequester


export (float, 0.1, 5, 0.1) var duration = 1


func _ready() -> void:
	add_to_group("jump_requesters")


func request_jump() -> void:
	Events.emit_signal("camera_jump_requested", translation, duration)
