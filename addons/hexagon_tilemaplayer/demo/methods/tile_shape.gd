extends Node

const DemoManager = preload("uid://c5t8k8u70hsgr")
const Enums = preload("uid://b2klbw1som8cc")
var demo: DemoManager
var center_cell = Vector3.ZERO
var shapes: Array[CollisionShape2D] = []


func _init(_demo: DemoManager) -> void:
	demo = _demo


func _ready() -> void:
	(
		demo
		. camera_2d
		. focus_tile(
			demo.tile_map.cube_to_local(center_cell),
			demo.camera_2d.FocusSide.MIDDLE_CENTER,
		)
	)

	var collision = CollisionShape2D.new()
	collision.shape = demo.tile_map.geometry_tile_shape.shape
	collision.transform = demo.tile_map.geometry_tile_shape.transform.translated(
		demo.tile_map.map_to_local(Vector2i(-1, 0))
	)
	demo.tile_map.add_child(collision)
	shapes.append(collision)

	var collision_approx = CollisionShape2D.new()
	collision_approx.shape = demo.tile_map.geometry_tile_approx_shape.shape
	collision_approx.transform = demo.tile_map.geometry_tile_approx_shape.transform.translated(
		demo.tile_map.map_to_local(Vector2i(1, 0))
	)
	demo.tile_map.add_child(collision_approx)
	shapes.append(collision_approx)

	var label = demo.sample_code
	label.clear()
	label.push_color(Color.from_string("CBCDD0", Color.WHITE))

	label.append_text("var collision = CollisionShape2D.new()\n")
	label.append_text("collision.shape = geometry_tile_shape.shape\n")
	label.append_text("collision.transform = geometry_tile_shape.transform.translated(\n")
	label.append_text("\tmap_to_local(Vector2i(-1,0))\n")
	label.append_text(")\n")
	label.newline()
	label.newline()

	label.append_text("var collision = CollisionShape2D.new()\n")
	label.append_text("collision.shape = geometry_tile_approx_shape.shape\n")
	label.append_text("collision.transform = geometry_tile_approx_shape.transform.translated(\n")
	label.append_text("\tmap_to_local(Vector2i(1,0))\n")
	label.append_text(")\n")
	label.pop_all()


func _exit_tree() -> void:
	for shape in shapes:
		shape.queue_free()
