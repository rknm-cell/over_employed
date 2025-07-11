# paper_shelf.gd - Updated with space key pickup
extends Node2D
# Create a smaller white rectangle for paper
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

	
	# Set speech bubble to default (no animation)
	speech_bubble.animation = "default"
	
	# Ensure shelf starts with no active task
	has_active_task = false
	update_visual_state()



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
	play_sound("paper_pickup")
	print("Picked up paper!")
	
	# Deactivate shelf task and reactivate printer
	set_task_active(false)
	
	# Tell printer to show "return to printer" state
	var printer = get_tree().get_first_node_in_group("printer")  # You might need to add printer to a group
	if printer:
		printer.current_state = printer.PrinterState.WAITING_FOR_PAPER_RETURN
		printer.update_visual_state()

func respawn_paper():
	# Called when printer is fixed
	has_paper = true
	print("Paper restocked on shelf!")



func _on_player_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		update_visual_state()
		if has_active_task:
			if has_paper:
				print("Press P to pick up paper")
			else:
				print("Shelf is empty")
		else:
			print("No active task - paper not available")

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
			speech_bubble.animation = "instruction"
		else:
			# Show task animation when task is active but player not nearby
			speech_bubble.animation = "task"
	else:
		# No active task - show default (no animation)
		speech_bubble.animation = "default"
