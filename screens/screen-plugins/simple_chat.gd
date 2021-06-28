extends ScreenPlugin

const CHAT_MESSAGE: Resource = preload("res://screens/gui/gui_chat_message.tscn")

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_chat_message_received(message: String) -> void:
	var chat_message: Label = CHAT_MESSAGE.instance()
	chat_message.text = message
	$VBoxContainer.add_child(chat_message)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func init_connections() -> void:
	main_screen.service.connect("chat_message_received", self, "_on_chat_message_received")

func cleanup_connections() -> void:
	pass

func initial_configs(_config: Dictionary) -> void:
	pass

func get_config() -> Dictionary:
	return Dictionary()

func set_config(_config: Dictionary) -> void:
	pass

func reset() -> void:
	for c in get_children():
		c.queue_free()
