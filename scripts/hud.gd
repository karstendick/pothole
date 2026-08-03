extends Label

@export var hole_path: NodePath

var _hole: Node3D

func _ready() -> void:
	_hole = get_node_or_null(hole_path) as Node3D

func _process(_delta: float) -> void:
	if _hole == null:
		return
	text = "Hole size: %.2f\nSwallowed: %d\n\nWASD / arrow keys to move" % [_hole.radius, _hole.swallowed_count]
