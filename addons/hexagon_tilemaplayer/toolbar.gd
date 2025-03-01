extends MenuButton

var popup: PopupMenu
var selection: EditorSelection
var plugin = EditorPlugin


func _init(_plugin: EditorPlugin) -> void:
	plugin = _plugin
	icon = preload("hexagon_tilemaplayer.svg")
	popup = get_popup()
	selection = EditorInterface.get_selection()
	_populate_menu()


func _populate_menu():
	popup.id_pressed.connect(_on_pressed)
	popup.about_to_popup.connect(func(): popup.get_window().min_size.x = 250)
	var fix_layout = PopupMenu.new()
	fix_layout.add_item("Was Stacked", TileSet.TILE_LAYOUT_STACKED)
	fix_layout.add_item("Was Stacked Offset", TileSet.TILE_LAYOUT_STACKED_OFFSET)
	fix_layout.add_item("Was Stairs Right", TileSet.TILE_LAYOUT_STAIRS_RIGHT)
	fix_layout.add_item("Was Stairs Down", TileSet.TILE_LAYOUT_STAIRS_DOWN)
	fix_layout.add_item("Was Diamond Right", TileSet.TILE_LAYOUT_DIAMOND_RIGHT)
	fix_layout.add_item("Was Diamond Down", TileSet.TILE_LAYOUT_DIAMOND_DOWN)
	fix_layout.id_pressed.connect(_on_fix_layout_pressed)
	popup.add_submenu_node_item("Fix tile layout", fix_layout)


func _on_pressed(id: int):
	pass


func _on_fix_layout_pressed(old_layout: int):
	var selection := selection.get_selected_nodes()
	if selection.size() != 1 or not selection[0] is HexagonTileMapLayer:
		return

	var tilemap: HexagonTileMapLayer = selection[0]
	var old_conversion_methods := HexagonTileMap.get_conversion_methods_for(
		tilemap.tile_set.tile_offset_axis, old_layout
	)
	var new_conversion_methods := HexagonTileMap.get_conversion_methods_for(
		tilemap.tile_set.tile_offset_axis, tilemap.tile_set.tile_layout
	)

	if old_conversion_methods.is_empty() or new_conversion_methods.is_empty():
		#EditorInterface.get_editor_toaster() # TODO wait for 4.4
		return

	var undo_redo = plugin.get_undo_redo()
	undo_redo.create_action("Fix Filemap")
	undo_redo.add_do_method(
		self, "_do_fix_layout", tilemap, old_conversion_methods, new_conversion_methods
	)
	undo_redo.add_undo_method(
		self, "_do_fix_layout", tilemap, new_conversion_methods, old_conversion_methods
	)
	undo_redo.commit_action()


func _do_fix_layout(tilemap: HexagonTileMapLayer, from: Dictionary, to: Dictionary):
	var tiles = []  # Record<Vector3i, TileData>
	for pos in tilemap.get_used_cells():
		(
			tiles
			. append(
				[
					from.map_to_cube.call(pos),
					tilemap.get_cell_source_id(pos),
					tilemap.get_cell_atlas_coords(pos),
					tilemap.get_cell_alternative_tile(pos),
				]
			)
		)
		tilemap.erase_cell(pos)

	for tile in tiles:
		(
			tilemap
			. set_cell(
				to.cube_to_map.call(tile[0]),
				tile[1],
				tile[2],
				tile[3],
			)
		)
