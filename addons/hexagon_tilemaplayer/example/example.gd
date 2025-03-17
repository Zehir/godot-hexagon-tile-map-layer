extends Node2D

@onready var camera_2d: Camera2D = $Camera2D
var is_camera_panning: bool = false


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("right_click"):
		is_camera_panning = true
	elif event.is_action_released("right_click"):
		is_camera_panning = false
	if is_camera_panning and event is InputEventMouseMotion:
		camera_2d.position -= (event as InputEventMouseMotion).relative / camera_2d.zoom.x
	if event.is_action_pressed("zoom_up"):
		camera_2d.zoom *= 0.9
	if event.is_action_pressed("zoom_down"):
		camera_2d.zoom *= 1.1


func _ready() -> void:
	for _tile_map: HexagonTileMapLayer in find_children("*", "HexagonTileMapLayer"):
		if _tile_map.is_visible_in_tree():
			demo_cube_explore_outline(_tile_map)
			demo_spirale(_tile_map, Vector2i(0, 0))

			if (
				_tile_map.tile_set.tile_offset_axis
				== TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL
			):
				demo_geometry_tile_shape(_tile_map, Vector2i(8, 0))
			else:
				demo_geometry_tile_shape(_tile_map, Vector2i(-6, 0))
			var gray_cells = _tile_map.get_used_cells_by_id(1, Vector2i(0, 0), 5)
			if gray_cells.size() == 2:
				demo_line(_tile_map, gray_cells[0], gray_cells[1])
				if _tile_map.pathfinding_enabled:
					demo_path_finding(_tile_map, gray_cells[0], gray_cells[1])
					_tile_map.astar_changed.connect(demo_path_finding)


func demo_spirale(_tile_map: HexagonTileMapLayer, center: Vector2i) -> void:
	var _center = _tile_map.map_to_cube(center)
	var line = Line2D.new()
	line.width = 20.0
	line.default_color = Color.BLUE
	for point in _tile_map.cube_spiral(
		_center, 2, TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE
	):
		line.add_point(_tile_map.cube_to_local(point))
	_tile_map.add_child(line)


func demo_line(_tile_map: HexagonTileMapLayer, from: Vector2i, to: Vector2i) -> void:
	var _from = _tile_map.map_to_cube(from)
	var _to = _tile_map.map_to_cube(to)
	var line = Line2D.new()
	line.width = 10.0
	line.default_color = Color.WHITE
	for point in _tile_map.cube_linedraw(_from, _to):
		line.add_point(_tile_map.cube_to_local(point))
	_tile_map.add_child(line)


func demo_path_finding(_tile_map: HexagonTileMapLayer, from: Vector2i, to: Vector2i) -> void:
	var _from = _tile_map.pathfinding_get_point_id(from)
	var _to = _tile_map.pathfinding_get_point_id(to)
	var line = Line2D.new()
	line.width = 5.0
	line.default_color = Color.RED
	for point in _tile_map.astar.get_id_path(_from, _to):
		var pos = _tile_map.astar.get_point_position(point)
		line.add_point(pos)
	_tile_map.add_child(line)


func demo_geometry_tile_shape(_tile_map: HexagonTileMapLayer, from: Vector2i) -> void:
	var center_pos = _tile_map.map_to_local(from)
	var collision = CollisionShape2D.new()
	collision.shape = _tile_map.geometry_tile_shape.shape
	collision.transform = _tile_map.geometry_tile_shape.transform.translated(center_pos)
	_tile_map.add_child(collision)

	var neighbor = _tile_map.get_neighbor_cell(from, TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE)
	var center_pos_approx = _tile_map.map_to_local(neighbor)
	var collision_approx = CollisionShape2D.new()
	collision_approx.shape = _tile_map.geometry_tile_approx_shape.shape
	collision_approx.transform = _tile_map.geometry_tile_approx_shape.transform.translated(
		center_pos_approx
	)
	_tile_map.add_child(collision_approx)


func demo_cube_explore_outline(_tile_map: HexagonTileMapLayer) -> void:
	var filter := func(tile: Vector3i, values: Array) -> bool:
		var cell_alternative = _tile_map.get_cell_alternative_tile(_tile_map.cube_to_map(tile))
		return cell_alternative in values

	var cells = _tile_map.cube_explore(Vector3i.ZERO, filter.bind([1]), filter.bind([0, 4]))
	var outlines = _tile_map.cube_outlines(cells)
	for outline in outlines:
		var line = Line2D.new()
		line.points = outline
		line.closed = true
		line.default_color = Color.YELLOW
		_tile_map.add_child(line)
