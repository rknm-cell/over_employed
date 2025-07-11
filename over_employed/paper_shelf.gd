# paper_shelf.gd - Updated with space key pickup and proper visibility control
extends Node2D

@onready var shelf_visual = $ShelfBody/ShelfVisual  # Your shelf rectangle
@onready var paper_visual = $ShelfBody/PaperVisual  # Create a smaller white rectangle for paper
@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

# Use the existing SpeechBubbleAnimation under ShelfBody:
@onready var speech_bubble = $ShelfBody/SpeechBubbleAnimation

var player_nearby = false
var has_paper = true
var has_active_task = false

# Sounds
@onready var sounds = {
	"paper_pickup": preload("res://sounds/paper_pickup.wav"),
	"error": preload("res://sounds/error.wav")
}

var game_ui: CanvasLayer

func _ready():
	add_child(audio_player)
	add_to_group("paper_shelf")
	
	# Find the GameUI node
	game_ui = get_tree().get_first_node_in_group("game_ui")
	if not game_ui:
		print("Warning: GameUI not found!")
	
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	
	# Setup paper visual
	setup_paper_visual()
	update_shelf_visual()
	
	# Hide speech bubble initially (like computer.gd)
	speech_bubble.visible = false
	speech_bubble.animation = "default"
	
	# Ensure shelf starts with no active task
	has_active_task = false

func setup_paper_visual():
	# Create paper visual if it doesn't exist
	if not paper_visual:
		paper_visual = ColorRect.new()
		paper_visual.name = "PaperVisual"
		$ShelfBody.add_child(paper_visual)
	
	# Make paper smaller than shelf and white
	var shelf_size = shelf_visual.size if shelf_visual else Vector2(100, 100)
	paper_visual.size = Vector2(shelf_size.x * 0.4, shelf_size.y * 0.2)  # Smaller rectangle
	paper_visual.position = Vector2(shelf_size.x * 0.3, shelf_size.y * 0.4)  # Centered better
	paper_visual.color = Color.WHITE

func _input(event):
	# Handle space key for paper pickup
	if event.is_action_pressed("ui_accept") and player_nearby:  # Space key
		attempt_take_paper()

func attempt_take_paper():
	if not has_active_task:
		print("No active task - paper not available!")
		play_sound("error")
		return
	
	if not has_paper:
		print("No paper on shelf!")
		play_sound("error")
		return
	
	if game_ui.has_item("paper"):
		print("You already have paper!")
		play_sound("error")
		return
	
	# Take the paper
	take_paper()

func take_paper():
	has_paper = false
	game_ui.add_to_inventory("paper")
	update_shelf_visual()
	play_sound("paper_pickup")
	print("Paper taken")  # Simple console message
	
	# Deactivate shelf task
	set_task_active(false)
	
	# Tell printer to show "return to printer" state
	var printer = get_tree().get_first_node_in_group("printer")
	if printer:
		printer.current_state = printer.PrinterState.WAITING_FOR_PAPER_RETURN
		printer.update_visual_state()

func respawn_paper():
	# Called when printer is fixed
	has_paper = true
	update_shelf_visual()
	print("Paper restocked on shelf!")

func update_shelf_visual():
	if paper_visual:
		paper_visual.visible = has_paper

func _on_player_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		update_visual_state()

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		update_visual_state()

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		audio_player.stream = sounds[sound_name]
		audio_player.play()
	else:
		print("Sound not found: ", sound_name)
		
func set_task_active(active: bool):
	has_active_task = active
	update_visual_state()
	if active:
		print("Paper shelf now has active task!")
	else:
		print("Paper shelf task cleared")

func update_visual_state():
	if has_active_task:
		if player_nearby:
			# Show instruction animation when player is nearby
			speech_bubble.visible = true
			speech_bubble.animation = "instruction"
		else:
			# Show task animation when task is active but player not nearby
			speech_bubble.visible = true
			speech_bubble.animation = "task"
	else:
		# No active task - hide speech bubble completely (like computer.gd)
		speech_bubble.visible = false
		speech_bubble.animation = "default"
