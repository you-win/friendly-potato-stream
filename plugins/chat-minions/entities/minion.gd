extends RigidBody2D

signal minion_selected(minion)

const SPEED: float = 250.0
const THROW_SPEED: float = 5.0
const LAST_POSITION_FRAME_SET: int = 3

const INITIAL_LIFETIME: float = 10800.0
const SAY_DURATION: float = 5.0

const NEW_MOVEMENT_DELAY: float = 3.0

const COLLISION_RESET_DELAY: float = 3.0

const MAX_CHAT_LOGS: int = 50

var lifetime: float = INITIAL_LIFETIME

onready var sprite: Sprite = $Sprite
onready var anim_player: AnimationPlayer = $AnimationPlayer

# Chat
onready var chat_bubble: Label = $ChatBubble
onready var say_timer: Timer = $SayTimer
var chat_bubble_initial_position: Vector2
var chat_bubble_initial_size: Vector2
var chat_logs := PoolStringArray()
var chat_logs_pointer: int = -1

onready var name_plate: Label = $NamePlate
onready var move_timer: Timer = $MoveTimer
onready var collision_layer_timer: Timer = $CollsionLayerTimer

var movement_vector: Vector2 = Vector2.ZERO

# Input
var should_track_mouse := false
var should_throw := false
var last_global_position_counter: int = 0
onready var last_global_position := global_position

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	say_timer.connect("timeout", self, "_on_say_timer_timeout")
	
	chat_bubble.connect("resized", self, "_on_chat_bubble_resized")
	chat_bubble.connect("visibility_changed", self, "_on_chat_bubble_visibility_changed")
	chat_bubble_initial_position = chat_bubble.rect_position
	chat_bubble_initial_size = chat_bubble.rect_size
	
	chat_logs.resize(MAX_CHAT_LOGS)
	
	name_plate.text = self.name
	var name_plate_initial_size_x: float = name_plate.rect_size.x
	name_plate.rect_position = Vector2(
		name_plate.rect_position.x - (name_plate.rect_size.x - name_plate_initial_size_x),
		name_plate.rect_position.y
	)
	
	move_timer.connect("timeout", self, "_on_move_timer_timeout")
	move_timer.start(NEW_MOVEMENT_DELAY)
	
	collision_layer_timer.connect("timeout", self, "_on_collision_layer_timer_timeout")

	connect("input_event", self, "_on_input_event")

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		self.queue_free()
		return
	
	sprite.modulate.a = (lifetime / INITIAL_LIFETIME) * 255
	
	if (linear_velocity.x > 0.01 or linear_velocity.x < -0.01):
		if anim_player.current_animation != "Move":
			anim_player.play("Move")
	else:
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle")
	
	if linear_velocity.x > 0:
		sprite.flip_h = false
	else:
		sprite.flip_h = true

	if Input.is_action_just_released("left_click"):
		should_track_mouse = false
		mode = RigidBody2D.MODE_CHARACTER

	if should_track_mouse:
		last_global_position_counter += 1
		if last_global_position_counter >= LAST_POSITION_FRAME_SET:
			last_global_position = global_position
			last_global_position_counter = 0
		global_position = get_global_mouse_position()
	elif should_throw:
		should_throw = false
		apply_central_impulse((global_position - last_global_position) * THROW_SPEED)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_chat_bubble_resized() -> void:
	if chat_bubble.rect_size != chat_bubble_initial_size:
		chat_bubble.rect_position = Vector2(
			chat_bubble.rect_position.x,
			chat_bubble.rect_position.y - (chat_bubble.rect_size.y - chat_bubble_initial_size.y)
		)
	else:
		chat_bubble.rect_position = chat_bubble_initial_position

func _on_chat_bubble_visibility_changed() -> void:
	chat_bubble.rect_size = chat_bubble_initial_size

func _on_say_timer_timeout() -> void:
	chat_bubble.visible = false

func _on_move_timer_timeout() -> void:
	generate_new_action()
	move_timer.start(NEW_MOVEMENT_DELAY)

func _on_collision_layer_timer_timeout() -> void:
	set_collision_layer_bit(1, false)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("left_click"):
		should_track_mouse = true
		should_throw = true
		mode = RigidBody2D.MODE_STATIC
		emit_signal("minion_selected", self)
		get_tree().set_input_as_handled()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func generate_new_action(command: String = "") -> void:
	if command.empty(): # Just move
		var random_f := AppManager.rng.randf()
		if random_f <= 0.3:
			apply_central_impulse(Vector2(SPEED, 0))
		elif random_f <= 0.6:
			apply_central_impulse(Vector2(-SPEED, 0))
		else:
			pass

func say(message: String) -> void:
	lifetime = INITIAL_LIFETIME
	
	# Reset chat bubble size
	chat_bubble.text = ""
	chat_bubble.rect_size = chat_bubble_initial_size
	
	chat_bubble.visible = false
	chat_bubble.set_deferred("visible", true)

	yield(get_tree(), "idle_frame")
	
	chat_bubble.text = message
	
#	chat_bubble.visible = true
	chat_bubble.visible = false
	chat_bubble.set_deferred("visible", true)
	
	say_timer.start(SAY_DURATION)
	
	# Store log
	chat_logs_pointer += 1
	if chat_logs_pointer > MAX_CHAT_LOGS:
		chat_logs_pointer = 0
	chat_logs[chat_logs_pointer] = message

func start_colliding() -> void:
	set_collision_layer_bit(1, true)
	collision_layer_timer.start(COLLISION_RESET_DELAY)
