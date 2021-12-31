extends CanvasLayer

"""
ControlLayer

UI for controlling the app. Does not reset itself.
"""

const MAX_CONSOLE_LOGS: int = 22

onready var settings_button: Button = $Control/ButtonsContainer/HBoxContainer/SettingsButton
onready var reset_button: Button = $Control/ButtonsContainer/HBoxContainer/ResetButton
onready var console: VBoxContainer = $Control/ConsoleContainer/ColorRect/ScrollContainer/VBoxContainer

onready var settings_container: PanelContainer = $Control/SettingsContainer
onready var simple_chat_toggle: CheckButton = $Control/SettingsContainer/PluginsContainer/VBoxContainer/SimpleChat
onready var h_scroll_text_toggle: CheckButton = $Control/SettingsContainer/PluginsContainer/VBoxContainer/HScrollText
onready var incremental_game_toggle: CheckButton = $Control/SettingsContainer/PluginsContainer/VBoxContainer/IncrementalGame
onready var chat_minions_toggle: CheckButton = $Control/SettingsContainer/PluginsContainer/VBoxContainer/ChatMinions
onready var mouse_ripple_toggle: CheckButton = $Control/SettingsContainer/PluginsContainer/VBoxContainer/MouseRipple

onready var main_screen = get_parent()
onready var control: Control = $Control

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	settings_button.connect("pressed", self, "_on_settings_button_pressed")
	reset_button.connect("pressed", self, "_on_reset_button_pressed")
	AppManager.connect("console_log", self, "_on_console_log")
	
	simple_chat_toggle.pressed = main_screen.enabled_plugins["simple_chat"]
	simple_chat_toggle.connect("toggled", self, "_on_simple_chat_toggled")
	h_scroll_text_toggle.pressed = main_screen.enabled_plugins["h_scroll_text"]
	h_scroll_text_toggle.connect("toggled", self, "_on_h_scroll_text_toggled")
	incremental_game_toggle.pressed = main_screen.enabled_plugins["incremental_game"]
	incremental_game_toggle.connect("toggled", self, "_on_incremental_game_toggled")
	chat_minions_toggle.pressed = main_screen.enabled_plugins["chat_minions"]
	chat_minions_toggle.connect("toggled", self, "_on_chat_minions_toggled")
	mouse_ripple_toggle.pressed = main_screen.enabled_plugins["mouse_ripple"]
	mouse_ripple_toggle.connect("toggled", self, "_on_mouse_ripple_toggled")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_ui"):
		control.visible = not control.visible

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_settings_button_pressed() -> void:
	settings_container.visible = not settings_container.visible

func _on_reset_button_pressed() -> void:
	main_screen.reset_plugins()

func _on_console_log(message: String) -> void:
	var label: Label = Label.new()
	label.text = message
	console.add_child(label)
	console.move_child(label, 0)
	
	if console.get_child_count() > MAX_CONSOLE_LOGS:
		console.get_child(MAX_CONSOLE_LOGS).free()

func _on_simple_chat_toggled(button_state: bool) -> void:
	main_screen.enabled_plugins["simple_chat"] = button_state
	main_screen.reload_plugins()

func _on_h_scroll_text_toggled(button_state: bool) -> void:
	main_screen.enabled_plugins["h_scroll_text"] = button_state
	main_screen.reload_plugins()

func _on_incremental_game_toggled(button_state: bool) -> void:
	main_screen.enabled_plugins["incremental_game"] = button_state
	main_screen.reload_plugins()

func _on_chat_minions_toggled(button_state: bool) -> void:
	main_screen.enabled_plugins["chat_minions"] = button_state
	main_screen.reload_plugins()

func _on_mouse_ripple_toggled(button_state: bool) -> void:
	main_screen.enabled_plugins["mouse_ripple"] = button_state
	main_screen.reload_plugins()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


