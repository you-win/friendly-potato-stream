extends CanvasLayer

onready var gui: PanelContainer = $PanelContainer
onready var chat_history: VBoxContainer = $PanelContainer/VBoxContainer/ChatHistoryContainer/ChatHistory

var is_gui_visible := false

onready var parent: Node2D = get_parent()
var current_minion: Node2D

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	find_node("Randomize").connect("pressed", self, "_on_randomize")
	find_node("Duckify").connect("pressed", self, "_on_duckify")
	find_node("MakeChonky").connect("pressed", self, "_on_make_chonky")
	find_node("MakeSmol").connect("pressed", self, "_on_make_smol")
	find_node("ResetScale").connect("pressed", self, "_on_reset_scale")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_randomize(minion: Node2D = null) -> void:
	var minion_to_use = current_minion
	if minion:
		minion_to_use = minion
	minion_to_use.sprite.texture = parent.create_random_image_texture()

func _on_duckify(minion: Node2D = null) -> void:
	var minion_to_use = current_minion
	if minion:
		minion_to_use = minion
	minion_to_use.sprite.texture = parent.create_rubber_duck_image_texture()

func _on_make_chonky(minion: Node2D = null, amount: float = 0.1) -> void:
	var minion_to_use = current_minion
	if minion:
		minion_to_use = minion

	minion_to_use.sprite.scale.x += amount
	minion_to_use.sprite.scale.y += amount

func _on_make_smol(minion: Node2D = null, amount: float = 0.1) -> void:
	var minion_to_use = current_minion
	if minion:
		minion_to_use = minion

	minion_to_use.sprite.scale.x -= amount
	minion_to_use.sprite.scale.y -= amount

func _on_reset_scale() -> void:
	current_minion.sprite.scale = Vector2.ONE

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func toggle_gui() -> void:
	gui.visible = not gui.visible
	is_gui_visible = gui.visible

func update_gui(minion: Node2D) -> void:
	current_minion = minion

	for child in chat_history.get_children():
		child.queue_free()

	yield(get_tree(), "idle_frame")
	
	for chat_log in minion.chat_logs:
		var label := Label.new()
		label.text = chat_log
		chat_history.call_deferred("add_child", label)

func make_chonky(minion: Node2D) -> void:
	_on_make_chonky(minion, 1.0)

func make_smol(minion: Node2D) -> void:
	_on_make_smol(minion, 1.0)

func on_randomize(minion: Node2D) -> void:
	_on_randomize(minion)

func on_duckify(minion: Node2D) -> void:
	_on_duckify(minion)
