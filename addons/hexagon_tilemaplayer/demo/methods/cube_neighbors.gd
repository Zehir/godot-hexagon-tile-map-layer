extends Node

const DemoManager = preload("uid://c5t8k8u70hsgr")
const Enums = preload("uid://b2klbw1som8cc")
var demo: DemoManager
var line: Line2D
var current_index: int = -1
var center_cell = Vector3i(3, -2, -1)


func _init(_demo: DemoManager) -> void:
	demo = _demo
	line = Line2D.new()
	line.width = 10.0
	line.default_color = Color.BLUE
	demo.tile_map.add_child(line)


func _exit_tree() -> void:
	line.queue_free()


func _ready() -> void:
	demo.tile_map.hovering_tile = Vector3i(3, -2, -1)

	var center_tile = demo.tile_map.cube_to_local(center_cell)
	line.add_point(center_tile)
	line.add_point(center_tile)

	demo.camera_2d.focus_tile(center_tile)

	var tile = demo.tile_map.get_or_make_debug_tile_with_color(0, Color.YELLOW)
	tile.position = center_tile

	var label = demo.sample_code
	label.clear()
	label.push_color(Color.from_string("CBCDD0", Color.WHITE))

	label.append_text("[color=C45C6D]var[/color] ")
	label.append_text("[color=yellow]center_cell[/color] = %s\n" % var_to_str(center_cell))

	label.append_text("[color=C45C6D]var[/color] ")
	label.append_text("[color=%s]cells[/color] = " % Color.GREEN.to_html())
	label.append_text("[color=57B2FF]cube_neighbors[/color](\n")
	label.append_text("\tcenter_cell,\n")
	label.append_text(")\n\n")

	var neighbors = demo.tile_map.cube_neighbors(center_cell)
	for neighbor_index in neighbors.size():
		tile = demo.tile_map.get_or_make_debug_tile(
			neighbor_index + 1, remap(neighbor_index, 0, 5, 0.0, 1.0)
		)
		tile.position = demo.tile_map.cube_to_local(neighbors[neighbor_index])

		var key: String = Enums.CellNeighbor.find_key(
			demo.tile_map.cube_side_neighbor_directions[neighbor_index]
		)
		label.push_color(tile.self_modulate)
		label.append_text("# %s" % key)
		if neighbor_index == current_index:
			label.add_text(" ")
			if demo.tile_map.tile_set.tile_offset_axis == TileSet.TILE_OFFSET_AXIS_HORIZONTAL:
				label.add_image(demo.tile_map.TILE_HORIZONTAL, 0, 20, Color.GREEN)
			else:
				label.add_image(demo.tile_map.TILE_VERTICAL, 0, 20, Color.GREEN)
		label.pop()
		label.newline()

	demo.tile_map.show_debug_tiles(6)
	label.pop_all()
