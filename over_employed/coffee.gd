# coffee.gd - Coffee making mechanics
extends Node2D

@onready var coffee_visual = $CoffeeBody/CoffeeShape  # Your coffee rectangle
@onready var coffee_area = $CoffeeArea
@onready var audio_player = AudioStreamPlayer2D.new()

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
	if not game_ui:
		print("Warning: GameUI not found!")
	
	coffee_area.body_entered.connect(_on_player_entered)
	coffee_area.body_exited.connect(_on_player_exited)
	
	# Start the 1-minute timer for initial coffee ding
	start_coffee_timer()
	update_coffee_visual()

func start_coffee_timer():
	print("Coffee will be ready in 1 minute...")
	initial_ding_timer = get_tree().create_timer(5.0)  # 1 minute
	initial_ding_timer.timeout.connect(coffee_ready_to_make)

func coffee_ready_to_make():
	current_state = CoffeeState.READY_TO_MAKE
	play_sound("ding")
	print("Coffee is ready to make! Go to coffee area and press C.")
	update_coffee_visual()

func _input(event):
	# Handle C key for coffee interactions
	if event.is_action_pressed("coffee"):
		print("C key pressed! Player nearby: ", player_nearby, " State: ", current_state)
		
	if event.is_action_pressed("coffee") and player_nearby: 
		print("coffee Key pressed") # C key
		handle_c_key_press()

func _process(delta):
	# Handle holding C key for drinking coffee
	if current_state == CoffeeState.READY_TO_DRINK and player_nearby and not is_drinking:
		if Input.is_action_pressed("coffee"):  # C key
			if not is_holding_c:
				# Start holding C
				is_holding_c = true
				c_hold_time = 0.0
				is_drinking = true
				current_state = CoffeeState.DRINKING
				print("Drinking coffee... (hold C for 5 seconds)")
				game_ui.show_progress_bar(c_hold_duration, "Drinking coffee (hold C)...")
				update_coffee_visual()
			
			# Update hold time
			c_hold_time += delta
			
			# Update progress bar value
			var progress = (c_hold_time / c_hold_duration) * 100
			if game_ui and game_ui.progress_bar.visible:
				game_ui.progress_bar.value = progress
			
			# Check if hold duration is complete
			if c_hold_time >= c_hold_duration:
				finish_drinking_coffee()
		else:
			# Player let go of C key - reset progress
			if is_holding_c:
				reset_c_hold()

func handle_c_key_press():
	match current_state:
		CoffeeState.READY_TO_MAKE:
			start_making_coffee()
		CoffeeState.BREWING:
			print("Coffee is still brewing... wait a moment")
		CoffeeState.READY_TO_DRINK:
			print("Hold C for 5 seconds to drink coffee")
		CoffeeState.DRINKING:
			print("Already drinking coffee...")
		CoffeeState.CONSUMED:
			print("Coffee already consumed")
		_:
			print("No coffee action available")

func start_making_coffee():
	current_state = CoffeeState.BREWING
	print("Making coffee... this will take 15 seconds")
	play_sound("brewing")
	update_coffee_visual()
	
	# Wait 15 seconds for brewing
	var brewing_timer = get_tree().create_timer(15.0)
	brewing_timer.timeout.connect(coffee_finished_brewing)

func coffee_finished_brewing():
	current_state = CoffeeState.READY_TO_DRINK
	print("Coffee is ready! Come drink it (hold C for 5 seconds)")
	play_sound("ding")
	update_coffee_visual()

func finish_drinking_coffee():
	current_state = CoffeeState.CONSUMED
	is_drinking = false
	is_holding_c = false
	c_hold_time = 0.0
	
	# Hide progress bar
	if game_ui:
		game_ui.hide_progress_bar()
	
	print("Coffee consumed! Task complete.")
	play_sound("success")
	update_coffee_visual()

func reset_c_hold():
	is_holding_c = false
	c_hold_time = 0.0
	is_drinking = false
	current_state = CoffeeState.READY_TO_DRINK  # Back to ready to drink
	
	if game_ui and game_ui.progress_bar.visible:
		game_ui.hide_progress_bar()
	
	print("Released C key - drinking progress reset")
	update_coffee_visual()

func update_coffee_visual():
	match current_state:
		CoffeeState.IDLE:
			coffee_visual.color = Color.GRAY  # Neutral
		CoffeeState.READY_TO_MAKE:
			coffee_visual.color = Color.YELLOW  # Ready to start
		CoffeeState.BREWING:
			coffee_visual.color = Color.ORANGE  # Brewing in progress
		CoffeeState.READY_TO_DRINK:
			coffee_visual.color = Color("#8B4513")  # Brown - coffee ready
		CoffeeState.DRINKING:
			coffee_visual.color = Color("#D2691E")  # Lighter brown - drinking
		CoffeeState.CONSUMED:
			coffee_visual.color = Color.GREEN  # Task completed

func _on_player_entered(body):
	print("Body entered coffee area: ", body.name, " Is player group: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		player_nearby = true
		print("Player is now nearby coffee!")
		match current_state:
			CoffeeState.READY_TO_MAKE:
				print("Press C to start making coffee")
			CoffeeState.BREWING:
				print("Coffee is brewing...")
			CoffeeState.READY_TO_DRINK:
				print("Hold C for 5 seconds to drink coffee")
			CoffeeState.DRINKING:
				print("Drinking coffee...")
			CoffeeState.CONSUMED:
				print("Coffee task completed!")
			_:
				print("Coffee area")

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		# Reset drinking progress if player leaves
		if is_holding_c:
			reset_c_hold()

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		audio_player.stream = sounds[sound_name]
		audio_player.play()
	else:
		print("Sound not found: ", sound_name)
