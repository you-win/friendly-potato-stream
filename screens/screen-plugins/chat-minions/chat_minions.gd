extends Node2D

const Minion: Resource = preload("res://screens/screen-plugins/chat-minions/entities/minion.tscn")

const PNG_EXTENSION: String = "png"
const DEFAULT_MINION_NAME: String = "DefaultMinion.png"
const POSSIBLE_SPRITES: Array = []

const RUBBER_DUCK_FILE_NAME: String = "RubberDuck.png"

var asset_dir: String
var rubber_duck_path: String

var username: String

onready var spawn_path_follow: PathFollow2D = $SpawnPath/SpawnPathFollow
onready var active_minions: Node = $ActiveMinions
onready var gui: CanvasLayer = $Gui

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if not OS.is_debug_build():
		asset_dir = OS.get_executable_path().get_base_dir() + "/chat-minions/assets/"
	else:
		asset_dir = "res://screens/screen-plugins/chat-minions/assets/"
	
	var dir := Directory.new()
	if dir.open(asset_dir) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if (file_name.get_extension() == PNG_EXTENSION and file_name != DEFAULT_MINION_NAME):
					POSSIBLE_SPRITES.append("%s%s" % [asset_dir, file_name])

				if file_name == RUBBER_DUCK_FILE_NAME:
					rubber_duck_path = "%s%s" % [asset_dir, file_name]
			file_name = dir.get_next()
	
	# Create self user
	var new_minion: Node2D = _create_minion(username)

	active_minions.call_deferred("add_child", new_minion)

	yield(new_minion, "ready")

	new_minion.sprite.texture = create_random_image_texture()

func _unhandled_input(event: InputEvent) -> void:
	if (gui.is_gui_visible and event.is_action_pressed("left_click")):
		gui.toggle_gui()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_minion_selected(minion: Node2D) -> void:
	if not gui.is_gui_visible:
		gui.toggle_gui()
	
	# TODO This is kinda expensive
	gui.update_gui(minion)

###############################################################################
# Private functions                                                           #
###############################################################################

func _create_minion(minion_name: String) -> Node2D:
	var new_minion: Node2D = Minion.instance()
	new_minion.name = minion_name
	new_minion.connect("minion_selected", self, "_on_minion_selected")
	
	return new_minion

func _create_image_texture(path: String) -> ImageTexture:
	var image := Image.new()
	var image_texture := ImageTexture.new()
	
	if image.load(path) != OK:
		AppManager.console_log("Failed to load image at %s" % path)
		return image_texture
		
	image_texture.create_from_image(image)
	image_texture.flags = 0 # All flags off
	
	return image_texture

func _get_existing_or_new_minion(minion_name: String) -> Node2D:
	var existing_minion: Node2D = active_minions.get_node_or_null(minion_name)
	
	if existing_minion:
		yield(get_tree(), "idle_frame") # TODO hacky workaround to sometimes yielding
		return existing_minion
	else:
		var new_minion: Node2D = _create_minion(minion_name)
		
		active_minions.call_deferred("add_child", new_minion)
		
		yield(new_minion, "ready")
		
		new_minion.sprite.texture = create_random_image_texture()

		spawn_path_follow.unit_offset = AppManager.rng.randf()
		new_minion.position = spawn_path_follow.position

		return new_minion

func _make_minions_jump() -> void:
	for child in active_minions.get_children():
		child.apply_impulse(Vector2(
			AppManager.rng.randf_range(-500, 500), 0),
			Vector2(
				AppManager.rng.randf_range(-500, 500),
				AppManager.rng.randf_range(-100, -500)
			)
		)
		child.start_colliding()

###############################################################################
# Public functions                                                            #
###############################################################################

func create_random_image_texture() -> ImageTexture:
	return _create_image_texture(
			POSSIBLE_SPRITES[AppManager.rng.randi_range(0, POSSIBLE_SPRITES.size() - 1)])

func create_rubber_duck_image_texture() -> ImageTexture:
	return _create_image_texture(rubber_duck_path)

func chat(user: String, message: String) -> void:
	var minion: Node2D = yield(_get_existing_or_new_minion(user), "completed")

	minion.say(message)

func command(user: String, lowercase_reward: String, message: String) -> void:
	match lowercase_reward:
		"jump":
			_make_minions_jump()
		"randomize minion":
			var minion = yield(_get_existing_or_new_minion(user), "completed")
			gui.on_randomize(minion)
		"custom command":
			var minion = yield(_get_existing_or_new_minion(user), "completed")
			if message.find("chonk") > -1:
				gui.make_chonky(minion)
			if message.find("smol") > -1:
				gui.make_smol(minion)
			if message.find("random") > -1:
				gui.on_randomize(minion)
			if message.find("duck") > -1:
				gui.on_duckify(minion)
			if message.find("jump") > -1:
				_make_minions_jump()

func setup(data: Dictionary) -> void:
	pass
