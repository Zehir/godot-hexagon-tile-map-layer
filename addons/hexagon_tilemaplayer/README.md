# Godot Hexagon TileMapLayer

Set of tools to use hexagon based tilemap in Godot with A\* pathfinding and cube coordinates system.

Require Godot 4.4+, for 4.3+ use version 1.0.1 or earlier

## Features

- A\* pathfinding support
- Cube coordinates system
- Conversion between different coordinate systems
- Both offset axis support (horizontal, vertical)
- All layout support (stacked, stacked offset, stairs right, stairs down, diamond right, diamond down)
- Toolbar actions to fix tilemaps after layout changes
- Debug visualization

## Quick Start

1. Setup your tileset with hexagon shaped tiles (TileSet.TileShape.TILE_SHAPE_HEXAGON)
2. Select your TileMapLayer node and change its type to HexagonTileMapLayer
3. (Optional) If you need pathfinding, create a new script extending HexagonTileMapLayer:

```gdscript
extends HexagonTileMapLayer

func _ready():
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

## Constants

### Debug Mode Flags

Used with the `debug_mode` property to control debug visualization:

- `DebugModeFlags.TILES_COORDS = 1`: Display tile coordinates on each tile
- `DebugModeFlags.CONNECTIONS = 2`: Display pathfinding connections between tiles

### Axis dependent constants

Collection of predefined vectors for hex movement and neighbor identification. These vectors are used to calculate hex positions and directions in the hex grid. Make sure to use the correct set of vectors based on your tilemap's orientation (horizontal or vertical offset).

#### Horizontal Offset Axis

```gdscript
const cube_horizontal_direction_vectors = {
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
```

Arrays of neighbor directions for side and corner neighbors:

```gdscript
# For horizontal offset axis:
const cube_horizontal_side_neighbors: Array[TileSet.CellNeighbor] = [
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
    TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE,
    TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
    TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
    TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE,
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE,
]

const cube_horizontal_corner_neighbors: Array[TileSet.CellNeighbor] = [
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
    TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
    TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_CORNER,
    TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER,
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_CORNER,
]
```

#### Vertical Offset Axis

```gdscript
const cube_vertical_direction_vectors = {
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
```

Arrays of neighbor directions for side and corner neighbors:

```gdscript
const cube_vertical_side_neighbors: Array[TileSet.CellNeighbor] = [
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
    TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
    TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_SIDE,
    TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE,
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_SIDE,
]

const cube_vertical_corner_neighbors: Array[TileSet.CellNeighbor] = [
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
    TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_CORNER,
    TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
    TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
    TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_CORNER,
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER,
]
```

These arrays define the order in which neighbors are visited when using functions like `cube_ring` and `cube_spiral`.

## Functions Reference

### Coordinate Conversions

- `map_to_cube(map_position: Vector2i) -> Vector3i`: Converts tilemap coordinates to cube coordinates. This is useful when you need to perform hex grid operations like distance calculation or finding neighbors.

```gdscript
# Converting from tilemap (2, 1) to cube coordinates
var cube_pos = tilemap.map_to_cube(Vector2i(2, 1))
print(cube_pos) # Output: (2, 1, -3) - notice x + y + z = 0
```

- `cube_to_map(cube_position: Vector3i) -> Vector2i`: Converts cube coordinates back to tilemap coordinates. Use this after performing hex grid calculations to place tiles or entities.

```gdscript
# Converting from cube (2, 1, -3) back to tilemap coordinates
var map_pos = tilemap.cube_to_map(Vector3i(2, 1, -3))
print(map_pos)  # Output: (2, 1)
```

- `local_to_cube(local_position: Vector2) -> Vector3i`: Converts pixel coordinates in the tilemap's local space to cube coordinates. Useful for converting mouse positions or entity positions to hex grid coordinates.

```gdscript
# Convert mouse position to cube coordinates
var mouse_pos = get_local_mouse_position()
var cube_pos = tilemap.local_to_cube(mouse_pos)
print(cube_pos)  # Output: Vector3i(2, -1, -1)

# Use it for entity placement
var entity_pos = my_entity.position
var entity_hex = tilemap.local_to_cube(entity_pos)
print("Entity is in hex: ", entity_hex)
```

- `cube_to_local(cube_position: Vector3i) -> Vector2`: Converts cube coordinates to pixel coordinates in the tilemap's local space. Use this to position entities or UI elements at the center of a hex.

```gdscript
# Get the center position of a hex for entity placement
var hex_pos = Vector3i(2, -1, -1)
var center = tilemap.cube_to_local(hex_pos)
my_entity.position = center  # Places entity at hex center

# Useful for UI indicators
var hex_centers = []
for hex in selected_hexes:
    hex_centers.append(tilemap.cube_to_local(hex))
highlight_hexes(hex_centers)  # Draw indicators at hex centers
```

### Grid Operations

- `cube_direction(direction: TileSet.CellNeighbor) -> Vector3i`: Returns the cube coordinate vector representing a hex direction.

There are two types of directions:

- Side directions (CELL*NEIGHBOR*\*\_SIDE): Move to adjacent hexes, one step away
- Corner directions (CELL*NEIGHBOR*\*\_CORNER): Move to diagonal hexes, two steps away in a single move

These vectors can be added to a cube position to move in the specified direction.

```gdscript
var top_right = tilemap.cube_direction(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE)
print(top_right)  # Output: Vector3i(1, -1, 0)

var right = tilemap.cube_direction(TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE)
print(right)  # Output: Vector3i(1, 0, -1)

# Corner directions (diagonal hexes, two steps)
var top_right_corner = tilemap.cube_direction(TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER)
print(top_right_corner)  # Output: Vector3i(2, -1, -1)  # Note the magnitude is 2

# Movement examples
var current_pos = Vector3i(0, 0, 0)

# Compare side vs corner movement
var side_move = current_pos + top_right + right # One step diagonally and one right
var corner_move = current_pos + top_right_corner  # Two steps diagonally at once
print(side_move == corner_move)  # Output: true - Both moves end up at the same position

# Create a zigzag path mixing side and corner moves
var zigzag = current_pos
zigzag += right  # Move one step right
zigzag += top_right_corner  # Jump two steps diagonally
print(zigzag)  # Output: Vector3i(3, -1, -2)
```

- `cube_neighbor(cube: Vector3i, direction: TileSet.CellNeighbor) -> Vector3i`: Gets the cube coordinates of a neighboring hex in a specified direction. Like `cube_direction`, it supports both side and corner neighbors. This is a convenience function that combines the current position with a direction vector.

```gdscript
# Get side neighbors (adjacent hexes)
var current = Vector3i(0, 0, 0)
var right_neighbor = tilemap.cube_neighbor(current, TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE)
print(right_neighbor)  # Output: Vector3i(1, 0, -1)

var top_right_neighbor = tilemap.cube_neighbor(current, TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE)
print(top_right_neighbor)  # Output: Vector3i(1, -1, 0)

# Get corner neighbors (diagonal hexes)
var top_right_corner = tilemap.cube_neighbor(current, TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER)
print(top_right_corner)  # Output: Vector3i(2, -1, -1)

# Chain multiple moves
var final_pos = tilemap.cube_neighbor(
        tilemap.cube_neighbor(current, TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE),
        TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE
)
print(final_pos)  # Output: Vector3i(2, -1, -1) - Same as using corner neighbor directly
```

- `cube_neighbors(cube: Vector3i) -> Array[Vector3i]`: Gets all adjacent hexes surrounding a center hex. Returns an array of 6 positions in clockwise order starting from top-right.

```gdscript
# Get all adjacent neighbors
var center = Vector3i(0, 0, 0)
var neighbors = tilemap.cube_neighbors(center)
print(neighbors) # Output: [
                 #   (1,-1,0),  # top-right
                 #   (1,0,-1),  # right
                 #   (0,1,-1),  # bottom-right
                 #   (-1,1,0),  # bottom-left
                 #   (-1,0,1),  # left
                 #   (0,-1,1)   # top-left
                 # ]

# Check all adjacent tiles
for neighbor in neighbors:
    if tilemap.get_cell_source_id(tilemap.cube_to_map(neighbor)) != -1:
        print("Found adjacent hex at: ", neighbor)
```

- `cube_corner_neighbors(cube: Vector3i) -> Array[Vector3i]`: Gets all corner (diagonal) hexes surrounding a center hex. Returns an array of 6 positions in clockwise order starting from top-right corner.

```gdscript
# Get all corner neighbors
var center = Vector3i(0, 0, 0)
var corners = tilemap.cube_corner_neighbors(center)
print(corners) # Output: [
               #   (2,-1,-1),  # top-right corner
               #   (1,1,-2),   # bottom-right corner
               #   (-1,2,-1),  # bottom corner
               #   (-2,1,1),   # bottom-left corner
               #   (-1,-1,2),  # top-left corner
               #   (1,-2,1)    # top corner
               # ]

# Get all surrounding hexes (both adjacent and corner)
var all_neighbors: Array[Vector3i] = []
all_neighbors.append_array(tilemap.cube_neighbors(center))     # 6 adjacent neighbors
all_neighbors.append_array(tilemap.cube_corner_neighbors(center)) # 6 corner neighbors
print(all_neighbors.size())  # Output: 12 total surrounding hexes
```

- `cube_distance(a: Vector3i, b: Vector3i) -> int`: Calculates the shortest path distance between two hexes in the hex grid. The distance is measured in number of steps needed to go from hex A to hex B, where each step is a move to an adjacent hex. This is also known as the "Manhattan distance" for hex grids.

> **Warning:** Don't use Vector3i.distance_to() for hex grid distances! It will give incorrect results because it measures straight-line (Euclidean) distance rather than hex grid steps.

```gdscript
# Calculate distance between hexes
var center = Vector3i(0, 0, 0)
var target = Vector3i(2, -1, -1)
var distance = tilemap.cube_distance(center, target)
print(distance)  # Output: 2 (need 2 steps to reach the target)

# Comparing distances
var hex1 = Vector3i(1, -1, 0)  # adjacent to center
var hex2 = Vector3i(2, -2, 0)  # two steps away
print(tilemap.cube_distance(center, hex1))  # Output: 1
print(tilemap.cube_distance(center, hex2))  # Output: 2

# WRONG WAY - don't use this!
print(center.distance_to(target))  # Output: 2.449... (incorrect, measures straight-line distance)

# Use it for range checks
var max_range = 2
if tilemap.cube_distance(center, target) <= max_range:
    print("Target is within range!")  # Will print as distance is 2

# Calculate movement cost (if each step costs 1)
var movement_points = 3
var can_reach = tilemap.cube_distance(center, target) <= movement_points
print(can_reach)  # Output: true (can reach destination in 3 steps)
```

- `cube_linedraw(a: Vector3i, b: Vector3i) -> Array[Vector3i]`: Returns all hexes that form a line between two points. Uses a linear interpolation to determine which hexes should be included in the line. Perfect for implementing line-of-sight, ranged attacks, or drawing paths between two points.

> **Note:** The returned array is guaranteed to start with vector `a` and end with vector `b`, making it easy to track the exact start and end points of your line.

```gdscript
# Draw a simple line
var start = Vector3i(0, 0, 0)
var end = Vector3i(2, -1, -1)
var line = tilemap.cube_linedraw(start, end)
print(line)  # Output: [(0, 0, 0), (1, -1, -1), (2, -1, -1)]
print(line[0] == start)  # Output: true - First element is always the start vector
print(line[-1] == end)   # Output: true - Last element is always the end vector

# Use it for line of sight checks
func has_line_of_sight(from: Vector3i, to: Vector3i) -> bool:
    var line = tilemap.cube_linedraw(from, to)
    for hex in line:
        if tilemap.get_cell_source_id(tilemap.cube_to_map(hex)) == 1:
            return false  # Line of sight blocked by wall
    return true

# Create a beam attack effect
var beam_hexes = tilemap.cube_linedraw(caster_pos, target_pos)
for hex in beam_hexes:
    apply_damage(hex)  # Apply damage to each hex in the line

# Visualize the path
var debug_line = Line2D.new()
for hex in tilemap.cube_linedraw(start, end):
    debug_line.add_point(tilemap.cube_to_local(hex))
tilemap.add_child(debug_line)
```

- `cube_range(center: Vector3i, distance: int) -> Array[Vector3i]`: Gets all hexes within a certain distance of a center hex. Creates a hexagonal-shaped area where every hex is at most 'distance' steps away from the center. Perfect for area-of-effect abilities or calculating movement ranges.

> **Note:** The returned hexes are ordered from left to right, row by row, which can be useful for consistent processing or display of the area.

> **See also:** If you need to process the hexes in a spiral pattern instead of row by row, check out the `cube_spiral` function.

```gdscript
# Get all hexes within 1 step of center (7 hexes total)
var center = Vector3i(0, 0, 0)
var cells = tilemap.cube_range(center, 1)
print(cells)  # Output: [
              #   (-1,0,1),   # left
              #   (-1,1,0),   # bottom-left
              #   (0,-1,1),   # top-left
              #   (0,0,0),    # center
              #   (0,1,-1)    # bottom-right
              #   (1,-1,0),   # top-right
              #   (1,0,-1),   # right
              # ]  # Notice the left-to-right ordering

# Calculate area of effect for a spell
var spell_range = 2
var affected_hexes = tilemap.cube_range(caster_position, spell_range)
for hex in affected_hexes:
    apply_effect(hex)  # Apply spell effect to each hex in range

# Check if target is within movement range
var movement_range = 3
var reachable_hexes = tilemap.cube_range(unit_position, movement_range)
if target_hex in reachable_hexes:
    print("Can reach target!")

# Visualize the range
for hex in tilemap.cube_range(center, 2):
    highlight_hex(tilemap.cube_to_local(hex))  # Show movement range to player
```

- `cube_rotate(position: Vector3i, rotations: int) -> Vector3i`: Rotates a hex position around the origin (0,0,0) by a number of 60-degree steps. Positive rotations are clockwise, negative are counter-clockwise. Each rotation value represents a 60-degree turn, so a full 360-degree rotation is 6 steps.

```gdscript
var pos = Vector3i(2, 0, -2)  # A hex two steps to the right

# Rotate clockwise (60 degrees)
var rotated = tilemap.cube_rotate(pos, 1)
print(rotated)  # Output: Vector3i(0, 2, -2)

# Rotate counter-clockwise (120 degrees)
var ccw = tilemap.cube_rotate(pos, -2)
print(ccw)  # Output: Vector3i(0, -2, 2)

# Full rotation (360 degrees = 6 steps)
var full = tilemap.cube_rotate(pos, 6)
print(full)  # Output: Vector3i(2, 0, -2) - Back to original position

# Multiple rotations are automatically normalized to 0-5
var large = tilemap.cube_rotate(pos, 10)  # Same as rotating by 4 or -2 (10 mod 6)
print(large)  # Output: Vector3i(0, -2, 2)

# Use it for rotating formations or patterns
var formation = [Vector3i(1,0,-1), Vector3i(2,0,-2), Vector3i(1,-1,0)]
var rotated_formation = formation.map(func(p): return tilemap.cube_rotate(p, 2))
print(rotated_formation)  # Output: [(-1, 1, 0), (-2, 2, 0), (0, 1, -1)]
```

- `cube_rotate_from(position: Vector3i, from: Vector3i, rotations: int) -> Vector3i`: Rotates a hex position around a center point by a number of 60-degree steps. Like `cube_rotate`, but allows you to specify a different center of rotation.

```gdscript
# Rotate around the origin point (0,0,0)
var pos = Vector3i(2, 0, -2)
var rotated = tilemap.cube_rotate(pos, 2)  # 120 degrees clockwise
print(rotated)  # Output: Vector3i(-2, 2, 0)

# Rotate around a different center point
var center = Vector3i(1, -1, 0)
var rotated_from = tilemap.cube_rotate_from(pos, center, 2)
print(rotated_from)  # Output: Vector3i(-1, 0, 1)

# Rotate a formation around its center
var formation = [Vector3i(0, 0, 0), Vector3i(1, 0, -1), Vector3i(1, -1, 0)]
var center_formation = Vector3i(1, 0, -1)  # Center of formation
var rotated_formation = formation.map(
    func(p): return tilemap.cube_rotate_from(p, center_formation, 2)
)
print(rotated_formation)  # Output: [(2, -1, -1), (1, 0, -1), (2, 0, -2)]
```

- `cube_ring(center: Vector3i, radius: int, first_side: TileSet.CellNeighbor = -1) -> Array[Vector3i]`: Gets all hexes at exactly a certain distance from the center. Creates a ring shape where every hex is exactly 'radius' steps from the center. Perfect for creating circular patterns or determining attack ranges.

> **Note:** The optional `first_side` parameter determines which side to start from when creating the ring (defaults to top-right). This allows you to control the orientation of patterns built from multiple rings.

```gdscript
# Create a simple ring of radius 2
var center = Vector3i(0, 0, 0)
var ring = tilemap.cube_ring(center, 2)
print(ring.size())  # Output: 12 (each ring has radius * 6 hexes)

# Create a ring starting from the top-right
var oriented_ring = tilemap.cube_ring(
    center,
    2,
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_SIDE
)

# Create multiple concentric rings
var rings = []
for r in range(1, 4):
    rings.append_array(tilemap.cube_ring(center, r))

# Example: Create a ripple effect
for current_radius in range(1, 4):
    for hex in tilemap.cube_ring(center, current_radius):
        var pos = tilemap.cube_to_map(hex)
        tilemap.set_cell(pos, 0, Vector2i(0,0), current_radius)

```

- `cube_spiral(center: Vector3i, radius: int, first_side: TileSet.CellNeighbor = -1) -> Array[Vector3i]`: Creates a spiral pattern starting from the center and going outward in a clockwise direction. Returns all hexes up to the specified radius, ordered in a spiral pattern. Useful for creating expanding effects or exploring hexes in an outward pattern.

> **Note:** Like `cube_ring`, the optional `first_side` parameter determines which side to start from (defaults to top-right). The spiral always starts with the center hex, then moves outward ring by ring.

> **Important:** Each hex in the spiral is adjacent to the next one, creating a continuous path. This means that while `first_side` determines the initial direction, the final orientation of each ring segment will vary to maintain adjacency. For example, if you start with a right-side neighbor, the path might end with a left-side neighbor to complete the spiral.

```gdscript
# Create a basic spiral of radius 2
var center = Vector3i(0, 0, 0)
var spiral = tilemap.cube_spiral(center, 2)
print(spiral.size())  # Output: 19 (1 center + 6 for ring 1 + 12 for ring 2)

# Create a spiral starting from a specific side
var oriented_spiral = tilemap.cube_spiral(
    center,
    2,
    TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_SIDE
)

# Visualization using ordered indices
var tween = create_tween()
for i in spiral.size():
    var delay = float(i) * 0.1  # Increase delay with each hex
    tween.tween_callback(func():
        var label = Label.new()
        label.text = str(i)
        label.position = tilemap.cube_to_local(spiral[i])
        tilemap.add_child(label)
    ).set_delay(delay)

```

- `cube_intersect_ranges(center1: Vector3i, range1: int, center2: Vector3i, range2: int) -> Array[Vector3i]`: Returns all hexes that are within range1 of center1 AND within range2 of center2. Useful for finding overlapping areas of effect or determining valid positions for abilities that require being in range of multiple targets.

```gdscript
# Find hexes that are within range of both units
var unit1_pos = Vector3i(0, 0, 0)
var unit2_pos = Vector3i(3, -1, -2)
var overlapping_hexes = tilemap.cube_intersect_ranges(
    unit1_pos, 2,  # Unit 1 has range of 2
    unit2_pos, 3   # Unit 2 has range of 3
)
# Result: All hexes that both units can reach
```

- `cube_rect(center: Vector3i, corner: Vector3i, axis: int = Vector3i.AXIS_Y) -> Array[Vector3i]`: Creates a rectangle-like shape on the hex grid by reflecting a corner point around a center point. Returns an array of 4 corner positions. The axis parameter determines the reflection plane.

```gdscript
# Create a rectangular formation
var center = Vector3i(0, 0, 0)
var corner = Vector3i(2, -1, -1)
var corners = tilemap.cube_rect(center, corner)
print(corners)  # Output: [top-right, bottom-right, bottom-left, top-left]

# Use different reflection axes
var corners_x = tilemap.cube_rect(center, corner, Vector3i.AXIS_X)
var corners_y = tilemap.cube_rect(center, corner, Vector3i.AXIS_Y)
var corners_z = tilemap.cube_rect(center, corner, Vector3i.AXIS_Z)
```

- `cube_reflect(position: Vector3i, axis: int) -> Vector3i`: Reflects a hex position across one of the three cube coordinate axes. The axis parameter determines which coordinate pair is swapped.

```gdscript
var pos = Vector3i(2, -1, -1)

# Reflect across different axes
var reflect_x = tilemap.cube_reflect(pos, Vector3i.AXIS_X)  # Swaps y and z
var reflect_y = tilemap.cube_reflect(pos, Vector3i.AXIS_Y)  # Swaps x and z
var reflect_z = tilemap.cube_reflect(pos, Vector3i.AXIS_Z)  # Swaps x and y

print(reflect_x)  # Output: Vector3i(2, -1, -1)
print(reflect_y)  # Output: Vector3i(-1, -1, 2)
print(reflect_z)  # Output: Vector3i(-1, 2, -1)
```

- `cube_reflect_from(position: Vector3i, from: Vector3i, axis: int) -> Vector3i`: Reflects a hex position around a center point across one of the three cube coordinate axes. Useful for creating symmetrical patterns or mirroring positions around a point.

```gdscript
var center = Vector3i(0, 0, 0)
var pos = Vector3i(2, -1, -1)

# Reflect position around center point
var reflection = tilemap.cube_reflect_from(pos, center, Vector3i.AXIS_Y)
print(reflection)  # Output: Vector3i(-2, 1, 1)

# Create symmetrical formations
var formation = [Vector3i(1, 0, -1), Vector3i(2, -1, -1)]
var mirrored = formation.map(
    func(p): return tilemap.cube_reflect_from(p, center, Vector3i.AXIS_Y)
)
print(mirrored)  # Output: [(-1, 0, 1), (-1, -1, 2)]
```

### Closest Cell Operations

> **Note:** For all these methods, when requesting multiple cells (count > 1), the cells are returned in order of proximity to the target position. The closest cell is always at index 0.

> **Implementation Detail:** The returned cells take into account the tile's orientation to determine the best matches.

The extension provides several methods to find the closest hex cell(s) from a given position:

- `get_closest_cells_from_local(local: Vector2, count: int = 1) -> Array[Vector3i]`: Returns an array of the closest hex cells to that position, ordered by proximity. The `count` parameter (default: 1) determines how many hexes to return. This is useful when you need to know not just the closest hex, but also nearby alternatives.

```gdscript
# Get multiple hexes near a position
var pos = Vector2(150, 150)
var nearby = tilemap.get_closest_cells_from_local(pos, 3)
print(nearby)  # Output: [Vector2i(3,2), Vector2i(3,3), Vector2i(2,2)]

# Create an area of effect around an impact point
var impact_pos = projectile.global_position
var affected = tilemap.get_closest_cells_from_local(
    tilemap.to_local(impact_pos),
    4  # Affect 4 closest hexes
)
for hex in affected:
    apply_explosion_damage(hex)

# Determine multiple valid placement positions
func get_valid_placement_options(world_pos: Vector2) -> Array[Vector2i]:
    var local_pos = tilemap.to_local(world_pos)
    var candidates = tilemap.get_closest_cells_from_local(local_pos, 5)
    return candidates.filter(func(hex): return is_valid_placement(hex))
```

- `get_closest_cell_from_local(local: Vector2) -> Vector3i`: Returns the map coordinates of the hex cell closest to a given position in the tilemap's local space.

```gdscript
# Get hex at a specific position
var local_pos = Vector2(100, 100)
var hex = tilemap.get_closest_cell_from_local(local_pos)
print(hex)  # Output: Vector2i(2, 1) - coordinates of closest hex

# Use with node positions
var entity_pos = some_entity.position
var entity_hex = tilemap.get_closest_cell_from_local(
    tilemap.to_local(entity_pos)  # Convert to tilemap's local space
)

# Track entity movement between hexes
func _process(_delta):
    var current_hex = tilemap.get_closest_cell_from_local(position)
    if current_hex != last_hex:
        on_enter_new_hex(current_hex)
        last_hex = current_hex
```

- `get_closest_cells_from_mouse(count: int = 1) -> Array[Vector3i]`: Returns an array of the closest hex cells to the mouse position, ordered by proximity. The `count` parameter (default: 1) determines how many hexes to return. This is useful when you need to know not just the closest hex, but also nearby alternatives.

```gdscript
# Get the three closest hexes to mouse
var closest = tilemap.get_closest_cells_from_mouse()  # Default count: 3
print(closest)  # Output: [Vector2i(2,1), Vector2i(2,2), Vector2i(1,1)]

# Get just the closest hex
var single = tilemap.get_closest_cells_from_mouse(1)
print(single)  # Output: [Vector2i(2,1)]

# Show multiple targeting options
var possible_targets = tilemap.get_closest_cells_from_mouse(3)
for hex in possible_targets:
    highlight_hex(hex, Color(1, 1, 0, 0.3))  # Highlight potential targets

# Create a splash damage preview
func update_area_preview():
    var targets = tilemap.get_closest_cells_from_mouse(3)
    clear_previews()
    for i in targets.size():
        var alpha = 1.0 - (i * 0.25)  # Fade out further hexes
        show_damage_preview(targets[i], alpha)
```

- `get_closest_cell_from_mouse() -> Vector3i`: Returns the map coordinates of the hex cell closest to the current mouse position.

```gdscript
# Get the hex under the mouse cursor
var target_hex = tilemap.get_closest_cell_from_mouse()
print(target_hex)  # Output: Vector2i(2, 1) - coordinates of the hex under mouse

# Useful for hover effects
func _process(_delta):
    var hovered_hex = tilemap.get_closest_cell_from_mouse()
    if hovered_hex != last_hovered_hex:
        update_hover_indicator(hovered_hex)
        last_hovered_hex = hovered_hex

# Handle click events
func _unhandled_input(event):
    if event is InputEventMouseButton and event.pressed:
        var clicked_hex = tilemap.get_closest_cell_from_mouse()
        handle_hex_click(clicked_hex)
```

## Pathfinding

The extension includes built-in A\* pathfinding support. When enabled, it automatically creates a navigation graph where each hex is a node and adjacent hexes are connected. You can customize the pathfinding behavior by overriding the weight calculation and connection rules.

> **Warning:** All pathfinding methods use map coordinates (Vector2i), not cube coordinates. If you're working with cube coordinates, remember to convert them using `cube_to_map()` before using these functions.

> **Note:** You can access the underlying AStar2D instance directly through the `astar` property for advanced pathfinding operations.

To use pathfinding:

1. Set `pathfinding_enabled = true` in your tilemap
2. (Optional) Override `_pathfinding_get_tile_weight` to set custom movement costs
3. (Optional) Override `_pathfinding_does_tile_connect` to control which hexes can be traversed

The pathfinding system uses (AStar2D)[https://docs.godotengine.org/en/stable/classes/class_astar2d.html] internally and provides these functions:

- `pathfinding_get_point_id(coord: Vector2i) -> int`: Gets the internal AStar2D node ID for a hex. This function is essential for working with AStar2D pathfinding operations, as it converts tilemap coordinates to the unique IDs used by the pathfinding system.

```gdscript

# Get ID for a specific hex
var hex_pos_a = Vector2i(-2, -1)
var hex_pos_b = tilemap.cube_to_map(Vector3i(0, 1, -1))
var id = tilemap.pathfinding_get_point_id(hex_pos_a)
print(id)  # Output: 9

# Use it with AStar2D methods
var start_id = tilemap.pathfinding_get_point_id(hex_pos_a)
var end_id = tilemap.pathfinding_get_point_id(hex_pos_b)
var path = tilemap.astar.get_id_path(start_id, end_id)
print(path)  # Output: [9, 16, 17, 22]

# Check point connections
var point_a = tilemap.pathfinding_get_point_id(Vector2i(-2, -1))
var point_b = tilemap.pathfinding_get_point_id(Vector2i(-1, 0))
var are_connected = tilemap.astar.are_points_connected(point_a, point_b)
print(are_connected)  # Output: true
```

- `pathfinding_recalculate_tile_weight(coord: Vector2i)`: Updates the pathfinding weight for a specific hex. Call this method whenever terrain conditions change that would affect movement cost through this hex (like placing mud, adding obstacles, etc.). The weight is calculated by calling your custom `_pathfinding_get_tile_weight` method.

```gdscript
# Make a hex harder to traverse when damaged
func apply_terrain_damage(pos: Vector2i):
    terrain_damage[pos] = true
    tilemap.pathfinding_recalculate_tile_weight(pos)  # Update pathfinding

# Override weight calculation based on terrain
func _pathfinding_get_tile_weight(coords: Vector2i) -> float:
    if terrain_damage.has(coords):
        return 2.0  # Damaged terrain costs twice as much to traverse
    return 1.0  # Normal terrain cost

# Batch update multiple tiles
for pos in affected_tiles:
    tilemap.pathfinding_recalculate_tile_weight(pos)
```

## Debug Visualization

The extension provides debug visualization features to help you understand and debug your hex grid. These visualizations are overlaid on top of your tilemap and can be toggled using the `debug_mode` property.

> **Note:** Debug visualization is only displayed during runtime, not in the editor. This helps keep the editor view clean while still providing debugging capabilities when you need them.

Available debug options:

- `DebugModeFlags.TILES_COORDS`: Displays coordinate information for each hex:
  - Pathfinding ID (when pathfinding is enabled)
  - Map coordinates (x, y)
  - Cube coordinates (x, y, z)
- `DebugModeFlags.CONNECTIONS`: Shows pathfinding connections between hexes as colored lines
  - Each connection gets a random color for better visibility
  - Only visible when pathfinding is enabled

You can enable multiple debug options at once by combining them with the bitwise OR operator:

```gdscript
# Show both coordinates and connections
tilemap.debug_mode = HexagonTileMapLayer.DebugModeFlags.TILES_COORDS | HexagonTileMapLayer.DebugModeFlags.CONNECTIONS

# Show only coordinates
tilemap.debug_mode = HexagonTileMapLayer.DebugModeFlags.TILES_COORDS

# Disable all debug visualization
tilemap.debug_mode = 0
```

## Utils

### Debug Helpers

- `_show_debug_text_on_tile(debug_container: Node2D, pos: Vector2i, text: String)`: Helper function to display text centered on a hex tile. Creates a RichTextLabel with proper formatting and positioning.

```gdscript
# Display custom text on a hex
var debug_container = Node2D.new()
var hex_pos = Vector2i(1, 1)
var text = "[center]Custom\nText[/center]"  # Use BBCode for formatting
tilemap._show_debug_text_on_tile(debug_container, hex_pos, text)
tilemap.add_child(debug_container)

# Show multiple labels
for hex in highlighted_hexes:
    var label_text = "[center]Hex %d[/center]" % [hex_count]
    tilemap._show_debug_text_on_tile(debug_container, hex, label_text)
```

The text will be:

- Centered on the hex (both horizontally and vertically)
- Auto-sized to fit the hex
- Using a font size proportional to hex size
- With outline for better visibility
- Ignoring mouse input
- Supporting BBCode formatting

## Static Functions Reference

Most grid operations are available as static methods, allowing you to use them without a TileMap instance. This is useful for:

- Grid calculations in separate systems
- Unit testing
- Pre-computing grid patterns

Most of the static methods have a `_for_axis` suffix and require you to specify the offset axis:

```gdscript
# Using instance method (uses tilemap's axis)
var neighbors = tilemap.cube_neighbors(pos)

# Using static method (specify axis explicitly)
var neighbors = HexagonTileMapLayer.cube_neighbors_for_axis(
    TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL,
    pos
)

# Get conversion methods for a specific layout
var methods = HexagonTileMapLayer.get_conversion_methods_for(
    TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL,
    TileSet.TileLayout.TILE_LAYOUT_STACKED
)
var cube_pos = methods.map_to_cube.call(map_pos)
```

Available static methods:

- `cube_direction_for_axis(axis: TileSet.TileOffsetAxis, direction: TileSet.CellNeighbor) -> Vector3i`: Static version of `cube_direction` that requires explicitly specifying the offset axis. Returns the cube coordinate vector for a given direction.

```gdscript
# Using instance method (uses tilemap's axis)
var vec = tilemap.cube_direction(TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE)

# Using static method (specify axis explicitly)
var vec = HexagonTileMapLayer.cube_direction_for_axis(
    TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL,
    TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE
)
```

Other available static methods:

- `cube_neighbor_for_axis(axis: TileSet.TileOffsetAxis, cube: Vector3i, direction: TileSet.CellNeighbor) -> Vector3i`
  See `cube_neighbor` for details.

- `cube_neighbors_for_axis(axis: TileSet.TileOffsetAxis, cube: Vector3i) -> Array[Vector3i]`
  See `cube_neighbors` for details.

- `cube_corner_neighbors_for_axis(axis: TileSet.TileOffsetAxis, cube: Vector3i) -> Array[Vector3i]`
  See `cube_corner_neighbors` for details.

- `cube_ring_for_axis(axis: TileSet.TileOffsetAxis, center: Vector3i, radius: int, first_side: TileSet.CellNeighbor = -1) -> Array[Vector3i]`
  See `cube_ring` for details.

- `cube_spiral_for_axis(axis: TileSet.TileOffsetAxis, center: Vector3i, radius: int, first_side: TileSet.CellNeighbor = -1) -> Array[Vector3i]`
  See `cube_spiral_for_axis` for details.

- `get_conversion_methods_for(axis: TileSet.TileOffsetAxis, layout: TileSet.TileLayout) -> Dictionary`: Returns a dictionary containing conversion methods for the specified axis and layout. The dictionary contains two functions:

  - `map_to_cube`: Converts from tilemap coordinates to cube coordinates
  - `cube_to_map`: Converts from cube coordinates to tilemap coordinates

This is particularly useful when you need to handle different hex layouts in custom systems:

```gdscript
# Get converters for a specific layout
var converters = HexagonTileMapLayer.get_conversion_methods_for(
    TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL,
    TileSet.TileLayout.TILE_LAYOUT_STACKED
)

# Use the converters
var cube_pos = converters.map_to_cube.call(tile_pos)
var map_pos = converters.cube_to_map.call(cube_pos)

# Handle multiple layouts
var layout_converters = {
    "stacked": HexagonTileMapLayer.get_conversion_methods_for(
        TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL,
        TileSet.TileLayout.TILE_LAYOUT_STACKED
    ),
    "diamond": HexagonTileMapLayer.get_conversion_methods_for(
        TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL,
        TileSet.TileLayout.TILE_LAYOUT_DIAMOND_RIGHT
    )
}
```

### Internal Conversion Methods

The `get_conversion_methods_for` function uses a set of static coordinate conversion methods internally. Each method handles a specific combination of offset axis and layout:

For horizontal offset axis:

- `_cube_to_horizontal_stacked` / `_horizontal_stacked_to_cube`
- `_cube_to_horizontal_stacked_offset` / `_horizontal_stacked_offset_to_cube`
- `_cube_to_horizontal_stairs_right` / `_horizontal_stairs_right_to_cube`
- `_cube_to_horizontal_stairs_down` / `_horizontal_stairs_down_to_cube`
- `_cube_to_horizontal_diamond_right` / `_horizontal_diamond_right_to_cube`
- `_cube_to_horizontal_diamond_down` / `_horizontal_diamond_down_to_cube`

For vertical offset axis:

- `_cube_to_vertical_stacked` / `_vertical_stacked_to_cube`
- `_cube_to_vertical_stacked_offset` / `_vertical_stacked_offset_to_cube`
- `_cube_to_vertical_stairs_right` / `_vertical_stairs_right_to_cube`
- `_cube_to_vertical_stairs_down` / `_vertical_stairs_down_to_cube`
- `_cube_to_vertical_diamond_right` / `_vertical_diamond_right_to_cube`
- `_cube_to_vertical_diamond_down` / `_vertical_diamond_down_to_cube`

These methods implement the mathematical formulas for converting between cube and tilemap coordinates for each layout type. You generally won't need to use these directly - instead, use `get_conversion_methods_for` to get the appropriate pair of conversion functions for your layout.
