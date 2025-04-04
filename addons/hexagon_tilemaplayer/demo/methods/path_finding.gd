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
		demo.tile_map.hovering_tile = Vector3i(1, 4, -5)
	else:
		demo.tile_map.hovering_tile = Vector3i(3, 2, -5)

	if not demo.tile_map.pathfinding_enabled:
		var label = demo.sample_code
		label.clear()
		label.push_color(Color.RED)
		label.append_text("You need to enable path finding first")
		return

	demo.tile_map.hovering_changed.connect(_on_tile_changed)
	tree_exiting.connect(
		demo.tile_map.hovering_changed.disconnect.bind(_on_tile_changed), CONNECT_ONE_SHOT
	)

	_on_tile_changed.call()


func _on_tile_changed() -> void:
	if demo.tile_map.hovering_tile == null:
		return

	var label = demo.sample_code
	label.clear()
	line.clear_points()

	var from = demo.tile_map.pathfinding_get_point_id(Vector2i.ZERO)

	label.push_color(Color.from_string("CBCDD0", Color.WHITE))
	label.append_text(
		"[color=C45C6D]var[/color] from = [color=57B2FF]pathfinding_get_point_id[/color](\n"
	)
	label.push_color(demo.tile_map.PRIMARY_COLOR)
	label.append_text("\tVector3i.ZERO")
	label.pop()
	label.append_text("\n)\n")
	label.push_color(Color.from_string("CBCDD0", demo.tile_map.SECONDARY_COLOR))
	label.append_text(
		"[color=C45C6D]var[/color] to = [color=57B2FF]pathfinding_get_point_id[/color](\n"
	)
	label.push_color(demo.tile_map.SECONDARY_COLOR)
	label.append_text("\t%s\n" % var_to_str(demo.tile_map.hovering_tile))
	label.pop()
	label.append_text(")\n")

	label.append_text("[color=C45C6D]var[/color] path = astar.")
	label.append_text("[color=57B2FF]get_id_path[/color](from, to)\n")

	label.append_text("[color=C45C6D]var[/color] points: Array[Vector3i] = []\n")
	label.append_text("for point_id in path:\n")
	label.append_text(
		"\t[color=C45C6D]var[/color] point_pos = astar.get_point_position(\n\t\tpoint_id\n\t)\n"
	)
	label.append_text("\tpoints.append(local_to_cube(point_pos))\n")

	var target = demo.tile_map.pathfinding_get_point_id(
		demo.tile_map.cube_to_map(demo.tile_map.hovering_tile)
	)

	var path = demo.tile_map.astar.get_id_path(from, target)
	var points: Array[Vector3i] = []
	for point_id in path:
		var point_pos = demo.tile_map.astar.get_point_position(point_id)
		points.append(demo.tile_map.local_to_cube(point_pos))
	var tiles = demo.tile_map.show_range_with_gradient_color(points)

	label.append_text("[color=57B2FF]print[/color](points.[color=57B2FF]size[/color]())")
	label.append_text("[color=gray] # %s[/color]\n" % points.size())
	label.append_text("[color=57B2FF]print[/color](points)\n")

	var point_count = points.size()
	for index in point_count:
		var tile = tiles[index]
		line.add_point(tile.position)
		label.push_color(tile.self_modulate)
		label.append_text("# %s" % var_to_str(points[index]))
		label.newline()
		label.pop()

	label.pop_all()
	demo.tile_map.show_debug_tiles(point_count - 1)
