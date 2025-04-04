extends Node

const DemoManager = preload("uid://c5t8k8u70hsgr")
const DemoCamera = preload("uid://t5kjk00fsm7k")

var demo: DemoManager


func _init(_demo: DemoManager) -> void:
	demo = _demo


func _enter_tree() -> void:
	demo.tile_map.hovering_changed.connect(_on_tile_changed)
	tree_exiting.connect(
		demo.tile_map.hovering_changed.disconnect.bind(_on_tile_changed), CONNECT_ONE_SHOT
	)


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
	if demo.tile_map.hovering_tile == null:
		return

	var tile_data = demo.tile_map.get_cell_tile_data(
		demo.tile_map.cube_to_map(demo.tile_map.hovering_tile)
	)

	if not tile_data:
		return

	var current_color = tile_data.get_custom_data("color")

	var filter := func(tile: Vector3i, value: String) -> bool:
		var cell_alternative = demo.tile_map.get_cell_tile_data(demo.tile_map.cube_to_map(tile))
		if not cell_alternative:
			return false
		return cell_alternative.get_custom_data("color") == value

	var cells = demo.tile_map.cube_explore(
		demo.tile_map.hovering_tile, filter.bind(current_color), filter.bind(&"green")
	)

	var label = demo.sample_code
	label.clear()

	label.push_color(Color.from_string("CBCDD0", Color.WHITE))
	label.append_text("[color=C45C6D]var[/color] cells = [color=57B2FF]cube_explore[/color](\n")
	label.push_color(demo.tile_map.PRIMARY_COLOR)
	label.append_text("\thovering_tile")
	label.pop()
	label.append_text(",\n")
	label.append_text("\tfilter.bind(%s),\n" % var_to_str(current_color))
	label.append_text('\tfilter.bind(&"green")\n')
	label.append_text(")\n\n")

	label.append_text("[color=57B2FF]print[/color](cells.[color=57B2FF]size[/color]())")
	label.append_text("[color=gray] # %s[/color]\n" % cells.size())
	label.append_text("[color=57B2FF]print[/color](cells)\n")

	var tiles = demo.tile_map.show_range_with_gradient_color(cells)

	var point_count = cells.size()
	for index in point_count:
		var tile = tiles[index]
		label.push_color(tile.self_modulate)
		label.append_text("# %s" % var_to_str(cells[index]))
		label.newline()
		label.pop()

	label.pop_all()
	demo.tile_map.show_debug_tiles(point_count - 1)
