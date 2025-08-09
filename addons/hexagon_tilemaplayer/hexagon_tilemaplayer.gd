@tool
@icon("uid://chl4qyjdth4vj")

## Set of tools to use hexagon based tilemap in Godot with [AStar2D] pathfinding and cube coordinates system.
##
## Require Godot 4.4+, for 4.3+ use version 1.0.1 or earlier.
## [br]
## [br] - [AStar2D] pathfinding support
## [br] - Cube coordinates system
## [br] - Conversion between different coordinate systems
## [br] - Both offset axis support (horizontal, vertical)
## [br] - All layout support (stacked, stacked offset, stairs right, stairs down, diamond right, diamond down)
## [br] - Toolbar actions to fix tilemaps after layout changes
## [br] - Debug visualization
## [br]
## [br]The extension uses two coordinate systems:
## [br]- Map coordinates (Vector2i): Native Godot tilemap coordinates
## [br]- Cube coordinates (Vector3i): Hexagonal coordinate system
class_name HexagonTileMapLayer extends TileMapLayer


## Shape of a single tile, based on a [Shape2D] and a [Transform2D] for positioning and rotation.
## See also [member geometry_tile_shape] and [member geometry_tile_approx_shape].
class TileShape:
	## Shape of the tile.
	var shape: Shape2D
	## Transform of the tile.
	var transform: Transform2D

	func _init(_shape: Shape2D, _transform: Transform2D) -> void:
		shape = _shape
		transform = _transform

	## Returns a copy of the tile shape with a new position.
	func get_for(position: Vector2) -> TileShape:
		return TileShape.new(shape, Transform2D(transform.x, transform.y, position))


var _current_tile_set: WeakRef

## [AStar2D] instance for this [HexagonTileMapLayer]. Only avaliable if [HexagonTileMapLayer.pathfinding_enabled] is true.
var astar: AStar2D

## Enable [AStar2D] Pathfinding
@export var pathfinding_enabled: bool = false

var _debug_container: Node2D
@onready var _debug_font_size = floori(tile_set.tile_size.x / 7.0)
@onready var _debug_font_outline_size = floori(tile_set.tile_size.x / 32.0)

## Used with the `debug_mode` property to control debug.
enum DebugModeFlags {
	## Displays coordinate information for each hex.
	## [br]  - Pathfinding ID (when pathfinding is enabled)
	## [br]  - Map coordinates (x, y)
	## [br]  - Cube coordinates (x, y, z)
	TILES_COORDS = 1,
	## Shows pathfinding connections between hexes as colored lines
	## [br]  - Each connection gets a random color for better visibility
	## [br]  - Only visible when pathfinding is enabled
	CONNECTIONS = 2,
}

## Display debug data about tiles and pathfinding connections.
##
## [br]These visualizations are overlaid on top of your tilemap.
## [br][b]Note[/b]: Debug visualization is only displayed during runtime, not in the editor. This helps keep the editor view clean while still providing debugging capabilities when you need them.
## [br] You can enable multiple debug options at once by combining them with the bitwise OR operator.
## [br] See [enum DebugModeFlags].
## [codeblock]
## # Show both coordinates and connections
## tilemap.debug_mode = HexagonTileMapLayer.DebugModeFlags.TILES_COORDS | HexagonTileMapLayer.DebugModeFlags.CONNECTIONS
## [/codeblock]
## [codeblock]
## # Show only coordinates
## tilemap.debug_mode = HexagonTileMapLayer.DebugModeFlags.TILES_COORDS
## [/codeblock]
## [codeblock]
## # Disable all debug visualization
## tilemap.debug_mode = 0
## [/codeblock]
@export_flags("Tiles coords", "Connections") var debug_mode: int = 0:
	set(value):
		debug_mode = value
		if not Engine.is_editor_hint() and is_inside_tree():
			_draw_debug()

## Emited when the [AStar2D] gets updated.
signal astar_changed

var _cube_to_map: Callable
var _map_to_cube: Callable

## Shape of a single tile. Based on a [ConvexPolygonShape2D] with the tile's corners. See also [member geometry_tile_approx_shape].
var geometry_tile_shape: TileShape
## Approximate shape of a single tile. Based on a [CapsuleShape2D]. See also [member geometry_tile_shape].
var geometry_tile_approx_shape: TileShape

## Direction vector for each neighbor in cube coordinates.
var cube_direction_vectors: Dictionary[TileSet.CellNeighbor, Vector3i]
## CellNeighbor array for each side neighbor.
var cube_side_neighbor_directions: Array[TileSet.CellNeighbor]
## CellNeighbor array for each corner neighbor.
var cube_corner_neighbor_directions: Array[TileSet.CellNeighbor]


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		tile_set.changed.connect(update_configuration_warnings)
	else:
		_current_tile_set = weakref(tile_set)
		tile_set.changed.connect(_on_tileset_changed)
		changed.connect(_on_changed)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		if tile_set.changed.is_connected(update_configuration_warnings):
			tile_set.changed.disconnect(update_configuration_warnings)
	else:
		if tile_set.changed.is_connected(_on_tileset_changed):
			tile_set.changed.disconnect(_on_tileset_changed)
		if changed.is_connected(_on_changed):
			changed.disconnect(_on_changed)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_on_tileset_changed()

	if pathfinding_enabled:
		astar_changed.connect(_draw_debug, CONNECT_DEFERRED + CONNECT_ONE_SHOT)
		pathfinding_generate_points()
	else:
		_draw_debug.call_deferred()


func _get_configuration_warnings():
	var warnings: Array[String] = []
	if tile_set.tile_shape != TileSet.TileShape.TILE_SHAPE_HEXAGON:
		warnings.append("This node only support hexagon shapes")
	return warnings


#region Pathfinding
@warning_ignore("unused_parameter")


func _pathfinding_get_tile_weight(coords: Vector2i) -> float:
	return 1.0


@warning_ignore("unused_parameter")


func _pathfinding_does_tile_connect(tile: Vector2i, neighbor: Vector2i) -> bool:
	return true


## Gets the internal AStar2D node ID for a hex.
##
## [br]This function is essential for working with AStar2D pathfinding operations, as it converts tilemap coordinates to the unique IDs used by the pathfinding system.
## [codeblock]
## # Get ID for a specific hex
## var hex_pos_a = Vector2i(-2, -1)
## var hex_pos_b = tilemap.cube_to_map(Vector3i(0, 1, -1))
## var id = tilemap.pathfinding_get_point_id(hex_pos_a)
## print(id)  # Output: 9
## [/codeblock]
## [codeblock]
## # Use it with AStar2D methods
## var start_id = tilemap.pathfinding_get_point_id(hex_pos_a)
## var end_id = tilemap.pathfinding_get_point_id(hex_pos_b)
## var path = tilemap.astar.get_id_path(start_id, end_id)
## print(path)  # Output: [9, 16, 17, 22]
## [/codeblock]
## [codeblock]
## # Check point connections
## var point_a = tilemap.pathfinding_get_point_id(Vector2i(-2, -1))
## var point_b = tilemap.pathfinding_get_point_id(Vector2i(-1, 0))
## var are_connected = tilemap.astar.are_points_connected(point_a, point_b)
## print(are_connected)  # Output: true
## [/codeblock]
func pathfinding_get_point_id(coord: Vector2i) -> int:
	return astar.get_closest_point(map_to_local(coord))


