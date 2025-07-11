# main room.gs
extends Node2D

# Game state
var game_time_elapsed = 0.0 # count UP from 0
var is_game_active = false
var fail_count = 0
var max_fails = 3
var task_counter = 1

# Coffee logic
var coffee_buff_active = false
var coffee_buff_time_remaining = 0.0
var coffee_buff_duration = 30.0
var player_node: CharacterBody2D
var coffee_location_node: Node2D

# Difficulty progression variables
var base_spawn_time = 5.0
var min_spawn_time = 1.0  # Changed from 2.0 to 1.0 for maximum chaos!
var current_spawn_time = 5.0
var speed_increase_interval = 30.0  # Every 30 seconds
var last_speed_increase_time = 0.0

# Timers
@onready var task_spawn_timer = Timer.new()

var active_tasks = {}  # Dictionary to track active tasks
var all_task_locations = []  # Full list for later
var current_task_locations = []  # What we're using now

# UI (we'll add a simple label for now)
var ui_label: Label
var score = 0
@onready var hud_lives = $HUD_lives

var menu_manager: Control

func _ready():
	setup_ui()
	setup_timers()
	setup_task_locations()
	
	# Get references to player and coffee
	player_node = get_tree().get_first_node_in_group("player")
	
	#make sure the main room can be paused
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Try to find coffee node - adjust path as needed
	coffee_location_node = $Coffee
	if not coffee_location_node:
		coffee_location_node = $Kitchen/Coffee  # Try this path
	
	# Setup menus instead of auto-starting
	setup_menu_manager()
	
func setup_menu_manager():
	# Load and create menu manager
	var MenuManagerScene = preload("res://menu_manager.gd")
	menu_manager = Control.new()
	menu_manager.set_script(MenuManagerScene)
	add_child(menu_manager)
	
	# Initialize menu manager with references
	menu_manager.initialize(self, player_node)
	
	# Connect menu signals
	menu_manager.start_game_requested.connect(_on_start_game_requested)
	menu_manager.restart_game_requested.connect(_on_restart_game_requested)
	menu_manager.resume_game_requested.connect(_on_resume_game_requested)

func setup_task_locations():
	# Full list (for later when you add more)
	all_task_locations = [
		$PushpalDesk1,
		$PushpalDesk2,
		$PushpalDesk3,
		$Printer,
		$Computer,
		$Computer2, 
		# $Kitchen
	]
	
	# Use all three pushpal desks plus printer and computers
	current_task_locations = [
		$PushpalDesk1,
		$PushpalDesk2,
		$PushpalDesk3,
		$Printer,
		$Computer,
		$Computer2,
	]
	
	print("Using ", current_task_locations.size(), " task locations: all three pushpal desks + printer")
	
func setup_ui():
	# Create a simple UI label
	ui_label = Label.new()
	ui_label.position = Vector2(20, 20)
	ui_label.add_theme_font_size_override("font_size", 24)
	add_child(ui_label)
	update_ui()

func setup_timers():
	# Task spawn timer - triggers every 5 seconds after initial spawn
	add_child(task_spawn_timer)
	task_spawn_timer.wait_time = 5.0
	task_spawn_timer.timeout.connect(_on_spawn_cycle)

func _process(delta):
	if is_game_active:
		game_time_elapsed += delta
		
		# Check if we should increase difficulty
		check_difficulty_increase()
		
		# Handle coffee buff countdown
		if coffee_buff_active:
			coffee_buff_time_remaining -= delta
			
			if coffee_buff_time_remaining <= 0:
				deactivate_coffee_buff()
		
		update_ui()

func update_ui():
	var minutes = int(game_time_elapsed) / 60
	var seconds = int(game_time_elapsed) % 60
	var base_text = "Time: %02d:%02d | Tasks: %d | Fails: %d/%d | Score: %d" % [minutes, seconds, task_counter, fail_count, max_fails, score]
	
	# Add coffee buff status if active
	if coffee_buff_active:
		var buff_seconds = int(coffee_buff_time_remaining)
		ui_label.text = base_text + " | ☕ BOOST: %ds" % buff_seconds
	else:
		ui_label.text = base_text
		
