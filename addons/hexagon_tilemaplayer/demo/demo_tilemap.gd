@tool
extends HexagonTileMapLayer

const TILE_HORIZONTAL = preload("uid://bay24yvwkqxim")
const TILE_VERTICAL = preload("uid://c3tqvwb12rhq3")
var PRIMARY_COLOR = Color.from_string("d35400", Color.BLACK)
var SECONDARY_COLOR = Color.from_string("2980b9", Color.WHITE)

var debug_hovering_tiles: Dictionary[int, Sprite2D] = {}

var hovering_tile: Vector3i = Vector3i.ZERO

signal hovering_changed


func get_or_make_debug_tile(
	index: int,
	weight: float = 0.5,
	primary_color: Color = PRIMARY_COLOR,
	secondary_color: Color = SECONDARY_COLOR,
) -> Sprite2D:
	var color = primary_color.lerp(secondary_color, weight)
	return get_or_make_debug_tile_with_color(index, color)


func get_or_make_debug_tile_with_color(
	index: int,
	color: Color = Color(randf(), randf(), randf()),
) -> Sprite2D:
	if debug_hovering_tiles.has(index):
		debug_hovering_tiles[index].self_modulate = color
		return debug_hovering_tiles[index]

	var sprite = Sprite2D.new()
	sprite.scale *= 0.9
	sprite.self_modulate = color
	if tile_set.tile_offset_axis == TileSet.TILE_OFFSET_AXIS_HORIZONTAL:
		sprite.texture = TILE_HORIZONTAL
	else:
		sprite.texture = TILE_VERTICAL
	debug_hovering_tiles[index] = sprite
	add_child(sprite)
	return sprite


func show_range_with_gradient_color(
	cells: Array[Vector3i],
	start_id: int = 0,
	primary_color: Color = PRIMARY_COLOR,
	secondary_color: Color = SECONDARY_COLOR,
) -> Array[Sprite2D]:
	var point_count = cells.size()
	var tiles: Array[Sprite2D] = []
	for index in point_count:
		var cell_position = cube_to_local(cells[index])

		var color_offset: float
		if point_count > 1:
			color_offset = remap(index, 0, point_count - 1, 0.0, 1.0)
		else:
			color_offset = 0.0
		var tile = get_or_make_debug_tile(
			start_id + index, color_offset, primary_color, secondary_color
		)
		tile.position = cell_position
		tiles.append(tile)
	return tiles


func show_range_with_color(
	cells: Array[Vector3i],
	start_id: int = 0,
	color: Color = Color(randf(), randf(), randf()),
) -> Array[Sprite2D]:
	var point_count = cells.size()
	var tiles: Array[Sprite2D] = []
	for index in point_count:
		var cell_position = cube_to_local(cells[index])
		var tile = get_or_make_debug_tile_with_color(start_id + index, color)
		tile.position = cell_position
		tiles.append(tile)
	return tiles


func show_debug_tiles(max_id: int = -1) -> void:
	if max_id == -1:
		for tile: Sprite2D in debug_hovering_tiles.values():
			tile.visible = false
	else:
		for index in debug_hovering_tiles.keys():
			debug_hovering_tiles[index].visible = index <= max_id


func _pathfinding_get_tile_weight(coords: Vector2i) -> float:
	return get_cell_tile_data(coords).get_custom_data("pathfinding_weight")


func _pathfinding_does_tile_connect(tile: Vector2i, neighbor: Vector2i) -> bool:
	var is_tile_ocean = get_cell_tile_data(tile).get_custom_data("is_ocean")
	var is_neighbor_ocean = get_cell_tile_data(neighbor).get_custom_data("is_ocean")
	return is_tile_ocean == is_neighbor_ocean


func _unhandled_input(event: InputEvent):
	if is_visible_in_tree() and event is InputEventMouseMotion:
		var cell_under_mouse = get_closest_cell_from_mouse()
		if cell_under_mouse.distance_squared_to(hovering_tile) != 0:
			hovering_tile = cell_under_mouse
			hovering_changed.emit()
