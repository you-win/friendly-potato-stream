extends Reference

signal connected
signal authenticated
signal chat_message_received(message)

const TWITCH_CHAT_URL: String = "wss://irc-ws.chat.twitch.tv:443"

# IRC-specific data
const AUTHENTICATED_CHAT_IDENTIFER: String = "001"
const STANDARD_CHAT_IDENTIFIER: String = "PRIVMSG"
const PING_CHAT_IDENTIFIER: String = "PING"
const PONG_CHAT_MESSAGE: String = "PONG :tmi.twitch.tv"

const CHAT_HISTORY_LENGTH: int = 100

var chat_history: PoolStringArray = PoolStringArray()
var current_chat_history_index: int = 0

var client: WebSocketClient = WebSocketClient.new()

###############################################################################
# Builtin functions                                                           #
###############################################################################

#func _init() -> void:
#	#warning-ignore:return_value_discarded
#	client.connect("connection_closed", self, "_on_connection_closed")
#	#warning-ignore:return_value_discarded
#	client.connect("connection_error", self, "_on_connection_error")
#	#warning-ignore:return_value_discarded
#	client.connect("connection_established", self, "_on_connection_established")
#	#warning-ignore:return_value_discarded
#	client.connect("data_received", self, "_on_data_received")
#	#warning-ignore:return_value_discarded
#	client.connect("server_close_request", self, "_on_server_close_request")
#
#	if client.connect_to_url(TWITCH_CHAT_URL) != OK:
#		AppManager.console_log("Could not connect to Twitch chat")

func _process(_delta: float) -> void:
	if client.get_connection_status() != WebSocketClient.CONNECTION_DISCONNECTED:
		client.poll()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_connection_closed(_was_clean_close: bool) -> void:
	pass

func _on_connection_error() -> void:
	pass

func _on_connection_established(_protocol: String) -> void:
	emit_signal("connected")
	print_debug("Connection established with Twitch")

func _on_data_received() -> void:
	var message: String = _get_websocket_message()
	
	# Chat messages come in the following format
	# :tmi.twitch.tv <num/IRC type> <user/channel> :<message>
	var split_message: PoolStringArray = message.split(" ", true, 3)
	
	if split_message[0] == PING_CHAT_IDENTIFIER:
		_send_websocket_message(PONG_CHAT_MESSAGE)
	else:
		match split_message[1]:
			AUTHENTICATED_CHAT_IDENTIFER:
				emit_signal("authenticated")
			STANDARD_CHAT_IDENTIFIER:
				_add_message_to_chat_history(split_message[3])
			_:
				print_debug("Unhandled message type received: %s" % message)

func _on_server_close_request(_code: int, _reason: String) -> void:
	pass

###############################################################################
# Private functions                                                           #
###############################################################################

func _get_websocket_message() -> String:
	return client.get_peer(1).get_packet().get_string_from_utf8().strip_edges().strip_escapes()

func _send_websocket_message(text: String) -> void:
	# TODO handle errors
	client.get_peer(1).put_packet(text.to_utf8())

func _add_message_to_chat_history(message: String) -> void:
	# Not sure if this is possible but just to be safe
	if message.length() <= 1:
		return
	# Strip preceding ":" character
	var stripped_message = message.substr(1)
	chat_history[current_chat_history_index] = stripped_message
	if current_chat_history_index == CHAT_HISTORY_LENGTH - 1:
		current_chat_history_index = 0
	else:
		current_chat_history_index += 1
	
	emit_signal("chat_message_received", stripped_message)

###############################################################################
# Public functions                                                            #
###############################################################################

func setup() -> void:
	#warning-ignore:return_value_discarded
	client.connect("connection_closed", self, "_on_connection_closed")
	#warning-ignore:return_value_discarded
	client.connect("connection_error", self, "_on_connection_error")
	#warning-ignore:return_value_discarded
	client.connect("connection_established", self, "_on_connection_established")
	#warning-ignore:return_value_discarded
	client.connect("data_received", self, "_on_data_received")
	#warning-ignore:return_value_discarded
	client.connect("server_close_request", self, "_on_server_close_request")
	
	if client.connect_to_url(TWITCH_CHAT_URL) != OK:
		AppManager.console_log("Could not connect to Twitch chat")

func authenticate(username: String, token: String) -> void:
	"""
	Sends auth creds to websocket.
	
	DOES NOT EMIT AUTHENTICATED SIGNAL. The 'authenticated' signal is emitted
	once the server confirms we are authenticated.
	"""
	
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_send_websocket_message("PASS oauth:" + token)
	_send_websocket_message("NICK " + username)

func join_channel(username: String) -> void:
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_send_websocket_message("JOIN #" + username)
