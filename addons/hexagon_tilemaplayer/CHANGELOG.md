# Changelog

## 1.0.0

### Added

- Initial release

## 1.0.1

### Patch Changes

- Fix incorrect loading of the toolbar

## 1.1.0

### Breaking change

- Require Godot 4.4 or later

### Added

- Axis dependant variables that get updated on ready
  - cube_direction_vectors: Dictionary[TileSet.CellNeighbor, Vector3i]
  - cube_side_neighbor_directions: Array[TileSet.CellNeighbor]
  - cube_corner_neighbor_directions: Array[TileSet.CellNeighbor]
- Methods to get cells position depending of local position
  - get_closest_cells_from_local(local: Vector2, count: int = 1) -> Array[Vector3i]
  - get_closest_cell_from_local(local: Vector2) -> Vector3i
  - get_closest_cells_from_mouse(count: int = 1) -> Array[Vector3i]
  - get_closest_cell_from_mouse() -> Vector3i

### Updated

- Reduce axis comparaison for static methods by caching neighbor_directions and direction_vectors vars
