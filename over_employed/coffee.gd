# coffee.gd - Coffee making mechanics
extends Node2D

@onready var coffee_visual = $CoffeeBody/CoffeeShape  # Your coffee rectangle
@onready var coffee_area = $CoffeeArea
@onready var audio_player = AudioStreamPlayer2D.new()

# Add these bubble references after your existing @onready variables:
@onready var task_bubble = $TaskBubble
@onready var instruction_bubble = $InstructionBubble

# Add bubble texture preloads:
@onready var bubble_exclamation = preload("res://art/speech_bubbles/bubble_exclamation.png")
@onready var bubble_hold_space = preload("res://art/speech_bubbles/bubble_hold_space.png")
@onready var bubble_cluster = preload("res://art/speech_bubbles/bubble_cluster.png")
@onready var bubble_press_space = preload("res://art/speech_bubbles/bubble_press_space.png")

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
	
	# Setup bubble textures and hide them initially
	task_bubble.visible = false
	instruction_bubble.visible = false
	
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
	update_visual_state()

func _input(event):
	if event.is_action_pressed("ui_accept") and player_nearby: 
		print("coffee Key pressed") # C key
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
				print("Drinking coffee... (hold Space for 5 seconds)")
				game_ui.show_progress_bar(c_hold_duration, "Drinking coffee (hold Space)...")
				update_coffee_visual()
			
			# Continue drinking (this runs every frame while holding)
			c_hold_time += delta
			print("Hold time: ", c_hold_time, " / ", c_hold_duration)
			
			# Update progress bar value
			var progress = (c_hold_time / c_hold_duration) * 100
			if game_ui and game_ui.progress_bar.visible:
				game_ui.progress_bar.value = progress
			
			# Check if hold duration is complete
			if c_hold_time >= c_hold_duration:
				print("DRINKING COMPLETE! Calling finish_drinking_coffee()")
				finish_drinking_coffee()
		else:
			# Player let go of Space key - reset progress
			if is_drinking:
				print("Player released Space key - resetting progress")
				reset_c_hold()
	
	# Also handle the DRINKING state (in case player releases and presses again)
	elif current_state == CoffeeState.DRINKING and player_nearby:
		if Input.is_action_pressed("ui_accept"):
			# Continue drinking
			c_hold_time += delta
			print("Hold time: ", c_hold_time, " / ", c_hold_duration)
			
			var progress = (c_hold_time / c_hold_duration) * 100
			if game_ui and game_ui.progress_bar.visible:
				game_ui.progress_bar.value = progress
			
			if c_hold_time >= c_hold_duration:
				print("DRINKING COMPLETE! Calling finish_drinking_coffee()")
				finish_drinking_coffee()
		else:
			# Player let go - reset
			print("Player released Space key - resetting progress")
			reset_c_hold()

func handle_space_key_press():
	match current_state:
		CoffeeState.READY_TO_MAKE:
			start_making_coffee()
		CoffeeState.BREWING:
			print("Coffee is still brewing... wait a moment")
		CoffeeState.READY_TO_DRINK:
			print("Hold Space for 5 seconds to drink coffee")
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
	update_visual_state()
	
	# Wait 15 seconds for brewing
	var brewing_timer = get_tree().create_timer(15.0)
	brewing_timer.timeout.connect(coffee_finished_brewing)

func coffee_finished_brewing():
	current_state = CoffeeState.READY_TO_DRINK
	print("Coffee is ready! Come drink it (hold C for 5 seconds)")
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
	
	print("Coffee consumed! Speed buff activated!")
	play_sound("success")
	update_coffee_visual()
	update_visual_state()
	
	# ADD DEBUG: Notify MainRoom to start speed buff
	var main_room = get_parent()
	print("Main room found: ", main_room != null)
	if main_room.has_method("activate_coffee_buff"):
		print("Calling activate_coffee_buff...")
		main_room.activate_coffee_buff()
	else:
		print("ERROR: MainRoom doesn't have activate_coffee_buff method!")

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
		update_visual_state()
		match current_state:
			CoffeeState.READY_TO_MAKE:
				print("Press Space to start making coffee")
			CoffeeState.BREWING:
				print("Coffee is brewing...")
			CoffeeState.READY_TO_DRINK:
				print("Hold Space for 5 seconds to drink coffee")
			CoffeeState.DRINKING:
				print("Drinking coffee...")
			CoffeeState.CONSUMED:
				print("Coffee task completed!")

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		update_visual_state()
		# Reset drinking progress if player leaves
		if is_holding_c:
			reset_c_hold()

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		audio_player.stream = sounds[sound_name]
		audio_player.play()
	else:
		print("Sound not found: ", sound_name)
		
func set_task_active(active: bool):
	if active:
		print("Coffee activated by MainRoom!")
		coffee_ready_to_make()
	else:
		# Reset coffee to idle if needed
		current_state = CoffeeState.IDLE
		update_coffee_visual()

func update_visual_state():
	if current_state == CoffeeState.IDLE:
		# No active task - hide both bubbles
		task_bubble.visible = false
		instruction_bubble.visible = false
	else:
		# Determine which textures to show based on state
		var task_texture = get_task_bubble_texture()
		var instruction_texture = get_instruction_bubble_texture()
		
		if task_texture:
			task_bubble.texture = task_texture
			
			if player_nearby and instruction_texture:  # Only show instruction if we have a texture
				# Player is nearby AND we have an instruction - show instruction, hide task bubble
				task_bubble.visible = false
				instruction_bubble.texture = instruction_texture
				instruction_bubble.visible = true
			else:
				# Player not nearby OR no instruction available - show task bubble, hide instruction
				task_bubble.visible = true
				instruction_bubble.visible = false
		else:
			# No texture - hide both
			task_bubble.visible = false
			instruction_bubble.visible = false
			
func get_task_bubble_texture():
	match current_state:
		CoffeeState.READY_TO_MAKE:
			return bubble_exclamation
		CoffeeState.BREWING:
			return bubble_cluster
		CoffeeState.READY_TO_DRINK:
			return bubble_exclamation
		_:
			return null

func get_instruction_bubble_texture():
	match current_state:
		CoffeeState.READY_TO_MAKE:
			return bubble_press_space
		CoffeeState.BREWING:
			return null # No instruction during brewing
		CoffeeState.READY_TO_DRINK:
			return bubble_hold_space
		_:
			return bubble_hold_space
