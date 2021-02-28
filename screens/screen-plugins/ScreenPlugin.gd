class_name ScreenPlugin
extends Control

"""
ScreenPlugin

Helps define a common set of APIs for each screen plugin.
"""

onready var main_screen: Node2D = get_parent().get_parent()

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func init_connections() -> void:
	AppManager.console_log("%s init_connections() not implemented." % self.name)

func cleanup_connections() -> void:
	AppManager.console_log("%s cleanup_connections() not implemented." % self.name)

func initial_configs(_config: Dictionary) -> void:
	AppManager.console_log("%s initial_configs(...) not implemented." % self.name)

func get_config() -> Dictionary:
	AppManager.console_log("%s get_configs(...) not implemented." % self.name)
	return Dictionary()

func set_config(_config: Dictionary) -> void:
	AppManager.console_log("%s set_configs(...) not implemented." % self.name)

func reset() -> void:
	AppManager.console_log("%s reset() not implemented." % self.name)
