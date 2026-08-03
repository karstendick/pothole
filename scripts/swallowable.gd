class_name Swallowable
extends RigidBody3D
## An object the hole can eat. Sits in the world as a normal rigid body until
## the hole claims it, then drops through the floor while shrinking away.

## How long the object takes to shrink to nothing after it starts falling.
const FALL_DURATION := 0.8
## Extra gravity applied while falling, so objects don't linger in the pit.
const FALL_GRAVITY_SCALE := 2.5

## Radius of the object's footprint. Leave at 0 to derive it from the
## collision shape; set it to override how big the hole must be to eat this.
@export var fit_radius_override: float = 0.0

var fit_radius: float = 0.5
var is_falling: bool = false

var _hole: Node3D
var _fall_time: float = 0.0
var _meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group(&"swallowable")
	fit_radius = fit_radius_override if fit_radius_override > 0.0 else _derive_fit_radius()
	for child in get_children():
		var mesh := child as MeshInstance3D
		if mesh != null:
			_meshes.append(mesh)

## Approximates the object's horizontal footprint from its first collision shape.
func _derive_fit_radius() -> float:
	for child in get_children():
		var collider := child as CollisionShape3D
		if collider == null or collider.shape == null:
			continue
		var sphere := collider.shape as SphereShape3D
		if sphere != null:
			return sphere.radius
		var box := collider.shape as BoxShape3D
		if box != null:
			return maxf(box.size.x, box.size.z) * 0.5
		var cylinder := collider.shape as CylinderShape3D
		if cylinder != null:
			return cylinder.radius
		var capsule := collider.shape as CapsuleShape3D
		if capsule != null:
			return capsule.radius
	return 0.5

func fall_into(hole: Node3D) -> void:
	if is_falling:
		return
	is_falling = true
	_hole = hole
	# Stop colliding with anything: the floor, and the objects still up top.
	collision_layer = 0
	collision_mask = 0
	gravity_scale = FALL_GRAVITY_SCALE
	hole.absorb(self)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_falling:
		return
	_fall_time += state.step
	# Steer toward the middle of the hole on the way down.
	var to_center := _hole.global_position - global_position
	to_center.y = 0.0
	var velocity := state.linear_velocity
	velocity.x = lerpf(velocity.x, to_center.x * 6.0, 0.3)
	velocity.z = lerpf(velocity.z, to_center.z * 6.0, 0.3)
	state.linear_velocity = velocity

func _process(_delta: float) -> void:
	if not is_falling:
		return
	var t := clampf(_fall_time / FALL_DURATION, 0.0, 1.0)
	var shrink := Vector3.ONE * (1.0 - t)
	for mesh in _meshes:
		mesh.scale = shrink
	if t >= 1.0:
		queue_free()
