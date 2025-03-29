extends Node

const DemoManager = preload("uid://c5t8k8u70hsgr")
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


func _exit_tree() -> void:
	demo.tile_map.hovering_changed.disconnect(_on_tile_changed)
	demo.tile_map.show_debug_tiles(-1)
	line.queue_free()


func _ready() -> void:
	demo.tile_map.hovering_tile = Vector3i(3, -2, -1)
	_on_tile_changed()


func _on_tile_changed() -> void:
	if not demo.tile_map.hovering_tile:
		return

	var label = demo.sample_code
	label.clear()
	line.clear_points()

	label.push_color(Color.from_string("CBCDD0", Color.WHITE))
	label.append_text("[color=C45C6D]var[/color] line = [color=57B2FF]cube_linedraw[/color](\n")
	label.push_color(demo.tile_map.PRIMARY_COLOR)
	label.append_text("\tVector3i.ZERO")
	label.pop()
	label.append_text(",\n")
	label.push_color(demo.tile_map.SECONDARY_COLOR)
	label.append_text("\t%s\n" % var_to_str(demo.tile_map.hovering_tile))
	label.pop()
	label.append_text(")\n\n")

	var points = demo.tile_map.cube_linedraw(Vector3i.ZERO, demo.tile_map.hovering_tile)

	label.append_text("[color=57B2FF]print[/color](line.[color=57B2FF]size[/color]())")
	label.append_text("[color=gray] # %s[/color]\n" % points.size())
	label.append_text("[color=57B2FF]print[/color](line)\n")
	var point_count = points.size()
	for index in point_count:
		var position = demo.tile_map.cube_to_local(points[index])
		line.add_point(position)
		var tile = demo.tile_map.get_or_make_debug_tile(
			index, remap(index, 0, point_count - 1, 0.0, 1.0)
		)
		tile.position = position

		label.push_color(tile.self_modulate)
		label.append_text("# %s" % var_to_str(points[index]))
		label.newline()
		label.pop()

	label.pop_all()
	demo.tile_map.show_debug_tiles(point_count - 1)
