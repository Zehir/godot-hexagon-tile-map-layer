extends Tree

const DemoManager = preload("uid://c5t8k8u70hsgr")

const CubeLinedraw = preload("uid://sh0b67wxk8us")

@onready var demo: DemoManager = %DemoManager
var current_method: Node

const methods: Dictionary[String, GDScript] = {
	"cube_neighbor": preload("uid://cykasr1p4xfed"),
	"cube_neighbors": preload("uid://x00gcujhimxg"),
	"cube_corner_neighbors": preload("uid://cau6opgjwiksw"),
	"cube_direction": preload("uid://cwjv67kxuu1li"),
	"cube_distance": preload("uid://croybbcw88our"),
	"cube_linedraw": preload("uid://sh0b67wxk8us"),
	"cube_range": preload("uid://b6cnoelqbw8uc"),
	"cube_intersect_ranges": preload("uid://dkugmb7vsjusc"),
	"cube_rotate": preload("uid://d4ndsqop2jy6n"),
	"cube_rotate_from": preload("uid://dnxp71qf1w3vg"),
	"cube_reflect": preload("uid://but5uj3o3qpac"),
	"cube_reflect_from": preload("uid://41shw4r5cyc0"),
}


func _ready() -> void:
	var root = create_item()
	root.set_text(0, "Methods")
	var default = "last"
	#hide_root = true

	for method_name in methods.keys():
		var child = create_item(root)
		child.set_text(0, method_name)
		child.set_metadata(0, methods[method_name])

		if default is String and method_name == default:
			default = child

	if default is String:
		var childs = root.get_children()
		childs.pop_back().select(0)
	else:
		default.select(0)


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
