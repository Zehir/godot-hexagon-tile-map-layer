extends Node

const DemoManager = preload("uid://c5t8k8u70hsgr")
const DemoCamera = preload("uid://t5kjk00fsm7k")

var demo: DemoManager
var lines: Array[Line2D]


func _init(_demo: DemoManager) -> void:
	demo = _demo


func _enter_tree() -> void:
	demo.tile_map.hovering_changed.connect(_on_tile_changed)
	tree_exiting.connect(
		demo.tile_map.hovering_changed.disconnect.bind(_on_tile_changed), CONNECT_ONE_SHOT
	)


func _exit_tree() -> void:
	for line in lines:
		line.queue_free()


func _ready() -> void:
	demo.camera_2d.focus_tile(demo.tile_map.cube_to_local(Vector3i.ZERO))

	if demo.tile_map.tile_set.tile_offset_axis == TileSet.TILE_OFFSET_AXIS_HORIZONTAL:
		demo.tile_map.hovering_tile = Vector3i(6, -3, -3)
	else:
		demo.tile_map.hovering_tile = Vector3i(5, -6, 1)

	_on_tile_changed.call()


func _on_tile_changed() -> void:
	if demo.tile_map.hovering_tile == null:
		return

	var label = demo.sample_code
	label.clear()

	for line in lines:
		line.queue_free()
		lines = []

	var distance = demo.tile_map.cube_distance(Vector3i.ZERO, demo.tile_map.hovering_tile)
	var points = demo.tile_map.cube_ring(Vector3i.ZERO, distance)
	var outlines = demo.tile_map.cube_outlines(points)

	label.push_color(Color.from_string("CBCDD0", Color.WHITE))
	label.append_text("[color=C45C6D]var[/color] ring = [color=57B2FF]cube_ring[/color](\n")
	label.push_color(Color.WHITE)
	label.append_text("\tVector3i.ZERO")
	label.pop()
	label.append_text(",\n")
	label.push_color(demo.tile_map.SECONDARY_COLOR)
	label.append_text("\t%s\n" % distance)
	label.pop()
	label.append_text(")\n\n")

	label.append_text(
		"[color=C45C6D]var[/color] outlines = [color=57B2FF]cube_outlines[/color](ring)\n"
	)
	label.append_text("for outline in outlines:\n")
	label.append_text("\tvar line = [color=57B2FF]make_line[/color]()\n")
	label.append_text("\tfor point in outline:\n")
	label.append_text("\t\tline.[color=57B2FF]add_point[/color](point)\n\n")

	label.append_text("[color=57B2FF]print[/color](outlines.[color=57B2FF]size[/color]())")
	label.append_text("[color=gray] # %s[/color]\n" % outlines.size())
	label.append_text("[color=57B2FF]print[/color](outlines)\n")
	label.append_text(var_to_str(outlines))

	var tiles = demo.tile_map.show_range_with_gradient_color(points)

	label.pop_all()
	demo.tile_map.show_debug_tiles(tiles.size() - 1)

	for outline in outlines:
		var line = make_line()
		for point in outline:
			line.add_point(point)


func make_line() -> Line2D:
	var line = Line2D.new()
	line.width = 10.0
	line.default_color = Color.BLACK
	line.z_index = 100
	line.closed = true
	demo.tile_map.add_child(line)
	lines.append(line)
	return line
