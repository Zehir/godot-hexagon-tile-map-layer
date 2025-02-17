extends HexagonTileMapLayer


func _pathfinding_get_tile_weight(coords: Vector2i) -> float:
	return get_cell_tile_data(coords).get_custom_data("pathfinding_weight")


func _pathfinding_does_tile_connect(tile: Vector2i, neighbor: Vector2i) -> bool:
	var is_tile_ocean = get_cell_tile_data(tile).get_custom_data("is_ocean")
	var is_neighbor_ocean = get_cell_tile_data(neighbor).get_custom_data("is_ocean")
	return is_tile_ocean == is_neighbor_ocean
