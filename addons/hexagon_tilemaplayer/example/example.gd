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
	for tile_map: HexagonTileMapLayer in find_children("*", "HexagonTileMapLayer"):
		if tile_map.is_visible_in_tree():
			demo_spirale(tile_map, Vector2i(0, 0))
			var gray_cells = tile_map.get_used_cells_by_id(1, Vector2i(0, 0), 5)
			if gray_cells.size() == 2:
				demo_line(tile_map, gray_cells[0], gray_cells[1])
				if tile_map.pathfinding_enabled:
					demo_path_finding(tile_map, gray_cells[0], gray_cells[1])
					tile_map.astar_changed.connect(demo_path_finding)


func demo_spirale(tile_map: HexagonTileMapLayer, center: Vector2i, radius: int = 2) -> void:
	var _center = tile_map.map_to_cube(center)
	var line = Line2D.new()
	line.width = 20.0
	line.default_color = Color.BLUE
	for point in tile_map.cube_spiral(
		_center, 2, TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE
	):
		line.add_point(tile_map.cube_to_local(point))
	tile_map.add_child(line)


func demo_line(tile_map: HexagonTileMapLayer, from: Vector2i, to: Vector2i) -> void:
	var _from = tile_map.map_to_cube(from)
	var _to = tile_map.map_to_cube(to)
	var line = Line2D.new()
	line.width = 10.0
	line.default_color = Color.WHITE
	for point in tile_map.cube_linedraw(_from, _to):
		line.add_point(tile_map.cube_to_local(point))
	tile_map.add_child(line)


func demo_path_finding(tile_map: HexagonTileMapLayer, from: Vector2i, to: Vector2i) -> void:
	var _from = tile_map.pathfinding_get_point_id(from)
	var _to = tile_map.pathfinding_get_point_id(to)
	var line = Line2D.new()
	line.width = 5.0
	line.default_color = Color.RED
	for point in tile_map.astar.get_id_path(_from, _to):
		var pos = tile_map.astar.get_point_position(point)
		line.add_point(pos)
	tile_map.add_child(line)
