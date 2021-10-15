extends Node2D

enum StreamingServiceType { TWITCH, YOUTUBE }
export(StreamingServiceType) var streaming_service = StreamingServiceType.TWITCH

const CONFIG_FILE_NAME: String = "potato-config.json"

const PLUGIN_NAMES: Dictionary = {
	"simple_chat": "simple_chat",
	"h_scroll_text": "h_scroll_text",
	"incremental_game": "incremental_game",
	"chat_minions": "chat_minions",
	"mouse_ripple": "mouse_ripple"
}

const PLUGINS: Dictionary = {
	PLUGIN_NAMES.simple_chat: "res://plugins/simple_chat.tscn",
	PLUGIN_NAMES.h_scroll_text: "res://plugins/h_scroll_text.tscn",
	PLUGIN_NAMES.incremental_game: "res://plugins/incremental_game.tscn",
	PLUGIN_NAMES.chat_minions: "res://plugins/chat-minions/runner.tscn",
	PLUGIN_NAMES.mouse_ripple: "res://plugins/mouse_ripple.tscn"
}

export var should_use_chromakey := true

# Options for which screens to load
export var enabled_plugins: Dictionary = {
	PLUGIN_NAMES.simple_chat: false,
	PLUGIN_NAMES.h_scroll_text: true,
	PLUGIN_NAMES.incremental_game: true,
	PLUGIN_NAMES.chat_minions: true,
	PLUGIN_NAMES.mouse_ripple: true
}

# Used for lazy reloading plugins 
var initial_plugin_values: Dictionary = {}

var loaded_plugins: Dictionary = {}

onready var screen_scale_layer: CanvasLayer = $ScreenScaleLayer

var username: String

# Can be either Twitch or Youtube for now
var service

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if not should_use_chromakey:
		get_viewport().transparent_bg = true
		# TODO currently isn't possible to do an overlay on windows
		OS.window_per_pixel_transparency_enabled = true
	else:
		find_node("ChromakeyColorRect").visible = true
	
	match streaming_service:
		StreamingServiceType.TWITCH:
			_load_twitch_chat_base()
		StreamingServiceType.YOUTUBE:
			_load_youtube_chat_base()
	
	# Load plugins
	if enabled_plugins[PLUGIN_NAMES.simple_chat]:
		var instance = load(PLUGINS[PLUGIN_NAMES.simple_chat]).instance()
		loaded_plugins[PLUGIN_NAMES.simple_chat] = instance
		screen_scale_layer.add_child(instance)
	if enabled_plugins[PLUGIN_NAMES.h_scroll_text]:
		var instance = load(PLUGINS[PLUGIN_NAMES.h_scroll_text]).instance()
		loaded_plugins[PLUGIN_NAMES.h_scroll_text] = instance
		screen_scale_layer.add_child(instance)
	if enabled_plugins[PLUGIN_NAMES.incremental_game]:
		var instance = load(PLUGINS[PLUGIN_NAMES.incremental_game]).instance()
		loaded_plugins[PLUGIN_NAMES.incremental_game] = instance
		screen_scale_layer.add_child(instance)
	if enabled_plugins[PLUGIN_NAMES.chat_minions]:
		var instance = load(PLUGINS[PLUGIN_NAMES.chat_minions]).instance()
		loaded_plugins[PLUGIN_NAMES.chat_minions] = instance
		screen_scale_layer.add_child(instance)
	if enabled_plugins[PLUGIN_NAMES.mouse_ripple]:
		var instance = load(PLUGINS[PLUGIN_NAMES.mouse_ripple]).instance()
		loaded_plugins[PLUGIN_NAMES.mouse_ripple] = instance
		screen_scale_layer.add_child(instance)

	initial_plugin_values = enabled_plugins.duplicate(true)
	
	for c in screen_scale_layer.get_children():
		# c is of type ScreenPlugin
		c.init_connections()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _load_config() -> Dictionary:
	var file: File = File.new()
	if OS.is_debug_build():
		#warning-ignore:return_value_discarded
		file.open("res://export/potato-config.json", File.READ)
	else:
		var executable_directory: String = OS.get_executable_path().get_base_dir()
		# TODO generate sensible error message if config not found
		file.open(executable_directory + "/" + CONFIG_FILE_NAME, File.READ)
	
	var text: String = file.get_as_text()
	file.close()
	# Assume the file is in Dictionary format
	# TODO maybe add some error handling?
	return parse_json(text)

func _load_twitch_chat_base() -> void:
	var config: Dictionary = _load_config()
	
	username = config["username"]
	
	service = TwitchIntegration.new()
	
	service.name = "Twitch"
#	add_child(service)
	call_deferred("add_child", service)
	
	yield(service, "ready")
	
	# Chat
	yield(service.chat_client, "connection_established")
	service.authenticate(config["username"], config["token"])
	yield(service, "authenticated")
	service.join_channel(config["join_channel"])
	AppManager.console_log("Twitch chat loaded")
	
	# PubSub
	# yield(service.pubsub_client, "connection_established") # NOTE not needed since both clients connect at the same time?
	service.pubsub_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT) # WTF it starts in the wrong write mode
	service.subscribe(config["channel_id"], config["token"], config["nonce"])
	yield(service, "pub_sub_connected")
	AppManager.console_log("Twitch PubSub loaded")

func _load_youtube_chat_base() -> void:
	printerr("Not yet implemented")

###############################################################################
# Public functions                                                            #
###############################################################################

func reset_plugins() -> void:
	for c in screen_scale_layer.get_children():
		# All children are of type ScreenPlugin.gd
		c.reset()
		AppManager.console_log("%s plugin reset." % c.name)

func reload_plugins() -> void:
	for key in enabled_plugins.keys():
		if (enabled_plugins[key] and not initial_plugin_values[key]):
			var instance = load(PLUGINS[key]).instance()
			loaded_plugins[key] = instance
			screen_scale_layer.add_child(instance)
		elif (not enabled_plugins[key] and initial_plugin_values[key]):
			yield(get_tree(), "idle_frame")
			if loaded_plugins.has(PLUGIN_NAMES[key]):
				loaded_plugins[PLUGIN_NAMES[key]].free()
				loaded_plugins.erase(PLUGIN_NAMES[key])
	
	initial_plugin_values = enabled_plugins.duplicate(true)
