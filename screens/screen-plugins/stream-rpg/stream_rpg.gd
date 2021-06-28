extends Node2D

const Player: Resource = preload("res://screens/screen-plugins/stream-rpg/entities/player.tscn")
const RedMushroom: Resource = preload("res://screens/screen-plugins/stream-rpg/entities/red_mushroom.tscn")

const TICK_LENGTH: float = 1.0
const VALID_DIRECTIONS: Array = ["north", "n", "south", "s", "east", "e", "west", "w"]

onready var positions: Node = $Positions
onready var entities: Node = $Entities
onready var tick_timer: Timer = $TickTimer
onready var stats_viewport: ViewportContainer = $CanvasLayer/StatsViewport
onready var stats_view: MarginContainer = $CanvasLayer/StatsViewport/Viewport/StatsView

var player: Node2D
var current_enemy: Node2D
var command_queue: Array = [] # Command
var tween_count: int = 0

class Command:
	var command_name: String
	var command_value: String
	var command_user: String
	
	func _init(p_command_name: String, p_command_value: String, p_command_user: String) -> void:
		command_name = p_command_name
		command_value = p_command_value
		command_user = p_command_user

class GameData:
	var player_stats: Dictionary
	var player_inventory: Array
	var current_enemy: Node2D
	
	func save() -> Dictionary:
		var saved_inv: Array = []
		for pi in player_inventory:
			saved_inv.append(pi.save())
		return {
			"player_stats": player_stats,
			"player_inventory": saved_inv,
			"current_enemy": current_enemy.save()
		}

var enemy_scaling: float = 1.0

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	tick_timer.connect("timeout", self, "_on_tick")
	tick_timer.start(TICK_LENGTH)
	
	current_enemy = RedMushroom.instance()
	current_enemy.global_position = positions.right.global_position
	entities.call_deferred("add_child", current_enemy)
	
	player = Player.instance()
	player.global_position = positions.left.global_position
	entities.call_deferred("add_child", player)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tick() -> void:
	if command_queue.empty():
		_handle_default_command()
	else:
		_handle_user_command(command_queue.pop_back())

	if current_enemy.health <= 0:
		player.experience += 1
		current_enemy.free()
		current_enemy = RedMushroom.instance()
		current_enemy.global_position = positions.right.global_position
		entities.call_deferred("add_child", current_enemy)
	
	stats_view.update_stats(player)

func _default_complete() -> void:
	match tween_count:
		0:
			tween_count += 1
			positions.move_character(player, positions.center, positions.left)
			current_enemy.health -= 1
		1:
			tween_count = 0
			positions.disconnect("move_completed", self, "_default_complete")
			tick_timer.start(TICK_LENGTH)
		_:
			AppManager.console_log("Invalid tween_count %s" % str(tween_count))
			tween_count = 0

func _attack_complete() -> void:
	match tween_count:
		0:
			tween_count += 1
			
			player.anim_player.play("Attack")
			yield(player.anim_player, "animation_finished")
			current_enemy.health -= 1
			player.anim_player.play("Attack")
			yield(player.anim_player, "animation_finished")
			current_enemy.health -= 1
			
			positions.move_character(player, positions.center, positions.left)
		1:
			tween_count = 0
			player.anim_player.play("Idle")
			positions.disconnect("move_completed", self, "_attack_complete")
			tick_timer.start(TICK_LENGTH)
		_:
			AppManager.console_log("Invalid tween_count %s" % str(tween_count))
			tween_count = 0

###############################################################################
# Private functions                                                           #
###############################################################################

func _parse_custom_command(user: String, message: String) -> void:
	pass

func _handle_default_command() -> void:
	positions.connect("move_completed", self, "_default_complete")
	positions.move_character(player, positions.left, positions.center)

func _handle_user_command(command: Command) -> void:
	match command.command_name:
		"attack":
			positions.connect("move_completed", self, "_attack_complete")
			player.anim_player.play("Move")
			positions.move_character(player, positions.left, positions.center)
		"view stats":
			stats_viewport.visible = true
			
			yield(get_tree().create_timer(5.0), "timeout")
			
			stats_viewport.visible = false
			tick_timer.start(TICK_LENGTH)

###############################################################################
# Public functions                                                            #
###############################################################################

func command(user: String, lower_reward: String, message: String) -> void:
	AppManager.console_log("%s : %s : %s" % [user, lower_reward, message])
	match lower_reward:
		"move":
			var lower_message: String = message.to_lower()
			if lower_message in VALID_DIRECTIONS:
				command_queue.append(Command.new(lower_reward, lower_message, user))
		"view stats":
			command_queue.append(Command.new(lower_reward, message, user))
		"interact":
			pass
		"attack":
			command_queue.append(Command.new(lower_reward, message, user))
		"custom command":
			_parse_custom_command(user, message)
		_:
			AppManager.console_log("Unhandled command: %s" % lower_reward)

func setup(data: Dictionary) -> void:
	pass
