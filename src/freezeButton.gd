extends Button

var _is_frozen = false


func _on_Button_pressed() -> void:
	if _is_frozen:
		Events.emit_signal("camera_unfreeze_requested")
	else:
		Events.emit_signal("camera_freeze_requested")
	_is_frozen = !_is_frozen
