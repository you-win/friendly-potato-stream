extends ScreenPlugin

const MinionFights: Resource = preload("res://screens/screen-plugins/minion-fights/minion_fights.tscn")

var VALID_COMMANDS: Array = [
	"crawler",
	"shooter",
	"big lad"
]

onready var viewport: Viewport = $MarginContainer/ViewportContainer/Viewport

var minion_fights: Node2D

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	minion_fights = MinionFights.instance()
	# TODO setup from save?
	viewport.call_deferred("add_child", minion_fights)

###############################################################################
# Connections                                                                 #
###############################################################################

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
	minion_fights.queue_free()
	
	minion_fights = MinionFights.instance()
	# TODO setup from save?
	viewport.call_deferred("add_child", minion_fights)
