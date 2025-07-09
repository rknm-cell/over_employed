extends Node2D

# Game state
var game_time_elapsed = 0.0 # count UP from 0
var is_game_active = false
var fail_count = 0
var max_fails = 3
var task_counter = 1

# Timers
@onready var task_spawn_timer = Timer.new()

var active_tasks = {}  # Dictionary to track active tasks
var all_task_locations = []  # Full list for later
var current_task_locations = []  # What we're using now

# UI (we'll add a simple label for now)
var ui_label: Label
var score = 0


func _ready():
    setup_ui()
    setup_timers()
    setup_task_locations()
    start_game() 	# Auto-start for testing (remove this later)

func setup_task_locations():
    # Full list (for later when you add more)
    all_task_locations = [
        $PushpalDesk1,
        $PushpalDesk2,  # Add back later
        # $Computer,
        # $Computer2, 
        # $Printer,
        # $Kitchen
    ]
    
    # For now, just use what we have
    current_task_locations = [
        $PushpalDesk1,
        $PushpalDesk2
        # AddPushpalDesk2 when ready
    ]
    
    print("Using ", current_task_locations.size(), " task locations for now")
    
func setup_ui():
    # Create a simple UI label
    ui_label = Label.new()
    ui_label.position = Vector2(20, 20)
    ui_label.add_theme_font_size_override("font_size", 24)
    add_child(ui_label)
    update_ui()

func setup_timers():
    # Task spawn timer - triggers every 30 seconds after initial spawn
    add_child(task_spawn_timer)
    task_spawn_timer.wait_time = 30.0
    task_spawn_timer.timeout.connect(_on_spawn_cycle)

func _process(delta):
    if is_game_active:
        game_time_elapsed += delta
        update_ui()

func update_ui():
    var minutes = int(game_time_elapsed) / 60
    var seconds = int(game_time_elapsed) % 60
    ui_label.text = "Time: %02d:%02d | Tasks: %d | Fails: %d/%d | Score: %d" % [minutes, seconds, task_counter, fail_count, max_fails, score]

func start_game():
    print("Starting game...")
    is_game_active = true
    fail_count = 0
    game_time_elapsed = 0.0
    task_counter = 2
    
    # Initial spawn: Always PushpalDesk1 + PushpalDesk2
    spawn_initial_tasks()
    
    # Start the 30-second cycle timer
    task_spawn_timer.start()
    
func spawn_initial_tasks():
    # Always spawn at first 2 locations (when we have them)
    var initial_locations = current_task_locations.slice(0, min(2, current_task_locations.size()))
    
    for location in initial_locations:
        spawn_task_at_location(location)
    
    print("Initial tasks spawned at ", initial_locations.size(), " locations")

func _on_spawn_cycle():
    if not is_game_active:
        return
    
    task_counter += 1
    print("30-second cycle! Task counter now: ", task_counter)
    
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
