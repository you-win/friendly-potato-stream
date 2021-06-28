extends Node

signal move_completed

const TWEEN_TIME: float = 0.5

onready var off_left: Position2D = $OffLeft
onready var left: Position2D = $Left
onready var center: Position2D = $Center
onready var right: Position2D = $Right
onready var off_right: Position2D = $OffRight

onready var _tween: Tween = $Tween

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_tween.connect("tween_all_completed", self, "_on_tween_complete")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tween_complete() -> void:
	_tween.remove_all()
	emit_signal("move_completed")

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func move_character(character: Node2D, from: Position2D, to: Position2D) -> void:
	_tween.interpolate_property(character, "global_position", from.global_position,
			to.global_position, TWEEN_TIME, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	
	_tween.start()
