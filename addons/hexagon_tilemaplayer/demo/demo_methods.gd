extends Tree

const DemoManager = preload("uid://c5t8k8u70hsgr")

const CubeLinedraw = preload("uid://sh0b67wxk8us")

@onready var demo: DemoManager = %DemoManager
var current_method: Node

const neighbors: Dictionary[String, GDScript] = {
	"cube_neighbor": preload("uid://cykasr1p4xfed"),
	"cube_neighbors": preload("uid://x00gcujhimxg"),
	"cube_corner_neighbors": preload("uid://cau6opgjwiksw"),
	"cube_direction": preload("uid://cwjv67kxuu1li"),
}
const transform: Dictionary[String, GDScript] = {
	"cube_distance": preload("uid://croybbcw88our"),
	"cube_rotate": preload("uid://d4ndsqop2jy6n"),
	"cube_rotate_from": preload("uid://dnxp71qf1w3vg"),
	"cube_reflect": preload("uid://but5uj3o3qpac"),
	"cube_reflect_from": preload("uid://41shw4r5cyc0"),
}
const shapes: Dictionary[String, GDScript] = {
	"cube_linedraw": preload("uid://sh0b67wxk8us"),
	"cube_rect": preload("uid://y2lutl2c46b7"),
	"cube_rect_corners": preload("uid://bnw55cavqioss"),
	"cube_ring": preload("uid://cbsxeto3wkwua"),
	"cube_spiral": preload("uid://b72r41cv74ijm"),
	"cube_range": preload("uid://b6cnoelqbw8uc"),
	"cube_intersect_ranges": preload("uid://dkugmb7vsjusc"),
}
const path_finding: Dictionary[String, GDScript] = {
	"Path finding": preload("uid://dims64wdod28x"),
}

const misc_methods: Dictionary[String, GDScript] = {
	"cube_explore": preload("uid://dbamn3uneu4mm"),
	"cube_outlines": preload("uid://1nm2lgaxjg17"),
	"tile_shape": preload("uid://crw1uyiphc514"),
}


func _ready() -> void:
	var root = create_item()
	root.set_text(0, "Methods")
	hide_root = true

	add_methods(root, "Neighbors", neighbors)
	add_methods(root, "Transform", transform)
	add_methods(root, "Shapes", shapes)
	add_methods(root, "Path finding", path_finding)
	add_methods(root, "Misc", misc_methods)


func add_methods(root: TreeItem, label: String, methods: Dictionary[String, GDScript]):
	if methods.size() == 0:
		return

	if methods.size() > 1:
		root = create_item(root)
		root.set_text(0, label)

	for method_name in methods.keys():
		var child = create_item(root)
		child.set_text(0, method_name)
		child.set_metadata(0, methods[method_name])


func _on_item_selected() -> void:
	var selected = get_selected()
	if current_method:
		current_method.queue_free()
		demo.sample_code.clear()
	var script = selected.get_metadata(0)
	if script is GDScript:
		current_method = script.new(demo)
		add_child(current_method)
	else:
		demo.sample_code.add_text("Please select a method on the left to view the result.")
