class_name YoutubeIntegration
extends Reference

const YOUTUBE_CHAT_URL: String = "www.googleapis.com/youtube/v3/liveChat/messages"
const REQUEST_TYPE: int = HTTPClient.METHOD_GET
const REQUEST_PORT: int = -1 # TODO I'm pretty sure this should be 443
const USE_SSL: bool = true


var http_client: HTTPClient = HTTPClient.new()

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	# Get OAuth token
	
	# Get live chat id
	
	# Store everything on this object
	pass

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_chat_messages() -> void:
	var error: int = http_client.connect_to_host(YOUTUBE_CHAT_URL, REQUEST_PORT, USE_SSL)
	if error != OK:
		printerr("Failed to connect to " + YOUTUBE_CHAT_URL)
	
	while(http_client.get_status() == HTTPClient.STATUS_CONNECTING or HTTPClient.STATUS_RESOLVING):
		http_client.poll()
