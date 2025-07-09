# printer.gd - Updated printer script with paper mechanics
extends Node2D

@onready var printer_visual = $PrinterBody/PrinterVisual  # Your printer rectangle
@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()


# Printer states
enum PrinterState { READY, WORKING, OUT_OF_PAPER, PAPER_JAM, FIXING, COMPLETED }
var current_state = PrinterState.READY
var player_nearby = false

# Paper jam fixing variables
var is_holding_j = false
var j_hold_time = 0.0
var j_hold_duration = 5.0
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
	else:
		game_ui.text_submitted.connect(_on_text_submitted)
	
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	
	update_printer_visual()

func _input(event):
	if event.is_action_pressed("ui_accept") and player_nearby:
		interact_with_printer()

func _process(delta):
	# Handle holding J key for paper jam
	if current_state == PrinterState.PAPER_JAM and player_nearby and not fixing_paper_jam:
		if Input.is_key_pressed(KEY_J):
			if not is_holding_j:
				# Start holding J
				is_holding_j = true
				j_hold_time = 0.0
				print("Hold J to fix paper jam...")
				game_ui.show_progress_bar(j_hold_duration, "Fixing paper jam (hold J)...")
			
			# Update hold time
			j_hold_time += delta
			
			# Update progress bar value
			var progress = (j_hold_time / j_hold_duration) * 100
			if game_ui.progress_bar.visible:
				game_ui.progress_bar.value = progress
			
			# Check if hold duration is complete
			if j_hold_time >= j_hold_duration:
				fix_paper_jam()
		else:
			# Player let go of J key - reset progress
			if is_holding_j:
				reset_j_hold()
	
	# Auto-reset completed state after a few seconds
	if current_state == PrinterState.COMPLETED:
		if not is_instance_valid(completed_timer):
			completed_timer = get_tree().create_timer(3.0)
			completed_timer.timeout.connect(reset_to_ready)

var completed_timer: SceneTreeTimer

func reset_to_ready():
	if current_state == PrinterState.COMPLETED:
		current_state = PrinterState.READY
		update_printer_visual()
		print("Printer ready for next task")

func reset_j_hold():
	is_holding_j = false
	j_hold_time = 0.0
	if game_ui and game_ui.progress_bar.visible:
		game_ui.hide_progress_bar()
	print("Released J key - progress reset")

func interact_with_printer():
	match current_state:
		PrinterState.READY:
			use_printer()
		PrinterState.WORKING:
			print("Printer is currently working...")
		PrinterState.OUT_OF_PAPER:
			game_ui.show_text_input(self, "Printer needs paper. Type 'fix' to repair:")
		PrinterState.PAPER_JAM:
			print("Hold 'J' key for 5 seconds to fix paper jam")
		PrinterState.FIXING:
			print("Printer is currently being fixed...")
		PrinterState.COMPLETED:
			print("Task completed! Printer ready for next use.")
			current_state = PrinterState.READY
			update_printer_visual()

func use_printer():
	current_state = PrinterState.WORKING
	update_printer_visual()
	
	# Randomly break the printer or work successfully
	var random_outcome = randi() % 3  # 0, 1, or 2
	
	# Small delay to show "working" state
	await get_tree().create_timer(1.0).timeout
	
	match random_outcome:
		0:  # Printer works successfully
			current_state = PrinterState.COMPLETED
			play_sound("printer_working")
			print("Printer working! Document printed successfully.")
		1:  # Out of paper
			current_state = PrinterState.OUT_OF_PAPER
			play_sound("error")
			print("Printer out of paper!")
		2:  # Paper jam
			current_state = PrinterState.PAPER_JAM
			play_sound("error")
			print("Paper jam!")
	
	update_printer_visual()

func _on_text_submitted(text: String, target: Node):
	if target != self:
		return
	
	if text == "fix":
		attempt_fix_out_of_paper()
	else:
		print("Unknown command: " + text)
		play_sound("error")

func attempt_fix_out_of_paper():
	if current_state != PrinterState.OUT_OF_PAPER:
		print("Printer doesn't need paper!")
		return
		
	if game_ui.has_item("paper"):
		fix_with_paper()
	else:
		flash_printer_color()
		print("You need paper to fix the printer!")

func fix_with_paper():
	current_state = PrinterState.FIXING
	fixing_paper_jam = false  # This is for out of paper, not jam
	print("Adding paper to printer...")
	
	# Show progress bar
	game_ui.show_progress_bar(5.0, "Loading paper...")
	
	# Remove paper from inventory
	game_ui.remove_from_inventory("paper")
	
	# Notify shelf to respawn paper
	var shelf = get_tree().get_first_node_in_group("paper_shelf")
	if shelf:
		shelf.respawn_paper()
	
	# Wait 5 seconds
	await get_tree().create_timer(5.0).timeout
	
	# Printer is now fixed and shows completion
	current_state = PrinterState.COMPLETED
	play_sound("success")
	print("Printer fixed! Paper loaded.")
	update_printer_visual()

func fix_paper_jam():
	fixing_paper_jam = true
	current_state = PrinterState.FIXING
	print("Paper jam cleared!")
	
	# Reset J key variables
	is_holding_j = false
	j_hold_time = 0.0
	
	# Wait a moment then mark as completed
	await get_tree().create_timer(0.5).timeout
	
	current_state = PrinterState.COMPLETED
	play_sound("success")
	fixing_paper_jam = false
	print("Printer fixed! Jam cleared.")
	update_printer_visual()

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
		PrinterState.READY:
			printer_visual.color = Color.GRAY
		PrinterState.WORKING:
			printer_visual.color = Color.YELLOW  # Shows it's processing
		PrinterState.OUT_OF_PAPER:
			printer_visual.color = Color.BLUE
		PrinterState.PAPER_JAM:
			printer_visual.color = Color.RED
		PrinterState.FIXING:
			printer_visual.color = Color.ORANGE
		PrinterState.COMPLETED:
			printer_visual.color = Color.GREEN  # Only green when task is completed!

func _on_player_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		print("Press Space to use printer")

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		# Reset J key progress if player leaves
		if is_holding_j:
			reset_j_hold()

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		audio_player.stream = sounds[sound_name]
		audio_player.play()
	else:
		print("Sound not found: ", sound_name)
