extends "res://arena.gd"

const OpponentView = preload("res://opponent_view.gd")

const WIN_SCORE := 5
const BOT_POS := Vector3(0, 0.95, -8.5)
const MAP_NAMES := ["Switchyard", "Foundry"]
const DIFFICULTIES := ["Standard", "Veteran"]

var map_index := Profile.choice("map", MAP_NAMES.size())
var veteran := Profile.choice("difficulty", DIFFICULTIES.size()) == 1
var bot: StaticBody3D
var opponent_view: OpponentView
var player_score := 0
var bot_score := 0
var player_health := 100
var bot_health := 100
var bot_clock := 0.0
var bot_cooldown := 1.0
var result_text := ""
var damage_flash := ColorRect.new()
var opponent_sound := AudioStreamPlayer3D.new()

func _ready() -> void:
	super._ready()
	opponent_sound.stream = preload("res://shot.wav")
	opponent_sound.volume_db = -10.0
	opponent_sound.pitch_scale = 0.8
	add_child(opponent_sound)
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.color = Color(0.8, 0.06, 0.04, 0.0)
	layer.add_child(damage_flash)

func is_outdoors() -> bool:
	return map_index == 0

func build_map() -> void:
	var foundry := map_index == 1
	var walls := Color("#474453") if foundry else Color("#3c535d")
	var floor_color := Color("#302b32") if foundry else Color("#233139")
	var trim := Color("#d98a50") if foundry else Color("#5bb4b3")
	var floor_body := box(self, Vector3(0, -0.25, 0), Vector3(22, 0.5, 26), floor_color)
	if is_outdoors():
		OutdoorYard.dress(self, floor_body)
	for z in [-13, 13]:
		wall(self, Vector3(0, 2.6, z), Vector3(22, 5.2, 0.5), walls)
		box(self, Vector3(0, 3.4, z * 0.975), Vector3(21.4, 0.11, 0.08), trim)
	for x in [-11, 11]:
		wall(self, Vector3(x, 2.6, 0), Vector3(0.5, 5.2, 26), walls)
		box(self, Vector3(x * 0.975, 3.4, 0), Vector3(0.08, 0.11, 25), trim)
	for x in [-8, -4, 0, 4, 8]:
		box(self, Vector3(x, 0.003, 0), Vector3(0.045, 0.006, 24), walls)
	var cover := [Vector3(-5, 0, 2), Vector3(4, 0, -3), Vector3(0, 0, -1)]
	if foundry:
		cover = [Vector3(-6, 0, -3), Vector3(6, 0, 2), Vector3(-2, 0, 4), Vector3(2, 0, -4)]
	for center: Vector3 in cover:
		add_cover(center + Vector3.UP, Vector3(3, 2, 1.65), walls.lightened(0.13), trim, not foundry)
		box(self, center + Vector3(0, 2.035, 0), Vector3(3.02, 0.07, 1.67), trim)

func reset_round() -> void:
	super.reset_round()
	player_health = 100
	bot_health = 100
	bot_clock = 0.0
	bot_cooldown = 1.0
	result_text = ""
	damage_flash.color.a = 0.0

func spawn_targets() -> void:
	bot = box(targets, BOT_POS, Vector3(0.72, 1.7, 0.55), Color("#973f43"))
	var hitbox_mesh := bot.get_child(1) as MeshInstance3D
	hitbox_mesh.hide()
	opponent_view = OpponentView.new()
	bot.add_child(opponent_view)

func advance_round() -> void:
	if not finished:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if maxi(player_score, bot_score) == WIN_SCORE:
		player_score = 0
		bot_score = 0
	super.advance_round()

func handle_hit(_target: Node3D) -> void:
	bot_health = maxi(0, bot_health - 34)
	if bot_health == 0:
		bot.hide()
		finish_round()

func finish_round() -> void:
	if finished:
		return
	super.finish_round()
	if bot_health == 0 or (time_left == 0.0 and player_health > bot_health):
		player_score += 1
		result_text = "ROUND WON"
	elif player_health == 0 or bot_health > player_health:
		bot_score += 1
		result_text = "ROUND LOST"
	else:
		result_text = "ROUND DRAW"

func update_opponent(delta: float) -> void:
	bot_clock += delta * (1.1 if veteran else 0.83)
	bot.position.x = sin(bot_clock) * 8.0
	opponent_view.face_and_stride(player.global_position, delta, absf(cos(bot_clock)))
	bot_cooldown = maxf(0.0, bot_cooldown - delta)
	if bot_cooldown > 0.0:
		return
	var origin := bot.global_position + Vector3(0, 0.5, 0)
	var ray := PhysicsRayQueryParameters3D.create(origin, player.camera.global_position)
	ray.exclude = [bot.get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(ray)
	if result.get("collider") != player:
		return
	bot_cooldown = randf_range(0.7, 1.05) if veteran else randf_range(1.1, 1.55)
	opponent_sound.position = origin
	opponent_sound.play()
	var chance := 0.66 if veteran else 0.46
	chance -= minf(player.velocity.length() * 0.045, 0.24)
	if randf() < chance:
		player_health = maxi(0, player_health - (25 if veteran else 20))
		damage_flash.color.a = 0.38
		if player_health == 0:
			finish_round()

func _process(delta: float) -> void:
	damage_flash.color.a = move_toward(damage_flash.color.a, 0.0, delta * 1.7)

func update_hud() -> void:
	var map_name: String = MAP_NAMES[map_index]
	hud.text = "%s   ·   FIRST TO %d\nYOU %d  —  %d BOT    %02ds\nHP %d     BOT HP %d     %s" % [
		map_name.to_upper(), WIN_SCORE, player_score, bot_score, ceili(time_left),
		player_health, bot_health, ammo_label()
	]
	overlay.text = ""
	if finished:
		if maxi(player_score, bot_score) == WIN_SCORE:
			overlay.text = "%s   ·   %d–%d\nEnter Rematch  ·  Tab Menu" % [
				"MATCH WON" if player_score == WIN_SCORE else "MATCH LOST", player_score, bot_score
			]
		else:
			overlay.text = "%s\nEnter Next Round  ·  Tab Menu" % result_text
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		overlay.text = "Click to play   ·   Tab Menu\nWASD Move  ·  Shift Walk  ·  Space Jump  ·  RMB Aim  ·  R Reload"
