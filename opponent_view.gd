extends Node3D

const Prop = preload("res://prop_mesh.gd")

var legs: Array[Node3D] = []
var stride := 0.0
var cloth := Prop.material(Color("#676955"))
var armor := Prop.material(Color("#74715d"))
var dark := Prop.material(Color("#303631"))
var accent := Prop.material(Color("#a64d3f"))
var skin := Prop.material(Color("#a97c62"))

func _ready() -> void:
	limb(self, Vector3(0, 0.12, 0), Vector3(0.41, 0.55, 0.27), cloth)
	limb(self, Vector3(0, -0.15, 0), Vector3(0.35, 0.27, 0.24), cloth)
	limb(self, Vector3(0, 0.49, 0.015), Vector3(0.19, 0.25, 0.19), skin)
	limb(self, Vector3(0, 0.59, -0.012), Vector3(0.265, 0.21, 0.27), armor)
	limb(self, Vector3(0, 0.50, 0.098), Vector3(0.184, 0.065, 0.05), dark)
	limb(self, Vector3(0, 0.435, 0.086), Vector3(0.17, 0.095, 0.071), cloth)
	Prop.block(self, Vector3(0, 0.13, 0.12), Vector3(0.34, 0.35, 0.13), armor)
	Prop.block(self, Vector3(0, 0.10, -0.154), Vector3(0.29, 0.32, 0.13), dark)
	Prop.block(self, Vector3(0, -0.18, 0.008), Vector3(0.34, 0.064, 0.25), dark)
	for side in [-1, 1]:
		Prop.block(self, Vector3(side * 0.095, 0.045, 0.19), Vector3(0.086, 0.13, 0.055), dark)
		var arm := limb(self, Vector3(side * 0.22, 0.17, 0.048), Vector3(0.15, 0.31, 0.15), cloth)
		arm.rotation_degrees.x = -32
		limb(self, Vector3(side * 0.23, 0.13, 0.067), Vector3(0.154, 0.09, 0.16), accent)
		var forearm := limb(self, Vector3(side * 0.143, 0.118, 0.22), Vector3(0.113, 0.12, 0.28), cloth)
		forearm.rotation_degrees.y = -side * 26
		limb(self, Vector3(side * 0.074, 0.13, 0.325), Vector3(0.09, 0.095, 0.105), dark)
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.11, -0.2, 0)
		add_child(leg)
		legs.append(leg)
		limb(leg, Vector3(0, -0.14, 0), Vector3(0.18, 0.34, 0.195), cloth)
		limb(leg, Vector3(0, -0.43, 0), Vector3(0.145, 0.31, 0.155), cloth)
		limb(leg, Vector3(0, -0.29, 0.069), Vector3(0.145, 0.145, 0.079), armor)
		limb(leg, Vector3(0, -0.63, 0.043), Vector3(0.15, 0.137, 0.25), dark)
	Prop.block(self, Vector3(0, 0.18, 0.34), Vector3(0.075, 0.075, 0.22), dark)

func limb(parent: Node3D, center: Vector3, size: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	var instance := Prop.place(parent, center, mesh, surface)
	instance.scale = size
	return instance

func face_and_stride(target: Vector3, delta: float, speed: float) -> void:
	var offset := target - global_position
	rotation.y = lerp_angle(rotation.y, atan2(offset.x, offset.z), minf(delta * 13.0, 1.0))
	stride += delta * (2.0 + speed * 8.0)
	legs[0].rotation.z = sin(stride) * speed * 0.18
	legs[1].rotation.z = -legs[0].rotation.z
