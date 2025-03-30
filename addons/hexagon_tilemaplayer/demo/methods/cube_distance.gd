extends Node

const DemoManager = preload("uid://c5t8k8u70hsgr")
const DemoCamera = preload("uid://t5kjk00fsm7k")

var demo: DemoManager
var line: Line2D


func _init(_demo: DemoManager) -> void:
	demo = _demo
	line = Line2D.new()
	line.width = 10.0
	line.default_color = Color.BLUE
	demo.tile_map.add_child(line)


func _enter_tree() -> void:
	demo.tile_map.hovering_changed.connect(_on_tile_changed)
	tree_exiting.connect(
		demo.tile_map.hovering_changed.disconnect.bind(_on_tile_changed), CONNECT_ONE_SHOT
	)


func _exit_tree() -> void:
	line.queue_free()


func _ready() -> void:
	(
		demo
		. camera_2d
		. focus_tile(
			demo.tile_map.cube_to_local(Vector3i.ZERO),
			DemoCamera.FocusSide.BOTTOM_LEFT,
		)
	)

	if demo.tile_map.tile_set.tile_offset_axis == TileSet.TILE_OFFSET_AXIS_HORIZONTAL:
		demo.tile_map.hovering_tile = Vector3i(6, -3, -3)
	else:
		demo.tile_map.hovering_tile = Vector3i(5, -6, 1)

	_on_tile_changed.call()


func _on_tile_changed() -> void:
	if not demo.tile_map.hovering_tile:
		return

	var label = demo.sample_code
	label.clear()
	line.clear_points()

	label.push_color(Color.from_string("CBCDD0", Color.WHITE))
	label.append_text("[color=C45C6D]var[/color] distance = [color=57B2FF]cube_distance[/color](\n")
	label.push_color(demo.tile_map.PRIMARY_COLOR)
	label.append_text("\tVector3i.ZERO")
	label.pop()
	label.append_text(",\n")
	label.push_color(demo.tile_map.SECONDARY_COLOR)
	label.append_text("\t%s\n" % var_to_str(demo.tile_map.hovering_tile))
	label.pop()
	label.append_text(")\n\n")

	var distance = demo.tile_map.cube_distance(Vector3i.ZERO, demo.tile_map.hovering_tile)


	label.append_text("[color=57B2FF]print[/color](distance) # %s" % distance)
	
	line.add_point(demo.tile_map.cube_to_local(Vector3i.ZERO))
	line.add_point(demo.tile_map.cube_to_local(demo.tile_map.hovering_tile))

	label.pop_all()
	demo.tile_map.show_debug_tiles(-1)
