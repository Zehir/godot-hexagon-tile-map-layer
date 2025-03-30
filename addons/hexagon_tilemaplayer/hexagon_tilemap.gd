@tool
@icon("hexagon_tilemaplayer.svg")

## Set of tools to use hexagon based tilemap in Godot with [AStar2D] pathfinding and cube coordinates system.
##
## Usualy theses methods are called from the [HexagonTileMapLayer] node.
class_name HexagonTileMap

const WEDGE_ANGLE: float = deg_to_rad(60.0)
const WEDGE_INV_ANGLE: float = 1 / WEDGE_ANGLE
const WEDGE_ANGLE_HALF: float = deg_to_rad(30.0)
const WEDGE_INV_ANGLE_HALF: float = 1 / WEDGE_ANGLE_HALF
const WEDGE_COUNT: int = 6

#region Cube coords conversions

## Direction vector for each neighbor in cube coordinates for horizontal layout.
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

## CellNeighbor array for each side neighbor for horizontal layout.
const cube_horizontal_side_neighbor_directions: Array[TileSet.CellNeighbor] = [
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE,
]

## CellNeighbor array for each corner neighbor for horizontal layout.
const cube_horizontal_corner_neighbor_directions: Array[TileSet.CellNeighbor] = [
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_CORNER,
]

## Direction vector for each neighbor in cube coordinates for vertical layout.
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

## CellNeighbor array for each side neighbor for vertical layout.
const cube_vertical_side_neighbor_directions: Array[TileSet.CellNeighbor] = [
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_SIDE,
]

## CellNeighbor array for each corner neighbor for vertical layout.
const cube_vertical_corner_neighbor_directions: Array[TileSet.CellNeighbor] = [
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER,
]


## Returns a dictionary containing conversion methods for the specified axis and layout.
##
## [br]The dictionary contains two functions:
## [br]- `map_to_cube`: Converts from tilemap coordinates to cube coordinates
## [br]- `cube_to_map`: Converts from cube coordinates to tilemap coordinates
## [br]This is particularly useful when you need to handle different hex layouts in custom systems.
## [codeblock]
## # Get converters for a specific layout
## var converters = HexagonTileMapLayer.get_conversion_methods_for(
##     TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL,
##     TileSet.TileLayout.TILE_LAYOUT_STACKED
## )
## [/codeblock]
## [codeblock]
## # Use the converters
## var cube_pos = converters.map_to_cube.call(tile_pos)
## var map_pos = converters.cube_to_map.call(cube_pos)
## [/codeblock]
## [codeblock]
## # Handle multiple layouts
## var layout_converters = {
##     "stacked": HexagonTileMapLayer.get_conversion_methods_for(
##         TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL,
##         TileSet.TileLayout.TILE_LAYOUT_STACKED
##     ),
##     "diamond": HexagonTileMapLayer.get_conversion_methods_for(
##         TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL,
##         TileSet.TileLayout.TILE_LAYOUT_DIAMOND_RIGHT
##     )
## }
## [/codeblock]
static func get_conversion_methods_for(
	axis: TileSet.TileOffsetAxis, layout: TileSet.TileLayout
) -> Dictionary[String, Callable]:
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


## Convert cube coordinate to horizontal stacked map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_horizontal_stacked(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x + ((cube_position.y & ~1) >> 1)
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


## Convert horizontal stacked map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _horizontal_stacked_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x - ((map_position.y & ~1) >> 1)
	var l_y = map_position.y
	return Vector3i(l_x, l_y, -l_x - l_y)


## Convert cube coordinate to horizontal offset stacked map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_horizontal_stacked_offset(cube_position: Vector3i) -> Vector2i:
	var x = cube_position.x + (cube_position.y + 1 >> 1)
	var y = cube_position.y
	return Vector2i(x, y)


## Convert horizontal offset stacked map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _horizontal_stacked_offset_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x - ((map_position.y + 1) >> 1)
	var l_y = map_position.y
	return Vector3i(l_x, l_y, -l_x - l_y)


