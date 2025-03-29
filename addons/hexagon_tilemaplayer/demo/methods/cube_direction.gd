extends Node

const DemoManager = preload("uid://c5t8k8u70hsgr")
var demo: DemoManager
var line: Line2D
var tween: Tween
var current_index: int = 0
var neighbors: Array = []

enum CellNeighbor {
	RIGHT_SIDE = 0,
	RIGHT_CORNER = 1,
	BOTTOM_RIGHT_SIDE = 2,
	BOTTOM_RIGHT_CORNER = 3,
	BOTTOM_SIDE = 4,
	BOTTOM_CORNER = 5,
	BOTTOM_LEFT_SIDE = 6,
	BOTTOM_LEFT_CORNER = 7,
	LEFT_SIDE = 8,
	LEFT_CORNER = 9,
	TOP_LEFT_SIDE = 10,
	TOP_LEFT_CORNER = 11,
	TOP_SIDE = 12,
	TOP_CORNER = 13,
	TOP_RIGHT_SIDE = 14,
	TOP_RIGHT_CORNER = 15,
}


func _init(_demo: DemoManager) -> void:
	demo = _demo
	line = Line2D.new()
	line.width = 10.0
	line.default_color = Color.BLUE
	demo.tile_map.add_child(line)

	for neighbor in demo.tile_map.cube_side_neighbor_directions:
		neighbors.append([neighbor, CellNeighbor.find_key(neighbor)])
	for neighbor in demo.tile_map.cube_corner_neighbor_directions:
		neighbors.append([neighbor, CellNeighbor.find_key(neighbor)])


func _exit_tree() -> void:
	line.queue_free()
	if is_instance_valid(tween) and tween.is_valid():
		tween.kill()


func _ready() -> void:
	demo.tile_map.hovering_tile = Vector3i(3, -2, -1)
	tween = create_tween()
	tween.set_loops()
	tween.tween_callback(update_tile)
	tween.tween_interval(1)

	var center_tile = demo.tile_map.cube_to_local(Vector3i.ZERO)
	line.add_point(center_tile)
	line.add_point(center_tile)

	demo.camera_2d.focus_tile(center_tile)


func update_tile() -> void:
	current_index = (current_index + 1) % 12
	var neighbor = neighbors[current_index]
	var label = demo.sample_code
	label.clear()
	label.push_color(Color.from_string("CBCDD0", Color.WHITE))

	label.append_text("[color=C45C6D]var[/color] ")
	label.append_text("[color=%s]cell[/color] = " % Color.GREEN.to_html())
	label.append_text("[color=57B2FF]cube_direction[/color](\n")
	label.append_text(
		"\t[color=8CF9D6]TileSet[/color].[color=BCE0FF]CELL_NEIGHBOR_\n\t%s[/color]\n" % neighbor[1]
	)
	label.append_text(")\n\n")

	for neighbor_index in neighbors.size():
		var tile = demo.tile_map.get_or_make_debug_tile(
			neighbor_index, remap(neighbor_index, 0, 11, 0.0, 1.0)
		)
		tile.position = demo.tile_map.cube_to_local(
			demo.tile_map.cube_direction(neighbors[neighbor_index][0])
		)

		var key: String = CellNeighbor.find_key(neighbors[neighbor_index][0])
		label.push_color(tile.self_modulate)
		label.append_text("# %s" % key)
		label.pop()
		if neighbor_index == current_index:
			label.append_text(" <--")
		label.newline()

		if neighbor_index == 5:
			label.append_text("\n")

	var position = demo.tile_map.cube_direction(neighbor[0])
	var tile = demo.tile_map.get_or_make_debug_tile_with_color(12, Color.GREEN)
	tile.position = demo.tile_map.cube_to_local(position)
	line.points[1] = tile.position
	demo.tile_map.show_debug_tiles(13)
	label.pop_all()
