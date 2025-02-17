@tool

class_name HexagonTileMapLayer extends TileMapLayer

var astar: AStar2D

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


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		tile_set.changed.connect(update_configuration_warnings)
	else:
		tile_set.changed.connect(_update_conversion_methods)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		tile_set.changed.disconnect(update_configuration_warnings)
	else:
		tile_set.changed.disconnect(_update_conversion_methods)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_update_conversion_methods()

	if pathfinding_enabled:
		astar_changed.connect(_draw_debug, Object.CONNECT_DEFERRED)
		astar = AStar2D.new()

		_pathfinding_generate_points()
		astar_changed.emit()
	else:
		_draw_debug.call_deferred()


var _cube_to_map: Callable
var _map_to_cube: Callable


func _get_configuration_warnings():
	var warnings: Array[String] = []
	if tile_set.tile_shape != TileSet.TileShape.TILE_SHAPE_HEXAGON:
		warnings.append("This node only support hexagon shapes")

	if not tile_set.tile_layout == TileSet.TileLayout.TILE_LAYOUT_STACKED or tile_set.tile_layout == TileSet.TileLayout.TILE_LAYOUT_STACKED_OFFSET:
		warnings.append("This script only support stacked layout")
	return warnings


#region Pathfinding
func _pathfinding_get_tile_weight(coords: Vector2i) -> float:
	return 1.0


func _pathfinding_does_tile_connect(tile: Vector2i, neighbor: Vector2i) -> bool:
	return true


func pathfinding_get_point_id(coord: Vector2i) -> int:
	return astar.get_closest_point(map_to_local(coord))


func pathfinding_recalculate_tile_weight(coord: Vector2i):
	astar.set_point_weight_scale(pathfinding_get_point_id(coord), _pathfinding_get_tile_weight(coord))


func _pathfinding_generate_points():
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
					_pathfinding_debug_display_connection(connections_container, id, neighbour_id, Color(randf(), randf(), randf(), 1.0))
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

	get_tree().root.add_child.call_deferred(debug_container)


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
	var text = "[center]#%d\n(%d, %d)\n(%d, %d, %d)[/center]" % [id, pos.x, pos.y, cube.x, cube.y, cube.z]
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
	const neighbour_directions = [
		TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
	]

	for id in astar.get_point_ids():
		var local_position = astar.get_point_position(id)
		var map_position = local_to_map(local_position)
		for neighbour in neighbour_directions:
			var neighbour_map_position = get_neighbor_cell(map_position, neighbour)
			if get_cell_source_id(neighbour_map_position) == -1:
				continue
			if not _pathfinding_does_tile_connect(map_position, neighbour_map_position):
				continue
			var neighbour_id = astar.get_closest_point(map_to_local(neighbour_map_position))
			astar.connect_points(id, neighbour_id)


func _pathfinding_debug_display_connection(debug_container: Node2D, id1: int, id2: int, color: Color):
	var line: Line2D = Line2D.new()
	line.default_color = color
	line.add_point(astar.get_point_position(id1))
	line.add_point(astar.get_point_position(id2))
	debug_container.add_child(line)


#endregion

#region Cube coords conversions


func cube_to_local(cube_position: Vector3i) -> Vector2:
	return map_to_local(cube_to_map(cube_position))


func local_to_cube(map_position: Vector2) -> Vector3i:
	return map_to_cube(local_to_map(map_position))


