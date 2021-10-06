extends Node2D

const Fighter: Resource = preload("res://screens/screen-plugins/minion-fights/entities/fighter.tscn")

onready var left_position: Vector2 = $Positions/Left.global_position
onready var right_position: Vector2 = $Positions/Right.global_position
onready var up_position: Vector2 = $Positions/Up.global_position
onready var down_position: Vector2 = $Positions/Down.global_position

onready var entities: Node2D = $Entities

var rng: RandomNumberGenerator

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	_spawn_fighter("asdf")

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _spawn_fighter(color_text: String) -> void:
	var x_pos: float = rng.randf_range(left_position.x, right_position.x)
	var y_pos: float = rng.randf_range(up_position.y, down_position.y)
	
	var fighter: KinematicBody2D = Fighter.instance()
	fighter.global_position = Vector2(x_pos, y_pos)
	
	entities.call_deferred("add_child", fighter)

###############################################################################
# Public functions                                                            #
###############################################################################