## Updates the pathfinding weight for a specific hex.
##
## [br]Call this method whenever terrain conditions change that would affect movement cost through this hex (like placing mud, adding obstacles, etc.). The weight is calculated by calling your custom `_pathfinding_get_tile_weight` method.
## [codeblock]
## # Make a hex harder to traverse when damaged
## func apply_terrain_damage(pos: Vector2i):
##     terrain_damage[pos] = true
##     tilemap.pathfinding_recalculate_tile_weight(pos)  # Update pathfinding
##
## # Override weight calculation based on terrain
## func _pathfinding_get_tile_weight(coords: Vector2i) -> float:
##     if terrain_damage.has(coords):
##         return 2.0  # Damaged terrain costs twice as much to traverse
##     return 1.0  # Normal terrain cost
##
## # Batch update multiple tiles
## for pos in affected_tiles:
##     tilemap.pathfinding_recalculate_tile_weight(pos)
## [/codeblock]
func pathfinding_recalculate_tile_weight(coord: Vector2i):
	astar.set_point_weight_scale(
		pathfinding_get_point_id(coord), _pathfinding_get_tile_weight(coord)
	)


## @deprecated: Use [method pathfinding_generate_points] instead.
func _pathfinding_generate_points():
	pathfinding_generate_points()


## Generate points and connections for the [Astar2D] instance.
##
## [br]This is automatically called in the _ready() function.
## [br]The points capacity is automatically adjusted based on the number of used cells.
## [br]If later you need to add more points to the astar instance call [method AStar2D.reserve_space] with num_nodes the total of points multiplied by 1.12.
## [br]See [url=https://github.com/godotengine/godot/issues/102612#issuecomment-2702275926]this issue[/url] for more information.
func pathfinding_generate_points():
	if not astar:
		astar = AStar2D.new()
	_pathfinding_create_points()
	_pathfinding_create_connections()
	astar_changed.emit()


func _draw_debug():
	if is_instance_valid(_debug_container):
		_debug_container.queue_free()
	if debug_mode == 0 or not is_visible_in_tree():
		return
	_debug_container = Node2D.new()
	_debug_container.z_index = 100

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
		_debug_container.add_child(connections_container)

	if debug_mode & DebugModeFlags.TILES_COORDS:
		var coords_container: Node2D = Node2D.new()
		if pathfinding_enabled:
			for id in astar.get_point_ids():
				_debug_tile_coords_with_pathfinding(coords_container, id)
		else:
			for pos in get_used_cells():
				_debug_tile_coords(coords_container, pos)
		_debug_container.add_child(coords_container)

	add_child.call_deferred(_debug_container)


func _pathfinding_create_points():
	astar.clear()
	var cells := get_used_cells()
	# Why 1.12 ? See https://github.com/godotengine/godot/issues/102612#issuecomment-2702275926
	var needed_space = cells.size() * 1.12
	if astar.get_point_capacity() < needed_space:
		astar.reserve_space(needed_space)

	var id: int = -1
	for coord in cells:
		id += 1
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


## Helper function to display text centered on a hex tile.
##
## [br]Creates a RichTextLabel with proper formatting and positioning :
## [br]- Centered on the hex (both horizontally and vertically)
## [br]- Auto-sized to fit the hex
## [br]- Using a font size proportional to hex size
## [br]- With outline for better visibility
## [br]- Ignoring mouse input
## [br]- Supporting BBCode formatting
## [codeblock]
## # Display custom text on a hex
## var debug_container = Node2D.new()
## var hex_pos = Vector2i(1, 1)
## var text = "[center]Custom\nText[/center]"  # Use BBCode for formatting
## tilemap._show_debug_text_on_tile(debug_container, hex_pos, text)
## tilemap.add_child(debug_container)
##
## # Show multiple labels
## for hex in highlighted_hexes:
##     var label_text = "[center]Hex %d[/center]" % [hex_count]
##     tilemap._show_debug_text_on_tile(debug_container, hex, label_text)
## [/codeblock]
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
## Converts cube coordinates to pixel coordinates in the tilemap's local space.
##
## [br]Use this to position entities or UI elements at the center of a hex.
## [codeblock]
## # Get the center position of a hex for entity placement
## var hex_pos = Vector3i(2, -1, -1)
## var center = tilemap.cube_to_local(hex_pos)
## my_entity.position = center  # Places entity at hex center
## [/codeblock]
## [codeblock]
## # Useful for UI indicators
## var hex_centers = []
## for hex in selected_hexes:
##     hex_centers.append(tilemap.cube_to_local(hex))
## highlight_hexes(hex_centers)  # Draw indicators at hex centers
## [/codeblock]
## See also: [method local_to_cube]
func cube_to_local(cube_position: Vector3i) -> Vector2:
	return map_to_local(cube_to_map(cube_position))


## Converts pixel coordinates in the tilemap's local space to cube coordinates.
##
## [br]Useful for converting mouse positions or entity positions to hex grid coordinates.
## [codeblock]
## # Convert mouse position to cube coordinates
## var mouse_pos = get_local_mouse_position()
## var cube_pos = tilemap.local_to_cube(mouse_pos)
## print(cube_pos)  # Output: Vector3i(2, -1, -1)
## [/codeblock]
## [codeblock]
## # Use it for entity placement
## var entity_pos = my_entity.position
## var entity_hex = tilemap.local_to_cube(entity_pos)
## print("Entity is in hex: ", entity_hex)
## [/codeblock]
## See also: [method cube_to_local]
func local_to_cube(map_position: Vector2) -> Vector3i:
	return map_to_cube(local_to_map(map_position))


func _on_changed() -> void:
	var current_tile_set: TileSet = _current_tile_set.get_ref()
	if current_tile_set != tile_set:
		if is_instance_valid(current_tile_set) and current_tile_set.changed.is_connected(_on_tileset_changed):
			current_tile_set.changed.disconnect(_on_tileset_changed)
		_current_tile_set = weakref(tile_set)
		if is_instance_valid(tile_set):
			tile_set.changed.connect(_on_tileset_changed)
			_on_tileset_changed()


