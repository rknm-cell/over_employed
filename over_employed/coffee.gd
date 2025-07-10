# coffee.gd - Coffee making mechanics
extends Node2D

@onready var coffee_sprite = $CoffeeBody/CoffeeSprite  # Animated coffee sprite
@onready var coffee_light = $CoffeeBody/CoffeeSprite/CoffeeLight  # Coffee light indicator
@onready var coffee_area = $CoffeeArea
@onready var audio_player = AudioStreamPlayer2D.new()

# Speech bubble animations are handled by the AnimatedSprite2D in the scene

# Coffee states
enum CoffeeState { IDLE, READY_TO_MAKE, BREWING, READY_TO_DRINK, DRINKING, CONSUMED }
var current_state = CoffeeState.IDLE
var player_nearby = false

# Drinking variables
var is_holding_c = false
var c_hold_time = 0.0
var c_hold_duration = 5.0
var is_drinking = false

# Sounds
@onready var sounds = {
	"ding": preload("res://sounds/ding.wav"),
	"brewing": preload("res://sounds/brew-start.wav"),
	"success": preload("res://sounds/success.wav")
}

var game_ui: CanvasLayer
var initial_ding_timer: SceneTreeTimer

func _ready():
	add_child(audio_player)
	
	# Find the GameUI node
	game_ui = get_tree().get_first_node_in_group("game_ui")
	
	coffee_area.body_entered.connect(_on_player_entered)
	coffee_area.body_exited.connect(_on_player_exited)
	
	# Start with empty coffee and hide speech bubbles
	coffee_sprite.animation = "empty"
	coffee_light.animation = "default"  # Light off initially
	$CoffeeBody/SpeechBubbles.visible = false
	update_coffee_visual()

func start_coffee_timer():
	initial_ding_timer = get_tree().create_timer(5.0)  # 1 minute
	initial_ding_timer.timeout.connect(coffee_ready_to_make)

func coffee_ready_to_make():
	current_state = CoffeeState.READY_TO_MAKE
	play_sound("ding")
	update_coffee_visual()
	update_visual_state()

func _input(event):
	if event.is_action_pressed("ui_accept") and player_nearby: 
		handle_space_key_press()
		
func _process(delta):
	# Handle holding Space key for drinking coffee
	if current_state == CoffeeState.READY_TO_DRINK and player_nearby:
		if Input.is_action_pressed("ui_accept"):  # press space
			if not is_drinking:
				# Start drinking
				is_drinking = true
				is_holding_c = true
				c_hold_time = 0.0
				current_state = CoffeeState.DRINKING
				game_ui.show_progress_bar(c_hold_duration, "Drinking coffee (hold Space)...")
				update_coffee_visual()
			
			# Continue drinking (this runs every frame while holding)
			c_hold_time += delta
			
			# Update progress bar value
			var progress = (c_hold_time / c_hold_duration) * 100
			if game_ui and game_ui.progress_bar.visible:
				game_ui.progress_bar.value = progress
			
			# Check if hold duration is complete
			if c_hold_time >= c_hold_duration:
				finish_drinking_coffee()
		else:
			# Player let go of Space key - reset progress
			if is_drinking:
				reset_c_hold()
	
	# Also handle the DRINKING state (in case player releases and presses again)
	elif current_state == CoffeeState.DRINKING and player_nearby:
		if Input.is_action_pressed("ui_accept"):
			# Continue drinking
			c_hold_time += delta
			
			var progress = (c_hold_time / c_hold_duration) * 100
			if game_ui and game_ui.progress_bar.visible:
				game_ui.progress_bar.value = progress
			
			if c_hold_time >= c_hold_duration:
				finish_drinking_coffee()
		else:
			# Player let go - reset
			reset_c_hold()

func handle_space_key_press():
	match current_state:
		CoffeeState.READY_TO_MAKE:
			start_making_coffee()
		CoffeeState.BREWING:
			pass
		CoffeeState.READY_TO_DRINK:
			pass
		CoffeeState.DRINKING:
			pass
		CoffeeState.CONSUMED:
			pass
		_:
			pass

func start_making_coffee():
	current_state = CoffeeState.BREWING
	play_sound("brewing")
	$CoffeeBody/SpeechBubbles.animation = "Busy"
	update_coffee_visual()
	update_visual_state()
	
	# Wait 15 seconds for brewing
	var brewing_timer = get_tree().create_timer(15.0)
	brewing_timer.timeout.connect(coffee_finished_brewing)

