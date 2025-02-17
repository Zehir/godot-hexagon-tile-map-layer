@tool
extends EditorPlugin


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("TileMapLayer", "EditorIcons")
