extends ScreenPlugin

const ChatMinions: Resource = preload("res://plugins/chat-minions/chat_minions.tscn")

onready var viewport: Viewport = $MarginContainer/ViewportContainer/Viewport

var chat_minions: Node2D

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	chat_minions = ChatMinions.instance()
	chat_minions.username = main_screen.username
	viewport.call_deferred("add_child", chat_minions)
	
	yield(chat_minions, "ready")
	chat_minions.setup({}) # TODO add some setup data?

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_command(user: String, reward: String, message: String) -> void:
	chat_minions.command(user.to_lower(), reward.to_lower(), message)

func _on_chat(user: String, message: String) -> void:
	chat_minions.chat(user.to_lower(), message)

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
	
	chat_minions = ChatMinions.instance()
	chat_minions.username = main_screen.username
	viewport.call_deferred("add_child", chat_minions)
	
	yield(chat_minions, "ready")
	chat_minions.setup({}) # TODO add some setup data?
