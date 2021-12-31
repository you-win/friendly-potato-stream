class_name TwitchIntegration
extends Node

"""
Integrates with the Twitch.tv IRC api via websocket.

A valid username and token are required when creating the object. Exists to
store chat history and provide an interface to Twitch chat.
"""

signal http_response_received
signal authenticated
signal pub_sub_connected

signal chat_message_received(user, message)

signal user_subscribed(user, months)
signal bits_received(user, amount, message)
signal channel_points_redeemed(user, reward, message)

# General API
const TWITCH_OAUTH_URL_FORMAT: String = """https://id.twitch.tv/oauth2/token
	?client_id=%s
	&client_secret=%s
	&grant_type=client_credentials"""
const TWITCH_GET_USER_URL_FORMAT: String = "https://api.twitch.tv/helix/users?login=%s"
const TWITCH_REFRESH_TOKEN_URL_FORMAT: String = """https://id.twitch.tv/oauth2/token
	?grant_type=refresh_token
	&refresh_token=%s
	&client_id=%s
	&client_secret=%s"""

# Chat
const TWITCH_CHAT_URL: String = "wss://irc-ws.chat.twitch.tv:443"

# Pub Sub
const PUB_SUB_URL: String = "wss://pubsub-edge.twitch.tv/"
const PING_MESSAGE: Dictionary = {
	"type": "PING"
}
const PING_TIME: float = 360.0 # In seconds
const POLL_TIME: float = 1.0

# IRC-specific data
const PONG_CHAT_MESSAGE: String = "PONG :tmi.twitch.tv"

const CHAT_HISTORY_LENGTH: int = 100

# Oauth # TODO unused, not needed for the most part?
var http: HTTPRequest
var user_code: String = "" # Needed for getting an oauth token
var access_token: String = "" # Needed for logging into twitch chat
var expires_in: float = 0.0

# NOTE can't break these out into separate files for some reason, signals don't fire correctly
# Websockets
var chat_client: WebSocketClient = WebSocketClient.new()
var pubsub_client: WebSocketClient = WebSocketClient.new()
var poll_counter: float = 0.0

# Twitch chat messages
var chat_history: PoolStringArray = PoolStringArray()
var current_chat_history_index: int = 0

# Pub sub
var nonce: String = ""
var ping_time_counter: float = 0.0

# HTTP Requests
var last_response

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	chat_history.resize(CHAT_HISTORY_LENGTH)
	
	#warning-ignore:return_value_discarded
	chat_client.connect("connection_closed", self, "_on_chat_connection_closed")
	#warning-ignore:return_value_discarded
	chat_client.connect("connection_error", self, "_on_chat_connection_error")
	#warning-ignore:return_value_discarded
	chat_client.connect("connection_established", self, "_on_chat_connection_established")
	#warning-ignore:return_value_discarded
	chat_client.connect("data_received", self, "_on_chat_data_received")
	#warning-ignore:return_value_discarded
	chat_client.connect("server_close_request", self, "_on_chat_server_close_request")
	
	#warning-ignore:return_value_discarded
	pubsub_client.connect("connection_closed", self, "_on_pubsub_connection_closed")
	#warning-ignore:return_value_discarded
	pubsub_client.connect("connection_error", self, "_on_pubsub_connection_error")
	#warning-ignore:return_value_discarded
	pubsub_client.connect("connection_established", self, "_on_pubsub_connection_established")
	#warning-ignore:return_value_discarded
	pubsub_client.connect("data_received", self, "_on_pubsub_data_received")
	#warning-ignore:return_value_discarded
	pubsub_client.connect("server_close_request", self, "_on_pubsub_server_close_request")
	
	if chat_client.connect_to_url(TWITCH_CHAT_URL) != OK:
		AppManager.console_log("Could not connect to Twitch chat")
	
	if pubsub_client.connect_to_url(PUB_SUB_URL) != OK:
		AppManager.console_log("Could not connect to Twitch pubsub")
	
	http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", self, "_on_http_response")

func _process(delta: float) -> void:
	poll_counter += delta
	if poll_counter >= POLL_TIME:
		poll_counter = 0.0
		if chat_client.get_connection_status() != WebSocketClient.CONNECTION_DISCONNECTED:
			chat_client.poll()
		if pubsub_client.get_connection_status() != WebSocketClient.CONNECTION_DISCONNECTED:
			pubsub_client.poll()
	
	ping_time_counter += delta
	if ping_time_counter >= PING_TIME:
		ping_time_counter = 0.0
		_send_pubsub_ping()

func _exit_tree() -> void:
	_on_chat_server_close_request(0, "")
	_on_pubsub_server_close_request(0, "")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_chat_connection_closed(was_clean_close: bool) -> void:
	if was_clean_close:
		AppManager.console_log("Chat connection closed")
	else:
		AppManager.console_log("Chat connection did not close cleanly")

