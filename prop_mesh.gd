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

static func finish(surface: StandardMaterial3D, texture: Texture2D, repeats: float) -> void:
	surface.albedo_texture = texture
	surface.uv1_triplanar = true
	surface.uv1_scale = Vector3.ONE * repeats

static func contoured(parent: Node3D, center: Vector3, size: Vector3, surface: Material) -> MeshInstance3D:
	var ring := PackedVector2Array([Vector2(-0.36,-0.5),Vector2(0.36,-0.5),Vector2(0.5,-0.34),Vector2(0.5,0.28),Vector2(0.31,0.5),Vector2(-0.31,0.5),Vector2(-0.5,0.28),Vector2(-0.5,-0.34)])
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var levels := [-0.5,-0.46,0.45,0.5]
	var widths := [0.88,1.0,1.0,0.9]
	for layer in range(3):
		for i in range(ring.size()):
			var j := (i+1) % ring.size()
			for corner in [[i,layer],[i,layer+1],[j,layer+1],[i,layer],[j,layer+1],[j,layer]]:
				var xy := ring[corner[0]] * float(widths[corner[1]])
				mesh.set_smooth_group(-1)
				mesh.add_vertex(Vector3(xy.x,xy.y,levels[corner[1]]) * size)
	for end in [0,3]:
		for i in range(ring.size()):
			var j := (i+1) % ring.size()
			for xy: Vector2 in [Vector2.ZERO,ring[i],ring[j]] if end == 0 else [Vector2.ZERO,ring[j],ring[i]]:
				mesh.set_smooth_group(-1)
				mesh.add_vertex(Vector3(xy.x * widths[end],xy.y * widths[end],levels[end]) * size)
	mesh.generate_normals()
	return place(parent, center, mesh.commit(), surface)
