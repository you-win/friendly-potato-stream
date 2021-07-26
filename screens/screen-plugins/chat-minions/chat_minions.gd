extends Node2D

const Minion: Resource = preload("res://screens/screen-plugins/chat-minions/entities/minion.tscn")

const PNG_EXTENSION: String = "png"
const DEFAULT_MINION_NAME: String = "DefaultMinion.png"
const POSSIBLE_SPRITES: Array = []

var asset_dir: String

var username: String

onready var spawn_path_follow: PathFollow2D = $SpawnPath/SpawnPathFollow

onready var active_minions: Node = $ActiveMinions

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
			file_name = dir.get_next()
	
	# Create self user
	var new_minion: Node2D = Minion.instance()
	new_minion.name = username
	
	active_minions.call_deferred("add_child", new_minion)
	
	yield(new_minion, "ready")
	
	new_minion.sprite.texture = _create_image_texture(POSSIBLE_SPRITES[AppManager.rng.randi_range(0, POSSIBLE_SPRITES.size() - 1)])

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _create_image_texture(path: String) -> ImageTexture:
	var image := Image.new()
	var image_texture := ImageTexture.new()
	
	if image.load(path) != OK:
		AppManager.console_log("Failed to load image at %s" % path)
		return image_texture
		
	image_texture.create_from_image(image)
	image_texture.flags = 0 # All flags off
	
	return image_texture

###############################################################################
# Public functions                                                            #
###############################################################################

func chat(user: String, message: String) -> void:
	var existing_minion: Node2D = active_minions.get_node_or_null(user)
	
	if existing_minion:
		existing_minion.say(message)
	else:
		var new_minion: Node2D = Minion.instance()
		new_minion.name = user
		
		active_minions.call_deferred("add_child", new_minion)
		
		yield(new_minion, "ready")
		
		new_minion.sprite.texture = _create_image_texture(POSSIBLE_SPRITES[AppManager.rng.randi_range(0, POSSIBLE_SPRITES.size() - 1)])
		
		spawn_path_follow.unit_offset = AppManager.rng.randf()
		new_minion.position = spawn_path_follow.position
		
		new_minion.say(message)

func command(user: String, lowercase_reward: String, message: String) -> void:
	match lowercase_reward:
		"jump":
			for child in active_minions.get_children():
				child.apply_impulse(Vector2(
					AppManager.rng.randf_range(-500, 500), 0),
					Vector2(
						AppManager.rng.randf_range(-500, 500),
						AppManager.rng.randf_range(100, 500)
					)
				)
				child.start_colliding()

func setup(data: Dictionary) -> void:
	pass
