extends RefCounted

static func material(color: Color, metallic: float = 0.0, roughness: float = 0.82) -> StandardMaterial3D:
	var surface := StandardMaterial3D.new()
	surface.albedo_color = color
	surface.metallic = metallic
	surface.roughness = roughness
	return surface

static func block(parent: Node3D, center: Vector3, size: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return place(parent, center, mesh, surface)

static func place(parent: Node3D, center: Vector3, mesh: Mesh, surface: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = center
	instance.material_override = surface
	parent.add_child(instance)
	return instance