## Convert cube coordinate to horizontal stairs right map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_horizontal_stairs_right(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


## Convert horizontal stairs right map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _horizontal_stairs_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y
	return Vector3i(l_x, l_y, -l_x - l_y)


## Convert cube coordinate to horizontal stairs down map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_horizontal_stairs_down(cube_position: Vector3i) -> Vector2i:
	var l_y = -cube_position.x
	var l_x = -cube_position.z - l_y
	return Vector2i(l_x, l_y)


## Convert horizontal stairs down map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _horizontal_stairs_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = -map_position.y
	var l_y = map_position.x + map_position.y + map_position.y
	var l_z = -map_position.x - map_position.y
	return Vector3i(l_x, l_y, l_z)


## Convert cube coordinate to horizontal diamond right map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_horizontal_diamond_right(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = -cube_position.z
	return Vector2i(l_x, l_y)


## Convert horizontal diamond right map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _horizontal_diamond_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y - map_position.x
	var l_z = -map_position.y
	return Vector3i(l_x, l_y, l_z)


## Convert cube coordinate to horizontal diamond down map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_horizontal_diamond_down(cube_position: Vector3i) -> Vector2i:
	var l_x = -cube_position.z
	var l_y = -cube_position.x
	return Vector2i(l_x, l_y)


## Convert horizontal diamond down map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _horizontal_diamond_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = -map_position.y
	var l_y = map_position.x + map_position.y
	var l_z = -map_position.x
	return Vector3i(l_x, l_y, l_z)


## Convert cube coordinate to vertical stacked map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_vertical_stacked(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y + ((cube_position.x - (cube_position.x & 1)) >> 1)
	return Vector2i(l_x, l_y)


## Convert vertical stacked map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _vertical_stacked_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y - ((map_position.x - (map_position.x & 1)) >> 1)
	return Vector3i(l_x, l_y, -l_x - l_y)


## Convert cube coordinate to vertical offset stacked map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_vertical_stacked_offset(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y + ((cube_position.x + (cube_position.x & 1)) >> 1)
	return Vector2i(l_x, l_y)


## Convert vertical offset stacked map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _vertical_stacked_offset_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y - ((map_position.x + (map_position.x & 1)) >> 1)
	return Vector3i(l_x, l_y, -l_x - l_y)


## Convert cube coordinate to vertical stairs right map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_vertical_stairs_right(cube_position: Vector3i) -> Vector2i:
	var l_x = -cube_position.y
	var l_y = cube_position.x + 2 * cube_position.y
	return Vector2i(l_x, l_y)


## Convert vertical stairs right map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _vertical_stairs_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.y + map_position.x * 2
	var l_y = -map_position.x
	return Vector3i(l_x, l_y, -l_x - l_y)


## Convert cube coordinate to vertical stairs down map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_vertical_stairs_down(cube_position: Vector3i) -> Vector2i:
	var l_x = cube_position.x
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


## Convert vertical stairs down map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _vertical_stairs_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_x = map_position.x
	var l_y = map_position.y
	return Vector3i(l_x, l_y, -l_x - l_y)


## Convert cube coordinate to vertical diamond right map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_vertical_diamond_right(cube_position: Vector3i) -> Vector2i:
	var l_x = -cube_position.y
	var l_y = -cube_position.z
	return Vector2i(l_x, l_y)


## Convert vertical diamond right map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _vertical_diamond_right_to_cube(map_position: Vector2i) -> Vector3i:
	var l_y = -map_position.x
	var l_z = -map_position.y
	return Vector3i(-l_y - l_z, l_y, l_z)


## Convert cube coordinate to vertical diamond down map coordinate.
## [br]See also [method get_conversion_methods_for]
static func _cube_to_vertical_diamond_down(cube_position: Vector3i) -> Vector2i:
	var l_x = -cube_position.z
	var l_y = cube_position.y
	return Vector2i(l_x, l_y)