func _update_conversion_methods() -> void:
	match tile_set.tile_offset_axis:
		TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
			match tile_set.tile_layout:
				TileSet.TileLayout.TILE_LAYOUT_STACKED:
					_cube_to_map = _cube_to_horizontal_stacked
					_map_to_cube = _horizontal_stacked_to_cube
				TileSet.TileLayout.TILE_LAYOUT_STACKED_OFFSET:
					_cube_to_map = _cube_to_horizontal_stacked_offset
					_map_to_cube = _horizontal_stacked_offset_to_cube
				TileSet.TileLayout.TILE_LAYOUT_STAIRS_RIGHT:
					_cube_to_map = _cube_to_horizontal_stairs_right
					_map_to_cube = _horizontal_stairs_right_to_cube
				TileSet.TileLayout.TILE_LAYOUT_STAIRS_DOWN:
					_cube_to_map = _cube_to_horizontal_stairs_down
					_map_to_cube = _horizontal_stairs_down_to_cube
				TileSet.TileLayout.TILE_LAYOUT_DIAMOND_RIGHT:
					_cube_to_map = _cube_to_horizontal_diamond_right
					_map_to_cube = _horizontal_diamond_right_to_cube
				TileSet.TileLayout.TILE_LAYOUT_DIAMOND_DOWN:
					_cube_to_map = _cube_to_horizontal_diamond_down
					_map_to_cube = _horizontal_diamond_down_to_cube
		TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_VERTICAL:
			match tile_set.tile_layout:
				TileSet.TileLayout.TILE_LAYOUT_STACKED:
					_cube_to_map = _cube_to_vertical_stacked
					_map_to_cube = _vertical_stacked_to_cube
				TileSet.TileLayout.TILE_LAYOUT_STACKED_OFFSET:
					_cube_to_map = _cube_to_vertical_stacked_offset
					_map_to_cube = _vertical_stacked_offset_to_cube
				TileSet.TileLayout.TILE_LAYOUT_STAIRS_RIGHT:
					_cube_to_map = _cube_to_vertical_stairs_right
					_map_to_cube = _vertical_stairs_right_to_cube
				TileSet.TileLayout.TILE_LAYOUT_STAIRS_DOWN:
					_cube_to_map = _cube_to_vertical_stairs_down
					_map_to_cube = _vertical_stairs_down_to_cube
				TileSet.TileLayout.TILE_LAYOUT_DIAMOND_RIGHT:
					_cube_to_map = _cube_to_vertical_diamond_right
					_map_to_cube = _vertical_diamond_right_to_cube
				TileSet.TileLayout.TILE_LAYOUT_DIAMOND_DOWN:
					_cube_to_map = _cube_to_vertical_diamond_down
					_map_to_cube = _vertical_diamond_down_to_cube


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
	return Vector3i(l_x, l_y, -l_x - l_y)


static func _cube_to_horizontal_stacked_offset(cube_position: Vector3i) -> Vector2i:
	var x = cube_position.x + (cube_position.y + 1 >> 1)
	var y = cube_position.y
	return Vector2i(x, y)


static func _horizontal_stacked_offset_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x - ((map_position.y + 1) >> 1)
	var l_y = map_position.y
	return Vector3i(l_x, l_y, -l_x - l_y)


