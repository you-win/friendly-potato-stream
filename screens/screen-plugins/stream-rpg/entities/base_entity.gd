extends Node2D

onready var sprite: Sprite = $Sprite
onready var anim_player: AnimationPlayer = $AnimationPlayer

var entity_name: String = "Base Entity"

# Stats
var health: float = 10.0
var strength: float = 1.0
var agility: float = 1.0
var intelligence: float = 1.0
var charisma: float = 1.0

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _init_stats(scaling: float) -> void:
	"""
	Done separately so we can set some reasonable base values earlier
	"""
	health *= scaling
	strength *= scaling
	agility *= scaling
	intelligence *= scaling
	charisma *= scaling

###############################################################################
# Public functions                                                            #
###############################################################################

func save() -> Dictionary:
	return {
		"entity_name": entity_name,
		"health": health,
		"strength": strength,
		"agility": agility,
		"intelligence": intelligence,
		"charisma": charisma
	}
