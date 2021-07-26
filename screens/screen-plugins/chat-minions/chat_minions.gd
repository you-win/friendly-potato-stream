extends Node2D

const Minion: Resource = preload("res://screens/screen-plugins/chat-minions/entities/minion.tscn")

const ASSET_DIR: String = "res://screens/screen-plugins/chat-minions/assets/"
const PNG_EXTENSION: String = "png"
const DEFAULT_MINION_NAME: String = "DefaultMinion.png"
const POSSIBLE_SPRITES: Array = []

onready var spawn_path_follow: PathFollow2D = $SpawnPath/SpawnPathFollow

onready var active_minions: Node = $ActiveMinions

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	var dir := Directory.new()
	if dir.open(ASSET_DIR) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if (file_name.get_extension() == PNG_EXTENSION and file_name != DEFAULT_MINION_NAME):
					POSSIBLE_SPRITES.append("%s%s" % [ASSET_DIR, file_name])
			file_name = dir.get_next()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

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
		
		new_minion.sprite.texture = load(POSSIBLE_SPRITES[AppManager.rng.randi_range(0, POSSIBLE_SPRITES.size() - 1)])
		
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
						AppManager.rng.randf_range(-500, 500)
						)
				)
				child.start_colliding()

func setup(data: Dictionary) -> void:
	pass
