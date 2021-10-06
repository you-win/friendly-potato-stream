extends ScreenPlugin

const CIRCLE_SIZE: float = 32.0
const MIN_WIGGLE_DISTANCE: float = 2.0

var mouse_reader = load("res://rust/mouse_reader.gdns").new()

onready var screen_size: Vector2 = OS.get_screen_size()
onready var viewport_size: Vector2 = get_viewport().size
onready var scale_factor: Vector2 = viewport_size / screen_size

var last_pos: Vector2 = Vector2.ZERO
var mouse_pos: Vector2 = Vector2.ZERO

var modulate_alpha: float = 1.0

onready var sprite: Sprite = $CanvasLayer/Sprite

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")

func _physics_process(delta: float) -> void:
	last_pos = mouse_pos
	mouse_pos = mouse_reader.get_mouse_position() * scale_factor
	
	sprite.global_position = mouse_pos
	
	if last_pos.distance_to(mouse_pos) > MIN_WIGGLE_DISTANCE:
		sprite.modulate.a = 1.0
	else:
		sprite.modulate.a -= delta * 1.5
	
	clamp(sprite.modulate.a, 0.0, 1.0)
	
###############################################################################
# Connections                                                                 #
###############################################################################

func _on_viewport_size_changed() -> void:
	viewport_size = get_viewport().size

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func init_connections() -> void:
	pass

func cleanup_connections() -> void:
	pass

func initial_configs(_config: Dictionary) -> void:
	pass

func get_config() -> Dictionary:
	return Dictionary()

func set_config(_config: Dictionary) -> void:
	pass

func reset() -> void:
	pass
