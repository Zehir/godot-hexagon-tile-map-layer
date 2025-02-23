@tool
@icon("hexagon_tilemaplayer.svg")
class_name HexagonTileMapLayer extends TileMapLayer

var astar: AStar2D

const WEDGE_ANGLE = deg_to_rad(60.0)
const WEDGE_INV_ANGLE = 1 / WEDGE_ANGLE
const WEDGE_ANGLE_HALF = deg_to_rad(30.0)
const WEDGE_INV_ANGLE_HALF = 1 / WEDGE_ANGLE_HALF
const WEDGE_COUNT = 6

## Enable A* Pathfinding
@export var pathfinding_enabled: bool = false

var debug_container: Node2D
@onready var _debug_font_size = floori(tile_set.tile_size.x / 7.0)
@onready var _debug_font_outline_size = floori(tile_set.tile_size.x / 32.0)

enum DebugModeFlags {
	TILES_COORDS = 1,
	CONNECTIONS = 2,
}

## Display debug data about tiles and pathfinding
@export_flags("Tiles coords", "Connections") var debug_mode: int = 0:
	set(value):
		debug_mode = value
		if not Engine.is_editor_hint() and is_inside_tree():
			_draw_debug()

signal astar_changed

var _cube_to_map: Callable
var _map_to_cube: Callable
var cube_direction_vectors: Dictionary[TileSet.CellNeighbor, Vector3i]
var cube_side_neighbor_directions: Array[TileSet.CellNeighbor]
var cube_corner_neighbor_directions: Array[TileSet.CellNeighbor]


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		tile_set.changed.connect(update_configuration_warnings)
	else:
		tile_set.changed.connect(_on_tileset_changed)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		tile_set.changed.disconnect(update_configuration_warnings)
	else:
		tile_set.changed.disconnect(_on_tileset_changed)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_on_tileset_changed()

	if pathfinding_enabled:
		astar_changed.connect(_draw_debug, Object.CONNECT_DEFERRED)
		_pathfinding_generate_points()
		astar_changed.emit()
	else:
		_draw_debug.call_deferred()


func _get_configuration_warnings():
	var warnings: Array[String] = []
	if tile_set.tile_shape != TileSet.TileShape.TILE_SHAPE_HEXAGON:
		warnings.append("This node only support hexagon shapes")
	return warnings


#region Pathfinding
func _pathfinding_get_tile_weight(coords: Vector2i) -> float:
	return 1.0


func _pathfinding_does_tile_connect(tile: Vector2i, neighbor: Vector2i) -> bool:
	return true


func pathfinding_get_point_id(coord: Vector2i) -> int:
	return astar.get_closest_point(map_to_local(coord))


func pathfinding_recalculate_tile_weight(coord: Vector2i):
	astar.set_point_weight_scale(
		pathfinding_get_point_id(coord), _pathfinding_get_tile_weight(coord)
	)


func _pathfinding_generate_points():
	if not astar:
		astar = AStar2D.new()
	astar.clear()
	_pathfinding_create_points()
	_pathfinding_create_connections()
	astar_changed.emit()


func _draw_debug():
	if debug_container:
		debug_container.queue_free()
	if debug_mode == 0 or not is_visible_in_tree():
		return
	debug_container = Node2D.new()
	debug_container.z_index = 100

	if debug_mode & DebugModeFlags.CONNECTIONS and pathfinding_enabled:
		var connections_container: Node2D = Node2D.new()
		for id in astar.get_point_ids():
			for neighbour_id in astar.get_point_connections(id):
				if neighbour_id > id:
					_pathfinding_debug_display_connection(
						connections_container,
						id,
						neighbour_id,
						Color(randf(), randf(), randf(), 1.0)
					)
		debug_container.add_child(connections_container)

	if debug_mode & DebugModeFlags.TILES_COORDS:
		var coords_container: Node2D = Node2D.new()
		if pathfinding_enabled:
			for id in astar.get_point_ids():
				_debug_tile_coords_with_pathfinding(coords_container, id)
		else:
			for pos in get_used_cells():
				_debug_tile_coords(coords_container, pos)
		debug_container.add_child(coords_container)

	add_child.call_deferred(debug_container)


