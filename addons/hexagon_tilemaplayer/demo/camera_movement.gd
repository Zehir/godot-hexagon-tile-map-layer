extends Camera2D

var is_camera_panning: bool = false


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				is_camera_panning = true
			elif event.is_released():
				is_camera_panning = false

	if is_camera_panning and event is InputEventMouseMotion:
		position -= (event as InputEventMouseMotion).relative / zoom.x

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom *= 0.9
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= 1.1
