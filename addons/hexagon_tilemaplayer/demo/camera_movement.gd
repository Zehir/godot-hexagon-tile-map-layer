extends Camera2D

var is_camera_panning: bool = false

const ZOOM_MIN = 0.2
const ZOOM_MAX = 1.5
const ZOOM_SPEED = 10

enum FocusSide {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	MIDDLE_LEFT,
	MIDDLE_CENTER,
	MIDDLE_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT,
}

var is_zooming: bool = false
var target_zoom: Vector2:
	get:
		return target_zoom
	set(value):
		is_zooming = true
		target_zoom = value.clampf(ZOOM_MIN, ZOOM_MAX)
		if is_equal_approx(target_zoom.x, 1.0):
			target_zoom.x = 1
			target_zoom.y = 1


func _ready() -> void:
	target_zoom = zoom


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
			target_zoom *= 0.9
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom *= 1.1


func _process(delta: float) -> void:
	if not is_zooming:
		return

	if zoom.is_equal_approx(target_zoom):
		is_zooming = false
		zoom = target_zoom
	else:
		zoom = zoom.slerp(target_zoom, ZOOM_SPEED * delta)


func focus_tile(
	target: Vector2,
	focus_side: FocusSide = FocusSide.MIDDLE_CENTER,
	focus_ratio: Vector2 = Vector2(0.25, 0.25)
) -> void:
	position = get_focus_position(target, focus_side, focus_ratio)


func get_focus_position(
	target: Vector2,
	focus_side: FocusSide = FocusSide.MIDDLE_CENTER,
	focus_ratio: Vector2 = Vector2(0.25, 0.25)
) -> Vector2:
	var result = Vector2(target)
	var viewport_size = get_viewport().get_visible_rect().size
	match focus_side:
		FocusSide.TOP_LEFT, FocusSide.MIDDLE_LEFT, FocusSide.BOTTOM_LEFT:
			result.x += viewport_size.x * focus_ratio.x / zoom.x
		FocusSide.TOP_RIGHT, FocusSide.MIDDLE_RIGHT, FocusSide.BOTTOM_RIGHT:
			result.x -= viewport_size.x * focus_ratio.x / zoom.x

	match focus_side:
		FocusSide.TOP_LEFT, FocusSide.TOP_CENTER, FocusSide.TOP_RIGHT:
			result.y += viewport_size.y * focus_ratio.y / zoom.y
		FocusSide.BOTTOM_LEFT, FocusSide.BOTTOM_CENTER, FocusSide.BOTTOM_RIGHT:
			result.y -= viewport_size.y * focus_ratio.y / zoom.y

	return result
