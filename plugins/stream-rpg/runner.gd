extends ScreenPlugin

const StreamRPG: Resource = preload("res://screens/screen-plugins/stream-rpg/stream_rpg.tscn")

const VALID_COMMANDS: Array = [
	"move",
	"view stats",
	"interact",
	"attack",
	"custom command"
]

onready var viewport: Viewport = $MarginContainer/ViewportContainer/Viewport

var stream_rpg: Node2D

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	stream_rpg = StreamRPG.instance()
	viewport.call_deferred("add_child", stream_rpg)
	stream_rpg.setup({}) # TODO add some setup data?

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_command(user: String, reward: String, message: String) -> void:
	# Filter out other rewards
	var lowercase_reward: String = reward.to_lower()
	if lowercase_reward in VALID_COMMANDS:
		stream_rpg.command(user, lowercase_reward, message)

func _on_chat(user: String, message: String) -> void:
	pass

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func init_connections() -> void:
	main_screen.service.connect("channel_points_redeemed", self, "_on_command")
	main_screen.service.connect("chat_message_received", self, "_on_chat")

func cleanup_connections() -> void:
	main_screen.service.disconnect("channel_points_redeemed", self, "_on_command")
	main_screen.service.disconnect("chat_message_received", self, "_on_chat")

func initial_configs(_config: Dictionary) -> void:
	pass

func get_config() -> Dictionary:
	return Dictionary()

func set_config(_config: Dictionary) -> void:
	pass

func reset() -> void:
	viewport.get_child(0).queue_free()
	
	stream_rpg = StreamRPG.instance()
	viewport.call_deferred("add_child", stream_rpg)
	
	yield(stream_rpg, "ready")
	stream_rpg.setup({}) # TODO add some setup data?