## Convert vertical diamond down map coordinate to cube coordinate.
## [br]See also [method get_conversion_methods_for]
static func _vertical_diamond_down_to_cube(map_position: Vector2i) -> Vector3i:
	var l_y = map_position.y
	var l_z = -map_position.x
	return Vector3i(-l_y - l_z, l_y, l_z)


#endregion


#region Cube coords maths
## Returns the cube coordinate vector representing a hex direction.
##
## [br]Static version of [method HexagonTileMapLayer.cube_direction]. Returns the cube coordinate vector for a given direction.
## [codeblock]
## var vec = HexagonTileMapLayer.cube_direction_for_axis(
##     TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL,
##     TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE
## )
## [/codeblock]
static func cube_direction_for_axis(
	axis: TileSet.TileOffsetAxis, direction: TileSet.CellNeighbor
) -> Vector3i:
	if axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		return cube_horizontal_direction_vectors[direction]
	else:
		return cube_vertical_direction_vectors[direction]


## Gets the cube coordinates of a neighboring hex in a specified direction.
##
## [br]See [method HexagonTileMapLayer.cube_neighbor] for details.
static func cube_neighbor_for_axis(
	axis: TileSet.TileOffsetAxis, cube: Vector3i, direction: TileSet.CellNeighbor
) -> Vector3i:
	return cube + cube_direction_for_axis(axis, direction)


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


## Gets all adjacent hexes surrounding a center hex.
##
## [br]See [method HexagonTileMapLayer.cube_neighbors] for details.
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


## Gets all corner (diagonal) hexes surrounding a center hex.
##
## [br]See [method HexagonTileMapLayer.cube_corner_neighbors] for details.
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


## Calculates the distance distance between two hexes in the hex grid.
##
## [br]See [HexagonTileMapLayer.cube_distance] for details.
static func cube_distance(a: Vector3i, b: Vector3i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y), abs(a.z - b.z))


## Rounds a fractional cube coordinate to the nearest valid hex coordinate.
##
## [br]Takes a Vector3 with floating point components and converts it to the nearest
## valid hex cube coordinate (Vector3i with integer components) while maintaining
## the cube coordinate constraint (x + y + z = 0).
## [br]This is essential when converting from pixel coordinates to hex grid positions,
## performing interpolation between hex coordinates, or implementing line drawing algorithms.
## [br][b]Parameters:[/b]
## [br]- [param frac]: The fractional cube coordinate to round (Vector3)
## [br][b]Returns:[/b] The nearest valid hex coordinate as Vector3i
## [codeblock]
## # Round a fractional cube coordinate
## var fractional = Vector3(2.7, -1.3, -1.4)
## var hex_pos = HexagonTileMap.cube_round(fractional)
## print(hex_pos)  # Output: Vector3i(3, -1, -2)
## [/codeblock]
static func cube_round(frac: Vector3) -> Vector3i:
	var x = round(frac.x)
	var y = round(frac.y)
	var z = round(frac.z)

	var x_diff = abs(x - frac.x)
	var y_diff = abs(y - frac.y)
	var z_diff = abs(z - frac.z)

	if x_diff > y_diff and x_diff > z_diff:
		x = -y - z
	elif y_diff > z_diff:
		y = -x - z
	else:
		z = -x - y

	return Vector3i(x, y, z)


