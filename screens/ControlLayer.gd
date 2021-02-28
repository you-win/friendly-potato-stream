extends CanvasLayer

"""
ControlLayer

UI for controlling the app. Does not reset itself.
"""

const MAX_CONSOLE_LOGS: int = 22

onready var settings_button: Button = $Control/ButtonsContainer/HBoxContainer/SettingsButton
onready var reset_button: Button = $Control/ButtonsContainer/HBoxContainer/ResetButton
onready var console: VBoxContainer = $Control/ConsoleContainer/ColorRect/ScrollContainer/VBoxContainer

onready var main_screen: MainScreen = get_parent()
onready var control: Control = $Control

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	#warning-ignore:return_value_discarded
	settings_button.connect("pressed", self, "_on_settings_button_pressed")
	#warning-ignore:return_value_discarded
	reset_button.connect("pressed", self, "_on_reset_button_pressed")
	#warning-ignore:return_value_discarded
	AppManager.connect("console_log", self, "_on_console_log")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_ui"):
		control.visible = not control.visible

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_settings_button_pressed() -> void:
	pass

func _on_reset_button_pressed() -> void:
	for c in main_screen.screen_scale_layer.get_children():
		# All children are of type ScreenPlugin.gd
		c.reset()
		AppManager.console_log("%s plugin reset." % c.name)

func _on_console_log(message: String) -> void:
	var label: Label = Label.new()
	label.text = message
	console.add_child(label)
	console.move_child(label, 0)
	
	if console.get_child_count() > MAX_CONSOLE_LOGS:
		console.get_child(MAX_CONSOLE_LOGS).free()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


