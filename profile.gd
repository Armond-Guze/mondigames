extends RefCounted

const PATH := "user://profile.cfg"
const SKINS := [
	["Slate", "#65778c", "#ffb451"],
	["Ember", "#a93645", "#ffd78d"],
	["Glacier", "#53a9bb", "#d8faff"],
	["Jade", "#377952", "#c1ec93"],
	["Violet", "#7955ae", "#ffd0f5"],
	["Carbon", "#242b3a", "#f3c976"]
]

static func choice(key: String, count: int) -> int:
	var config := ConfigFile.new()
	config.load(PATH)
	return clampi(int(config.get_value("options", key, 0)), 0, count - 1)

static func save_choice(key: String, value: int) -> Error:
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value("options", key, value)
	return config.save(PATH)
