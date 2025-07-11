# printer.gd - Updated with auto-start and Space key mechanics
extends Node2D

@onready var printer_visual = $PrinterBody/PrinterVisual  # Your printer rectangle
@onready var printer_light = $PrinterBody/PrinterLight  # Printer light indicator
@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()
@onready var task_bubble = $TaskBubble
@onready var instruction_bubble = $InstructionBubble
@onready var printer_bubble_animation = $PrinterBody/PrinterBubbleAnimation

# Printer states
enum PrinterState { 
	IDLE, 
	OUT_OF_PAPER, 
	PAPER_JAM, 
	FIXING, 
	COMPLETED,
	WAITING_FOR_PAPER_PICKUP,
	WAITING_FOR_PAPER_RETURN
}
var current_state = PrinterState.IDLE
var player_nearby = false

# Paper jam fixing variables
var is_holding_space = false
var space_hold_time = 0.0
var space_hold_duration = 2.0  # Changed from 5 to 2 seconds
var fixing_paper_jam = false

# Blinking variables (from computer.gd)
var is_blinking = false
var blink_timer: Timer
var task_start_time = 0.0
var slow_blink_timer: Timer
var fast_blink_timer: Timer
var solid_red_timer: Timer

# Sounds
@onready var sounds = {
	"success": preload("res://sounds/success.wav"),
	"error": preload("res://sounds/error.wav"),
	"printer_working": preload("res://sounds/printer.wav")
}

var game_ui: CanvasLayer

func _ready():
	add_child(audio_player)
	add_to_group("printer")
	
	# Find the GameUI node
	game_ui = get_tree().get_first_node_in_group("game_ui")
	
	# Setup blinking timers (from computer.gd)
	blink_timer = Timer.new()
	blink_timer.one_shot = false
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	add_child(blink_timer)
	
	# Setup phase timers
	slow_blink_timer = Timer.new()
	slow_blink_timer.one_shot = true
	slow_blink_timer.timeout.connect(start_slow_blinking)
	add_child(slow_blink_timer)
	
	fast_blink_timer = Timer.new()
	fast_blink_timer.one_shot = true
	fast_blink_timer.timeout.connect(start_fast_blinking)
	add_child(fast_blink_timer)
	
	solid_red_timer = Timer.new()
	solid_red_timer.one_shot = true
	solid_red_timer.timeout.connect(start_solid_red)
	add_child(solid_red_timer)
	
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	
	task_bubble.visible = false
	instruction_bubble.visible = false
	
	# Initialize printer light to off state
	printer_light.animation = "off"
	
	# Hide bubble animation initially (like computer.gd)
	printer_bubble_animation.visible = false
	printer_bubble_animation.animation = "default"

func set_task_active(active: bool):
	if active:
		start_random_printer_task()
	else:
		# Reset printer to idle when task fails/completes
		current_state = PrinterState.IDLE
		update_printer_visual()
		update_visual_state()
		# Stop blinking when task is completed or failed
		stop_blinking()

func start_random_printer_task():
	# Randomly choose between out of paper (blue) or paper jam (red)
	var random_outcome = randi() % 2  # 0 or 1
	
	match random_outcome:
		0:  # Out of paper
			current_state = PrinterState.OUT_OF_PAPER
			play_sound("error")
		1:  # Paper jam
			current_state = PrinterState.PAPER_JAM
			play_sound("error")
	
	update_printer_visual()
	update_visual_state()
	
	# Start blinking timers when task is assigned
	task_start_time = Time.get_time_dict_from_system()["second"]
	start_blinking_timers()
	
	# Flash the light briefly to indicate task start
	flash_task_start()

func _input(event):
	# Handle Space key press for paper refill (when player has paper)
	if event.is_action_pressed("ui_accept") and player_nearby:  # Space key
		handle_space_key_press()

