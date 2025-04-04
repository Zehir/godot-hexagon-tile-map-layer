extends MenuButton

var popup: PopupMenu
var selection: EditorSelection
var plugin = EditorPlugin


func _init(_plugin: EditorPlugin) -> void:
	plugin = _plugin
	icon = preload("uid://chl4qyjdth4vj")
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
	var undo_redo = plugin.get_undo_redo()
	undo_redo.create_action("Fix Filemap")
	undo_redo.add_do_method(
		HexagonTileMap, "update_cells_layout", tilemap, old_layout, tilemap.tile_set.tile_layout
	)
	undo_redo.add_undo_method(
		HexagonTileMap, "update_cells_layout", tilemap, tilemap.tile_set.tile_layout, old_layout
	)
	undo_redo.commit_action()
