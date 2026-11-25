extends Node3D

const Profile = preload("res://profile.gd")

const REST := Vector3(0.09, -0.075, -0.19)

func _ready() -> void:
	position = REST
	var body := Color("#283647")
	var palette: Array = Profile.SKINS[Profile.choice("skin", Profile.SKINS.size())]
	var slide := Color(palette[1])
	var accent := Color(palette[2])
	part(Vector3.ZERO, Vector3(0.046, 0.032, 0.103), slide)
	part(Vector3(0, -0.02, 0.011), Vector3(0.048, 0.018, 0.083), body)
	part(Vector3(0, -0.044, 0.029), Vector3(0.036, 0.045, 0.035), body)
	part(Vector3(0, 0.019, -0.041), Vector3(0.009, 0.007, 0.01), accent)
	part(Vector3(0, 0.017, 0.043), Vector3(0.026, 0.008, 0.008), body)
	part(Vector3(0, -0.059, 0.061), Vector3(0.052, 0.045, 0.092), Color("#35445a"))

func part(center: Vector3, size: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.position = center
	add_child(visual)

func kick() -> void:
	position.z = REST.z + 0.02
	rotation.x = 0.11

func _process(delta: float) -> void:
	position = position.move_toward(REST, delta * 0.16)
	rotation.x = move_toward(rotation.x, 0.0, delta * 0.9)
