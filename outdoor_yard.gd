extends RefCounted

const Prop = preload("res://prop_mesh.gd")

static func light_world(environment: Environment, sun: DirectionalLight3D) -> void:
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("#397eac")
	atmosphere.sky_horizon_color = Color("#c4d9df")
	atmosphere.ground_horizon_color = Color("#b5c5c0")
	atmosphere.ground_bottom_color = Color("#646b58")
	var sky := Sky.new()
	sky.sky_material = atmosphere
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_color = Color("#c6d9e1")
	environment.ambient_light_energy = 0.72
	sun.light_color = Color("#fff1d8")
	sun.light_energy = 0.92

static func dress(parent: Node3D, floor_body: StaticBody3D) -> void:
	add_rock_banks(parent)
	var noise := FastNoiseLite.new()
	noise.seed = 17
	noise.frequency = 0.042
	var palette := Gradient.new()
	palette.colors = PackedColorArray([Color("#75634d"), Color("#c9b994")])
	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.noise = noise
	texture.color_ramp = palette
	texture.seamless = true
	var ground := Prop.material(Color.WHITE)
	ground.albedo_texture = texture
	var floor_mesh := floor_body.get_child(1) as MeshInstance3D
	floor_mesh.material_override = ground

	var weeds := MultiMesh.new()
	weeds.transform_format = MultiMesh.TRANSFORM_3D
	weeds.use_colors = true
	weeds.mesh = make_tuft()
	var random := RandomNumberGenerator.new()
	random.seed = 426
	var points: Array[Vector3] = []
	for side in [-1, 1]:
		for index in range(380):
			var z := random.randf_range(-12.15, 12.15)
			var width := 0.6 + 0.5 * sin(z * 0.55 + side)
			var x: float = side * (10.45 - random.randf() * width)
			points.append(Vector3(x, 0.009, z))
		for index in range(105):
			points.append(Vector3(random.randf_range(-9.4, 9.4), 0.009, side * random.randf_range(11.75, 12.55)))
	weeds.instance_count = points.size()
	for index in range(points.size()):
		var scale := random.randf_range(0.65, 1.3)
		var basis := Basis(Vector3.UP, random.randf() * TAU).scaled(Vector3.ONE * scale)
		weeds.set_instance_transform(index, Transform3D(basis, points[index]))
		weeds.set_instance_color(index, Color("#526040").lerp(Color("#9ba470"), random.randf()))
	var verge := MultiMeshInstance3D.new()
	verge.multimesh = weeds
	verge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var blades := Prop.material(Color.WHITE)
	blades.vertex_color_use_as_albedo = true
	blades.vertex_color_is_srgb = true
	blades.cull_mode = BaseMaterial3D.CULL_DISABLED
	verge.material_override = blades
	parent.add_child(verge)

	var gravel := Prop.material(Color("#827966"))
	var pebble := SphereMesh.new()
	pebble.radius = 0.045
	pebble.height = 0.06
	pebble.radial_segments = 5
	pebble.rings = 2
	var stones := MultiMesh.new()
	stones.transform_format = MultiMesh.TRANSFORM_3D
	stones.mesh = pebble
	stones.instance_count = 160
	for index in range(stones.instance_count):
		var scale := random.randf_range(0.5, 1.7)
		var location := Vector3(random.randf_range(-10.25, 10.25), 0.016, random.randf_range(-12, 12))
		stones.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3(scale, 0.65, scale)), location))
	var gravel_mesh := MultiMeshInstance3D.new()
	gravel_mesh.multimesh = stones
	gravel_mesh.material_override = gravel
	parent.add_child(gravel_mesh)
	var paving := Prop.material(Color("#747a76"))
	for offset in [-8.5, 8.5]:
		for index in range(8):
			Prop.block(parent, Vector3(offset, 0.001, index * 3.0 - 10.5), Vector3(1.15, 0.004, 2.93), paving)

static func make_tuft() -> ArrayMesh:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(7):
		var angle := index * TAU / 7.0
		var outward := Vector3(cos(angle), 0, sin(angle))
		var across := Vector3(-outward.z, 0, outward.x) * 0.018
		var root := outward * (0.035 + index * 0.008)
		var tip := root + outward * (0.04 + index * 0.008) + Vector3.UP * (0.12 + (index % 3) * 0.045)
		mesh.add_vertex(root - across)
		mesh.add_vertex(root + across)
		mesh.add_vertex(tip)
	mesh.generate_normals()
	return mesh.commit()

static func add_rock_banks(parent: Node3D) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 3148
	var noise := FastNoiseLite.new()
	noise.seed = 33
	noise.frequency = 3.5
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.width = 256
	texture.height = 256
	texture.as_normal_map = true
	texture.bump_strength = 3.0
	var surfaces: Array[StandardMaterial3D] = []
	for color in [Color("#97836b"), Color("#a59479"), Color("#857562")]:
		var surface := Prop.material(color)
		surface.normal_enabled = true
		surface.normal_texture = texture
		surface.uv1_triplanar = true
		surfaces.append(surface)

	var source := SphereMesh.new()
	source.radial_segments = 14
	source.rings = 8
	var geometry := SurfaceTool.new()
	geometry.create_from(source, 0)
	var arrays := geometry.commit_to_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for index in range(vertices.size()):
		var point := vertices[index]
		vertices[index] = point * (1.0 + 0.24 * noise.get_noise_3dv(point))
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var rock_mesh := ArrayMesh.new()
	rock_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	for index in range(26):
		var x := index * 1.75 - 22.0
		var size := random.randf_range(4.6, 9.0)
		var rock := Prop.place(parent, Vector3(x, 1.1, random.randf_range(-21.0, -15.6)), rock_mesh, surfaces[index % surfaces.size()])
		rock.scale = Vector3(size * 1.25, size * 1.65, size)
		rock.rotation.y = random.randf_range(-PI, PI)
	for index in range(28):
		var side := -1.0 if index % 2 == 0 else 1.0
		var size := random.randf_range(0.14, 0.52)
		var rock := Prop.place(parent, Vector3(side * random.randf_range(9.9, 10.5), size * 0.23, random.randf_range(-12, 12)), rock_mesh, surfaces[index % surfaces.size()])
		rock.scale = Vector3(size * 1.35, size * 0.7, size)
