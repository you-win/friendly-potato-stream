extends MarginContainer

onready var name_label: Label = $MarginContainer/HBoxContainer/Left/Name
onready var strength_label: Label = $MarginContainer/HBoxContainer/Left/Strength
onready var agility_label: Label = $MarginContainer/HBoxContainer/Left/Agility
onready var experience_label: Label = $MarginContainer/HBoxContainer/Right/Experience
onready var intelligence_label: Label = $MarginContainer/HBoxContainer/Right/Intelligence
onready var charisma_label: Label = $MarginContainer/HBoxContainer/Right/Charisma

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	pass

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func update_stats(data: Node2D) -> void:
	name_label.text = data.entity_name
	strength_label.text = "Strength: %s" % str(data.strength)
	agility_label.text = "Agility: %s" % str(data.agility)
	experience_label.text = "Experience: %s" % str(data.experience)
	intelligence_label.text = "Intelligence: %s" % str(data.intelligence)
	charisma_label.text = "Charisma: %s" % str(data.charisma)
