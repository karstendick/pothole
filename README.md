# pothole

A small Donut County–style game built with Godot 4.7. You control a hole in the
ground; drive it under objects and they fall in, and the hole grows with every
thing it eats.

Open the project in Godot and press F5, or run it from the command line:

```
godot --path .
```

Move with **WASD** or the **arrow keys**.

## How it works

The ground stays a solid plane the whole time — the hole is a black disc drawn
on top of it plus a bit of bookkeeping in [scripts/hole.gd](scripts/hole.gd).
Every physics frame the hole looks at each object in the `swallowable` group and:

- ignores it if its footprint is wider than the hole,
- nudges it toward the middle if it's straddling the rim,
- swallows it once its centre crosses inside the rim.

Swallowing hands the object over to [scripts/swallowable.gd](scripts/swallowable.gd),
which clears the object's collision layer and mask so it drops straight through
the floor, steers it toward the centre on the way down, and shrinks it to nothing
before freeing it. The hole then grows by area, so each object matters less as
the hole gets bigger.

An object's footprint is derived from its collision shape (sphere/cylinder/capsule
radius, or half the widest horizontal side of a box). Set `fit_radius_override` on
a body to control that by hand.

## Adding objects

Duplicate any `RigidBody3D` under `Objects` in
[scenes/main.tscn](scenes/main.tscn). Each one needs the `swallowable.gd` script,
a `MeshInstance3D`, and a `CollisionShape3D` — the group and footprint are set up
automatically at runtime.

## Tuning

Most of the feel is exported on the `Hole` node: `move_speed`, `start_radius`,
`max_radius`, `growth_factor` (how much each object grows the hole),
`suction_strength` (the tug at the rim), and `fit_tolerance` (how snugly an
object has to fit before it's eaten).
