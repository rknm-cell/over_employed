extends Node2D

# Game state
var game_time_elapsed = 0.0 # count UP from 0
var is_game_active = false
var fail_count = 0
var max_fails = 3
var task_counter = 1

# Coffee logic
var coffee_spawn_timer: Timer
var coffee_buff_active = false
var coffee_buff_time_remaining = 0.0
var coffee_buff_duration = 30.0
var player_node: CharacterBody2D
var coffee_location_node: Node2D

# Timers
@onready var task_spawn_timer = Timer.new()

var active_tasks = {}  # Dictionary to track active tasks
var all_task_locations = []  # Full list for later
var current_task_locations = []  # What we're using now

# UI (we'll add a simple label for now)
var ui_label: Label
var score = 0


func _ready():
	print("=== MAIN ROOM DEBUG ===")
	print("Main room scene loaded!")
	
	setup_ui()
	setup_timers()
	setup_task_locations()
	
	# Get references to player and coffee
	player_node = get_tree().get_first_node_in_group("player")
	
	# Try to find coffee node - adjust path as needed
	coffee_location_node = $Coffee
	if not coffee_location_node:
		coffee_location_node = $Kitchen/Coffee  # Try this path
	
	print("Player found: ", player_node != null)
	print("Coffee found: ", coffee_location_node != null)
	if coffee_location_node:
		print("Coffee node name: ", coffee_location_node.name)
	
	start_game() 	# Auto-start for testing (remove this later)

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
	
	# Coffee spawn timer - triggers at 60 seconds
	coffee_spawn_timer = Timer.new()
	add_child(coffee_spawn_timer)
	coffee_spawn_timer.wait_time = 6.0
	coffee_spawn_timer.one_shot = true
	coffee_spawn_timer.timeout.connect(_on_coffee_available)

func _process(delta):
	if is_game_active:
		game_time_elapsed += delta
		
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
	print("Starting game...")
	is_game_active = true
	fail_count = 0
	game_time_elapsed = 0.0
	task_counter = 1
	
	# Initial spawn: One random task
	spawn_initial_tasks()
	
	# Start the 5-second cycle timer
	task_spawn_timer.start()
	# Start coffee timer
	coffee_spawn_timer.start()
	
func spawn_initial_tasks():
	# Spawn one random task at the beginning
	var random_location = current_task_locations[randi() % current_task_locations.size()]
	spawn_task_at_location(random_location)
	
	print("Initial task spawned at: ", random_location.name)

func _on_spawn_cycle():
	if not is_game_active:
		return
	
	task_counter += 1
	print("5-second cycle! Task counter now: ", task_counter)
	
	# Spawn 1 more random task at an inactive location
	spawn_random_task()

func spawn_random_task():
	# Find locations that don't have active tasks
	var available_locations = []
	for location in current_task_locations:
		if location.name not in active_tasks:
			available_locations.append(location)
	
	if available_locations.size() == 0:
		print("All locations are active!")
		return
	
	var chosen_location = available_locations[randi() % available_locations.size()]
	spawn_task_at_location(chosen_location)
	
func spawn_task_at_location(location_node):
	var task_name = location_node.name
	print("Spawning task at: ", task_name)
	
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
	
	print("Task active at ", task_name, " - 15 seconds to complete!")
	
func _on_task_failed(task_name: String):
	print("Task FAILED at: ", task_name)
	
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
		print("Task COMPLETED at: ", task_name)
		
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
		print("Score: ", score)
	
func _on_game_won():
	print("YOU WIN! Survived 3 minutes!")
	end_game(true)

func add_fail():
	fail_count += 1
	print("Task failed! Fails: ", fail_count, "/", max_fails)
	
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
	
	if won:
		ui_label.text += " - YOU WIN!"
	else:
		ui_label.text += " - GAME OVER!"
	
	print("Game ended. Won: ", won)

func _on_coffee_available():
	if not is_game_active:
		return
	
	print("60 seconds reached - Coffee is now available!")
	
	if coffee_location_node and coffee_location_node.has_method("set_task_active"):
		coffee_location_node.set_task_active(true)
	else:
		print("Error: Coffee node not found or doesn't have set_task_active method")
		
func activate_coffee_buff():
	if coffee_buff_active:
		print("Coffee buff already active!")
		return
	
	print("Coffee buff activated! 2x speed for 30 seconds!")
	coffee_buff_active = true
	coffee_buff_time_remaining = coffee_buff_duration
	
	# Double the player's speed
	if player_node:
		var old_speed = player_node.speed
		player_node.speed *= 2
		print("Player speed increased from ", old_speed, " to ", player_node.speed)
	else:
		print("ERROR: Player node not found!")
		
func deactivate_coffee_buff():
	if not coffee_buff_active:
		return
	
	print("Coffee buff expired! Speed back to normal.")
	coffee_buff_active = false
	coffee_buff_time_remaining = 0.0
	
	# Reset player speed to normal
	if player_node:
		player_node.speed /= 2  # Divide by 2 to get back to original speed
		print("Player speed reset to: ", player_node.speed)
