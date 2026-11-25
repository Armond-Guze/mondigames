extends RefCounted

const Prop = preload("res://prop_mesh.gd")

static func dress(body: StaticBody3D, size: Vector3, accent: Color, shipping_crate: bool) -> void:
	var dark := Prop.material(Color("#222c33"), 0.2)
	var edge := Prop.material(Color("#76818a") if shipping_crate else Color("#888985"), 0.14)
	var trim := Prop.material(accent, 0.1)
	var bolt := CylinderMesh.new()
	bolt.top_radius = 0.035
	bolt.bottom_radius = 0.042
	bolt.height = 0.027
	bolt.radial_segments = 6

	for x_sign in [-1, 1]:
		for z_sign in [-1, 1]:
			var corner := Vector3(x_sign * (size.x / 2.0 - 0.08), 0, z_sign * (size.z / 2.0 - 0.055))
			Prop.block(body, corner, Vector3(0.19, size.y, 0.15), edge)
	for side in [-1, 1]:
		var face: float = side * (size.z / 2.0 + 0.012)
		for height in [-0.43, 0.43]:
			Prop.block(body, Vector3(0, size.y * height, face), Vector3(size.x - 0.12, 0.13, 0.07), edge)
		for index in range(-4, 5):
			var x: float = index * size.x / 10.0
			if shipping_crate:
				Prop.block(body, Vector3(x, 0, face), Vector3(0.08, size.y * 0.72, 0.055), dark)
			var fastener := Prop.place(body, Vector3(x, size.y * 0.43, face + side * 0.04), bolt, dark)
			fastener.rotation_degrees.x = 90
		var plaque := Vector3(side * size.x * 0.25, size.y * 0.27, face + side * 0.046)
		Prop.block(body, plaque, Vector3(0.52, 0.14, 0.018), dark)
		for index in range(3):
			var stripe := Prop.block(body, plaque + Vector3((index - 1) * 0.145, 0, side * 0.011), Vector3(0.067, 0.12, 0.01), trim)
			stripe.rotation_degrees.z = 28

	for side in [-1, 1]:
		var face: float = side * (size.x / 2.0 + 0.01)
		for height in [-0.43, 0.43]:
			Prop.block(body, Vector3(face, size.y * height, 0), Vector3(0.07, 0.13, size.z - 0.12), edge)
		var recess := Vector3(face, 0.16, 0)
		Prop.block(body, recess, Vector3(0.025, 0.19, 0.46), dark)
		Prop.block(body, recess + Vector3(side * 0.027, 0.025, 0), Vector3(0.055, 0.055, 0.35), edge)
