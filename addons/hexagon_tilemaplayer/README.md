# Godot Hexagon TileMapLayer

[![Godot minimum version](https://img.shields.io/badge/Godot-v4.4%2B-%232C3E50?logo=godotengine&logoColor=6584C4&style=for-the-badge)](https://godotengine.org/releases/4.4/)
[![GitHub Release](https://img.shields.io/github/v/release/Zehir/godot-hexagon-tile-map-layer?sort=semver&display_name=release&style=for-the-badge&color=2980B9)](https://github.com/Zehir/godot-hexagon-tile-map-layer/releases/latest)
[![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/Zehir/godot-hexagon-tile-map-layer/total?style=for-the-badge&color=2980B9)](https://github.com/Zehir/godot-hexagon-tile-map-layer/releases)
[![GitHub Repo stars](https://img.shields.io/github/stars/Zehir/godot-hexagon-tile-map-layer?style=for-the-badge&color=16A085)](https://github.com/Zehir/godot-hexagon-tile-map-layer/stargazers)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/Zehir?style=for-the-badge&color=16A085)](https://github.com/sponsors/Zehir)

<!-- description_start -->

Set of tools to use hexagon based tilemap in Godot with A\* pathfinding and cube coordinates system.

Require [Godot 4.4](https://godotengine.org/releases/4.4/)+, for [4.3](https://godotengine.org/releases/4.3/)+ use version [1.0.1](https://github.com/Zehir/godot-hexagon-tile-map-layer/releases/tag/v1.0.1) or earlier

<!-- description_end -->

<p align="center">
  <img src="https://raw.githubusercontent.com/Zehir/godot-hexagon-tile-map-layer/main/images/cube_linedraw.png" />
</p>

## Features

<!-- description_start -->

- A\* pathfinding support
- Cube coordinates system
- Conversion between different coordinate systems
- Both offset axis support (horizontal, vertical)
- All layout support (stacked, stacked offset, stairs right, stairs down, diamond right, diamond down)
- Toolbar actions to fix tilemaps after layout changes
- Debug visualization
- Embeded documentation

<!-- description_end -->

## Quick Start

1. Setup your tileset with hexagon shaped tiles (TileSet.TileShape.TILE_SHAPE_HEXAGON)
2. Select your TileMapLayer node and change its type to HexagonTileMapLayer
3. (Optional) If you need pathfinding, create a new script extending HexagonTileMapLayer:

```gdscript
@tool
extends HexagonTileMapLayer

func _ready():
    super._ready()
    # Enable pathfinding
    pathfinding_enabled = true

    # Customize pathfinding weights (optional)
    func _pathfinding_get_tile_weight(coords: Vector2i) -> float:
        # Return custom weight value (default is 1.0)
        return 1.0

    # Customize pathfinding connections (optional)
    func _pathfinding_does_tile_connect(tile: Vector2i, neighbor: Vector2i) -> bool:
        # Return whether tiles should be connected (default is true)
        return true

    # Enable debug visualization (optional)
    debug_mode = DebugModeFlags.TILES_COORDS | DebugModeFlags.CONNECTIONS
```

See the `example.tscn` scene for a complete demo of the features.

## Documentation

The extension includes a detailed documentation accessible from the editor. You can find it in the Help menu under the Search Help section.
There is two classes documented:

- HexagonTileMapLayer
- HexagonTileMap

You can also open the documentation from the context menu by right-clicking on the HexagonTileMapLayer header in the inspector and selecting "Open Documentation".

## Coordinate Systems

The extension uses two coordinate systems:

- Map coordinates (Vector2i): Native Godot tilemap coordinates
- Cube coordinates (Vector3i): Hexagonal coordinate system

### Understanding Cube Coordinates

Cube coordinates are based on three axes (q, r, s) instead of the traditional two axes used in square grids. These coordinates follow the constraint that `q + r + s = 0`, meaning they always lie on a diagonal plane in 3D space.

> **Note:** In this extension, the cube coordinates (x, y, z) correspond to (q, r, s) in the Red Blob Games guide. The concepts are the same, just with different axis names.

> For a comprehensive guide on hexagonal grids and cube coordinates, check out [Amit Patel's excellent article on Red Blob Games](https://www.redblobgames.com/grids/hexagons/). This implementation is based on the concepts explained there.

Key concepts:

1. **Three Axes**: Each axis represents a direction in the hex grid:

   - q (green): From west to east
   - r (blue): From northwest to southeast
   - s (purple): From southwest to northeast

2. **Vector Operations**: Unlike offset coordinates, cube coordinates support standard vector operations:

   - Addition/subtraction of coordinates
   - Multiplication/division by scalars
   - Distance calculations
   - Rotation and reflection

3. **Directional Movement**: Each hex direction combines two cube coordinate changes:

   - Northeast: q+1, s-1
   - East: q+1, r-1
   - Southeast: r+1, s-1
   - Southwest: q-1, s+1
   - West: q-1, r+1
   - Northwest: r-1, s+1

This coordinate system makes many hex grid algorithms simpler and more elegant, as they can be adapted from existing 3D cartesian coordinate algorithms.

## Toolbar actions

The extension adds a toolbar button in the editor (with the hexagon icon) when exactly one HexagonTileMapLayer node is selected that provides the following actions:

- **Fix tile layout**: When changing a tileset's layout (e.g., from Stacked to Diamond), the tiles in existing tilemaps will be misplaced. This action helps fix the tilemap by converting the tiles' positions from their original layout to the new one.

  The submenu provides options to specify what the original layout was:

  - Was Stacked
  - Was Stacked Offset
  - Was Stairs Right
  - Was Stairs Down
  - Was Diamond Right
  - Was Diamond Down

  Simply select your HexagonTileMapLayer node and choose the layout that was previously used. The tiles will be automatically repositioned to match the new layout while maintaining their relative positions. If you're not sure what the original layout was, you can try each option until the tiles align correctly and use the undo feature if needed between attempts.
