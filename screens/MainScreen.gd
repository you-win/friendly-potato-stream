class_name MainScreen
extends Node2D

enum StreamingServiceType { TWITCH, YOUTUBE }
export(StreamingServiceType) var streaming_service = StreamingServiceType.TWITCH

const CONFIG_FILE_NAME: String = "potato-config.json"
const CONFIG_FILE_USERNAME_KEY: String = "username"
const CONFIG_FILE_TOKEN_KEY: String = "token"

# Options for which screens to load
export var simple_chat: bool = false
export var h_scroll_text: bool = true
export var incremental_game: bool = true

onready var screen_scale_layer: CanvasLayer = $ScreenScaleLayer

# Can be either Twitch or Youtube for now
var service

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	get_viewport().transparent_bg = true
	# TODO currently isn't possible to do an overlay on windows
	OS.window_per_pixel_transparency_enabled = true
	# OS.window_size = OS.max_window_size
	# OS.set_window_mouse_passthrough([Vector2(-1.0, -1.0), Vector2(-1.0, -2.0), Vector2(-2.0, -1.0)])
	
	match streaming_service:
		StreamingServiceType.TWITCH:
			_load_twitch_chat_base()
		StreamingServiceType.YOUTUBE:
			_load_youtube_chat_base()
	
	# TODO refactor this into something more modular
	# Load plugins
	if simple_chat:
		var instance = load("res://screens/screen-plugins/SimpleChat.tscn").instance()
		screen_scale_layer.add_child(instance)
	if h_scroll_text:
		var instance = load("res://screens/screen-plugins/HScrollText.tscn").instance()
		screen_scale_layer.add_child(instance)
	if incremental_game:
		var instance = load("res://screens/screen-plugins/IncrementalGame.tscn").instance()
		screen_scale_layer.add_child(instance)
	
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
	
	service = TwitchChat.new()
	
	service.name = "TwitchChat"
	add_child(service)
	
	yield(service.websocket_client, "connection_established")
	
	service.authenticate(config[CONFIG_FILE_USERNAME_KEY], config[CONFIG_FILE_TOKEN_KEY])
	
	yield(service, "authenticated")
	
	service.join_channel(config[CONFIG_FILE_USERNAME_KEY])
	
	# service.connect("chat_message_received", self, "_on_chat_message_received")
	AppManager.console_log("Twitch chat loaded")

func _load_youtube_chat_base() -> void:
	printerr("Not yet implemented")

###############################################################################
# Public functions                                                            #
###############################################################################


