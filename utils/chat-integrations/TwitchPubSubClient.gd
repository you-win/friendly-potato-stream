extends Reference

signal connected

const PUB_SUB_URL: String = "wss://pubsub-edge.twitch.tv"

const PING_MESSAGE: Dictionary = {
	"type": "PING"
}
const PING_TIME: float = 25800.0 # Equal to 4:30

var client: WebSocketClient = WebSocketClient.new()
var nonce: String = ""

var ping_time_counter: float = 0.0

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
#	if client.connect_to_url(PUB_SUB_URL) != OK:
#		AppManager.console_log("Could not connect to Twitch pubsub")

func _process(delta: float) -> void:
	ping_time_counter += delta
	if ping_time_counter >= PING_TIME:
		_send_websocket_message(JSON.print(PING_MESSAGE))
		ping_time_counter = 0.0
	
	if client.get_connection_status() != WebSocketClient.CONNECTION_DISCONNECTED:
		client.poll()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_connection_error() -> void:
	pass

func _on_connection_established(_protocol: String) -> void:
	emit_signal("connected")
	print_debug("Connection established with Twitch")

func _on_data_received() -> void:
	"""
	Pub Sub messages come in format
	{
		"type": "some_format",
		"nonce": "this is our provided key",
		"data" {
			"some data"
		}
	}
	"""
	var message: String = _get_websocket_message()
	
	var json_message = parse_json(message)
	if typeof(json_message) != TYPE_DICTIONARY:
		AppManager.console_log("Unrecognized message from pubsub: %s" % json_message)
	
	match json_message["type"]:
		"PONG": # This is the server's response to our PING
			pass
		"RECONNECT":
			AppManager.console_log("Reconnect request received, restarting PubSub")
			client.disconnect_from_host()
			OS.delay_msec(5000)
			if client.connect_to_url(PUB_SUB_URL) != OK:
				AppManager.console_log("Could not connect to Twitch pubsub")
		"RESPONSE":
			if (not json_message.has("nonce") or json_message["nonce"] != self.nonce):
				AppManager.console.log("Invalid nonce in response: %s" % json_message)
				return
			if not json_message["error"].empty():
				AppManager.console_log("Error received from PubSub: %s" % json_message["error"])
				return
			AppManager.console_log("Successfully subscribed to PubSub, probably")
		"MESSAGE": # Bits and subscriptions
			if (not json_message.has("data") or not json_message["data"].has("message")):
				AppManager.console_log("Invalid message received: %s" % json_message)
				return
			var ps_topic: String = json_message["data"]["topic"]
			var ps_message = parse_json(json_message["data"]["message"])
			print_debug(ps_message) # TODO do something with this
			if "subscribe" in ps_topic:
				pass
			elif "bits" in ps_topic:
				pass
			else:
				AppManager.console_log("Unhandled MESSAGE event: %s" % json_message)
		"reward-redeemed": # Channel points
			if (not json_message.has("data") or not json_message["data"].has("redemption")
					or not json_message["data"]["redemption"].has("user")
					or not json_message["data"]["redemption"].has("reward")):
				AppManager.console_log("Invalid channel point message received: %s" % json_message)
				return
			var channel_point_user: String = json_message["data"]["redemption"]["user"]["display_name"]
			var channel_point_data: Dictionary = json_message["data"]["redemption"]["reward"]
			print_debug(channel_point_user)
			print_debug(channel_point_data)
		_:
			pass

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
	
	if client.connect_to_url(PUB_SUB_URL) != OK:
		AppManager.console_log("Could not connect to Twitch pubsub")

func subscribe(channel_id: String, token: String, p_nonce: String) -> void:
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
	
	_send_websocket_message(JSON.print(request))
