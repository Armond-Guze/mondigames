extends Node3D

const Profile = preload("res://profile.gd")
const Prop = preload("res://prop_mesh.gd")
const REST := Vector3(0.085, -0.075, -0.188)

const AIM_REST := Vector3(0, -0.032, -0.205)

var aim_weight := 0.0
var kick_back := 0.0
var slide := Node3D.new()
var slide_travel := 0.0
var reload_progress := 0.0
var model := Node3D.new()
var magazine: MeshInstance3D
var reload_hand: MeshInstance3D

const MAG_SEATED := Vector3(0, -0.061, 0.041)

func _ready() -> void:
	position = REST
	var palette: Array = Profile.SKINS[Profile.choice("skin", Profile.SKINS.size())]
	var finish := Prop.material(Color(palette[1]), 0.48, 0.43)
	var accent := Prop.material(Color(palette[2]), 0.12, 0.5)
	var polymer := Prop.material(Color("#343944"), 0.05, 0.88)
	var steel := Prop.material(Color("#68727e"), 0.65, 0.38)
	var black := Prop.material(Color("#181e25"), 0.1, 0.78)

	Prop.finish(finish, preload("res://art/gunmetal.jpg"), 13.0)
	Prop.finish(polymer, preload("res://art/rubber.jpg"), 20.0)
	add_child(model)
	model.add_child(slide)
	Prop.contoured(slide, Vector3(0, 0.008, -0.009), Vector3(0.038, 0.030, 0.115), finish)
	Prop.block(slide, Vector3(0.019, 0.01, -0.007), Vector3(0.003, 0.01, 0.025), steel)
	for index in range(6):
		for side in [-1, 1]:
			var groove := Prop.block(slide, Vector3(side * 0.0185, 0.007, 0.019 + index * 0.0044), Vector3(0.002, 0.019, 0.002), black)
			groove.rotation_degrees.x = -17

	Prop.block(model, Vector3(0, -0.012, 0.006), Vector3(0.034, 0.013, 0.097), polymer)
	var grip := Prop.contoured(model, Vector3(0, -0.039, 0.034), Vector3(0.027, 0.049, 0.034), polymer)
	grip.rotation_degrees.x = -16
	magazine = Prop.block(model, MAG_SEATED, Vector3(0.025, 0.032, 0.030), black)
	for index in range(5):
		Prop.block(model, Vector3(0, -0.026 - index * 0.006, 0.052 + index * 0.0015), Vector3(0.021, 0.002, 0.003), black)

	Prop.block(model, Vector3(0, -0.034, 0.001), Vector3(0.012, 0.006, 0.034), polymer)
	Prop.block(model, Vector3(0, -0.026, -0.016), Vector3(0.013, 0.02, 0.006), polymer)
	Prop.block(model, Vector3(0, -0.022, 0.005), Vector3(0.005, 0.014, 0.005), steel)
	cylinder(Vector3(0, 0.008, -0.062), 0.0105, 0.019, steel)
	cylinder(Vector3(0, 0.008, -0.072), 0.0068, 0.002, black)
	Prop.block(slide, Vector3(0, 0.026, -0.054), Vector3(0.006, 0.01, 0.01), black)
	Prop.block(slide, Vector3(0, 0.031, -0.054), Vector3(0.004, 0.003, 0.004), accent)
	for side in [-1, 1]:
		Prop.block(slide, Vector3(side * 0.010, 0.028, 0.041), Vector3(0.006, 0.01, 0.009), black)
		Prop.block(slide, Vector3(side * 0.010, 0.028, 0.046), Vector3(0.003, 0.003, 0.002), accent)

	for side in [-1, 1]:
		var panel := Prop.contoured(model, Vector3(side * 0.014, -0.042, 0.034), Vector3(0.004, 0.034, 0.025), polymer)
		panel.rotation_degrees.x = -16
		var pin := rounded_part(Vector3(side * 0.018, -0.011, 0.024), Vector3(0.003, 0.006, 0.006), steel)
		pin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glove := Prop.material(Color("#373836"))
	var sleeve := Prop.material(Color("#56594b"))
	var palm := rounded_part(Vector3(0.007, -0.045, 0.037), Vector3(0.041, 0.051, 0.051), glove)
	palm.rotation_degrees.x = -18
	for finger in range(3):
		rounded_part(Vector3(-0.012, -0.041 - finger * 0.009, 0.02), Vector3(0.027, 0.009, 0.019), glove)
	var forearm := rounded_part(Vector3(0.02, -0.074, 0.072), Vector3(0.041, 0.041, 0.1), sleeve)
	forearm.rotation_degrees.x = -32
	reload_hand = Prop.block(model, MAG_SEATED, Vector3(0.044, 0.024, 0.043), Prop.material(Color("#3e4654")))
	reload_hand.hide()
	for instance in find_children("*", "MeshInstance3D", true, false):
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func rounded_part(center: Vector3, size: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	var part := Prop.place(model, center, mesh, surface)
	part.scale = size
	return part

func cylinder(center: Vector3, radius: float, length: float, surface: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 20
	Prop.place(model, center, mesh, surface).rotation_degrees.x = 90

func kick() -> void:
	kick_back = 0.018
	rotation.x = 0.115
	slide_travel = 0.012

func pose_reload(progress: float) -> void:
	reload_progress = progress if progress < 1.0 else 0.0
	var tilt := smoothstep(0.0, 0.22, reload_progress) * (1.0 - smoothstep(0.72, 1.0, reload_progress))
	model.rotation = Vector3(-0.44, 0.18, 0.44) * tilt
	model.position = Vector3(-0.028, -0.008, -0.014) * tilt

	var drop := smoothstep(0.19, 0.40, reload_progress)
	var insert := 1.0 - smoothstep(0.48, 0.72, reload_progress)
	var travel := drop if reload_progress < 0.45 else insert
	magazine.position = MAG_SEATED + Vector3(-0.014, -0.058, 0.017) * travel
	magazine.visible = reload_progress < 0.40 or reload_progress >= 0.48
	reload_hand.position = magazine.position + Vector3(-0.021, -0.012, 0.008)
	reload_hand.visible = reload_progress >= 0.48 and reload_progress < 0.77

func _process(delta: float) -> void:
	kick_back = move_toward(kick_back, 0.0, delta * 0.16)
	position = REST.lerp(AIM_REST, aim_weight) + Vector3.BACK * kick_back
	rotation.x = move_toward(rotation.x, 0.0, delta * 0.9)
	slide_travel = move_toward(slide_travel, 0.0, delta * 0.18)
	var rack := smoothstep(0.73, 0.81, reload_progress) * (1.0 - smoothstep(0.81, 0.91, reload_progress))
	slide.position.z = maxf(slide_travel, rack * 0.012)