func _on_pubsub_connection_closed(was_clean_close: bool) -> void:
	if was_clean_close:
		AppManager.console_log("PubSub connection closed cleanly")
	else:
		AppManager.console_log("PubSub connection did not close cleanly")

func _on_chat_connection_error() -> void:
	AppManager.console_log("Chat connection error")

func _on_pubsub_connection_error() -> void:
	AppManager.console_log("PubSub connection error")

func _on_chat_connection_established(_protocol: String) -> void:
	AppManager.console_log("Chat connection established")

func _on_pubsub_connection_established(_protocol: String) -> void:
	AppManager.console_log("PubSub connection established")

func _on_chat_data_received() -> void:
	var message: String = _get_chat_websocket_message()

	# Chat messages come in the following format
	# :tmi.twitch.tv <num/IRC type> <user/channel> :<message>
	var split_message: PoolStringArray = message.split(" ", true, 3)

	if split_message[0] == "PING":
		_send_chat_websocket_message(PONG_CHAT_MESSAGE)
	else:
		match split_message[1]:
			"001":
				emit_signal("authenticated")
			"PRIVMSG":
				_add_message_to_chat_history(split_message[0], split_message[3])
			"366", "JOIN":
				# Do nothing
				pass
			_:
				AppManager.console_log("Unhandled message type received: %s" % message)

func _on_pubsub_data_received() -> void:
	"""
	https://dev.twitch.tv/docs/pubsub
	Pub Sub messages come in format
	{
		"type": "some_format",
		"nonce": "this is our provided key",
		"data" {
			"some data"
		}
	}
	"""
	var message: String = _get_pubsub_websocket_message()
	
	var json_message = parse_json(message)
	if typeof(json_message) != TYPE_DICTIONARY:
		AppManager.console_log("Unrecognized message from pubsub: %s" % json_message)
	
	match json_message["type"]:
		"PONG": # This is the server's response to our PING
			pass
		"RECONNECT":
			AppManager.console_log("Reconnect request received, restarting PubSub")
			pubsub_client.disconnect_from_host()
			OS.delay_msec(5000)
			if pubsub_client.connect_to_url(PUB_SUB_URL) != OK:
				AppManager.console_log("Could not connect to Twitch pubsub")
		"RESPONSE":
			if (not json_message.has("nonce") or json_message["nonce"] != self.nonce):
				AppManager.console.log("Invalid nonce in response: %s" % json_message)
				return
			if not json_message["error"].empty():
				AppManager.console_log("Error received from PubSub: %s" % json_message["error"])
				return
			AppManager.console_log("Successfully subscribed to PubSub, probably")
			emit_signal("pub_sub_connected")
		"MESSAGE": # Bits and subscriptions
			if (not json_message.has("data") or not json_message["data"].has("message")):
				AppManager.console_log("Invalid message received: %s" % json_message)
				return
			
			var ps_topic: String = json_message["data"]["topic"]
			var ps_message = parse_json(json_message["data"]["message"])
				
			if "subscribe" in ps_topic:
				var user_name: String = "anon"
				# NOTE Not a complete null check but I blame Twitch for any other nulls
				# NOTE twitch sends a display name but use the user_name for consistency
				if ps_message.has("user_name"):
					user_name = ps_message["user_name"]
				emit_signal("user_subscribed", user_name, ps_message["cumulative_months"])
			elif "bits" in ps_topic:
				var user_name: String = "anon"
				# NOTE Not a complete null check but I blame Twitch for any other nulls
				if (not ps_message["is_anonymous"] and ps_message.has("user_name")):
					user_name = ps_message["user_name"]
				emit_signal("bits_received", user_name, ps_message["bits_used"], ps_message["chat_message"])
			elif "channel-points" in ps_topic:
				# NOTE Not a complete null check but I blame Twitch for any other nulls
				if (not ps_message.has("data") or not ps_message["data"].has("redemption")):
					AppManager.console_log("Invalid channel point message received: %s" % ps_message)
					return
				var user_input: String = ""
				if ps_message["data"]["redemption"].has("user_input"):
					user_input = ps_message["data"]["redemption"]["user_input"]
				
				emit_signal("channel_points_redeemed",
						ps_message["data"]["redemption"]["user"]["display_name"],
						ps_message["data"]["redemption"]["reward"]["title"],
						user_input)
			else:
				AppManager.console_log("Unhandled MESSAGE event: %s" % json_message)
		"reward-redeemed": # Channel points
			# Intentionally don't handle this since Twitch sends us redundant messages
			pass
		_:
			print_debug("asdf")