func _pathfinding_create_points():
	var cells := get_used_cells()
	astar.reserve_space(1 << int(log(cells.size()) / log(2)))

	for coord in cells:
		var id = astar.get_available_point_id()
		var weight = _pathfinding_get_tile_weight(coord)
		var pos = map_to_local(coord)
		astar.add_point(id, pos, weight)


func _debug_tile_coords_with_pathfinding(debug_container: Node2D, id: int):
	var pos = local_to_map(astar.get_point_position(id))
	var cube = map_to_cube(pos)
	var text = (
		"[center]#%d\n(%d, %d)\n(%d, %d, %d)[/center]" % [id, pos.x, pos.y, cube.x, cube.y, cube.z]
	)
	_show_debug_text_on_tile(debug_container, pos, text)


func _debug_tile_coords(debug_container: Node2D, pos: Vector2i):
	var cube = map_to_cube(pos)
	var text = "[center](%d, %d)\n(%d, %d, %d)[/center]" % [pos.x, pos.y, cube.x, cube.y, cube.z]
	_show_debug_text_on_tile(debug_container, pos, text)


func _show_debug_text_on_tile(debug_container: Node2D, pos: Vector2i, text: String):
	var label: RichTextLabel = RichTextLabel.new()
	label.fit_content = true
	label.set_position(map_to_local(pos))
	label.bbcode_enabled = true
	label.text = text
	label.size.x = tile_set.tile_size.x
	label.resized.connect(
		func():
			label.position.x -= label.size.x * 0.5
			label.position.y -= label.size.y * 0.5,
		ConnectFlags.CONNECT_ONE_SHOT
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.scroll_active = false
	label.add_theme_font_size_override("normal_font_size", _debug_font_size)
	label.add_theme_constant_override("outline_size", _debug_font_outline_size)
	debug_container.add_child(label)


func _pathfinding_create_connections() -> void:
	var neighbours = cube_side_neighbor_directions.slice(0, 3)
	for id in astar.get_point_ids():
		var local_position = astar.get_point_position(id)
		var map_position = local_to_map(local_position)
		for neighbour in neighbours:
			var neighbour_map_position = get_neighbor_cell(map_position, neighbour)
			if get_cell_source_id(neighbour_map_position) == -1:
				continue
			if not _pathfinding_does_tile_connect(map_position, neighbour_map_position):
				continue
			var neighbour_id = astar.get_closest_point(map_to_local(neighbour_map_position))
			astar.connect_points(id, neighbour_id)


func _pathfinding_debug_display_connection(
	debug_container: Node2D, id1: int, id2: int, color: Color
):
	var line: Line2D = Line2D.new()
	line.default_color = color
	line.add_point(astar.get_point_position(id1))
	line.add_point(astar.get_point_position(id2))
	debug_container.add_child(line)


#endregion

#region Cube coords conversions
const cube_horizontal_direction_vectors: Dictionary[TileSet.CellNeighbor, Vector3i] = {
	# Direct side
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE: Vector3i(1, -1, 0),
	TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE: Vector3i(1, 0, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE: Vector3i(0, 1, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE: Vector3i(-1, 1, 0),
	TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE: Vector3i(-1, 0, 1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE: Vector3i(0, -1, 1),
	# Corner
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER: Vector3i(2, -1, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER: Vector3i(1, 1, -2),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_CORNER: Vector3i(-1, 2, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER: Vector3i(-2, 1, 1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER: Vector3i(-1, -1, 2),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_CORNER: Vector3i(1, -2, 1),
}

const cube_horizontal_side_neighbor_directions: Array[TileSet.CellNeighbor] = [
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE,
]

const cube_horizontal_corner_neighbor_directions: Array[TileSet.CellNeighbor] = [
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_CORNER,
]

const cube_vertical_direction_vectors: Dictionary[TileSet.CellNeighbor, Vector3i] = {
	# Direct side
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE: Vector3i(1, -1, 0),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE: Vector3i(1, 0, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_SIDE: Vector3i(0, 1, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE: Vector3i(-1, 1, 0),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE: Vector3i(-1, 0, 1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_SIDE: Vector3i(0, -1, 1),
	# Corner
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER: Vector3i(1, -2, 1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_CORNER: Vector3i(2, -1, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER: Vector3i(1, 1, -2),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER: Vector3i(-1, 2, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_CORNER: Vector3i(-2, 1, 1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER: Vector3i(-1, -1, 2),
}

const cube_vertical_side_neighbor_directions: Array[TileSet.CellNeighbor] = [
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_SIDE,
]

const cube_vertical_corner_neighbor_directions: Array[TileSet.CellNeighbor] = [
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER,
]


func cube_to_local(cube_position: Vector3i) -> Vector2:
	return map_to_local(cube_to_map(cube_position))


func local_to_cube(map_position: Vector2) -> Vector3i:
	return map_to_cube(local_to_map(map_position))


func _on_tileset_changed() -> void:
	_debug_font_size = floori(tile_set.tile_size.x / 7.0)
	_debug_font_outline_size = floori(tile_set.tile_size.x / 32.0)
	var conversion_methods := get_conversion_methods_for(
		tile_set.tile_offset_axis, tile_set.tile_layout
	)
	if not conversion_methods.is_empty():
		_cube_to_map = conversion_methods.cube_to_map
		_map_to_cube = conversion_methods.map_to_cube

	if tile_set.tile_offset_axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		cube_direction_vectors = cube_horizontal_direction_vectors
		cube_side_neighbor_directions = cube_horizontal_side_neighbor_directions
		cube_corner_neighbor_directions = cube_horizontal_corner_neighbor_directions
	else:
		cube_direction_vectors = cube_vertical_direction_vectors
		cube_side_neighbor_directions = cube_vertical_side_neighbor_directions
		cube_corner_neighbor_directions = cube_vertical_corner_neighbor_directions


static func get_conversion_methods_for(
	axis: TileSet.TileOffsetAxis, layout: TileSet.TileLayout
) -> Dictionary:
	match axis:
		TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
			match layout:
				TileSet.TileLayout.TILE_LAYOUT_STACKED:
					return {
						"cube_to_map": _cube_to_horizontal_stacked,
						"map_to_cube": _horizontal_stacked_to_cube
					}
				TileSet.TileLayout.TILE_LAYOUT_STACKED_OFFSET:
					return {
						"cube_to_map": _cube_to_horizontal_stacked_offset,
						"map_to_cube": _horizontal_stacked_offset_to_cube
					}
				TileSet.TileLayout.TILE_LAYOUT_STAIRS_RIGHT:
					return {
						"cube_to_map": _cube_to_horizontal_stairs_right,
						"map_to_cube": _horizontal_stairs_right_to_cube
					}
				TileSet.TileLayout.TILE_LAYOUT_STAIRS_DOWN:
					return {
						"cube_to_map": _cube_to_horizontal_stairs_down,
						"map_to_cube": _horizontal_stairs_down_to_cube
					}
				TileSet.TileLayout.TILE_LAYOUT_DIAMOND_RIGHT:
					return {
						"cube_to_map": _cube_to_horizontal_diamond_right,
						"map_to_cube": _horizontal_diamond_right_to_cube
					}
				TileSet.TileLayout.TILE_LAYOUT_DIAMOND_DOWN:
					return {
						"cube_to_map": _cube_to_horizontal_diamond_down,
						"map_to_cube": _horizontal_diamond_down_to_cube
					}
		TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_VERTICAL:
			match layout:
				TileSet.TileLayout.TILE_LAYOUT_STACKED:
					return {
						"cube_to_map": _cube_to_vertical_stacked,
						"map_to_cube": _vertical_stacked_to_cube
					}
				TileSet.TileLayout.TILE_LAYOUT_STACKED_OFFSET:
					return {
						"cube_to_map": _cube_to_vertical_stacked_offset,
						"map_to_cube": _vertical_stacked_offset_to_cube
					}
				TileSet.TileLayout.TILE_LAYOUT_STAIRS_RIGHT:
					return {
						"cube_to_map": _cube_to_vertical_stairs_right,
						"map_to_cube": _vertical_stairs_right_to_cube
					}
				TileSet.TileLayout.TILE_LAYOUT_STAIRS_DOWN:
					return {
						"cube_to_map": _cube_to_vertical_stairs_down,
						"map_to_cube": _vertical_stairs_down_to_cube
					}
				TileSet.TileLayout.TILE_LAYOUT_DIAMOND_RIGHT:
					return {
						"cube_to_map": _cube_to_vertical_diamond_right,
						"map_to_cube": _vertical_diamond_right_to_cube
					}
				TileSet.TileLayout.TILE_LAYOUT_DIAMOND_DOWN:
					return {
						"cube_to_map": _cube_to_vertical_diamond_down,
						"map_to_cube": _vertical_diamond_down_to_cube
					}
	push_error("Could not find conversion method for axis %d and layout %s" % [axis, layout])
	return {}


func cube_to_map(cube_position: Vector3i) -> Vector2i:
	return _cube_to_map.call(cube_position)


func map_to_cube(map_position: Vector2i) -> Vector3i:
	return _map_to_cube.call(map_position)


static func _cube_to_horizontal_stacked(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x + ((cube_position.y & ~1) >> 1)
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


static func _horizontal_stacked_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x - ((map_position.y & ~1) >> 1)
	var l_y = map_position.y
	return Vector3i(l_x, l_y, - l_x - l_y)


static func _cube_to_horizontal_stacked_offset(cube_position: Vector3i) -> Vector2i:
	var x = cube_position.x + (cube_position.y + 1 >> 1)
	var y = cube_position.y
	return Vector2i(x, y)


static func _horizontal_stacked_offset_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x - ((map_position.y + 1) >> 1)
	var l_y = map_position.y
	return Vector3i(l_x, l_y, - l_x - l_y)


static func _cube_to_horizontal_stairs_right(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


static func _horizontal_stairs_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y
	return Vector3i(l_x, l_y, - l_x - l_y)


static func _cube_to_horizontal_stairs_down(cube_position: Vector3i) -> Vector2i:
	var l_y = - cube_position.x
	var l_x = - cube_position.z - l_y
	return Vector2i(l_x, l_y)


static func _horizontal_stairs_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = - map_position.y
	var l_y = map_position.x + map_position.y + map_position.y
	var l_z = - map_position.x - map_position.y
	return Vector3i(l_x, l_y, l_z)


static func _cube_to_horizontal_diamond_right(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = - cube_position.z
	return Vector2i(l_x, l_y)


static func _horizontal_diamond_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y - map_position.x
	var l_z = - map_position.y
	return Vector3i(l_x, l_y, l_z)


static func _cube_to_horizontal_diamond_down(cube_position: Vector3i) -> Vector2i:
	var l_x = - cube_position.z
	var l_y = - cube_position.x
	return Vector2i(l_x, l_y)


static func _horizontal_diamond_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = - map_position.y
	var l_y = map_position.x + map_position.y
	var l_z = - map_position.x
	return Vector3i(l_x, l_y, l_z)


static func _cube_to_vertical_stacked(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y + ((cube_position.x - (cube_position.x & 1)) >> 1)
	return Vector2i(l_x, l_y)


static func _vertical_stacked_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y - ((map_position.x - (map_position.x & 1)) >> 1)
	return Vector3i(l_x, l_y, - l_x - l_y)


static func _cube_to_vertical_stacked_offset(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y + ((cube_position.x + (cube_position.x & 1)) >> 1)
	return Vector2i(l_x, l_y)


static func _vertical_stacked_offset_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y - ((map_position.x + (map_position.x & 1)) >> 1)
	return Vector3i(l_x, l_y, - l_x - l_y)


static func _cube_to_vertical_stairs_right(cube_position: Vector3i) -> Vector2i:
	var l_x = - cube_position.y
	var l_y = cube_position.x + 2 * cube_position.y
	return Vector2i(l_x, l_y)


static func _vertical_stairs_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.y + map_position.x * 2
	var l_y = - map_position.x
	return Vector3i(l_x, l_y, - l_x - l_y)


static func _cube_to_vertical_stairs_down(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


static func _vertical_stairs_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y
	return Vector3i(l_x, l_y, - l_x - l_y)


static func _cube_to_vertical_diamond_right(cube_position: Vector3i) -> Vector2i:
	var l_x = - cube_position.y
	var l_y = - cube_position.z
	return Vector2i(l_x, l_y)


static func _vertical_diamond_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_y = - map_position.x
	var l_z = - map_position.y
	return Vector3i(- l_y - l_z, l_y, l_z)


static func _cube_to_vertical_diamond_down(cube_position: Vector3i) -> Vector2i:
	var l_x = - cube_position.z
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


static func _vertical_diamond_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_y = map_position.y
	var l_z = - map_position.x
	return Vector3i(- l_y - l_z, l_y, l_z)


#endregion

#region Cube coords maths


func cube_direction(direction: TileSet.CellNeighbor) -> Vector3i:
	return cube_direction_vectors[direction]


static func cube_direction_for_axis(
	axis: TileSet.TileOffsetAxis, direction: TileSet.CellNeighbor
) -> Vector3i:
	if axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		return cube_horizontal_direction_vectors[direction]
	else:
		return cube_vertical_direction_vectors[direction]


func cube_neighbor(cube: Vector3i, direction: TileSet.CellNeighbor) -> Vector3i:
	return cube + cube_direction(direction)


static func cube_neighbor_for_axis(
	axis: TileSet.TileOffsetAxis, cube: Vector3i, direction: TileSet.CellNeighbor
) -> Vector3i:
	return cube + cube_direction_for_axis(axis, direction)


func cube_neighbors(cube: Vector3i) -> Array[Vector3i]:
	return _cube_neighbors_for_neighbor(cube_side_neighbor_directions, cube_direction_vectors, cube)


static func cube_neighbors_for_axis(
	axis: TileSet.TileOffsetAxis, cube: Vector3i
) -> Array[Vector3i]:
	if axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		return _cube_neighbors_for_neighbor(
			cube_horizontal_side_neighbor_directions, cube_horizontal_direction_vectors, cube
		)
	else:
		return _cube_neighbors_for_neighbor(
			cube_vertical_side_neighbor_directions, cube_vertical_direction_vectors, cube
		)


static func _cube_neighbors_for_neighbor(
	neighbor_directions: Array[TileSet.CellNeighbor],
	direction_vectors: Dictionary[TileSet.CellNeighbor, Vector3i],
	cube: Vector3i
) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	result.resize(WEDGE_COUNT)
	for neighbor_index in WEDGE_COUNT:
		var neighbor = neighbor_directions[neighbor_index]
		result[neighbor_index] = cube + direction_vectors[neighbor]
	return result


func cube_corner_neighbors(cube: Vector3i) -> Array[Vector3i]:
	return _cube_corner_neighbors_for_neighbor(
		cube_corner_neighbor_directions, cube_direction_vectors, cube
	)


static func cube_corner_neighbors_for_axis(
	axis: TileSet.TileOffsetAxis, cube: Vector3i
) -> Array[Vector3i]:
	if axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		return _cube_corner_neighbors_for_neighbor(
			cube_horizontal_corner_neighbor_directions, cube_horizontal_direction_vectors, cube
		)
	else:
		return _cube_corner_neighbors_for_neighbor(
			cube_vertical_corner_neighbor_directions, cube_vertical_direction_vectors, cube
		)


static func _cube_corner_neighbors_for_neighbor(
	neighbor_directions: Array[TileSet.CellNeighbor],
	direction_vectors: Dictionary[TileSet.CellNeighbor, Vector3i],
	cube: Vector3i
) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	result.resize(WEDGE_COUNT)
	for neighbor_index in WEDGE_COUNT:
		var neighbor = neighbor_directions[neighbor_index]
		result[neighbor_index] = cube + direction_vectors[neighbor]
	return result


static func cube_distance(a: Vector3i, b: Vector3i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y), abs(a.z - b.z))


static func cube_linedraw(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var results: Array[Vector3i] = []
	var distance = cube_distance(a, b)
	var ac = Vector3(a)
	var bc = Vector3(b)
	for index in range(0, distance):
		results.append(Vector3i(lerp(ac, bc, 1.0 / distance * index).round()))
	# Sometime the edges are missings
	if results[0] != a:
		results.push_front(a)
	if results[-1] != b:
		results.push_back(b)
	return results


static func cube_range(center: Vector3i, distance: int) -> Array[Vector3i]:
	var results: Array[Vector3i] = []
	for q in range(- distance, distance + 1):
		for r in range(max(- distance, -q - distance), min(distance, -q + distance) + 1):
			var s = -q - r
			results.append(center + Vector3i(q, r, s))
	return results


static func cube_intersect_ranges(
	center1: Vector3i, range1: int, center2: Vector3i, range2: int
) -> Array[Vector3i]:
	var results: Array[Vector3i] = []
	var xmin = max(center1.x - range1, center2.x - range2)
	var xmax = min(center1.x + range1, center2.x + range2)
	var ymin = max(center1.y - range1, center2.y - range2)
	var ymax = min(center1.y + range1, center2.y + range2)
	var zmin = max(center1.z - range1, center2.z - range2)
	var zmax = min(center1.z + range1, center2.z + range2)
	for q in range(xmin, xmax + 1):
		for r in range(max(ymin, -q - zmax), min(ymax, -q - zmin) + 1):
			results.append(Vector3i(q, r, -q - r))
	return results


# Positive rotation = clockwise
static func cube_rotate(position: Vector3i, rotations: int) -> Vector3i:
	if abs(rotations) > WEDGE_COUNT:
		rotations = roundi(rotations % WEDGE_COUNT)
	if rotations == 0:
		return position
	elif rotations < 0:
		for i in range(- rotations):
			position = Vector3i(- position.z, - position.x, - position.y)
	elif rotations > 0:
		for i in range(rotations):
			position = Vector3i(- position.y, - position.z, - position.x)
	return position


static func cube_rotate_from(position: Vector3i, from: Vector3i, rotations: int) -> Vector3i:
	return from + cube_rotate(position - from, rotations)


static func cube_reflect(position: Vector3i, axis: int) -> Vector3i:
	match axis:
		Vector3i.AXIS_X:
			return Vector3i(position.x, position.z, position.y)
		Vector3i.AXIS_Y:
			return Vector3i(position.z, position.y, position.x)
		Vector3i.AXIS_Z:
			return Vector3i(position.y, position.x, position.z)
	return position


static func cube_reflect_from(position: Vector3i, from: Vector3i, axis: int) -> Vector3i:
	return from + cube_reflect(position - from, axis)


static func cube_rect(
	center: Vector3i, corner: Vector3i, axis: int = Vector3i.AXIS_Y
) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	result.resize(4)
	result[0] = corner
	result[1] = cube_reflect_from(corner, center, axis)
	result[2] = - result[0]
	result[3] = - result[1]
	return result


func cube_ring(
	center: Vector3i, radius: int, first_side: TileSet.CellNeighbor = -1
) -> Array[Vector3i]:
	return _cube_ring_for_neighbor(
		cube_side_neighbor_directions, cube_direction_vectors, center, radius, first_side
	)


static func cube_ring_for_axis(
	axis: TileSet.TileOffsetAxis,
	center: Vector3i,
	radius: int,
	first_side: TileSet.CellNeighbor = -1
) -> Array[Vector3i]:
	if axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		return _cube_ring_for_neighbor(
			cube_horizontal_side_neighbor_directions,
			cube_horizontal_direction_vectors,
			center,
			radius,
			first_side
		)
	else:
		return _cube_ring_for_neighbor(
			cube_vertical_side_neighbor_directions,
			cube_vertical_direction_vectors,
			center,
			radius,
			first_side
		)


static func _cube_ring_for_neighbor(
	neighbor_directions: Array[TileSet.CellNeighbor],
	direction_vectors: Dictionary[TileSet.CellNeighbor, Vector3i],
	center: Vector3i,
	radius: int,
	first_side: TileSet.CellNeighbor = -1
) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var first_index: int
	if first_side == -1:
		first_index = 0
		first_side = neighbor_directions[first_index]
	else:
		first_index = neighbor_directions.find(first_side)

	if first_index == -1:
		push_error("Invalid first_side value provided '%s'" % first_index)
		return result
	if radius < 1:
		return result

	var hex = center + direction_vectors[first_side] * radius
	for i in range(first_index + 2, first_index + 8):
		for j in range(radius):
			result.append(hex)
			hex += direction_vectors[neighbor_directions[i % WEDGE_COUNT]]
	return result


func cube_spiral(center: Vector3i, radius: int, first_side: TileSet.CellNeighbor = -1):
	return _cube_spiral_for_neighbor(
		cube_side_neighbor_directions, cube_direction_vectors, center, radius, first_side
	)


static func cube_spiral_for_axis(
	axis: TileSet.TileOffsetAxis,
	center: Vector3i,
	radius: int,
	first_side: TileSet.CellNeighbor = -1
) -> Array[Vector3i]:
	if axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		return _cube_spiral_for_neighbor(
			cube_horizontal_side_neighbor_directions,
			cube_horizontal_direction_vectors,
			center,
			radius,
			first_side
		)
	else:
		return _cube_spiral_for_neighbor(
			cube_vertical_side_neighbor_directions,
			cube_vertical_direction_vectors,
			center,
			radius,
			first_side
		)


static func _cube_spiral_for_neighbor(
	neighbor_directions: Array[TileSet.CellNeighbor],
	direction_vectors: Dictionary[TileSet.CellNeighbor, Vector3i],
	center: Vector3i,
	radius: int,
	first_side: TileSet.CellNeighbor = -1
):
	var result: Array[Vector3i] = [center]
	if radius < 1:
		return result
	for k in range(1, radius + 1):
		var new_ring = _cube_ring_for_neighbor(
			neighbor_directions, direction_vectors, center, k, first_side
		)
		for a in range(1, k):
			new_ring.push_front(new_ring.pop_back())
		result.append_array(new_ring)
	return result

#endregion


#region Closest Cell Operations
func get_closest_cell_from_mouse() -> Vector3i:
	return get_closest_cell_from_local(get_local_mouse_position())


func get_closest_cell_from_local(local: Vector2) -> Vector3i:
	return map_to_cube(local_to_map(local))


func get_closest_cells_from_mouse(count: int = 1) -> Array[Vector3i]:
	return get_closest_cells_from_local(get_local_mouse_position(), count)


func get_closest_cells_from_local(local: Vector2, count: int = 1) -> Array[Vector3i]:
	var center_map = local_to_map(local)
	var center_cube = map_to_cube(center_map)
	var cells: Array[Vector3i] = [center_cube]
	if count == 1:
		return cells
	cells.resize(count)
	count -= 1
	
	var center_local = map_to_local(center_map)
	var wedge_index := _wedge_index_for_local_direction(local - center_local)
	var direction_index = ceili(wedge_index)
	var next_after = wedge_index - direction_index > -0.5
	var direction = cube_side_neighbor_directions[direction_index - 1]
	var current_ring_size: int = 1
	if next_after:
		while count > 0:
			var ring = cube_ring(center_cube, current_ring_size, direction)
			current_ring_size += 1
			for i in ring.size() / 2 + 1:
				cells.append(ring[i])
				count -= 1
				if count < 0:
					return cells
				cells.append(ring[-i])
				count -= 1
				if count < 0:
					return cells
	else:
		while count > 0:
			var ring = cube_ring(center_cube, current_ring_size, direction)
			current_ring_size += 1
			for i in ring.size() / 2 + 1:
				cells.append(ring[-i])
				count -= 1
				if count < 0:
					return cells
				cells.append(ring[i])
				count -= 1
				if count < 0:
					return cells
	return [] # For the linter, will never happen

func _wedge_index_for_local_direction(direction: Vector2) -> float:
	return _wedge_index_for_local_direction_for_axis(tile_set.tile_offset_axis, direction)

static func _wedge_index_for_local_direction_for_axis(axis: TileSet.TileOffsetAxis, direction: Vector2) -> float:
	if axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		return absf(WEDGE_COUNT - WEDGE_INV_ANGLE * (direction.angle_to(Vector2.DOWN) + PI))
	else:
		return absf(WEDGE_COUNT - WEDGE_INV_ANGLE * (direction.angle_to(Vector2.DOWN.rotated(WEDGE_ANGLE_HALF)) + PI))
#endregion
