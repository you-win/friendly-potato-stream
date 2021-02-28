extends ScreenPlugin

enum ScrollDirection { LEFT, RIGHT }
export(ScrollDirection) var scroll_direction = ScrollDirection.LEFT

const CHAT_MESSAGE: Resource = preload("res://entities/chat-objects/ChatMessage.tscn")

const BASE_SCROLL_SPEED: float = 5.0

var scroll_speed: float = 0.0
var spawn_location_x: float = 0.0

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	match scroll_direction:
		ScrollDirection.LEFT:
			scroll_speed = -BASE_SCROLL_SPEED
			spawn_location_x = self.rect_size.x
		scroll_direction.RIGHT:
			scroll_speed = BASE_SCROLL_SPEED
			spawn_location_x = 0.0

func _physics_process(_delta: float) -> void:
	for c in get_children():
		# TODO factor in scroll direction here
		c.global_position += Vector2(-5, 0)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_chat_message_received(message: String) -> void:
	var chat_message: Node2D = CHAT_MESSAGE.instance()
	
	var random_amount: float = rand_range(-self.rect_size.y / 2, self.rect_size.y / 2)
	
	chat_message.global_position = Vector2(spawn_location_x, self.rect_size.y / 2 + random_amount)
	
	add_child(chat_message)
	chat_message.label.text = message

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
