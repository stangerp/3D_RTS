extends Spatial


#############################
# EXPORT PARAMS
#############################
# movement params
export (float,0,1000) var movement_speed = 20
# rotation
export (int, 0, 90) var min_elevation_angle = 10
export (int, 0, 90) var max_elevation_angle = 90
export (float, 0, 1000, 0.1) var rotation_speed = 20
# zoom
export (int, 0, 1000) var min_zoom = 10
export (int, 0, 1000) var max_zoom = 90
export (float, 0, 1000, 0.1) var zoom_speed = 10
export (float, 0, 1, 0.1) var zoom_speed_damp = 0.5
# flags
export (bool) var allow_rotation = true
export (bool) var inverted_y = false
export (bool) var zoom_to_cursor = false


#############################
# PARAMS
#############################
# movement
var _last_mouse_position = Vector2()
var _is_rotating = false
onready var elevation = $Elevation
# zoom
var _zoom_direction = 0
onready var camera = $Elevation/Camera
const PLANE = Plane(Vector3.UP, 0)
const RAY_LENGTH = 1000


#############################
# OVERRIDE FUNCTIONS
#############################
func _process(delta: float) -> void:
	_move(delta)
	_rotate(delta)
	_zoom(delta)
	
func _unhandled_input(event: InputEvent) -> void:
	# test if we are rotating
	if event.is_action_pressed("camera_rotate"):
		_is_rotating = true
		_last_mouse_position = get_viewport().get_mouse_position()
	if event.is_action_released("camera_rotate"):
		_is_rotating = false
	# test if we are zooming
	if event.is_action_pressed("camera_zoom_in"):
		_zoom_direction = -1
	if event.is_action_pressed("camera_zoom_out"):
		_zoom_direction = 1
	



##############################
# MOVEMENT FUNCTIONS
##############################
func _move(delta: float) -> void:
	# initialise a velocity vector
	var velocity = Vector3()
	# populate it
	if Input.is_action_pressed("camera_forward"):
		velocity -= transform.basis.z
	if Input.is_action_pressed("camera_backward"):
		velocity += transform.basis.z
	if Input.is_action_pressed("camera_left"):
		velocity -= transform.basis.x
	if Input.is_action_pressed("camera_right"):
		velocity += transform.basis.x
	velocity = velocity.normalized()
	# translate
	translation += velocity * delta * movement_speed


func _rotate(delta: float) -> void:
	if not _is_rotating or not allow_rotation:
		return
	# calculate mouse movement
	var displacement = _get_mouse_displacement()
	# use the horizontal displacement to rotate
	_rotate_left_right(delta,displacement.x)
	# use the vertical displacement to elevate
	_elevate(delta, displacement.y)


func _zoom(delta: float) -> void:
	# calculate the new zoom and clamp it between min and max zoom
	var new_zoom = clamp(
		camera.translation.z + zoom_speed * delta * _zoom_direction,
		min_zoom,
		max_zoom
		)
	# save 3d position
	var pointing_at = _get_plane_click_location()
	# zoom
	camera.translation.z = new_zoom
	# move the camera such that we are pointing at the same location
	if zoom_to_cursor and pointing_at != null:
		_realign_camera(pointing_at)
	# stop scrolling
	_zoom_direction *= zoom_speed_damp
	if abs(_zoom_direction) <= 0.0001:
		_zoom_direction = 0


###########################
# HELPER FUNCTIONS
###########################
func _get_mouse_displacement() -> Vector2:
	var current_mouse_position = get_viewport().get_mouse_position()
	var displacement = current_mouse_position - _last_mouse_position
	_last_mouse_position = current_mouse_position
	return displacement


func _rotate_left_right(delta: float, val: float) -> void:
	rotation_degrees.y += val * delta * rotation_speed


func _elevate(delta: float, val: float) -> void:
	# calculate new elevation
	var new_elevation = elevation.rotation_degrees.x
	if inverted_y:
		new_elevation += val * delta * rotation_speed
	else:
		new_elevation -= val * delta * rotation_speed
		
	# clamp the new elevation
	new_elevation = clamp(
		new_elevation,
		-max_elevation_angle,
		-min_elevation_angle
	)
	# set the new elevation based on the clamped value
	elevation.rotation_degrees.x = new_elevation


func _get_plane_click_location() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = camera.project_ray_origin(mouse_pos)
	var ray_to = ray_from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	return PLANE.intersects_ray(ray_from, ray_to)


func _realign_camera(location: Vector3) -> void:
	# calculate where we need to move
	var new_location = _get_plane_click_location()
	var displacement = location - new_location
	# move the camera based on that calculation
	translation += displacement
