extends Node3D

const Player = preload("res://player.gd")
const SPAWN := Vector3(0, 0.05, 9)
const ROUND_TIME := 45.0
const MAGAZINE := 8
const RELOAD_TIME := 0.85
const TARGET_POSITIONS := [
	Vector3(-7, 1.15, -6), Vector3(-3, 1.15, -9), Vector3(0, 1.15, -7),
	Vector3(4, 1.15, -9), Vector3(7, 1.15, -4), Vector3(6, 1.15, 3)
]

const Profile = preload("res://profile.gd")
const OutdoorYard = preload("res://outdoor_yard.gd")
const CoverDetail = preload("res://cover_detail.gd")
const MENU := "res://menu.tscn"

var player := Player.new()
var targets := Node3D.new()
var hud := Label.new()
var crosshair := Label.new()
var shot_sound := AudioStreamPlayer.new()
var hit_marker_left := 0.0
var overlay := Label.new()
var time_left := ROUND_TIME
var ammo := MAGAZINE
var reload_left := 0.0
var hits := 0
var shots := 0
var finished := false
var shot_queued := false

func _ready() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#b5d5ea")
	environment.environment.ambient_light_energy = 0.58
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -25, 0)
	sun.shadow_enabled = true
	if is_outdoors():
		OutdoorYard.light_world(environment.environment, sun)
	add_child(sun)

	build_map()
	add_child(targets)
	add_child(player)
	shot_sound.stream = preload("res://shot.wav")
	shot_sound.volume_db = -8.0
	shot_sound.max_polyphony = 3
	add_child(shot_sound)
	build_hud()
	reset_round()

func is_outdoors() -> bool:
	return true

func build_map() -> void:
	var concrete := Color("#39495c")
	var cover := Color("#52677d")
	OutdoorYard.dress(self, box(self, Vector3(0, -0.25, 0), Vector3(22, 0.5, 26), Color("#283747")))
	box(self, Vector3(0, 2, -13), Vector3(22, 4, 0.5), concrete)
	box(self, Vector3(0, 2, 13), Vector3(22, 4, 0.5), concrete)
	for x in [-11, 11]:
		box(self, Vector3(x, 2, 0), Vector3(0.5, 4, 26), concrete)
	for position in [Vector3(-5, 1, 1), Vector3(1, 1, -2), Vector3(5, 1, 5)]:
		add_cover(position, Vector3(2.8, 2, 1.5), cover, Color("#ffb451"), true)
	for x in [-8, -4, 0, 4, 8]:
		box(self, Vector3(x, 0.005, 0), Vector3(0.045, 0.01, 24), Color("#3f596b"))

func add_cover(center: Vector3, size: Vector3, color: Color, accent: Color, shipping_crate: bool) -> void:
	var body := box(self, center, size, color)
	CoverDetail.dress(body, size, accent, shipping_crate)

func box(parent: Node3D, center: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = center
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	body.add_child(visual)
	parent.add_child(body)
	return body

func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 24)
	crosshair.add_theme_constant_override("outline_size", 4)
	crosshair.add_theme_color_override("font_outline_color", Color("#101923"))
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(crosshair)
	hud.position = Vector2(24, 18)
	hud.add_theme_font_size_override("font_size", 22)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	overlay.offset_top = -116
	overlay.offset_bottom = -20
	overlay.add_theme_font_size_override("font_size", 20)
	overlay.add_theme_color_override("font_shadow_color", Color.BLACK)
	overlay.add_theme_constant_override("shadow_offset_y", 2)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)

func clear_targets() -> void:
	for target in targets.get_children():
		targets.remove_child(target)
		target.queue_free()

func reset_round() -> void:
	clear_targets()
	spawn_targets()
	player.position = SPAWN
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	time_left = ROUND_TIME
	reload_left = 0.0
	player.weapon.pose_reload(0.0)
	ammo = MAGAZINE
	hits = 0
	shots = 0
	finished = false
	hit_marker_left = 0.0
	shot_queued = false

func spawn_targets() -> void:
	for position in TARGET_POSITIONS:
		box(targets, position, Vector3(0.8, 0.8, 0.28), Color("#ffb451"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_TAB:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_tree().change_scene_to_file(MENU)
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_R:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					start_reload()
			KEY_ENTER:
				advance_round()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if finished:
			return
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif reload_left == 0.0 and ammo > 0:
			shot_queued = true

func shoot() -> void:
	player.weapon.kick()
	shot_sound.play()
	ammo -= 1
	shots += 1
	var origin := player.camera.global_position
	var end := origin - player.camera.global_basis.z * 80.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [player.get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty() and result.collider.get_parent() == targets:
		hits += 1
		hit_marker_left = 0.18
		handle_hit(result.collider)
	player.camera.rotation.x = minf(player.camera.rotation.x + 0.012, 1.45)

func handle_hit(target: Node3D) -> void:
	targets.remove_child(target)
	target.queue_free()
	if hits == TARGET_POSITIONS.size():
		finish_round()

func advance_round() -> void:
	reset_round()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func finish_round() -> void:
	finished = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if shot_queued:
		shot_queued = false
		if not finished and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and reload_left == 0.0:
			shoot()

	if not finished and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		time_left = maxf(0.0, time_left - delta)
		update_reload(delta)
		if time_left == 0.0:
			finish_round()
		else:
			update_opponent(delta)

	hit_marker_left = maxf(0.0, hit_marker_left - delta)
	crosshair.text = "×" if hit_marker_left > 0.0 else "+"
	crosshair.modulate = Color("#ffce79") if hit_marker_left > 0.0 else Color.WHITE
	crosshair.modulate.a = 1.0 if hit_marker_left > 0.0 else 1.0 - player.aim_weight

	update_hud()

func start_reload() -> void:
	if not finished and ammo < MAGAZINE and reload_left == 0.0:
		reload_left = RELOAD_TIME

func update_reload(delta: float) -> void:
	if reload_left <= 0.0:
		return
	reload_left = maxf(0.0, reload_left - delta)
	player.weapon.pose_reload(1.0 - reload_left / RELOAD_TIME)
	if reload_left == 0.0:
		ammo = MAGAZINE

func update_opponent(_delta: float) -> void:
	pass

func ammo_label() -> String:
	var ammo_text := "%d / %d" % [ammo, MAGAZINE]
	if reload_left > 0.0:
		ammo_text = "RELOADING"
	elif ammo == 0:
		ammo_text = "EMPTY  [R]"
	return ammo_text

func update_hud() -> void:
	hud.text = "MONDIGAMES   /   RANGE\n%02ds     %d/%d TARGETS     %s" % [
		ceili(time_left), hits, TARGET_POSITIONS.size(), ammo_label()
	]
	overlay.text = ""
	if finished:
		var result_text := "TIME UP"
		if hits == TARGET_POSITIONS.size():
			result_text = "RANGE CLEAR"
		var accuracy := roundi(100.0 * hits / maxi(shots, 1))
		overlay.text = "%s   /   %d%% ACCURACY\nPress Enter to restart" % [result_text, accuracy]
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		overlay.text = "Click to enter the range\nWASD Move  ·  Shift Walk  ·  Space Jump  ·  Click Shoot  ·  RMB Aim  ·  R Reload  ·  Esc Pause  ·  Tab Menu"