func start_game():
	is_game_active = true
	fail_count = 0
	game_time_elapsed = 0.0
	task_counter = 0
	
	# Reset difficulty system
	current_spawn_time = base_spawn_time
	last_speed_increase_time = 0.0
	task_spawn_timer.wait_time = current_spawn_time
	
	# Initial spawn: One random task
	spawn_initial_tasks()
	
	# Start the timer with initial spawn time
	task_spawn_timer.start()
	
	# Start coffee system
	if coffee_location_node and coffee_location_node.has_method("start_coffee_system"):
		coffee_location_node.start_coffee_system()
		
func spawn_initial_tasks():
	# Spawn one random task at the beginning
	var random_location = current_task_locations[randi() % current_task_locations.size()]
	spawn_task_at_location(random_location)

func _on_spawn_cycle():
	if not is_game_active:
		return
	
	task_counter += 1
	
	# Spawn 1 more random task at an inactive location
	spawn_random_task()

func spawn_random_task():
	# Find locations that don't have active tasks
	var available_locations = []
	for location in current_task_locations:
		if location.name not in active_tasks:
			available_locations.append(location)
	
	if available_locations.size() == 0:
		return
	
	var chosen_location = available_locations[randi() % available_locations.size()]
	spawn_task_at_location(chosen_location)
	
func spawn_task_at_location(location_node):
	var task_name = location_node.name
	
	# Create a timer for this specific task
	var task_timer = Timer.new()
	add_child(task_timer)
	task_timer.wait_time = 15.0  # 15 seconds to complete
	task_timer.one_shot = true
	task_timer.timeout.connect(_on_task_failed.bind(task_name))
	task_timer.start()
	
	# Store the active task
	active_tasks[task_name] = {
		"timer": task_timer,
		"location": location_node
	}
	
	# Set visual indicator - make it yellow for active task
	if location_node.has_method("set_task_active"):
		location_node.set_task_active(true)
	
func _on_task_failed(task_name: String):
	# Clean up the failed task
	if task_name in active_tasks:
		var location_node = active_tasks[task_name].location
		
		# Reset visual indicator
		if location_node.has_method("set_task_active"):
			location_node.set_task_active(false)
			
		active_tasks[task_name].timer.queue_free()
		active_tasks.erase(task_name)
	
	add_fail()
	
# Add this function for when player completes a task
# Update your complete_task function:
func complete_task(task_name: String):
	if task_name in active_tasks:
		var location_node = active_tasks[task_name].location
		
		# Reset visual indicator
		if location_node.has_method("set_task_active"):
			location_node.set_task_active(false)
		
		# Stop and clean up the timer
		active_tasks[task_name].timer.stop()
		active_tasks[task_name].timer.queue_free()
		active_tasks.erase(task_name)
		
		# Add points
		score += 10
	
func _on_game_won():
	end_game(true)

func add_fail():
	fail_count += 1
	
	# Update HUD lives
	if hud_lives and fail_count <= 3:
		hud_lives.get_node("Life_0%d/Fired" % fail_count).visible = true
	
	update_ui()    # Update UI immediately to show the new fail count
	
	if fail_count >= max_fails:
		print("GAME OVER! Too many fails!")
		end_game(false)

func end_game(won: bool):
	is_game_active = false
	task_spawn_timer.stop()
	
	# Stop all active task timers
	for task_name in active_tasks:
		active_tasks[task_name].timer.stop()
		active_tasks[task_name].timer.queue_free()
	active_tasks.clear()
	
	# Show game over menu instead of just updating UI
	if menu_manager:
		menu_manager.show_game_over_menu(won, score, game_time_elapsed)

func _on_coffee_available():
	if not is_game_active:
		return
	
	if coffee_location_node and coffee_location_node.has_method("set_task_active"):
		coffee_location_node.set_task_active(true)
	else:
		print("Error: Coffee node not found or doesn't have set_task_active method")
		
