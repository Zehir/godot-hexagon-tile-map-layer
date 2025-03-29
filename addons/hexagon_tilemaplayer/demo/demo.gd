extends Node2D

const STACKED_HORIZONTAL = preload("uid://brm40hxx3wp8n")
const STACKED_VERTICAL = preload("uid://l4anov1m1f53")
@onready var hexagon_tile_map_layer: HexagonTileMapLayer = $HexagonTileMapLayer
@onready var button_layout_vertical: CheckBox = %LayoutVertical
@onready var button_layout_horizontal: CheckBox = %LayoutHorizontal
@onready var tile_set_layout_option: OptionButton = %TileSetLayout


func _ready() -> void:
	if (
		hexagon_tile_map_layer.tile_set.tile_offset_axis
		== TileSet.TileOffsetAxis.TILE_OFFSET_AXIS_HORIZONTAL
	):
		button_layout_horizontal.button_pressed = true
	else:
		button_layout_vertical.button_pressed = true

	tile_set_layout_option.selected = hexagon_tile_map_layer.tile_set.tile_layout


func _on_tile_layout_offset_vertical_pressed() -> void:
	hexagon_tile_map_layer.tile_set = STACKED_VERTICAL
	hexagon_tile_map_layer.astar_changed.connect(
		_on_tile_layout_selected.bind(tile_set_layout_option.selected), CONNECT_ONE_SHOT
	)
	hexagon_tile_map_layer.pathfinding_generate_points()


func _on_tile_layout_offset_horizontal_pressed() -> void:
	hexagon_tile_map_layer.tile_set = STACKED_HORIZONTAL
	hexagon_tile_map_layer.astar_changed.connect(
		_on_tile_layout_selected.bind(tile_set_layout_option.selected), CONNECT_ONE_SHOT
	)
	hexagon_tile_map_layer.pathfinding_generate_points()


func _on_tile_layout_selected(index: int) -> void:
	hexagon_tile_map_layer.update_cells_layout(
		hexagon_tile_map_layer.tile_set.tile_layout, index as TileSet.TileLayout
	)

	if hexagon_tile_map_layer.pathfinding_enabled:
		hexagon_tile_map_layer.astar_changed.connect(
			hexagon_tile_map_layer._draw_debug, CONNECT_DEFERRED + CONNECT_ONE_SHOT
		)
		hexagon_tile_map_layer.pathfinding_generate_points()
	else:
		hexagon_tile_map_layer._draw_debug.call_deferred()