## Returns all hexes that form a line between two points.
##
## [br]See [HexagonTileMapLayer.cube_linedraw] for details.
static func cube_linedraw(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var results: Array[Vector3i] = []
	if a == b:
		results.append(a)
		return results

	var distance = cube_distance(a, b)
	var ac = Vector3(a)
	var bc = Vector3(b)
	for index in range(0, distance):
		results.append(cube_round(lerp(ac, bc, 1.0 / distance * index)))
	# Sometime the edges are missings
	if results[0] != a:
		results.push_front(a)
	if results[-1] != b:
		results.push_back(b)
	return results


## Gets all hexes within a certain distance of a center hex.
##
## [br]See [HexagonTileMapLayer.cube_range] for details.
static func cube_range(center: Vector3i, distance: int) -> Array[Vector3i]:
	var results: Array[Vector3i] = []
	if distance == 0:
		results.append(center)
		return results
	for q in range(-distance, distance + 1):
		for r in range(max(-distance, -q - distance), min(distance, -q + distance) + 1):
			var s = -q - r
			results.append(center + Vector3i(q, r, s))
	return results


## Returns all hexes that are within range1 of center1 AND within range2 of center2.
##
## [br]See [HexagonTileMapLayer.cube_intersect_ranges] for details.
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


## Rotates a hex position around the origin (0,0,0) by a number of 60-degree steps.
##
## [br]See [HexagonTileMapLayer.cube_rotate] for details.
static func cube_rotate(position: Vector3i, rotations: int) -> Vector3i:
	if abs(rotations) > WEDGE_COUNT:
		rotations = roundi(rotations % WEDGE_COUNT)
	if rotations == 0:
		return position
	elif rotations < 0:
		for i in range(-rotations):
			position = Vector3i(-position.z, -position.x, -position.y)
	elif rotations > 0:
		for i in range(rotations):
			position = Vector3i(-position.y, -position.z, -position.x)
	return position


## Rotates a hex position around a center point by a number of 60-degree steps.
##
## [br]See [HexagonTileMapLayer.cube_rotate_from] for details.
static func cube_rotate_from(position: Vector3i, from: Vector3i, rotations: int) -> Vector3i:
	return from + cube_rotate(position - from, rotations)


## Reflects a hex position across one of the three cube coordinate axes.
##
## [br]See [HexagonTileMapLayer.cube_reflect] for details.
static func cube_reflect(position: Vector3i, axis: Vector3i.Axis) -> Vector3i:
	match axis:
		Vector3i.Axis.AXIS_X:
			return Vector3i(position.x, position.z, position.y)
		Vector3i.Axis.AXIS_Y:
			return Vector3i(position.z, position.y, position.x)
		Vector3i.Axis.AXIS_Z:
			return Vector3i(position.y, position.x, position.z)
	return position


## Reflects a hex position around a center point across one of the three cube coordinate axes.
##
## [br]See [HexagonTileMapLayer.cube_reflect_from] for details.
static func cube_reflect_from(position: Vector3i, from: Vector3i, axis: Vector3i.Axis) -> Vector3i:
	return from + cube_reflect(position - from, axis)


## Creates a rectangle-like shape on the hex grid by reflecting a corner point around a center point.
##
## [br]See [HexagonTileMapLayer.cube_rect] for details.
static func cube_rect(
	center: Vector3i, corner: Vector3i, axis: Vector3i.Axis = Vector3i.Axis.AXIS_Y
) -> Array[Vector3i]:
	var corners = cube_rect_corners(center, corner, axis)
	var result: Array[Vector3i] = []

	# Get the bounds of the rectangle
	var min_x = min(corners[0].x, corners[1].x, corners[2].x, corners[3].x)
	var max_x = max(corners[0].x, corners[1].x, corners[2].x, corners[3].x)
	var min_y = min(corners[0].y, corners[1].y, corners[2].y, corners[3].y)
	var max_y = max(corners[0].y, corners[1].y, corners[2].y, corners[3].y)
	var min_z = min(corners[0].z, corners[1].z, corners[2].z, corners[3].z)
	var max_z = max(corners[0].z, corners[1].z, corners[2].z, corners[3].z)

	# Calculate diagonal vectors between corners
	var diag1 = corners[1] - corners[0]
	var diag2 = corners[3] - corners[0]

	# Fill the rectangle with all valid hex coordinates
	for q in range(min_x, max_x + 1):
		for r in range(max(min_y, -q - max_z), min(max_y, -q - min_z) + 1):
			var s = -q - r
			if s >= min_z and s <= max_z:
				var point = Vector3i(q, r, s)
				var v = point - corners[0]
				# Check if point is inside parallelogram using dot products
				var a = (
					float(v.x * diag2.y - v.y * diag2.x)
					/ float(diag1.x * diag2.y - diag1.y * diag2.x)
				)
				var b = (
					float(v.x * diag1.y - v.y * diag1.x)
					/ float(diag2.x * diag1.y - diag2.y * diag1.x)
				)
				if a >= 0 and a <= 1 and b >= 0 and b <= 1:
					result.append(point)
	return result


## Creates a rectangle-like shape on the hex grid by reflecting a corner point around a center point.
##
## [br]See [HexagonTileMapLayer.cube_rect_corners] for details.
static func cube_rect_corners(
	center: Vector3i, corner: Vector3i, axis: Vector3i.Axis = Vector3i.Axis.AXIS_Y
) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	result.resize(4)
	result[0] = corner
	result[1] = cube_reflect_from(corner, center, axis)
	var center_twice = center + center
	result[2] = center_twice - result[0]
	result[3] = center_twice - result[1]
	return result


## Gets all hexes at exactly a certain distance from the center.
##
## [br]See [method HexagonTileMapLayer.cube_ring] for details.
@warning_ignore("int_as_enum_without_cast")
@warning_ignore("int_as_enum_without_match")


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


@warning_ignore("int_as_enum_without_cast")
@warning_ignore("int_as_enum_without_match")


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
		result.append(center)
		return result

	var hex = center + direction_vectors[first_side] * radius
	for i in range(first_index + 2, first_index + 8):
		for j in range(radius):
			result.append(hex)
			hex += direction_vectors[neighbor_directions[i % WEDGE_COUNT]]
	return result


## Creates a spiral pattern starting from the center and going outward in a clockwise direction.
##
## [br]See [method HexagonTileMapLayer.cube_spiral] for details.
@warning_ignore("int_as_enum_without_cast")
@warning_ignore("int_as_enum_without_match")


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


@warning_ignore("int_as_enum_without_cast")
@warning_ignore("int_as_enum_without_match")


static func _cube_spiral_for_neighbor(
	neighbor_directions: Array[TileSet.CellNeighbor],
	direction_vectors: Dictionary[TileSet.CellNeighbor, Vector3i],
	center: Vector3i,
	radius: int,
	first_side: TileSet.CellNeighbor = -1
) -> Array[Vector3i]:
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


static func _wedge_index_for_local_direction_for_axis(
	axis: TileSet.TileOffsetAxis, direction: Vector2
) -> float:
	if axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		return absf(
			(
				HexagonTileMap.WEDGE_COUNT
				- HexagonTileMap.WEDGE_INV_ANGLE * (direction.angle_to(Vector2.DOWN) + PI)
			)
		)
	else:
		return absf(
			(
				HexagonTileMap.WEDGE_COUNT
				- (
					HexagonTileMap.WEDGE_INV_ANGLE
					* (
						direction.angle_to(Vector2.DOWN.rotated(HexagonTileMap.WEDGE_ANGLE_HALF))
						+ PI
					)
				)
			)
		)


#endregion

#region Geometry


## Returns the geometry methods for a specific axis.
##
## [br]The returned dictionary contains the following methods:
## [br]- `tile_corners`: Returns the local positions of corner a hexagon tile. See [method geometry_horizontal_tile_corners] and [method geometry_vertical_tile_corners].
static func get_geometry_methods_for(axis: TileSet.TileOffsetAxis) -> Dictionary[String, Callable]:
	if axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		return {"tile_corners": geometry_horizontal_tile_corners}
	else:
		return {"tile_corners": geometry_vertical_tile_corners}


## Returns the local positions of corner a hexagon tile in a horizontal layout.
##
## [br]The returned array contains the corner positions in local coordinates relative to the tile center.
## [br]The corners are ordered in a clockwise direction starting from the top right corner.
static func geometry_horizontal_tile_corners(tile_size: Vector2i) -> Array[Vector2]:
	var height = tile_size.y
	var width = tile_size.x
	var half_height = height * 0.5
	var half_width = width * 0.5
	var quarter_height = height * 0.25
	return [
		Vector2(0, -half_height),
		Vector2(half_width, -quarter_height),
		Vector2(half_width, quarter_height),
		Vector2(0, half_height),
		Vector2(-half_width, quarter_height),
		Vector2(-half_width, -quarter_height),
	]


## Returns the local positions of corner a hexagon tile in a vertical layout.
##
## [br]The returned array contains the corner positions in local coordinates relative to the tile center.
## [br]The corners are ordered in a clockwise direction starting from the top right corner.
static func geometry_vertical_tile_corners(tile_size: Vector2i) -> Array[Vector2]:
	var height = tile_size.y
	var width = tile_size.x
	var half_height = height * 0.5
	var half_width = width * 0.5
	var quarter_width = roundi(width * 0.25)
	return [
		Vector2(quarter_width, -half_height),
		Vector2(half_width, 0),
		Vector2(quarter_width, half_height),
		Vector2(-quarter_width, half_height),
		Vector2(-half_width, 0),
		Vector2(-quarter_width, -half_height),
	]


#endregion


## Updates the layout of a hex tilemap while preserving the logical positions of all tiles.
##
## [br]When changing a tilemap's layout (e.g., from stacked to diamond), this function ensures
## all tiles maintain their relative positions by converting them through the cube coordinate system.
## [br][color=yellow][b]Note:[/b][/color] This function only updates the positions of existing tiles. It does not modify
## the tileset's properties like cell size, offset, or other configuration parameters. You'll need to
## adjust those manually if needed.
## [br][b]Parameters:[/b]
## [br]- [param tilemap]: The HexagonTileMapLayer to update
## [br]- [param from]: The current/source TileSet.TileLayout
## [br]- [param to]: The desired/target TileSet.TileLayout
## [codeblock]
## # Convert a map from stacked to diamond layout
## HexagonTileMap.update_cells_layout(
##     my_tilemap,
##     TileSet.TileLayout.TILE_LAYOUT_STACKED,
##     TileSet.TileLayout.TILE_LAYOUT_DIAMOND_RIGHT
## )
## [/codeblock]
## [codeblock]
## # Add a layout switcher to your game
## func _on_layout_button_pressed():
##     var current_layout = tilemap.tile_set.tile_layout
##     var new_layout
##
##     match current_layout:
##         TileSet.TileLayout.TILE_LAYOUT_STACKED:
##             new_layout = TileSet.TileLayout.TILE_LAYOUT_DIAMOND_RIGHT
##         TileSet.TileLayout.TILE_LAYOUT_DIAMOND_RIGHT:
##             new_layout = TileSet.TileLayout.TILE_LAYOUT_STAIRS_RIGHT
##         _:
##             new_layout = TileSet.TileLayout.TILE_LAYOUT_STACKED
##
##     HexagonTileMap.update_cells_layout(tilemap, current_layout, new_layout)
##
##     # Update the tilemap with the new layout
##     tilemap.tile_set.tile_layout = new_layout
##     tilemap.pathfinding_generate_points()
##     tilemap._draw_debug.call_deferred()
## [/codeblock]
static func update_cells_layout(
	tilemap: HexagonTileMapLayer, from: TileSet.TileLayout, to: TileSet.TileLayout
):
	var from_conversion = get_conversion_methods_for(tilemap.tile_set.tile_offset_axis, from)
	var to_conversion = get_conversion_methods_for(tilemap.tile_set.tile_offset_axis, to)

	tilemap.tile_set.tile_layout = to

	var tiles = []  # Record<Vector3i, TileData>
	for pos in tilemap.get_used_cells():
		(
			tiles
			. append(
				[
					from_conversion.map_to_cube.call(pos),
					tilemap.get_cell_source_id(pos),
					tilemap.get_cell_atlas_coords(pos),
					tilemap.get_cell_alternative_tile(pos),
				]
			)
		)
		tilemap.erase_cell(pos)

	for tile in tiles:
		(
			tilemap
			. set_cell(
				to_conversion.cube_to_map.call(tile[0]),
				tile[1],
				tile[2],
				tile[3],
			)
		)