static func _cube_to_horizontal_stairs_right(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


static func _horizontal_stairs_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y
	return Vector3i(l_x, l_y, -l_x - l_y)


static func _cube_to_horizontal_stairs_down(cube_position: Vector3i) -> Vector2i:
	var l_y = -cube_position.x
	var l_x = -cube_position.z - l_y
	return Vector2i(l_x, l_y)


static func _horizontal_stairs_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = -map_position.y
	var l_y = map_position.x + map_position.y + map_position.y
	var l_z = -map_position.x - map_position.y
	return Vector3i(l_x, l_y, l_z)


static func _cube_to_horizontal_diamond_right(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = -cube_position.z
	return Vector2i(l_x, l_y)


static func _horizontal_diamond_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y - map_position.x
	var l_z = -map_position.y
	return Vector3i(l_x, l_y, l_z)


static func _cube_to_horizontal_diamond_down(cube_position: Vector3i) -> Vector2i:
	var l_x = -cube_position.z
	var l_y = -cube_position.x
	return Vector2i(l_x, l_y)


static func _horizontal_diamond_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = -map_position.y
	var l_y = map_position.x + map_position.y
	var l_z = -map_position.x
	return Vector3i(l_x, l_y, l_z)


static func _cube_to_vertical_stacked(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y + ((cube_position.x - (cube_position.x & 1)) >> 1)
	return Vector2i(l_x, l_y)


static func _vertical_stacked_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y - ((map_position.x - (map_position.x & 1)) >> 1)
	return Vector3i(l_x, l_y, -l_x - l_y)


static func _cube_to_vertical_stacked_offset(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y + ((cube_position.x + (cube_position.x & 1)) >> 1)
	return Vector2i(l_x, l_y)


static func _vertical_stacked_offset_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y - ((map_position.x + (map_position.x & 1)) >> 1)
	return Vector3i(l_x, l_y, -l_x - l_y)


static func _cube_to_vertical_stairs_right(cube_position: Vector3i) -> Vector2i:
	var l_x = -cube_position.y
	var l_y = cube_position.x + 2 * cube_position.y
	return Vector2i(l_x, l_y)


static func _vertical_stairs_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.y + map_position.x * 2
	var l_y = -map_position.x
	return Vector3i(l_x, l_y, -l_x - l_y)


static func _cube_to_vertical_stairs_down(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


static func _vertical_stairs_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y
	return Vector3i(l_x, l_y, -l_x - l_y)


static func _cube_to_vertical_diamond_right(cube_position: Vector3i) -> Vector2i:
	var l_x = -cube_position.y
	var l_y = -cube_position.z
	return Vector2i(l_x, l_y)


static func _vertical_diamond_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_y = -map_position.x
	var l_z = -map_position.y
	return Vector3i(-l_y - l_z, l_y, l_z)


static func _cube_to_vertical_diamond_down(cube_position: Vector3i) -> Vector2i:
	var l_x = -cube_position.z
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


static func _vertical_diamond_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_y = map_position.y
	var l_z = -map_position.x
	return Vector3i(-l_y - l_z, l_y, l_z)


#endregion

#region Cube coords maths

const cube_direction_vectors = {
	TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE: Vector3i(1, 0, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE: Vector3i(0, 1, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE: Vector3i(-1, 1, 0),
	TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE: Vector3i(-1, 0, 1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE: Vector3i(0, -1, 1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE: Vector3i(1, -1, 0),
	TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_CORNER: Vector3i(2, -1, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER: Vector3i(1, -2, 1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER: Vector3i(-1, -1, 2),
	TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_CORNER: Vector3i(-2, 1, 1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER: Vector3i(-1, 2, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER: Vector3i(1, 1, -2),
}


static func cube_direction(direction: TileSet.CellNeighbor) -> Vector3i:
	return cube_direction_vectors[direction]


static func cube_neighbor(cube: Vector3i, direction: TileSet.CellNeighbor) -> Vector3i:
	return cube + cube_direction(direction)


static func cube_neighbors(cube: Vector3i) -> Array[Vector3i]:
	return [
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE],
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE],
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE],
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE],
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE],
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE],
	]


static func cube_diagonal_neighbors(cube: Vector3i) -> Array[Vector3i]:
	return [
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_CORNER],
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER],
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER],
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_CORNER],
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER],
		cube + cube_direction_vectors[TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER],
	]


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
	for q in range(-distance, distance + 1):
		for r in range(max(-distance, -q - distance), min(distance, -q + distance) + 1):
			var s = -q - r
			results.append(center + Vector3i(q, r, s))
	return results


static func cube_intersect_ranges(center1: Vector3i, range1: int, center2: Vector3i, range2: int) -> Array[Vector3i]:
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
	if abs(rotations) > 6:
		rotations = roundi(rotations % 6)
	if rotations == 0:
		return position
	elif rotations < 0:
		for i in range(-rotations):
			position = Vector3i(-position.z, -position.x, -position.y)
	elif rotations > 0:
		for i in range(rotations):
			position = Vector3i(-position.y, -position.z, -position.x)
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


static func cube_rect(center: Vector3i, corner: Vector3i, axis: int = Vector3i.AXIS_Y) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	result.resize(4)
	result[0] = corner
	result[1] = cube_reflect_from(corner, center, axis)
	result[2] = -result[0]
	result[3] = -result[1]
	return result


static func cube_ring(center: Vector3i, radius: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	if radius < 1:
		return result
	var hex = center + cube_direction(TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE) * radius
	for i in [
		TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
	]:
		for j in range(radius):
			result.append(hex)
			hex = cube_neighbor(hex, i)
	return result


static func cube_spiral(center: Vector3i, radius: int):
	var result: Array[Vector3i] = [center]
	if radius < 1:
		return result
	for k in range(1, radius + 1):
		var new_ring = cube_ring(center, k)
		for a in range(1, k):
			new_ring.push_front(new_ring.pop_back())
		result.append_array(new_ring)
	return result


#endregion


func test(foo: Vector2i):
	var foo_local = map_to_local(foo)
	var foo_cube = map_to_cube(foo)
	var center_cube = map_to_cube(Vector2i(0, 0))

	#line.add_point(cube_to_local(center_cube))
	var points = cube_spiral(center_cube, 2)
	for point_index in range(1, points.size()):
		var line = Line2D.new()
		line.width = 5.0
		line.default_color = Color(randf(), randf(), randf())
		line.z_index = 1000
		line.add_point(cube_to_local(points[point_index - 1]))
		line.add_point(cube_to_local(points[point_index]))
		add_child(line)
