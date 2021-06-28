extends "res://screens/screen-plugins/stream-rpg/entities/base_entity.gd"

onready var debug_label: Label = $DebugLabel

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	anim_player.play("Idle")

func _process(delta: float) -> void:
	debug_label.text = str(self.health)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