# Callback to update the static data and conversions methods when the tileset changed.
func _on_tileset_changed() -> void:
	_debug_font_size = floori(tile_set.tile_size.x / 7.0)
	_debug_font_outline_size = floori(tile_set.tile_size.x / 32.0)
	var conversion_methods := HexagonTileMap.get_conversion_methods_for(
		tile_set.tile_offset_axis, tile_set.tile_layout
	)
	if not conversion_methods.is_empty():
		_cube_to_map = conversion_methods.cube_to_map
		_map_to_cube = conversion_methods.map_to_cube

	var geometry_methods := HexagonTileMap.get_geometry_methods_for(tile_set.tile_offset_axis)
	if not geometry_methods.is_empty():
		var shape = ConvexPolygonShape2D.new()
		shape.points = PackedVector2Array(geometry_methods.tile_corners.call(tile_set.tile_size))
		geometry_tile_shape = TileShape.new(shape, Transform2D.IDENTITY)

	if tile_set.tile_offset_axis == TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL:
		cube_direction_vectors = HexagonTileMap.cube_horizontal_direction_vectors
		cube_side_neighbor_directions = HexagonTileMap.cube_horizontal_side_neighbor_directions
		cube_corner_neighbor_directions = HexagonTileMap.cube_horizontal_corner_neighbor_directions
		if tile_set.tile_size.y > tile_set.tile_size.x:
			var shape = CapsuleShape2D.new()
			shape.radius = tile_set.tile_size.x * 0.5
			shape.height = tile_set.tile_size.y
			geometry_tile_approx_shape = TileShape.new(shape, Transform2D.IDENTITY)
		else:
			var shape = CapsuleShape2D.new()
			shape.radius = tile_set.tile_size.y * 0.5
			shape.height = tile_set.tile_size.x
			geometry_tile_approx_shape = TileShape.new(
				shape, Transform2D.IDENTITY.rotated(PI * 0.5)
			)
	else:
		cube_direction_vectors = HexagonTileMap.cube_vertical_direction_vectors
		cube_side_neighbor_directions = HexagonTileMap.cube_vertical_side_neighbor_directions
		cube_corner_neighbor_directions = HexagonTileMap.cube_vertical_corner_neighbor_directions

		if tile_set.tile_size.x > tile_set.tile_size.y:
			var shape = CapsuleShape2D.new()
			shape.radius = tile_set.tile_size.y * 0.5
			shape.height = tile_set.tile_size.x
			geometry_tile_approx_shape = TileShape.new(
				shape, Transform2D.IDENTITY.rotated(PI * 0.5)
			)
		else:
			var shape = CapsuleShape2D.new()
			shape.radius = tile_set.tile_size.x * 0.5
			shape.height = tile_set.tile_size.y
			geometry_tile_approx_shape = TileShape.new(shape, Transform2D.IDENTITY)


## Converts cube coordinates back to [TileMapLayer] cell coordinates.
##
## [br]Use this after performing hex grid calculations to place tiles or entities.
## [codeblock]
## # Converting from cube (2, 1, -3) back to tilemap coordinates
## var map_pos = tilemap.cube_to_map(Vector3i(2, 1, -3))
## print(map_pos)  # Output: (2, 1)
## [/codeblock]
## See also: [method map_to_cube]
func cube_to_map(cube_position: Vector3i) -> Vector2i:
	return _cube_to_map.call(cube_position)


## Converts [TileMapLayer] cell coordinates to cube coordinates.
##
## [br]This is useful when you need to perform hex grid operations like distance calculation or finding neighbors.
## [codeblock]
## # Converting from tilemap (2, 1) to cube coordinates
## var cube_pos = tilemap.map_to_cube(Vector2i(2, 1))
## print(cube_pos) # Output: (2, 1, -3) - notice x + y + z = 0
## [/codeblock]
## See also: [method cube_to_map]
func map_to_cube(map_position: Vector2i) -> Vector3i:
	return _map_to_cube.call(map_position)


#endregion


#region Cube coords maths
## Returns the cube coordinate vector representing a hex direction.
##
## [br]There are two types of directions each inherited from [enum TileSet.CellNeighbor]:
## [br]    - Side directions like [param CELL_NEIGHBOR_RIGHT_SIDE]: Move to adjacent hexes, one step away
## [br]    - Corner directions like [param CELL_NEIGHBOR_RIGHT_CORNER]: Move to diagonal hexes, two steps away in a single move
## [br]These vectors can be added to a cube position to move in the specified direction.
## [codeblock]
## var top_right = tilemap.cube_direction(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE)
## print(top_right)  # Output: Vector3i(1, -1, 0)
##
## var right = tilemap.cube_direction(TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE)
## print(right)  # Output: Vector3i(1, 0, -1)
##
## # Corner directions (diagonal hexes, two steps)
## var top_right_corner = tilemap.cube_direction(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER)
## print(top_right_corner)  # Output: Vector3i(2, -1, -1)  # Note the magnitude is 2
## [/codeblock]
## [codeblock]
## # Movement examples
## var current_pos = Vector3i(0, 0, 0)
##
## # Compare side vs corner movement
## var side_move = current_pos + top_right + right # One step diagonally and one right
## var corner_move = current_pos + top_right_corner  # Two steps diagonally at once
## print(side_move == corner_move)  # Output: true - Both moves end up at the same position
##
## # Create a zigzag path mixing side and corner moves
## var zigzag = current_pos
## zigzag += right  # Move one step right
## zigzag += top_right_corner  # Jump two steps diagonally
## print(zigzag)  # Output: Vector3i(3, -1, -2)
## [/codeblock]
func cube_direction(direction: TileSet.CellNeighbor) -> Vector3i:
	return cube_direction_vectors[direction]


## Gets the cube coordinates of a neighboring hex in a specified direction.
##
## [br]Like [method cube_direction], it supports both side and corner neighbors.
## This is a convenience function that combines the current position with a direction vector.
## [codeblock]
## # Get side neighbors (adjacent hexes)
## var current = Vector3i(0, 0, 0)
## var right_neighbor = tilemap.cube_neighbor(current, TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE)
## print(right_neighbor)  # Output: Vector3i(1, 0, -1)
##
## var top_right_neighbor = tilemap.cube_neighbor(current, TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE)
## print(top_right_neighbor)  # Output: Vector3i(1, -1, 0)
##
## # Get corner neighbors (diagonal hexes)
## var top_right_corner = tilemap.cube_neighbor(current, TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER)
## print(top_right_corner)  # Output: Vector3i(2, -1, -1)
## [/codeblock]
## [codeblock]
## # Chain multiple moves
## var final_pos = tilemap.cube_neighbor(
##     tilemap.cube_neighbor(current, TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE),
##     TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE
## )
## print(final_pos)  # Output: Vector3i(2, -1, -1) - Same as using corner neighbor directly
## [/codeblock]
func cube_neighbor(cube: Vector3i, direction: TileSet.CellNeighbor) -> Vector3i:
	return cube + cube_direction(direction)