func coffee_finished_brewing():
	current_state = CoffeeState.READY_TO_DRINK
	play_sound("ding")
	update_coffee_visual()
	update_visual_state()

func finish_drinking_coffee():
	current_state = CoffeeState.CONSUMED
	is_drinking = false
	is_holding_c = false
	c_hold_time = 0.0
	
	# Hide progress bar
	if game_ui:
		game_ui.hide_progress_bar()
	
	play_sound("success")
	update_coffee_visual()
	update_visual_state()
	
	# Hide speech bubbles after a short delay to show completion
	var hide_timer = get_tree().create_timer(2.0)
	hide_timer.timeout.connect(func(): $CoffeeBody/SpeechBubbles.visible = false)
	
	# Notify MainRoom to start speed buff
	var main_room = get_parent()
	if main_room.has_method("activate_coffee_buff"):
		main_room.activate_coffee_buff()

func reset_c_hold():
	is_holding_c = false
	c_hold_time = 0.0
	is_drinking = false
	current_state = CoffeeState.READY_TO_DRINK  # Back to ready to drink
	
	if game_ui and game_ui.progress_bar.visible:
		game_ui.hide_progress_bar()
	
	update_coffee_visual()

func update_coffee_visual():
	match current_state:
		CoffeeState.IDLE:
			coffee_sprite.animation = "empty"  # Empty coffee machine
			coffee_light.animation = "default"  # Light off
		CoffeeState.READY_TO_MAKE:
			coffee_sprite.animation = "empty"  # Still empty but ready to make
			coffee_light.animation = "default"  # Light off
		CoffeeState.BREWING:
			coffee_sprite.animation = "empty"  # Still empty during brewing
			coffee_light.animation = "red"  # Red light while brewing
		CoffeeState.READY_TO_DRINK:
			coffee_sprite.animation = "full"  # Coffee is ready to drink
			coffee_light.animation = "green"  # Green light when ready
		CoffeeState.DRINKING:
			coffee_sprite.animation = "full"  # Still full while drinking
			coffee_light.animation = "green"  # Keep green while drinking
		CoffeeState.CONSUMED:
			coffee_sprite.animation = "empty"  # Back to empty after drinking
			coffee_light.animation = "default"  # Light off

func _on_player_entered(body):
	if body.name == "Player":  # Use simple name check like kitchen
		player_nearby = true
		update_visual_state()

func _on_player_exited(body):
	if body.name == "Player":  # Use simple name check like kitchen
		player_nearby = false
		update_visual_state()
		# Reset drinking progress if player leaves
		if is_holding_c:
			reset_c_hold()

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		audio_player.stream = sounds[sound_name]
		audio_player.play()

# Simple activation function like kitchen's activate_monitor()
func activate_coffee():
	if current_state == CoffeeState.IDLE:
		current_state = CoffeeState.READY_TO_MAKE
		update_coffee_visual()
		update_visual_state()
		play_sound("ding")
	elif current_state == CoffeeState.READY_TO_MAKE:
		start_making_coffee()
	elif current_state == CoffeeState.READY_TO_DRINK:
		pass
		
func set_task_active(active: bool):
	if active:
		coffee_ready_to_make()
	else:
		# Reset coffee to idle if needed
		current_state = CoffeeState.IDLE
		update_coffee_visual()
		update_visual_state()

func update_visual_state():
	var speech_bubbles = $CoffeeBody/SpeechBubbles
	
	if current_state == CoffeeState.IDLE:
		# No active task - hide speech bubbles
		speech_bubbles.visible = false
	else:
		# Show appropriate speech bubble animation based on state
		speech_bubbles.visible = true
		match current_state:
			CoffeeState.READY_TO_MAKE:
				speech_bubbles.animation = "Exclamation"
			CoffeeState.BREWING:
				speech_bubbles.animation = "Busy"
			CoffeeState.READY_TO_DRINK:
				speech_bubbles.animation = "Exclamation"
			CoffeeState.DRINKING:
				speech_bubbles.animation = "Busy"
			CoffeeState.CONSUMED:
				speech_bubbles.animation = "Exclamation"
			_:
				speech_bubbles.visible = false
