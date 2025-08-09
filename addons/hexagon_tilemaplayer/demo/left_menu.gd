extends VBoxContainer

const DemoManager = preload("uid://c5t8k8u70hsgr")

@onready var demo: DemoManager = %DemoManager

@onready var hexagon_tile_map_layer_horizontal: HexagonTileMapLayer = %HexagonTileMapLayerHorizontal
@onready var hexagon_tile_map_layer_vertical: HexagonTileMapLayer = %HexagonTileMapLayerVertical

@onready var button_layout_vertical: CheckBox = %LayoutVertical
@onready var button_layout_horizontal: CheckBox = %LayoutHorizontal
@onready var button_tile_set_layout_option: OptionButton = %TileSetLayout

@onready var button_enable_pathfinding: CheckButton = %EnablePathfinding
@onready var button_display_pathfinding_connections: CheckButton = %DisplayPathfindingConnections
@onready var button_display_tiles_coords: CheckButton = %DisplayTilesCoords
@onready var methods_tree: Tree = %MethodsTree


func _ready() -> void:
	button_layout_horizontal.button_pressed = hexagon_tile_map_layer_horizontal.is_visible_in_tree()
	button_layout_vertical.button_pressed = hexagon_tile_map_layer_vertical.is_visible_in_tree()
	button_tile_set_layout_option.selected = demo.tile_map.tile_set.tile_layout
	button_display_pathfinding_connections.visible = (
		hexagon_tile_map_layer_horizontal.pathfinding_enabled
	)
	button_enable_pathfinding.button_pressed = hexagon_tile_map_layer_horizontal.pathfinding_enabled
	button_display_pathfinding_connections.button_pressed = (
		hexagon_tile_map_layer_horizontal.debug_mode
		& HexagonTileMapLayer.DebugModeFlags.CONNECTIONS
	)
	button_display_tiles_coords.button_pressed = (
		hexagon_tile_map_layer_horizontal.debug_mode
		& HexagonTileMapLayer.DebugModeFlags.TILES_COORDS
	)


func _on_tile_layout_offset_vertical_pressed() -> void:
	switch_to_tilemap(hexagon_tile_map_layer_vertical)


func _on_tile_layout_offset_horizontal_pressed() -> void:
	switch_to_tilemap(hexagon_tile_map_layer_horizontal)


func switch_to_tilemap(new_tile_map: HexagonTileMapLayer):
	demo.tile_map.visible = false
	var old_layout = demo.tile_map.tile_set.tile_layout
	var old_method = methods_tree.get_selected()
	methods_tree.deselect_all()
	demo.tile_map = new_tile_map
	demo.tile_map.visible = true
	_on_enable_pathfinding_toggled(button_enable_pathfinding.button_pressed)
	update_debug_mode()
	_on_tile_layout_selected(old_layout)
	if old_method:
		methods_tree.set_selected(old_method, 0)


func _on_tile_layout_selected(index: int) -> void:
	demo.tile_map.update_cells_layout(
		demo.tile_map.tile_set.tile_layout, index as TileSet.TileLayout
	)
	demo.tile_map.tile_set.tile_layout = index as TileSet.TileLayout
	_on_enable_pathfinding_toggled(demo.tile_map.pathfinding_enabled)


func _on_enable_pathfinding_toggled(toggled_on: bool) -> void:
	demo.tile_map.pathfinding_enabled = toggled_on
	button_display_pathfinding_connections.visible = toggled_on

	if demo.tile_map.pathfinding_enabled:
		demo.tile_map.astar_changed.connect(
			demo.tile_map._draw_debug, CONNECT_DEFERRED + CONNECT_ONE_SHOT
		)
		demo.tile_map.pathfinding_generate_points()
	else:
		if demo.tile_map.astar:
			demo.tile_map.astar = null
		demo.tile_map._draw_debug.call_deferred()

	var old_method = methods_tree.get_selected()
	if old_method:
		methods_tree.deselect_all()
		methods_tree.set_selected(old_method, 0)


func update_debug_mode() -> void:
	demo.tile_map.debug_mode = (
		(
			HexagonTileMapLayer.DebugModeFlags.CONNECTIONS
			if button_display_pathfinding_connections.button_pressed
			else 0
		)
		+ (
			HexagonTileMapLayer.DebugModeFlags.TILES_COORDS
			if button_display_tiles_coords.button_pressed
			else 0
		)
	)