func _process(delta):
	# Handle holding Space key for paper jam
	if current_state == PrinterState.PAPER_JAM and player_nearby and not fixing_paper_jam:
		if Input.is_action_pressed("ui_accept"):  # Space key
			if not is_holding_space:
				# Start holding Space
				is_holding_space = true
				space_hold_time = 0.0
				game_ui.show_progress_bar(space_hold_duration, "Fixing paper jam (hold Space)...")
			
			# Update hold time
			space_hold_time += delta
			
			# Update progress bar value
			var progress = (space_hold_time / space_hold_duration) * 100
			if game_ui and game_ui.progress_bar.visible:
				game_ui.progress_bar.value = progress
			
			# Check if hold duration is complete
			if space_hold_time >= space_hold_duration:
				fix_paper_jam()
		else:
			# Player let go of Space key - reset progress
			if is_holding_space:
				reset_space_hold()

func handle_space_key_press():
	match current_state:
		PrinterState.OUT_OF_PAPER:
			attempt_refill_paper()
		PrinterState.WAITING_FOR_PAPER_RETURN:
			attempt_refill_paper()
		PrinterState.PAPER_JAM:
			pass  # Paper jam uses hold, not press
		PrinterState.IDLE:
			pass
		_:
			pass

func attempt_refill_paper():
	if not game_ui.has_item("paper"):
		# Player doesn't have paper - need to go get it from shelf
		current_state = PrinterState.WAITING_FOR_PAPER_PICKUP
		
		# Activate the paper shelf
		var shelf = get_tree().get_first_node_in_group("paper_shelf")
		if shelf:
			shelf.set_task_active(true)
		
		update_visual_state()  # Hide printer bubbles
		return
	
	# Player has paper, start refilling
	refill_paper()

func refill_paper():
	current_state = PrinterState.FIXING
	
	# Remove paper from inventory
	game_ui.remove_from_inventory("paper")
	
	# Notify shelf to respawn paper
	var shelf = get_tree().get_first_node_in_group("paper_shelf")
	if shelf:
		shelf.respawn_paper()
	
	update_printer_visual()
	
	# Brief fixing delay
	await get_tree().create_timer(1.0).timeout
	
	# Task completed
	complete_task()

func fix_paper_jam():
	fixing_paper_jam = true
	current_state = PrinterState.FIXING
	
	# Reset Space key variables
	is_holding_space = false
	space_hold_time = 0.0
	
	# Hide progress bar
	if game_ui:
		game_ui.hide_progress_bar()
	
	update_printer_visual()
	
	# Brief fixing delay
	await get_tree().create_timer(1.0).timeout
	
	# Task completed
	fixing_paper_jam = false
	complete_task()

func complete_task():
	current_state = PrinterState.COMPLETED
	play_sound("success")
	update_printer_visual()
	
	# Notify MainRoom task is complete
	var main_room = get_parent()
	main_room.complete_task(name)
	
	# Flash the light to show completion
	flash_printer_color()
	
	# Brief delay then go idle
	await get_tree().create_timer(1.0).timeout
	current_state = PrinterState.IDLE
	update_printer_visual()
	update_visual_state()

func reset_space_hold():
	is_holding_space = false
	space_hold_time = 0.0
	if game_ui and game_ui.progress_bar.visible:
		game_ui.hide_progress_bar()

func flash_printer_color():
	var original_animation = printer_light.animation
	var flash_count = 6
	
	for i in flash_count:
		printer_light.animation = "green"  # Flash green
		await get_tree().create_timer(0.1).timeout
		printer_light.animation = original_animation  # Return to original state
		await get_tree().create_timer(0.1).timeout

func flash_task_start():
	# Flash red briefly to indicate task start
	var original_animation = printer_light.animation
	printer_light.animation = "red"
	await get_tree().create_timer(0.2).timeout
	printer_light.animation = original_animation