## Gets all adjacent hexes surrounding a center hex.
##
## [br]Returns an array of 6 positions in clockwise order starting from top-right.
## [codeblock]
## # Get all adjacent neighbors
## var center = Vector3i(0, 0, 0)
## var neighbors = tilemap.cube_neighbors(center)
## print(neighbors) # Output: [
##                  #   (1,-1,0),  # top-right
##                  #   (1,0,-1),  # right
##                  #   (0,1,-1),  # bottom-right
##                  #   (-1,1,0),  # bottom-left
##                  #   (-1,0,1),  # left
##                  #   (0,-1,1)   # top-left
##                  # ]
## [/codeblock]
## [codeblock]
## # Check all adjacent tiles
## for neighbor in neighbors:
##     if tilemap.get_cell_source_id(tilemap.cube_to_map(neighbor)) != -1:
##         print("Found adjacent hex at: ", neighbor)
## [/codeblock]
## See also: [method cube_corner_neighbors]
## See also static version: [method HexagonTileMap.cube_neighbors_for_axis]
func cube_neighbors(cube: Vector3i) -> Array[Vector3i]:
	return HexagonTileMap._cube_neighbors_for_neighbor(
		cube_side_neighbor_directions, cube_direction_vectors, cube
	)


## Gets all corner (diagonal) hexes surrounding a center hex.
##
## [br]Returns an array of 6 positions in clockwise order starting from top-right corner.
## [codeblock]
## # Get all corner neighbors
## var center = Vector3i(0, 0, 0)
## var corners = tilemap.cube_corner_neighbors(center)
## print(corners) # Output: [
##                #   (2,-1,-1),  # top-right corner
##                #   (1,1,-2),   # bottom-right corner
##                #   (-1,2,-1),  # bottom corner
##                #   (-2,1,1),   # bottom-left corner
##                #   (-1,-1,2),  # top-left corner
##                #   (1,-2,1)    # top corner
##                # ]
## [/codeblock]
## [codeblock]
## # Get all surrounding hexes (both adjacent and corner)
## var all_neighbors: Array[Vector3i] = []
## all_neighbors.append_array(tilemap.cube_neighbors(center))        # 6 adjacent neighbors
## all_neighbors.append_array(tilemap.cube_corner_neighbors(center)) # 6 corner neighbors
## print(all_neighbors.size())  # Output: 12 total surrounding hexes
## [/codeblock]
## See also: [method cube_neighbors]
## See also static version: [method HexagonTileMap.cube_corner_neighbors_for_axis]
func cube_corner_neighbors(cube: Vector3i) -> Array[Vector3i]:
	return HexagonTileMap._cube_corner_neighbors_for_neighbor(
		cube_corner_neighbor_directions, cube_direction_vectors, cube
	)


## Calculates the distance distance between two hexes in the hex grid.
##
## [br]The distance is measured in number of steps needed to go from hex A to hex B, where each step is a move to an adjacent hex. This is also known as the [url=https://en.wikipedia.org/wiki/Taxicab_geometry]Manhattan distance[/url] for hex grids.
## [br][color=e67e22][b]Warning:[/b][/color] Don't use [method Vector3i.distance_to] for hex grid distances. It will give incorrect results because it measures straight-line [url=https://en.wikipedia.org/wiki/Euclidean_geometry]Euclidean[/url] distance rather than hex grid steps.
## [codeblock]
## # Calculate distance between hexes
## var center = Vector3i(0, 0, 0)
## var target = Vector3i(2, -1, -1)
## var distance = tilemap.cube_distance(center, target)
## print(distance)  # Output: 2 (need 2 steps to reach the target)
## [/codeblock]
## [codeblock]
## # Comparing distances
## var hex1 = Vector3i(1, -1, 0)  # adjacent to center
## var hex2 = Vector3i(2, -2, 0)  # two steps away
## print(tilemap.cube_distance(center, hex1))  # Output: 1
## print(tilemap.cube_distance(center, hex2))  # Output: 2
## [/codeblock]
## [codeblock]
## # Use it for range checks
## var max_range = 2
## if tilemap.cube_distance(center, target) <= max_range:
##     print("Target is within range!")  # Will print as distance is 2
## [/codeblock]
## [codeblock]
## # Calculate movement cost (if each step costs 1)
## var movement_points = 3
## var can_reach = tilemap.cube_distance(center, target) <= movement_points
## print(can_reach)  # Output: true (can reach destination in 3 steps)
## [/codeblock]
## [codeblock]
## # WRONG WAY - don't use this!
## print(center.distance_to(target))  # Output: 2.449... (incorrect, measures straight-line distance)
## [/codeblock]
func cube_distance(a: Vector3i, b: Vector3i) -> int:
	return HexagonTileMap.cube_distance(a, b)


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
func cube_round(frac: Vector3) -> Vector3i:
	return HexagonTileMap.cube_round(frac)


