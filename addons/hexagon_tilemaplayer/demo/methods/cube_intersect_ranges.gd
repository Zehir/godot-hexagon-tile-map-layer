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
	line.z_index = 100
	demo.tile_map.add_child(line)


func _enter_tree() -> void:
	demo.tile_map.hovering_changed.connect(_on_tile_changed)
	tree_exiting.connect(
		demo.tile_map.hovering_changed.disconnect.bind(_on_tile_changed), CONNECT_ONE_SHOT
	)


func _exit_tree() -> void:
	line.queue_free()


func _ready() -> void:
	demo.camera_2d.focus_tile(demo.tile_map.cube_to_local(Vector3i.ZERO))
	demo.tile_map.hovering_tile = Vector3i(2, -2, 0)
	_on_tile_changed.call()


func _on_tile_changed() -> void:
	if demo.tile_map.hovering_tile == null:
		return
	var second_center = Vector3i(2, -2, 0)
	var distance = demo.tile_map.cube_distance(second_center, demo.tile_map.hovering_tile)

	var first_range = demo.tile_map.cube_range(Vector3i.ZERO, 3)
	var second_range = demo.tile_map.cube_range(second_center, distance)
	var cells = demo.tile_map.cube_intersect_ranges(Vector3i.ZERO, 3, second_center, distance)

	demo.tile_map.show_range_with_color(first_range, 0, Color.GREEN_YELLOW)
	demo.tile_map.show_range_with_color(second_range, first_range.size(), Color.CADET_BLUE)

	var label = demo.sample_code
	label.clear()
	line.clear_points()

	label.push_color(Color.from_string("CBCDD0", Color.WHITE))
	label.append_text(
		"[color=C45C6D]var[/color] cells = [color=57B2FF]cube_intersect_ranges[/color](\n"
	)
	label.push_color(Color.GREEN_YELLOW)
	label.append_text("\tVector3i.ZERO, 3")
	label.pop()
	label.append_text(",\n")

	label.push_color(Color.CADET_BLUE)
	label.append_text("\t%s, %s" % [var_to_str(second_center), distance])
	label.pop()
	label.append_text("\n)\n\n")
	label.append_text("[color=57B2FF]print[/color](cells.[color=57B2FF]size[/color]())")
	label.append_text("[color=gray] # %s[/color]\n" % cells.size())
	label.append_text("[color=57B2FF]print[/color](cells)\n")

	var base_index = first_range.size() + second_range.size()

	var tiles = demo.tile_map.show_range_with_gradient_color(cells, base_index)

	var point_count = cells.size()
	for index in point_count:
		line.add_point(tiles[index].position)
		label.push_color(tiles[index].self_modulate)
		label.append_text("# %s" % var_to_str(cells[index]))
		label.newline()
		label.pop()

	label.pop_all()
	demo.tile_map.show_debug_tiles(base_index + point_count - 1)
