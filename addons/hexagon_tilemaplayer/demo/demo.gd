extends Node2D

@onready var hexagon_tile_map_layer_horizontal: HexagonTileMapLayer = $HexagonTileMapLayerHorizontal
@onready var hexagon_tile_map_layer_vertical: HexagonTileMapLayer = $HexagonTileMapLayerVertical
@onready var tile_map: HexagonTileMapLayer = hexagon_tile_map_layer_horizontal

@onready var button_layout_vertical: CheckBox = %LayoutVertical
@onready var button_layout_horizontal: CheckBox = %LayoutHorizontal
@onready var tile_set_layout_option: OptionButton = %TileSetLayout


func _ready() -> void:
	button_layout_horizontal.button_pressed = hexagon_tile_map_layer_horizontal.is_visible_in_tree()
	button_layout_vertical.button_pressed = hexagon_tile_map_layer_vertical.is_visible_in_tree()
	tile_set_layout_option.selected = tile_map.tile_set.tile_layout


func _on_tile_layout_offset_vertical_pressed() -> void:
	tile_map = hexagon_tile_map_layer_vertical
	hexagon_tile_map_layer_horizontal.visible = false
	hexagon_tile_map_layer_vertical.visible = true
	_on_tile_layout_selected(hexagon_tile_map_layer_horizontal.tile_set.tile_layout)

func _on_tile_layout_offset_horizontal_pressed() -> void:
	tile_map = hexagon_tile_map_layer_horizontal
	hexagon_tile_map_layer_vertical.visible = false
	hexagon_tile_map_layer_horizontal.visible = true
	_on_tile_layout_selected(hexagon_tile_map_layer_vertical.tile_set.tile_layout)


func _on_tile_layout_selected(index: int) -> void:
	tile_map.update_cells_layout(
		tile_map.tile_set.tile_layout, index as TileSet.TileLayout
	)
	
	tile_map.tile_set.tile_layout = index as TileSet.TileLayout

	if tile_map.pathfinding_enabled:
		tile_map.astar_changed.connect(
			tile_map._draw_debug, CONNECT_DEFERRED + CONNECT_ONE_SHOT
		)
		tile_map.pathfinding_generate_points()
	else:
		tile_map._draw_debug.call_deferred()
