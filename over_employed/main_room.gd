extends Node2D

# Game state
var game_time_left = 180.0  # 3 minutes in seconds
var is_game_active = false
var fail_count = 0
var max_fails = 3
var active_tasks = {}  # Dictionary to track active tasks
var task_locations = []  # Array of task nodes
var score = 0

# Timers
@onready var main_timer = Timer.new()
@onready var task_spawn_timer = Timer.new()

# UI (we'll add a simple label for now)
var ui_label: Label

func _ready():
    setup_ui()
    setup_timers()
    setup_task_locations()
    start_game() 	# Auto-start for testing (remove this later)

func setup_task_locations():
    # Get all the task location nodes
    task_locations = [
        $PushpalDesk1,
        #$PushpalDesk2, 
        #$PushpalDesk3,
        #$Computer,
        #$Computer2,
        #$Printer,
        #$Kitchen
    ]
    print("Found ", task_locations.size(), " task locations")
    
func setup_ui():
    # Create a simple UI label
    ui_label = Label.new()
    ui_label.position = Vector2(20, 20)
    ui_label.add_theme_font_size_override("font_size", 24)
    add_child(ui_label)
    update_ui()

func setup_timers():
    # Main game timer
    add_child(main_timer)
    main_timer.wait_time = game_time_left
    main_timer.one_shot = true
    main_timer.timeout.connect(_on_game_won)
    
    # Task spawn timer  
    add_child(task_spawn_timer)
    task_spawn_timer.wait_time = 2.0
    task_spawn_timer.timeout.connect(_on_spawn_task)


func _process(delta):
    if is_game_active:
        update_ui()

func update_ui():
    var minutes = int(main_timer.time_left) / 60
    var seconds = int(main_timer.time_left) % 60
    ui_label.text = "Time: %02d:%02d | Fails: %d/%d | Score: %d" % [minutes, seconds, fail_count, max_fails, score]

func start_game():
    print("Starting game...")
    is_game_active = true
    fail_count = 0
    main_timer.start()
    task_spawn_timer.start()

func _on_spawn_task():
    if not is_game_active:
        return
        
    # Pick a random task location that doesn't already have an active task
    var available_locations = []
    for location in task_locations:
        if location.name not in active_tasks:
            available_locations.append(location)
    
    if available_locations.size() == 0:
        print("No available task locations!")
        return
    
    var chosen_location = available_locations[randi() % available_locations.size()]
    spawn_task_at_location(chosen_location)
    
func spawn_task_at_location(location_node):
    var task_name = location_node.name
    print("Spawning task at: ", task_name)
    
    # Create a timer for this specific task
    var task_timer = Timer.new()
    add_child(task_timer)
    task_timer.wait_time = 5.0  # 15 seconds to complete
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
    main_timer.stop()
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