func _on_chat_server_close_request(_code: int, _reason: String) -> void:
	AppManager.console_log("Chat close request received")
	chat_client.disconnect_from_host()

func _on_pubsub_server_close_request(_code: int, _reason: String) -> void:
	AppManager.console_log("PubSub close request received")
	pubsub_client.disconnect_from_host()

func _on_http_response(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
	"""
	We are looking for a response in this format
	{
		"access_token": string
		"refresh_token": string
		"expires_in": float
		"scope": [
			string
		]
		"token_type": "bearer"
	}
	"""
	var body_string: String = body.get_string_from_ascii()
	if result != HTTPRequest.RESULT_SUCCESS:
		AppManager.console_log("Bad result. Response code %s: %s" % [response_code, body_string])
		return
	
	if (not response_code >= 200 and not response_code <= 299):
		AppManager.console_log("Bad response code %s: %s" % [response_code, body_string])
		return
	
	var json_response = parse_json(body_string)
	if typeof(json_response) != TYPE_DICTIONARY:
		AppManager.console_log("Bad json response: %s" % body_string)
		return
	
	last_response = json_response
	emit_signal("http_response_received")

###############################################################################
# Private functions                                                           #
###############################################################################

func _get_chat_websocket_message() -> String:
	return chat_client.get_peer(1).get_packet().get_string_from_utf8().strip_edges().strip_escapes()

func _get_pubsub_websocket_message() -> String:
	return pubsub_client.get_peer(1).get_packet().get_string_from_utf8().strip_edges().strip_escapes()

func _send_chat_websocket_message(text: String) -> void:
	# TODO handle errors
	chat_client.get_peer(1).put_packet(text.to_utf8())

func _send_pubsub_websocket_message(text: String) -> void:
	# TODO handle errors
	pubsub_client.get_peer(1).put_packet(text.to_utf8())

func _send_pubsub_ping() -> void:
	pubsub_client.get_peer(1).put_packet(JSON.print(PING_MESSAGE).to_utf8())
	AppManager.console_log("sending pubsub ping")

func _add_message_to_chat_history(user: String, message: String) -> void:
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
	
	var stripped_user := user.substr(1, user.find("!") - 1)
	
	emit_signal("chat_message_received", stripped_user, stripped_message)

###############################################################################
# Public functions                                                            #
###############################################################################

###
# General
###

func refresh_token(client_id: String, client_secret: String, refresh: String) -> void:
	var post_request: String = TWITCH_REFRESH_TOKEN_URL_FORMAT.strip_escapes() % [
		refresh,
		client_id,
		client_secret
	]
	print(post_request)
	http.request(post_request, PoolStringArray(), true, HTTPClient.METHOD_POST)

#func get_oauth_token(client_id: String, client_secret: String) -> void:
#	var post_request: String = TWITCH_OAUTH_URL_FORMAT.strip_escapes() % [client_id, client_secret]
#
#	http.request(post_request, PoolStringArray(), true, HTTPClient.METHOD_POST)
#
#func get_join_channel_id(client_id: String, channel: String, token: String) -> void:
#	var get_request: String = TWITCH_GET_USER_URL_FORMAT % channel
#	var headers: PoolStringArray = PoolStringArray([
#		"Authorization: Bearer %s" % token,
#		"Client-Id: %s" % client_id
#	])
#
#	http.request(get_request, headers, true, HTTPClient.METHOD_GET)

###
# Chat
###

func authenticate(username: String, token: String) -> void:
	"""
	Sends auth creds to websocket.

	DOES NOT EMIT AUTHENTICATED SIGNAL. The 'authenticated' signal is emitted
	once the server confirms we are authenticated.
	"""

	chat_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_send_chat_websocket_message("PASS oauth:" + token)
	_send_chat_websocket_message("NICK " + username)

func join_channel(username: String) -> void:
	chat_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_send_chat_websocket_message("JOIN #" + username)

###
# PubSub
###

func subscribe(channel_id: String, token: String, p_nonce: String) -> void:
	"""
	DOES NOT EMIT PUB_SUB_CONNECTED SIGNAL. The 'pub_sub_connected' signal is emitted
	from a handled websocket message
	"""
	_send_pubsub_ping()
	yield(pubsub_client, "data_received")
	self.nonce = p_nonce
	var request: Dictionary = {
		"type": "LISTEN",
		"nonce": p_nonce,
		"data": {
			"topics": [
				"channel-bits-events-v2.%s" % channel_id,
				"channel-points-channel-v1.%s" % channel_id,
				"channel-subscribe-events-v1.%s" % channel_id
			],
			"auth_token": token
		}
	}
	
	_send_pubsub_websocket_message(JSON.print(request))
