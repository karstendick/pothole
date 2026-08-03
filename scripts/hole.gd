extends Node3D
## The player-controlled hole. Slides around the ground plane, pulls nearby
## objects toward its rim, and swallows the ones small enough to fit.

signal absorbed(body: Node3D, new_radius: float)

@export var move_speed: float = 7.0
@export var start_radius: float = 0.8
@export var max_radius: float = 7.0
## How much of a swallowed object's footprint is added to the hole's area.
@export var growth_factor: float = 0.35
## Half-extents of the area the hole is allowed to roam, in world units.
@export var bounds: Vector2 = Vector2(19.0, 19.0)
## Sideways force pulling objects that fit toward the rim.
@export var suction_strength: float = 12.0
## An object is swallowed once its footprint is this fraction of the hole or less.
@export var fit_tolerance: float = 0.95

var radius: float = 0.8
var swallowed_count: int = 0

@onready var _visual: MeshInstance3D = $Visual

func _ready() -> void:
	radius = start_radius
	_visual.scale = Vector3(radius, 1.0, radius)

func _process(delta: float) -> void:
	# Ease the disc toward the current radius so growth reads as a little pop.
	var target := Vector3(radius, 1.0, radius)
	_visual.scale = _visual.scale.lerp(target, 1.0 - exp(-12.0 * delta))

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var pos := global_position + Vector3(input.x, 0.0, input.y) * move_speed * delta
	pos.x = clampf(pos.x, -bounds.x, bounds.x)
	pos.z = clampf(pos.z, -bounds.y, bounds.y)
	pos.y = 0.0
	global_position = pos

	_update_swallowables()

func _update_swallowables() -> void:
	for body in get_tree().get_nodes_in_group(&"swallowable"):
		var swallowable := body as Swallowable
		if swallowable == null or swallowable.is_falling:
			continue

		var to_hole := global_position - swallowable.global_position
		to_hole.y = 0.0
		var distance := to_hole.length()

		if swallowable.fit_radius > radius * fit_tolerance:
			continue # Too big for now -- it rests on the surface instead.

		if distance < radius:
			swallowable.fall_into(self)
		elif distance < radius + swallowable.fit_radius:
			# Straddling the rim: tug it in so it tips over the edge.
			var pull := to_hole / maxf(distance, 0.001)
			swallowable.apply_central_force(pull * suction_strength * swallowable.mass)

## Called by a Swallowable as it drops through. Grows the hole by area so that
## each object contributes less as the hole gets bigger.
func absorb(body: Swallowable) -> void:
	swallowed_count += 1
	var footprint := body.fit_radius
	radius = minf(sqrt(radius * radius + growth_factor * footprint * footprint), max_radius)
	absorbed.emit(body, radius)
