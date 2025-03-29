extends Node

const DemoTilemap = preload("uid://dfjog7h4t2dnb")
const DemoCamera = preload("uid://t5kjk00fsm7k")

@onready var tile_map: DemoTilemap = %HexagonTileMapLayerHorizontal
@onready var camera_2d: DemoCamera = %Camera2D
@onready var sample_code: RichTextLabel = %SampleCode
