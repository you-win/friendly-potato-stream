extends ScreenPlugin

const PLUGIN_NAME: String = "IncrementalGame"
const SAVE_FILE_NAME: String = "incremental-game.json"

const MAX_SCALE: int = 42
const MIN_SCALE: int = 22
const DEFAULT_SCALE: int = 28

onready var _container_size: Vector2 = $MarginContainer.rect_size
onready var _spawn_location: Vector2 = $MarginContainer.rect_global_position + (_container_size / 2)

var _allow_move: bool = false

var _graphic: Node2D = Polygon2D.new()

var _score: Big = Big.new(0)
var _score_label: Label = Label.new()
var _score_font_path: String = "res://assets/fonts/hack/Hack-Regular.ttf"
var _score_font: DynamicFont = DynamicFont.new()

var _current_scale: int = DEFAULT_SCALE

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_read_data()
	
	# Create graphic background
	_graphic.polygon = PoolVector2Array([
		Vector2(0 - _container_size.x / 2, 0 + _container_size.y / 2),
		Vector2(0 + _container_size.x / 2, 0 + _container_size.y / 2),
		Vector2(0 + _container_size.x / 2, 0 - _container_size.y / 2),
		Vector2(0 - _container_size.x / 2, 0 - _container_size.y / 2)
	])
	_graphic.global_position = _spawn_location
	_graphic.color = Color.cornflower
	_graphic.z_index -= 100 # Try and place this under everything
	self.add_child(_graphic)
	
	# Create score label and font
	_score_label.text = _score.to_string()
	_score_label.align = Label.ALIGN_CENTER
	_score_label.valign = Label.VALIGN_CENTER
	_score_label.rect_size = _container_size
	_score_font.font_data = load(_score_font_path)
	_score_font.size = _current_scale
	_score_font.use_filter = true
	_score_label.set("custom_fonts/font", _score_font)
	
	_graphic.add_child(_score_label)
	
	_score_label.rect_global_position = _spawn_location - (_container_size / 2)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_chat_message_received(_user: String, _message: String) -> void:
	_score.plus(1)
	_score_label.text = _score.to_string()
	# TODO Don't write data every time
	_write_data()

###############################################################################
# Private functions                                                           #
###############################################################################

func _read_data() -> void:
	var save_file: File = File.new()
	if not OS.is_debug_build():
		var executable_directory: String = OS.get_executable_path().get_base_dir()
		
		if not save_file.file_exists(executable_directory + "/" + SAVE_FILE_NAME):
			AppManager.console_log("No save data found.")
			return
		
		save_file.open(executable_directory + "/" + SAVE_FILE_NAME, File.READ)
	else:
		if not save_file.file_exists("res://export/" + SAVE_FILE_NAME):
			AppManager.console_log("No save data found.")
			return
		save_file.open("res://export/" + SAVE_FILE_NAME, File.READ)
		
	var save_data = parse_json(save_file.get_as_text())
	if typeof(save_data) != TYPE_DICTIONARY:
		# Bad data
		AppManager.console_log("Found save file for %s but data is not in expected format." % PLUGIN_NAME)
		return
	
	_score = Big.new(save_data["score"])
	_score_font_path = save_data["score_font_path"]
	
	AppManager.console_log("Save data loaded for %s." % PLUGIN_NAME)

func _write_data() -> void:
	var save_file: File = File.new()
	if not OS.is_debug_build():
		var executable_directory: String = OS.get_executable_path().get_base_dir()
		
		save_file.open(executable_directory + "/" + SAVE_FILE_NAME, File.WRITE)
	else:
		save_file.open("res://export/" + SAVE_FILE_NAME, File.WRITE)
	
	var save_data: Dictionary = {
		"score": _score.to_string(), # If the number is too high we won't be able to load, maybe
		"score_font_path": _score_font.font_data.font_path
	}
	
	save_file.store_string(to_json(save_data))
	
	save_file.close()

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
	_graphic.global_position = _spawn_location
	_graphic.scale = Vector2.ONE
	_score_font.size = DEFAULT_SCALE
	_current_scale = DEFAULT_SCALE
