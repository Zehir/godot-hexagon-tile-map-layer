# Changelog

## 2.5.1

### Patch Changes

- f27e698: Refactor tile_set reference to use WeakRef. Fix #14
- fda61f2: Fix demo when switching layout without any method selected.

## 2.5.0

### Minor Changes

- c8e4691: Added `cube_explore` demo.
- 14d6f07: Removed old example folder.
- 7f40399: Added demo for Path finding.
- 8e96a08: Added demo for tile shape.
- 96cf0e0: Added demo in build. #11
- fbc1ede: Updated SVG icons.
- fed8915: Added `cube_outlines` demo.
- 14d6f07: Cleanup demo with new data set and menu.

## 2.4.0

### Minor Changes

- 2db5f3d: Added `cube_range` and `cube_intersect_ranges` demo. Refactored some parts of the demos.
- c5644a9: Added `cube_rect`, `cube_rect_corner_neighbors`, `cube_ring` demo.
- 6b4f4a1: Updated `cube_linedraw` demo.
- 50344a8: Added `cube_neighbors`, `cube_corner_neighbors`, `cube_distance` demo.
- cf10679: Added `cube_neighbor` demo.
- 153735d: Added `cube_spiral` demo and rework method list.
- 6b4f4a1: Added `cube_direction` demo.
- 10ef17a: Added `cube_rotate`, `cube_rotate_from`, `cube_reflect`, `cube_reflect_from` demo.

### Patch Changes

- bdccc2b: Fixed `cube_ring` returning empty array with size of 0.
- 3b88ded: Fixed `cube_range` to return the center cell with a distance of 0.
- e6cef6e: Fixed `cube_linedraw` not returning a cell when both points are the same.

## 2.3.1

### Patch Changes

- ef3cc9f: Removed demo folder from main build.

## 2.3.0

### Minor Changes

- e9cff51: Added interactive demo for the plugin showcasing hex grid functionality with layout selection.
  More methods will be added to the demo in the future.
- 9777a32: Added `update_cells_layout` method to updates the layout of a hex tilemap while preserving the logical positions of all tiles.
- 69ff05f: Added method `HexagonTileMap.update_cells_layout` to updates the layout of a hex tilemap while preserving the logical positions of all tiles.
- 60ab58b: Added methods `HexagonTileMap.cube_round` and `cube_round` to rounds a fractional cube coordinate to the nearest valid hex coordinate.

### Patch Changes

- b061de5: Fixed conversion methods reloading when the tile_set itself is replaced during runtime.
- dedab9e: Fixed `cube_linedraw` method that could skip some tiles on the line depending on the selected tile_layout when the line is aligned to some of the corner axes.

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