## Returns all hexes that form a line between two points.
##
## [br]Uses a linear interpolation to determine which hexes should be included in the line. Perfect for implementing line-of-sight, ranged attacks, or drawing paths between two points.
## [br][b]Note[/b]: The returned array is guaranteed to start with vector [param a] and end with vector [param b], making it easy to track the exact start and end points of your line.
## [codeblock]
## # Draw a simple line
## var start = Vector3i(0, 0, 0)
## var end = Vector3i(2, -1, -1)
## var line = tilemap.cube_linedraw(start, end)
## print(line)  # Output: [(0, 0, 0), (1, -1, -1), (2, -1, -1)]
## print(line[0] == start)  # Output: true - First element is always the start vector
## print(line[-1] == end)   # Output: true - Last element is always the end vector
## [/codeblock]
## [codeblock]
## # Use it for line of sight checks
## func has_line_of_sight(from: Vector3i, to: Vector3i) -> bool:
##     var line = tilemap.cube_linedraw(from, to)
##     for hex in line:
##         if tilemap.get_cell_source_id(tilemap.cube_to_map(hex)) == 1:
##             return false  # Line of sight blocked by wall
##     return true
## [/codeblock]
## [codeblock]
## # Create a beam attack effect
## var beam_hexes = tilemap.cube_linedraw(caster_pos, target_pos)
## for hex in beam_hexes:
##     apply_damage(hex)  # Apply damage to each hex in the line
## [/codeblock]
## [codeblock]
## # Visualize the path
## var debug_line = Line2D.new()
## for hex in tilemap.cube_linedraw(start, end):
##     debug_line.add_point(tilemap.cube_to_local(hex))
## tilemap.add_child(debug_line)
## [/codeblock]
func cube_linedraw(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	return HexagonTileMap.cube_linedraw(a, b)


## Gets all hexes within a certain distance of a center hex.
##
## [br]Creates a hexagonal-shaped area where every hex is at most [param distance] steps away from the center. Perfect for area-of-effect abilities or calculating movement ranges.
## [br][b]Note[/b]: The returned hexes are ordered from left to right, row by row, which can be useful for consistent processing or display of the area.
## [codeblock]
## # Get all hexes within 1 step of center (7 hexes total)
## var center = Vector3i(0, 0, 0)
## var cells = tilemap.cube_range(center, 1)
## print(cells)  # Output: [
##               #   (-1,0,1),   # left
##               #   (-1,1,0),   # bottom-left
##               #   (0,-1,1),   # top-left
##               #   (0,0,0),    # center
##               #   (0,1,-1)    # bottom-right
##               #   (1,-1,0),   # top-right
##               #   (1,0,-1),   # right
##               # ]  # Notice the left-to-right ordering
## [/codeblock]
## [codeblock]
## # Calculate area of effect for a spell
## var spell_range = 2
## var affected_hexes = tilemap.cube_range(caster_position, spell_range)
## for hex in affected_hexes:
##     apply_effect(hex)  # Apply spell effect to each hex in range
## [/codeblock]
## [codeblock]
## # Check if target is within movement range
## var movement_range = 3
## var reachable_hexes = tilemap.cube_range(unit_position, movement_range)
## if target_hex in reachable_hexes:
##     print("Can reach target!")
## [/codeblock]
## [codeblock]
## # Visualize the range
## for hex in tilemap.cube_range(center, 2):
##     highlight_hex(tilemap.cube_to_local(hex))  # Show movement range to player
## [/codeblock]
## See also [method cube_spiral] and [method cube_intersect_ranges].
func cube_range(center: Vector3i, distance: int) -> Array[Vector3i]:
	return HexagonTileMap.cube_range(center, distance)


## Returns all hexes that are within range1 of center1 AND within range2 of center2.
##
## [br]Useful for finding overlapping areas of effect or determining valid positions for abilities that require being in range of multiple targets.
## [codeblock]
## # Find hexes that are within range of both units
## var unit1_pos = Vector3i(0, 0, 0)
## var unit2_pos = Vector3i(3, -1, -2)
## var overlapping_hexes = tilemap.cube_intersect_ranges(
##     unit1_pos, 2,  # Unit 1 has range of 2
##     unit2_pos, 3   # Unit 2 has range of 3
## )
## # Result: All hexes that both units can reach
## [/codeblock]
## See also [method cube_range].
func cube_intersect_ranges(
	center1: Vector3i, range1: int, center2: Vector3i, range2: int
) -> Array[Vector3i]:
	return HexagonTileMap.cube_intersect_ranges(center1, range1, center2, range2)


## Rotates a hex position around the origin (0,0,0) by a number of 60-degree steps.
##
## [br]Positive rotations are clockwise, negative are counter-clockwise. Each rotation value represents a 60-degree turn, so a full 360-degree rotation is 6 steps.
## [codeblock]
## var pos = Vector3i(2, 0, -2)  # A hex two steps to the right
## # Rotate clockwise (60 degrees)
## var rotated = tilemap.cube_rotate(pos, 1)
## print(rotated)  # Output: Vector3i(0, 2, -2)
## [/codeblock]
## [codeblock]
## # Rotate counter-clockwise (120 degrees)
## var ccw = tilemap.cube_rotate(pos, -2)
## print(ccw)  # Output: Vector3i(0, -2, 2)
## [/codeblock]
## [codeblock]
## # Full rotation (360 degrees = 6 steps)
## var full = tilemap.cube_rotate(pos, 6)
## print(full)  # Output: Vector3i(2, 0, -2) - Back to original position
## [/codeblock]
## [codeblock]
## # Multiple rotations are automatically normalized to 0-5
## var large = tilemap.cube_rotate(pos, 10)  # Same as rotating by 4 or -2 (10 mod 6)
## print(large)  # Output: Vector3i(0, -2, 2)
## [/codeblock]
## [codeblock]
## # Use it for rotating formations or patterns
## var formation = [Vector3i(1,0,-1), Vector3i(2,0,-2), Vector3i(1,-1,0)]
## var rotated_formation = formation.map(func(p): return tilemap.cube_rotate(p, 2))
## print(rotated_formation)  # Output: [(-1, 1, 0), (-2, 2, 0), (0, 1, -1)]
## [/codeblock]
## See also [method cube_rotate_from].
func cube_rotate(cell: Vector3i, rotations: int) -> Vector3i:
	return HexagonTileMap.cube_rotate(cell, rotations)


## Rotates a hex position around a center point by a number of 60-degree steps.
##
## [br]Like [method cube_rotate], but allows you to specify a different center of rotation.
## [codeblock]
## # Rotate around the origin point (0,0,0)
## var pos = Vector3i(2, 0, -2)
## var rotated = tilemap.cube_rotate(pos, 2)  # 120 degrees clockwise
## print(rotated)  # Output: Vector3i(-2, 2, 0)
## [/codeblock]
## [codeblock]
## # Rotate around a different center point
## var center = Vector3i(1, -1, 0)
## var rotated_from = tilemap.cube_rotate_from(pos, center, 2)
## print(rotated_from)  # Output: Vector3i(-1, 0, 1)
## [/codeblock]
## [codeblock]
## # Rotate a formation around its center
## var formation = [Vector3i(0, 0, 0), Vector3i(1, 0, -1), Vector3i(1, -1, 0)]
## var center_formation = Vector3i(1, 0, -1)  # Center of formation
## var rotated_formation = formation.map(
##     func(p): return tilemap.cube_rotate_from(p, center_formation, 2)
## )
## print(rotated_formation)  # Output: [(2, -1, -1), (1, 0, -1), (2, 0, -2)]
## [/codeblock]
## See also [method cube_rotate].
func cube_rotate_from(cell: Vector3i, from: Vector3i, rotations: int) -> Vector3i:
	return HexagonTileMap.cube_rotate_from(cell, from, rotations)


## Reflects a hex position across one of the three cube coordinate axes.
##
## [br]The axis parameter determines which coordinate pair is swapped.
## [codeblock]
## var pos = Vector3i(2, -1, -1)
##
## # Reflect across different axes
## var reflect_x = tilemap.cube_reflect(pos, Vector3i.Axis.AXIS_X)  # Swaps y and z
## var reflect_y = tilemap.cube_reflect(pos, Vector3i.Axis.AXIS_Y)  # Swaps x and z
## var reflect_z = tilemap.cube_reflect(pos, Vector3i.Axis.AXIS_Z)  # Swaps x and y
##
## print(reflect_x)  # Output: Vector3i(2, -1, -1)
## print(reflect_y)  # Output: Vector3i(-1, -1, 2)
## print(reflect_z)  # Output: Vector3i(-1, 2, -1)
## [/codeblock]
## See also [method cube_reflect_from].
func cube_reflect(cell: Vector3i, axis: Vector3i.Axis) -> Vector3i:
	return HexagonTileMap.cube_reflect(cell, axis)


## Reflects a hex position around a center point across one of the three cube coordinate axes.
##
## [br]Useful for creating symmetrical patterns or mirroring positions around a point.
## [codeblock]
## var center = Vector3i(0, 0, 0)
## var pos = Vector3i(2, -1, -1)
##
## # Reflect position around center point
## var reflection = tilemap.cube_reflect_from(pos, center, Vector3i.Axis.AXIS_Y)
## print(reflection)  # Output: Vector3i(-2, 1, 1)
## [/codeblock]
## [codeblock]
## # Create symmetrical formations
## var formation = [Vector3i(1, 0, -1), Vector3i(2, -1, -1)]
## var mirrored = formation.map(
##     func(p): return tilemap.cube_reflect_from(p, center, Vector3i.Axis.AXIS_Y)
## )
## print(mirrored)  # Output: [(-1, 0, 1), (-1, -1, 2)]
## [/codeblock]
## See also [method cube_reflect].
func cube_reflect_from(cell: Vector3i, from: Vector3i, axis: Vector3i.Axis) -> Vector3i:
	return HexagonTileMap.cube_reflect_from(cell, from, axis)


## Creates a rectangle-like shape on the hex grid by reflecting a corner point around a center point.
##
## [br]Returns an array with all cell inside the rectangle. The axis parameter determines the reflection plane.
## [codeblock]
## # Create a rectangular formation
## var center = Vector3i(0, 0, 0)
## var corner = Vector3i(2, -1, -1)
## var cells = tilemap.cube_rect(center, corner)
## [/codeblock]
## See also [method cube_rect_corners].
func cube_rect(
	center: Vector3i, corner: Vector3i, axis: Vector3i.Axis = Vector3i.Axis.AXIS_Y
) -> Array[Vector3i]:
	return HexagonTileMap.cube_rect(center, corner, axis)


## Creates a rectangle-like shape on the hex grid by reflecting a corner point around a center point.
##
## [br]Returns an array of 4 corner positions. The axis parameter determines the reflection plane.
## [codeblock]
## # Create a rectangular formation
## var center = Vector3i(0, 0, 0)
## var corner = Vector3i(2, -1, -1)
## var corners = tilemap.cube_rect_corners(center, corner)
## print(corners)  # Output: [top-right, bottom-right, bottom-left, top-left]
## [/codeblock]
## [codeblock]
## # Use different reflection axes
## var corners_x = tilemap.cube_rect_corners(center, corner, Vector3i.Axis.AXIS_X)
## var corners_y = tilemap.cube_rect_corners(center, corner, Vector3i.Axis.AXIS_Y)
## var corners_z = tilemap.cube_rect_corners(center, corner, Vector3i.Axis.AXIS_Z)
## [/codeblock]
## See also [method cube_rect].
func cube_rect_corners(
	center: Vector3i, corner: Vector3i, axis: Vector3i.Axis = Vector3i.Axis.AXIS_Y
) -> Array[Vector3i]:
	return HexagonTileMap.cube_rect_corners(center, corner, axis)


## Creates a ring shape where all hexes are exactly 'radius' steps from the center.
##
## [br]Returns a collection of hexes that form a ring pattern at the specified radius. The number of hexes in the ring equals radius * 6.
## [br][b]Note[/b]: The optional [param first_side] parameter specifies the starting side for ring creation (defaults to top-right). This controls the orientation of patterns constructed from multiple rings.
## [codeblock]
## # Create a simple ring of radius 2
## var center = Vector3i(0, 0, 0)
## var ring = tilemap.cube_ring(center, 2)
## print(ring.size())  # Output: 12 (each ring has radius * 6 hexes)
## [/codeblock]
## [codeblock]
## # Create a ring starting from the top-right
## var oriented_ring = tilemap.cube_ring(
##     center,
##     2,
##     TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE
## )
## [/codeblock]
## [codeblock]
## # Create multiple concentric rings
## var rings = []
## for r in range(1, 4):
##     rings.append_array(tilemap.cube_ring(center, r))
## [/codeblock]
## [codeblock]
## # Example: Create a ripple effect
## for current_radius in range(1, 4):
##     for hex in tilemap.cube_ring(center, current_radius):
##         var pos = tilemap.cube_to_map(hex)
##         tilemap.set_cell(pos, 0, Vector2i(0,0), current_radius)
## [/codeblock]
## See also [method cube_spiral].
## See also static version [HexagonTileMap.cube_ring_for_axis]
@warning_ignore("int_as_enum_without_cast")
@warning_ignore("int_as_enum_without_match")


func cube_ring(
	center: Vector3i, radius: int, first_side: TileSet.CellNeighbor = -1
) -> Array[Vector3i]:
	return HexagonTileMap._cube_ring_for_neighbor(
		cube_side_neighbor_directions, cube_direction_vectors, center, radius, first_side
	)


## Creates a spiral pattern from center to outer radius in clockwise direction.
##
## [br]Returns all hexes up to the specified radius, organized in a spiral pattern. The spiral traverses hexes in a continuous path from center outward.
## [br][b]Note[/b]: The optional [param first_side] parameter determines the initial direction of the spiral (defaults to top-right). The spiral begins at the center hex and expands outward ring by ring.
## [br][color=e67e22][b]Warning:[/b][/color] The spiral maintains hex adjacency throughout its path. While [param first_side] sets the initial direction, subsequent segments adjust to maintain continuity. For instance, a spiral starting with a right-side neighbor may conclude with a left-side neighbor to complete the pattern.
## [codeblock]
## # Create a basic spiral of radius 2
## var center = Vector3i(0, 0, 0)
## var spiral = tilemap.cube_spiral(center, 2)
## print(spiral.size())  # Output: 19 (1 center + 6 for ring 1 + 12 for ring 2)
## [/codeblock]
## [codeblock]
## # Create a spiral starting from a specific side
## var oriented_spiral = tilemap.cube_spiral(
##     center,
##     2,
##     TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE
## )
## [/codeblock]
## [codeblock]
## # Visualization using ordered indices
## var tween = create_tween()
## for i in spiral.size():
##     var delay = float(i) * 0.1  # Increase delay with each hex
##     tween.tween_callback(func():
##         var label = Label.new()
##         label.text = str(i)
##         label.position = tilemap.cube_to_local(spiral[i])
##         tilemap.add_child(label)
##     ).set_delay(delay)
## [/codeblock]
## See also [method cube_ring].
## [br]See also static version [method HexagonTileMap.cube_spiral_for_axis].
@warning_ignore("int_as_enum_without_cast")
@warning_ignore("int_as_enum_without_match")


func cube_spiral(
	center: Vector3i, radius: int, first_side: TileSet.CellNeighbor = -1
) -> Array[Vector3i]:
	return HexagonTileMap._cube_spiral_for_neighbor(
		cube_side_neighbor_directions, cube_direction_vectors, center, radius, first_side
	)


#endregion

#region Closest Cell Operations


## Determines the map coordinates of the hex cell nearest to the current mouse position.
##
## [codeblock]
## # Get the hex under the mouse cursor
## var target_hex = tilemap.get_closest_cell_from_mouse()
## print(target_hex)  # Output: Vector2i(2, 1) - coordinates of the hex under mouse
## [/codeblock]
## [codeblock]
## # Useful for hover effects
## func _process(_delta):
##     var hovered_hex = tilemap.get_closest_cell_from_mouse()
##     if hovered_hex != last_hovered_hex:
##         update_hover_indicator(hovered_hex)
##         last_hovered_hex = hovered_hex
## [/codeblock]
## [codeblock]
## # Handle click events
## func _unhandled_input(event):
##     if event is InputEventMouseButton and event.pressed:
##         var clicked_hex = tilemap.get_closest_cell_from_mouse()
##         handle_hex_click(clicked_hex)
## [/codeblock]
## See also [method get_closest_cells_from_mouse] and [method get_closest_cell_from_local].
func get_closest_cell_from_mouse() -> Vector3i:
	return get_closest_cell_from_local(get_local_mouse_position())


## Determines the map coordinates of the hex cell nearest to a given position in the tilemap's local space.
##
## [codeblock]
## # Get hex at a specific position
## var local_pos = Vector2(100, 100)
## var hex = tilemap.get_closest_cell_from_local(local_pos)
## print(hex)  # Output: Vector2i(2, 1) - coordinates of closest hex
## [/codeblock]
## [codeblock]
## # Use with node positions
## var entity_pos = some_entity.position
## var entity_hex = tilemap.get_closest_cell_from_local(
##     tilemap.to_local(entity_pos)  # Convert to tilemap's local space
## )
## [/codeblock]
## [codeblock]
## # Track entity movement between hexes
## func _process(_delta):
##     var current_hex = tilemap.get_closest_cell_from_local(position)
##     if current_hex != last_hex:
##         on_enter_new_hex(current_hex)
##         last_hex = current_hex
## [/codeblock]
## See also [method get_closest_cells_from_local]
func get_closest_cell_from_local(local: Vector2) -> Vector3i:
	return map_to_cube(local_to_map(local))


## Returns an array of hex cells nearest to the mouse position, sorted by proximity.
##
## [br] The [param count] parameter (default: 1) specifies the number of hexes to return. This enables retrieving both the nearest hex and additional alternatives when needed.
## [codeblock]
## # Get the three closest hexes to mouse
## var closest = tilemap.get_closest_cells_from_mouse()  # Default count: 3
## print(closest)  # Output: [Vector2i(2,1), Vector2i(2,2), Vector2i(1,1)]
## [/codeblock]
## [codeblock]
## # Get just the closest hex
## var single = tilemap.get_closest_cells_from_mouse(1)
## print(single)  # Output: [Vector2i(2,1)]
## [/codeblock]
## [codeblock]
## # Show multiple targeting options
## var possible_targets = tilemap.get_closest_cells_from_mouse(3)
## for hex in possible_targets:
##     highlight_hex(hex, Color(1, 1, 0, 0.3))  # Highlight potential targets
## [/codeblock]
## [codeblock]
## # Create a splash damage preview
## func update_area_preview():
##     var targets = tilemap.get_closest_cells_from_mouse(3)
##     clear_previews()
##     for i in targets.size():
##         var alpha = 1.0 - (i * 0.25)  # Fade out further hexes
##         show_damage_preview(targets[i], alpha)
## [/codeblock]
## See also [method get_closest_cell_from_mouse] and [method get_closest_cells_from_local].
func get_closest_cells_from_mouse(count: int = 1) -> Array[Vector3i]:
	return get_closest_cells_from_local(get_local_mouse_position(), count)


## Returns an array of hex cells nearest to the specified position, sorted by proximity.
##
## [br]The [param count] parameter (default: 1) specifies the number of hexes to return. This enables retrieving both the nearest hex and additional alternatives when needed.
## [codeblock]
## # Get multiple hexes near a position
## var pos = Vector2(150, 150)
## var nearby = tilemap.get_closest_cells_from_local(pos, 3)
## print(nearby)  # Output: [Vector2i(3,2), Vector2i(3,3), Vector2i(2,2)]
## [/codeblock]
## [codeblock]
## # Create an area of effect around an impact point
## var impact_pos = projectile.global_position
## var affected = tilemap.get_closest_cells_from_local(
##     tilemap.to_local(impact_pos),
##     4  # Affect 4 closest hexes
## )
## for hex in affected:
##     apply_explosion_damage(hex)
## [/codeblock]
## [codeblock]
## # Determine multiple valid placement positions
## func get_valid_placement_options(world_pos: Vector2) -> Array[Vector2i]:
##     var local_pos = tilemap.to_local(world_pos)
##     var candidates = tilemap.get_closest_cells_from_local(local_pos, 5)
##     return candidates.filter(func(hex): return is_valid_placement(hex))
## [/codeblock]
## [codeblock]
## # Visualization using ordered indices
## var tween = create_tween()
## for i in spiral.size():
##     var delay = float(i) * 0.1  # Increase delay with each hex
##     tween.tween_callback(func():
##         var label = Label.new()
##         label.text = str(i)
##         label.position = tilemap.cube_to_local(spiral[i])
##         tilemap.add_child(label)
##     ).set_delay(delay)
## [/codeblock]
## See also [method get_closest_cell_from_local] and [method get_closest_cells_from_mouse]
func get_closest_cells_from_local(local: Vector2, count: int = 1) -> Array[Vector3i]:
	var center_map = local_to_map(local)
	var center_cube = map_to_cube(center_map)
	var cells: Array[Vector3i] = [center_cube]
	if count == 1:
		return cells
	cells.resize(count)
	count -= 1

	var center_local = map_to_local(center_map)
	var wedge_index := HexagonTileMap._wedge_index_for_local_direction_for_axis(
		tile_set.tile_offset_axis, local - center_local
	)
	var direction_index = ceili(wedge_index)
	var next_after = wedge_index - direction_index > -0.5
	var direction = cube_side_neighbor_directions[direction_index - 1]
	var current_ring_size: int = 1
	if next_after:
		while count > 0:
			var ring = cube_ring(center_cube, current_ring_size, direction)
			current_ring_size += 1
			@warning_ignore("integer_division")
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
			@warning_ignore("integer_division")
			for i in ring.size() / 2 + 1:
				cells.append(ring[-i])
				count -= 1
				if count < 0:
					return cells
				cells.append(ring[i])
				count -= 1
				if count < 0:
					return cells
	# For the linter, will never happen
	return []


## Explores hexes from a starting point based on filter and traversal conditions.
##
## [br]Performs a flood-fill exploration of the hex grid, collecting hexes that match the [param filter]
## condition. Exploration continues through hexes that match either [param filter] OR [param maybe].
## [br][b]Parameters:[/b]
## [br]- [param start]: The starting hex in cube coordinates
## [br]- [param filter]: A Callable returning bool - if true, include this hex in results and explore through it
## [br]- [param maybe]: A Callable returning bool - if true, explore through this hex (but don't include in results)
##
## [codeblock]
## # Find all connected water tiles
## var water_tiles = tilemap.cube_explore(
##     start_position,
##     # Only collect deep water
##     func(pos): return is_deep_water(pos),
##     # Maybe traverse shallow water
##     func(pos): return is_shallow_water(pos)
## )
## [/codeblock]
## [codeblock]
## # Find all cells of same type up to a maximum distance
## var max_distance = 3
## var matching_tiles = tilemap.cube_explore(
##     start_position,
##     func(pos):
##         # Include tiles of same type within distance limit
##         return get_cell_type(pos) == target_type and \
##                cube_distance(start_position, pos) <= max_distance,
##     func(pos): return false  # Don't traverse non-matching tiles
## )
## [/codeblock]
## [codeblock]
## # Find terrain until reaching obstacles
## var visible_area = tilemap.cube_explore(
##     player_position,
##     func(pos):
##         # Stop at walls, include everything else
##         return get_cell_type(pos) != CELL_TYPE_WALL,
##     func(pos): return false  # Don't traverse through anything special
## )
## [/codeblock]
## [codeblock]
## # Find connected tiles by their alternative tile value
## var filter := func(tile: Vector3i, cell_alternatives: Array) -> bool:
##     var cell_alternative = _tile_map.get_cell_alternative_tile(_tile_map.cube_to_map(tile))
##     return cell_alternative in cell_alternatives
##
## # Find tiles with alternative=1, traversing through tiles with alternative=0 or 4
## var connected = _tile_map.cube_explore(
##     Vector3i.ZERO,
##     filter.bind([1]),      # Collect tiles with alternative=1
##     filter.bind([0, 4])    # Allow traversing through tiles with alternative=0 or 4
## )
## [/codeblock]
func cube_explore(
	start: Vector3i, filter: Callable, maybe: Callable = func(_pos): return false
) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var visited: Dictionary[Vector3i, bool] = {}
	var queue: Array[Vector3i] = [start]

	visited[start] = true
	if filter.call(start):
		result.append(start)

	while not queue.is_empty():
		var current = queue.pop_front()

		# Check all neighbors
		for neighbor in cube_neighbors(current):
			if neighbor in visited:
				continue

			visited[neighbor] = true

			var is_filtered = filter.call(neighbor)

			if is_filtered:
				result.append(neighbor)

			if is_filtered or maybe.call(neighbor):
				queue.append(neighbor)

	return result


## Generates outline for a group of connected or not hex cells.
##
## [br]Takes an array of hex positions in cube coordinates and returns an array of outlines, where each outline is an array of [Vector2] points in the tilemap's local space.
## [br]This is useful for creating visual borders or selection indicators around groups of hexes.
## [br]The returned outlines are not closed polygons. You could have multiple outlines for a group of cells, depending on their shape (e.g. a group of cells forming a ring).
## [codeblock]
## # Create an outline for a group of cells
## var cells = [Vector3i(0,0,0), Vector3i(1,-1,0), Vector3i(1,0,-1)]
## var outlines = tilemap.cube_outlines(cells)
## print(outlines)  # Output: [[[x1,y1], [x2,y2], ...]] - Array of point arrays
## [/codeblock]
## [codeblock]
## # Visualize the outline with a Line2D
## var line = Line2D.new()
## line.width = 4
## line.default_color = Color.YELLOW
## line.closed = true
## # Each outline is a separate closed polygon
## for outline in outlines:
##     for point in outline:
##         line.add_point(point)
##     line.add_point(outline[0])  # Close the polygon
## tilemap.add_child(line)
## [/codeblock]
func cube_outlines(cells: Array[Vector3i]) -> Array[Array]:
	# See also https://github.com/godotengine/godot-proposals/issues/9127 for a proposal to have polygons with holes
	# Step 1: Generate all edge segments from cells
	var edges: Array[Array] = []
	var corners = (geometry_tile_shape.shape as ConvexPolygonShape2D).points
	for cell in cells:
		var cell_center: Vector2 = cube_to_local(cell)
		for i in 6:
			var neighbor = cube_neighbor(cell, cube_side_neighbor_directions[i])
			if not cells.has(neighbor):
				var point_1: Vector2 = cell_center + corners[i]
				var point_2: Vector2 = cell_center + corners[(i + 1) % 6]
				edges.append([point_1, point_2])
	corners = null

	# Step 2: Create a list of outlines
	var outlines: Array[Array] = []
	while not edges.is_empty():
		var current_outline: Array[Vector2] = []
		var start_edge: Array = edges.pop_front()
		var current_point: Vector2 = start_edge[0]
		var next_point: Vector2 = start_edge[1]

		current_outline.append(current_point)

		# Safety limit
		for _loop in edges.size():
			current_outline.append(next_point)

			if next_point.distance_squared_to(current_outline[0]) < 1.0:
				current_outline.pop_back()
				break

			var found = false
			for i in edges.size():
				var edge = edges[i]
				if next_point.distance_squared_to(edge[0]) < 1.0:
					current_point = next_point
					next_point = edge[1]
					edges.remove_at(i)
					found = true
					break
				elif next_point.distance_squared_to(edge[1]) < 1.0:
					current_point = next_point
					next_point = edge[0]
					edges.remove_at(i)
					found = true
					break

			if not found:
				push_error("Could not find the next edge in the loop")
				break

		if current_outline.size() > 2:
			outlines.append(current_outline)

	return outlines


## Updates the layout of a hex tilemap while preserving the logical positions of all tiles.
##
## [br]When changing a tilemap's layout (e.g., from stacked to diamond), this function ensures
## all tiles maintain their relative positions by converting them through the cube coordinate system.
## [br][color=yellow][b]Note:[/b][/color] This function only updates the positions of existing tiles. It does not modify
## the tileset's properties like cell size, offset, or other configuration parameters. You'll need to
## adjust those manually if needed.
## [br][b]Parameters:[/b]
## [br]- [param from]: The current/source TileSet.TileLayout
## [br]- [param to]: The desired/target TileSet.TileLayout
## [codeblock]
## # Convert a map from stacked to diamond layout
## my_tilemap.update_cells_layout(
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
##     tilemap.update_cells_layout(current_layout, new_layout)
##
##     # Update the tilemap with the new layout
##     tilemap.tile_set.tile_layout = new_layout
##     tilemap.pathfinding_generate_points()
##     tilemap._draw_debug.call_deferred()
## [/codeblock]
func update_cells_layout(from: TileSet.TileLayout, to: TileSet.TileLayout):
	HexagonTileMap.update_cells_layout(self, from, to)