func update_printer_visual():
	match current_state:
		PrinterState.IDLE:
			printer_light.animation = "off"  # Light off when idle
		PrinterState.OUT_OF_PAPER:
			printer_light.animation = "yellow"  # Yellow light for out of paper
		PrinterState.PAPER_JAM:
			printer_light.animation = "red"  # Red light for paper jam
		PrinterState.FIXING:
			printer_light.animation = "yellow"  # Yellow light while fixing
		PrinterState.COMPLETED:
			printer_light.animation = "green"  # Green light when completed
		PrinterState.WAITING_FOR_PAPER_PICKUP:
			printer_light.animation = "yellow"  # Yellow light when waiting for paper
		PrinterState.WAITING_FOR_PAPER_RETURN:
			printer_light.animation = "yellow"  # Yellow light when waiting for paper return

func update_visual_state():
	if current_state == PrinterState.IDLE or current_state == PrinterState.WAITING_FOR_PAPER_PICKUP:
		# No active task on printer - hide bubble animation (like computer.gd)
		printer_bubble_animation.visible = false
	else:
		# Has active task - show appropriate animation
		printer_bubble_animation.visible = true
		
		if player_nearby:
			# Show instruction animation based on state
			match current_state:
				PrinterState.PAPER_JAM:
					printer_bubble_animation.animation = "hold"
				PrinterState.OUT_OF_PAPER, PrinterState.WAITING_FOR_PAPER_RETURN:
					printer_bubble_animation.animation = "press"
				_:
					printer_bubble_animation.animation = "press"
		else:
			# Show task animation when player is away
			printer_bubble_animation.animation = "task"

# Blinking functions (from computer.gd)
func start_blinking_timers():
	# Start 5-second timer for initial blinking
	slow_blink_timer.wait_time = 5.0
	slow_blink_timer.start()
	
	# Start 10-second timer for fast blinking (5 seconds after slow blinking starts)
	fast_blink_timer.wait_time = 10.0
	fast_blink_timer.start()
	
	# Start 14-second timer for solid red (4 seconds after fast blinking starts)
	solid_red_timer.wait_time = 14.0
	solid_red_timer.start()

func start_slow_blinking():
	if current_state != PrinterState.IDLE and current_state != PrinterState.WAITING_FOR_PAPER_PICKUP:
		is_blinking = true
		blink_timer.wait_time = 0.5
		blink_timer.start()
		printer_bubble_animation.modulate = Color.WHITE  # Reset to white when starting

func start_fast_blinking():
	if current_state != PrinterState.IDLE and current_state != PrinterState.WAITING_FOR_PAPER_PICKUP:
		is_blinking = true
		blink_timer.wait_time = 0.25
		blink_timer.start()
		printer_bubble_animation.modulate = Color.WHITE  # Reset to white when starting

func start_solid_red():
	if current_state != PrinterState.IDLE and current_state != PrinterState.WAITING_FOR_PAPER_PICKUP:
		is_blinking = false
		blink_timer.stop()
		printer_bubble_animation.modulate = Color.RED

func stop_blinking():
	is_blinking = false
	blink_timer.stop()
	printer_bubble_animation.modulate = Color.WHITE

func reset_blinking():
	"""Reset blinking system completely - called when game resets"""
	is_blinking = false
	blink_timer.stop()
	slow_blink_timer.stop()
	fast_blink_timer.stop()
	solid_red_timer.stop()
	printer_bubble_animation.modulate = Color.WHITE
	task_start_time = 0.0

func _on_blink_timer_timeout():
	if is_blinking and current_state != PrinterState.IDLE and current_state != PrinterState.WAITING_FOR_PAPER_PICKUP:
		# Toggle between normal and red
		if printer_bubble_animation.modulate == Color.WHITE:
			printer_bubble_animation.modulate = Color.RED
		else:
			printer_bubble_animation.modulate = Color.WHITE

func _on_player_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		update_visual_state()

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		update_visual_state()
		# Reset Space key progress if player leaves
		if is_holding_space:
			reset_space_hold()

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		audio_player.stream = sounds[sound_name]
		audio_player.play()
