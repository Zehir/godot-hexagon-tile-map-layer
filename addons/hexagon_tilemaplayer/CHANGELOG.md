# Changelog

## 2.2.0

### Minor Changes

- 7fc7a51: Added method `cube_outlines` to generate outline for a group of hex cells.
- cfd2915: Added method `cube_explore` to explores hexes from a starting point based on filter and traversal conditions.

### Patch Changes

- b8e2a6b: Renamed various variables and added @warning_ignore where needed to suppress warnings.
- afecf5f: Added missing documentation about TileShape class.
- d88bbf0: Fixed Vector2 return order in function `geometry_horizontal_tile_corners` to match the vertical version

## 2.1.0

### Minor Changes

- 2c4ef71: Added `geometry_tile_shape` and `geometry_tile_approx_shape` properties to HexagonTileMapLayer.
- 2c4ef71: Added TileShape sub class to store the shape of a tile for physics collision.
- 2c4ef71: Added HexagonTileMap.geometry_horizontal_tile_corners to get Vector2 position of tile corner.

## 2.0.4

### Updated

- \_pathfinding_generate_points() function is now called pathfinding_generate_points()

### Fixed

- Fix issue with pathfinding points capacity #1
- astar_changed event was called twice.

## 2.0.3

### Fixed

- Fix debug container redraw

## 2.0.2

### Fixed

- Add missing documentation for `cube_rect`

## 2.0.1

### Fixed

- Fix invalid return from `cube_rect_corners` function when center was not `0, 0, 0`
- Rix documentation generation on plugin load (Related to Godot Issue)

## 2.0.0

### Breaking changes

- Split the static methods inside a HexagonTileMap class
- Renammed the `cube_rect` to `cube_rect_corners`

### Added

- New method `cube_rect` to get all cells inside the rect.

### Updated

- Changed the type of `axis` param from `int` to `Vector3i.Axis`. There is no difference in the runtime.
  - cube_reflect(position: Vector3i, axis: Vector3i.Axis) -> Vector3i
  - cube_reflect_from(position: Vector3i, from: Vector3i, axis: Vector3i.Axis) -> Vector3i
  - cube_rect(center: Vector3i, corner: Vector3i, axis: Vector3i.Axis = Vector3i.Axis.AXIS_Y) -> Array[Vector3i]
  - cube_rect_corners(center: Vector3i, corner: Vector3i, axis: Vector3i.Axis = Vector3i.Axis.AXIS_Y) -> Array[Vector3i]

### Fixed

- Fix return type of `cube_spiral` to be `Array[Vector3i]`

## 1.1.0

### Breaking changes

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

## 1.0.1

### Patch Changes

- Fix incorrect loading of the toolbar

## 1.0.0

### Added

- Initial release
