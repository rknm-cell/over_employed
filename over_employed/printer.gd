# printer.gd - Updated with auto-start and P key mechanics
extends Node2D

@onready var printer_visual = $PrinterBody/PrinterVisual  # Your printer rectangle
@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

# Printer states
enum PrinterState { IDLE, OUT_OF_PAPER, PAPER_JAM, FIXING, COMPLETED }
var current_state = PrinterState.IDLE
var player_nearby = false

# Paper jam fixing variables
var is_holding_p = false
var p_hold_time = 0.0
var p_hold_duration = 5.0
var fixing_paper_jam = false

# Sounds
@onready var sounds = {
	"success": preload("res://sounds/success.wav"),
	"error": preload("res://sounds/error.wav"),
	"printer_working": preload("res://sounds/printer.wav")
}

var game_ui: CanvasLayer

func _ready():
	add_child(audio_player)
	
	# Find the GameUI node
	game_ui = get_tree().get_first_node_in_group("game_ui")
	if not game_ui:
		print("Warning: GameUI not found!")
	
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	
	# Auto-start printer task after 2-3 seconds
	await get_tree().create_timer(2.5).timeout
	start_random_printer_task()

func start_random_printer_task():
	# Randomly choose between out of paper (blue) or paper jam (red)
	var random_outcome = randi() % 2  # 0 or 1
	
	match random_outcome:
		0:  # Out of paper
			current_state = PrinterState.OUT_OF_PAPER
			play_sound("error")
			print("Printer out of paper!")
		1:  # Paper jam
			current_state = PrinterState.PAPER_JAM
			play_sound("error")
			print("Paper jam!")
	
	update_printer_visual()

func _input(event):
	# Handle P key press for paper refill (when player has paper)
	if event.is_action_pressed("cancel") and player_nearby:  # P key
		handle_p_key_press()

func _process(delta):
	# Handle holding P key for paper jam
	if current_state == PrinterState.PAPER_JAM and player_nearby and not fixing_paper_jam:
		if Input.is_key_pressed(KEY_P):
			if not is_holding_p:
				# Start holding P
				is_holding_p = true
				p_hold_time = 0.0
				print("Hold P to fix paper jam...")
				game_ui.show_progress_bar(p_hold_duration, "Fixing paper jam (hold P)...")
			
			# Update hold time
			p_hold_time += delta
			
			# Update progress bar value
			var progress = (p_hold_time / p_hold_duration) * 100
			if game_ui and game_ui.progress_bar.visible:
				game_ui.progress_bar.value = progress
			
			# Check if hold duration is complete
			if p_hold_time >= p_hold_duration:
				fix_paper_jam()
		else:
			# Player let go of P key - reset progress
			if is_holding_p:
				reset_p_hold()

func handle_p_key_press():
	match current_state:
		PrinterState.OUT_OF_PAPER:
			attempt_refill_paper()
		PrinterState.PAPER_JAM:
			print("Hold P to fix paper jam")
		PrinterState.IDLE:
			print("Printer is idle - no task active")
		_:
			print("Printer doesn't need fixing")

func attempt_refill_paper():
	if not game_ui.has_item("paper"):
		print("You need paper to refill the printer!")
		flash_printer_color()
		return
	
	# Player has paper, start refilling
	refill_paper()

func refill_paper():
	current_state = PrinterState.FIXING
	print("Refilling printer with paper...")
	
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
	print("Paper jam cleared!")
	
	# Reset P key variables
	is_holding_p = false
	p_hold_time = 0.0
	
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
	print("Printer task completed!")
	update_printer_visual()
	
	# Stay green for 1 second, then go idle
	await get_tree().create_timer(1.0).timeout
	
	# Go back to idle (no color) for 2 seconds before next task
	current_state = PrinterState.IDLE
	update_printer_visual()
	print("Printer idle...")
	
	# Wait 2 seconds then start new task
	await get_tree().create_timer(5.0).timeout
	start_random_printer_task()

func reset_p_hold():
	is_holding_p = false
	p_hold_time = 0.0
	if game_ui and game_ui.progress_bar.visible:
		game_ui.hide_progress_bar()
	print("Released P key - progress reset")

func flash_printer_color():
	var original_color = printer_visual.color
	var flash_count = 6
	
	for i in flash_count:
		printer_visual.color = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		printer_visual.color = original_color
		await get_tree().create_timer(0.1).timeout

func update_printer_visual():
	match current_state:
		PrinterState.IDLE:
			printer_visual.color = Color.GRAY  # Neutral color when no task
		PrinterState.OUT_OF_PAPER:
			printer_visual.color = Color.BLUE
		PrinterState.PAPER_JAM:
			printer_visual.color = Color.RED
		PrinterState.FIXING:
			printer_visual.color = Color.ORANGE
		PrinterState.COMPLETED:
			printer_visual.color = Color.GREEN

func _on_player_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		match current_state:
			PrinterState.OUT_OF_PAPER:
				print("Press P to refill paper (need paper from shelf)")
			PrinterState.PAPER_JAM:
				print("Hold P to fix paper jam")
			PrinterState.COMPLETED:
				print("Task completed!")
			PrinterState.IDLE:
				print("Printer is idle")

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		# Reset P key progress if player leaves
		if is_holding_p:
			reset_p_hold()

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		audio_player.stream = sounds[sound_name]
		audio_player.play()
	else:
		print("Sound not found: ", sound_name)
