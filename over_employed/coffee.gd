# coffee.gd - Self-contained coffee system (PRESS SPACE TO DRINK)
extends Node2D

@onready var coffee_sprite = $CoffeeBody/CoffeeSprite
@onready var coffee_light = $CoffeeBody/CoffeeSprite/CoffeeLight
@onready var coffee_area = $CoffeeArea
@onready var speech_bubbles = $CoffeeBody/SpeechBubbles
@onready var audio_player = AudioStreamPlayer2D.new()

# Coffee states
enum CoffeeState { IDLE, READY_TO_MAKE, BREWING, READY_TO_DRINK, CONSUMED }
var current_state = CoffeeState.IDLE
var player_nearby = false

# Respawn timing
var respawn_timer: Timer
var initial_spawn_timer: Timer

# Sounds
@onready var sounds = {
	"ding": preload("res://sounds/ding.wav"),
	"brewing": preload("res://sounds/brew-start.wav"),
	"success": preload("res://sounds/success.wav")
}

var game_ui: CanvasLayer
var main_room_node: Node2D

func _ready():
	add_child(audio_player)
	
	# Find the GameUI node
	game_ui = get_tree().get_first_node_in_group("game_ui")
	main_room_node = get_parent()
	
	# Setup timers
	setup_timers()
	
	# Connect area signals
	coffee_area.body_entered.connect(_on_player_entered)
	coffee_area.body_exited.connect(_on_player_exited)
	
	# Start in IDLE state
	reset_coffee_system()

func setup_timers():
	# Initial spawn timer (30 seconds after game start)
	initial_spawn_timer = Timer.new()
	initial_spawn_timer.wait_time = 30.0
	initial_spawn_timer.one_shot = true
	initial_spawn_timer.timeout.connect(coffee_ready_to_make)
	add_child(initial_spawn_timer)
	
	# Respawn timer (30 seconds after buff expires)
	respawn_timer = Timer.new()
	respawn_timer.wait_time = 30.0
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(coffee_ready_to_make)
	add_child(respawn_timer)

func start_coffee_system():
	"""Called by main_room when game starts"""
	current_state = CoffeeState.IDLE
	update_coffee_visual()
	update_visual_state()
	initial_spawn_timer.start()
	print("Coffee system started - will be ready in 30 seconds")

func reset_coffee_system():
	"""Called by main_room when game resets"""
	current_state = CoffeeState.IDLE
	player_nearby = false
	
	# Stop all timers
	if initial_spawn_timer:
		initial_spawn_timer.stop()
	if respawn_timer:
		respawn_timer.stop()
	
	# Hide progress bar if visible
	if game_ui and game_ui.progress_bar.visible:
		game_ui.hide_progress_bar()
	
	update_coffee_visual()
	update_visual_state()
	print("Coffee system reset")

func coffee_ready_to_make():
	"""Coffee becomes available for brewing"""
	current_state = CoffeeState.READY_TO_MAKE
	play_sound("ding")
	update_coffee_visual()
	update_visual_state()
	print("Coffee is ready to make!")

func _input(event):
	if event.is_action_pressed("ui_accept") and player_nearby: 
		handle_space_key_press()
		
func _process(delta):
	# No more hold space logic needed!
	pass

func handle_space_key_press():
	match current_state:
		CoffeeState.READY_TO_MAKE:
			start_making_coffee()
		CoffeeState.READY_TO_DRINK:
			drink_coffee()  # Simple press to drink
		CoffeeState.BREWING, CoffeeState.CONSUMED:
			pass # Do nothing during these states
		_:
			pass

func start_making_coffee():
	current_state = CoffeeState.BREWING
	play_sound("brewing")
	update_coffee_visual()
	update_visual_state()
	print("Started brewing coffee...")
	
	# Wait 15 seconds for brewing
	var brewing_timer = get_tree().create_timer(15.0)
	brewing_timer.timeout.connect(coffee_finished_brewing)

func coffee_finished_brewing():
	current_state = CoffeeState.READY_TO_DRINK
	play_sound("ding")
	update_coffee_visual()
	update_visual_state()
	print("Coffee finished brewing - ready to drink!")

func drink_coffee():
	"""Simple press to drink coffee - no holding required"""
	current_state = CoffeeState.CONSUMED
	
	play_sound("success")
	update_coffee_visual()
	update_visual_state()
	print("Coffee consumed - activating speed buff!")
	
	# Activate speed buff in main room
	if main_room_node.has_method("activate_coffee_buff"):
		main_room_node.activate_coffee_buff()

func _on_player_entered(body):
	if body.name == "Player":
		player_nearby = true
		update_visual_state()

func _on_player_exited(body):
	if body.name == "Player":
		player_nearby = false
		update_visual_state()

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		audio_player.stream = sounds[sound_name]
		audio_player.play()

func update_coffee_visual():
	match current_state:
		CoffeeState.IDLE:
			coffee_sprite.animation = "empty"
			coffee_light.animation = "default"
			coffee_light.visible = false  # Ensure light is invisible
		CoffeeState.READY_TO_MAKE:
			coffee_sprite.animation = "empty"
			coffee_light.animation = "default"
			coffee_light.visible = false  # No light
		CoffeeState.BREWING:
			coffee_sprite.animation = "empty"
			coffee_light.animation = "red"
			coffee_light.visible = true  # Show red light
		CoffeeState.READY_TO_DRINK:
			coffee_sprite.animation = "full"
			coffee_light.animation = "green"
			coffee_light.visible = true  # Show green light
		CoffeeState.CONSUMED:
			coffee_sprite.animation = "empty"
			coffee_light.animation = "green"
			coffee_light.visible = true  # Show green light during buff
			
func update_visual_state():
	match current_state:
		CoffeeState.IDLE:
			speech_bubbles.visible = false  # No speech bubble
		CoffeeState.READY_TO_MAKE:
			speech_bubbles.visible = true
			speech_bubbles.animation = "Exclamation"  # Exclamation when ready to make
		CoffeeState.BREWING:
			speech_bubbles.visible = true
			speech_bubbles.animation = "Busy"  # Scribble bubble while brewing
		CoffeeState.READY_TO_DRINK:
			speech_bubbles.visible = true
			speech_bubbles.animation = "Exclamation"  # Exclamation when ready to drink
		CoffeeState.CONSUMED:
			speech_bubbles.visible = false  # No speech bubble during speed buff
			
# Public method for main_room to call when speed buff expires
func on_speed_buff_expired():
	"""Called by main_room when the 30-second speed buff expires"""
	if current_state == CoffeeState.CONSUMED:
		reset_to_idle_state()
		
func reset_to_idle_state():
	"""Reset coffee to IDLE state and start the 30-second spawn timer"""
	current_state = CoffeeState.IDLE
	
	# Force everything to reset to initial state
	coffee_sprite.animation = "empty"
	coffee_light.animation = "default"
	coffee_light.visible = false  # Force light to be invisible
	speech_bubbles.visible = false
	
	# Reset all variables
	player_nearby = false
	
	# Hide progress bar if visible
	if game_ui and game_ui.progress_bar.visible:
		game_ui.hide_progress_bar()
	
	respawn_timer.start()  # Start 30-second timer to become ready again
	print("Coffee reset to idle - will be ready again in 30 seconds...")
