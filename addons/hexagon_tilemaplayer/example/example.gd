extends Node2D

@onready var horizontal: HexagonTileMapLayer = $Horizontal
@onready var vertical: HexagonTileMapLayer = $Vertical


func _ready() -> void:
	for tile_map: HexagonTileMapLayer in [horizontal, vertical]:
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
	for point in tile_map.cube_spiral(_center, 2):
		line.add_point(tile_map.cube_to_local(point))
	add_child(line)


func demo_line(tile_map: HexagonTileMapLayer, from: Vector2i, to: Vector2i) -> void:
	var _from = tile_map.map_to_cube(from)
	var _to = tile_map.map_to_cube(to)
	var line = Line2D.new()
	line.width = 10.0
	line.default_color = Color.WHITE
	for point in tile_map.cube_linedraw(_from, _to):
		line.add_point(tile_map.cube_to_local(point))
	add_child(line)


func demo_path_finding(tile_map: HexagonTileMapLayer, from: Vector2i, to: Vector2i) -> void:
	var _from = tile_map.pathfinding_get_point_id(from)
	var _to = tile_map.pathfinding_get_point_id(to)
	var line = Line2D.new()
	line.width = 5.0
	line.default_color = Color.RED
	for point in tile_map.astar.get_id_path(_from, _to):
		var pos = tile_map.astar.get_point_position(point)
		line.add_point(pos)
	add_child(line)