func activate_coffee_buff():
	if coffee_buff_active:
		return
	
	coffee_buff_active = true
	coffee_buff_time_remaining = coffee_buff_duration
	
	# Double the player's speed
	if player_node:
		var old_speed = player_node.speed
		player_node.speed *= 2
	else:
		print("ERROR: Player node not found!")
		
func deactivate_coffee_buff():
	if not coffee_buff_active:
		return
	
	coffee_buff_active = false
	coffee_buff_time_remaining = 0.0
	
	# Reset player speed to normal
	if player_node:
		player_node.speed /= 2
	
	# Notify coffee that buff expired
	if coffee_location_node and coffee_location_node.has_method("on_speed_buff_expired"):
		coffee_location_node.on_speed_buff_expired()
		
# Signal handlers for menu manager
func _on_start_game_requested():
	start_game()

func _on_restart_game_requested():
	reset_game()
	start_game()

func _on_resume_game_requested():
	pass

# Add this new function:
func check_difficulty_increase():
	# Check if we've passed a 30-second interval
	var current_interval = int(game_time_elapsed / speed_increase_interval)
	var last_interval = int(last_speed_increase_time / speed_increase_interval)
	
	if current_interval > last_interval and current_spawn_time > min_spawn_time:
		# Time to increase difficulty!
		increase_difficulty()
		last_speed_increase_time = game_time_elapsed

# Add this new function:
func increase_difficulty():
	var old_spawn_time = current_spawn_time
	current_spawn_time = max(current_spawn_time - 1.0, min_spawn_time)
	
	# Update the timer for future spawns
	task_spawn_timer.wait_time = current_spawn_time
	
	# Placeholder for visual/audio feedback
	show_speed_increase_feedback(old_spawn_time, current_spawn_time)
	
	print("DIFFICULTY INCREASED! Spawn time: %.1fs -> %.1fs" % [old_spawn_time, current_spawn_time])

# Add this placeholder function for feedback:
func show_speed_increase_feedback(old_time: float, new_time: float):
	# TODO: Add visual/audio feedback here
	# Ideas: Screen flash, sound effect, UI message
	
	# Placeholder - you can add visual effects later
	if ui_label:
		# Flash the UI briefly to show speed increase
		var original_color = ui_label.modulate
		ui_label.modulate = Color.RED
		
		# Reset color after brief flash
		await get_tree().create_timer(0.2).timeout
		ui_label.modulate = original_color
		
func reset_game():
	# Stop all timers
	task_spawn_timer.stop()
	
	# Clear active tasks
	for task_name in active_tasks:
		active_tasks[task_name].timer.stop()
		active_tasks[task_name].timer.queue_free()
		# Reset task locations
		var location_node = active_tasks[task_name].location
		if location_node.has_method("set_task_active"):
			location_node.set_task_active(false)
	active_tasks.clear()
	
	# Reset ALL task locations to ensure no lingering tasks
	for location in all_task_locations:
		if location.has_method("set_task_active"):
			location.set_task_active(false)
		# Also reset blinking systems if they exist
		if location.has_method("reset_blinking"):
			location.reset_blinking()
	
	# Reset HUD lives
	if hud_lives:
		for i in range(1, 4):
			var life_node = hud_lives.get_node("Life_0%d/Fired" % i)
			if life_node:
				life_node.visible = false
	
	# Reset coffee buff
	if coffee_buff_active:
		deactivate_coffee_buff()
	
	# Reset coffee system
	if coffee_location_node and coffee_location_node.has_method("reset_coffee_system"):
		coffee_location_node.reset_coffee_system()
	
	# Reset player position
	if player_node:
		player_node.position = Vector2(500, 300)
	
	# Reset game variables
	game_time_elapsed = 0.0
	fail_count = 0
	task_counter = 1
	score = 0
	is_game_active = false
	
	# Reset difficulty system
	current_spawn_time = base_spawn_time
	last_speed_increase_time = 0.0
	task_spawn_timer.wait_time = current_spawn_time
	
	# Update UI to reflect reset state
	update_ui()
