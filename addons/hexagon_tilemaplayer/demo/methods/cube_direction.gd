extends Node

const DemoManager = preload("uid://c5t8k8u70hsgr")
const Enums = preload("uid://b2klbw1som8cc")
var demo: DemoManager
var line: Line2D
var tween: Tween
var current_index: int = -1
var neighbors: Array = []


func _init(_demo: DemoManager) -> void:
	demo = _demo
	line = Line2D.new()
	line.width = 10.0
	line.default_color = Color.BLUE
	line.z_index = 100
	demo.tile_map.add_child(line)

	for neighbor in demo.tile_map.cube_side_neighbor_directions:
		neighbors.append([neighbor, Enums.CellNeighbor.find_key(neighbor)])
	for neighbor in demo.tile_map.cube_corner_neighbor_directions:
		neighbors.append([neighbor, Enums.CellNeighbor.find_key(neighbor)])


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
	label.append_text(") * 2\n\n")

	var tile: Sprite2D

	for neighbor_index in neighbors.size():
		tile = demo.tile_map.get_or_make_debug_tile(
			neighbor_index, remap(neighbor_index, 0, 11, 0.0, 1.0)
		)
		tile.position = demo.tile_map.cube_to_local(
			demo.tile_map.cube_direction(neighbors[neighbor_index][0]) * 2
		)

		var key: String = Enums.CellNeighbor.find_key(neighbors[neighbor_index][0])
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

		if neighbor_index == 5:
			label.append_text("\n")

	var position = demo.tile_map.cube_direction(neighbor[0]) * 2
	tile = demo.tile_map.get_or_make_debug_tile_with_color(12, Color.GREEN)
	tile.position = demo.tile_map.cube_to_local(position)
	line.points[1] = tile.position
	demo.tile_map.show_debug_tiles(12)
	label.pop_all()
