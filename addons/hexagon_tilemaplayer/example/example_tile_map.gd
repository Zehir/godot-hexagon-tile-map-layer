@tool
extends HexagonTileMapLayer

const TILE_HORIZONTAL = preload("tile_horizontal.png")
const TILE_VERTICAL = preload("tile_vertical.png")

var debug_hovering_tiles: Dictionary[int, Sprite2D] = {}


func _ready() -> void:
	super._ready()
	var colors = [Color.BLUE, Color.WHITE, Color.RED]

	for i in colors.size():
		_get_or_make_debug_tile(i, colors[i])


func _get_or_make_debug_tile(
	index: int, color: Color = Color(randf(), randf(), randf())
) -> Sprite2D:
	if debug_hovering_tiles.has(index):
		return debug_hovering_tiles[index]

	var sprite = Sprite2D.new()
	sprite.scale *= 0.9
	sprite.modulate = color
	if tile_set.tile_offset_axis == TileSet.TILE_OFFSET_AXIS_HORIZONTAL:
		sprite.texture = TILE_HORIZONTAL
	else:
		sprite.texture = TILE_VERTICAL
	debug_hovering_tiles[index] = sprite
	add_child(sprite)
	return sprite


func _pathfinding_get_tile_weight(coords: Vector2i) -> float:
	return get_cell_tile_data(coords).get_custom_data("pathfinding_weight")


func _pathfinding_does_tile_connect(tile: Vector2i, neighbor: Vector2i) -> bool:
	var is_tile_ocean = get_cell_tile_data(tile).get_custom_data("is_ocean")
	var is_neighbor_ocean = get_cell_tile_data(neighbor).get_custom_data("is_ocean")
	return is_tile_ocean == is_neighbor_ocean


func _unhandled_input(event: InputEvent):
	if is_visible_in_tree() and event is InputEventMouseMotion:
		var pos_list = get_closest_cells_from_local(get_local_mouse_position(), 4)
		if pos_list.size() == 0:
			return
		if get_cell_source_id(cube_to_map(pos_list[0])) != -1:
			for pos_index in pos_list.size():
				_get_or_make_debug_tile(pos_index).position = map_to_local(
					cube_to_map(pos_list[pos_index])
				)
