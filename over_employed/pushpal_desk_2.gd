# pushpal_desk_2.gd
extends Node2D

@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

# New sprite nodes for visual indicators
@onready var task_bubble = $TaskBubble
@onready var instruction_bubble = $InstructionBubble

# Load the hold space bubble texture
@onready var bubble_exclamation = preload("res://art/speech_bubbles/bubble_exclamation.png")
@onready var bubble_hold_space = preload("res://art/speech_bubbles/bubble_hold_space.png")

var player_nearby = false
var has_active_task = false

# Hold space variables
var is_holding_space = false
var space_hold_time = 0.0
var space_hold_duration = 2.0  # 2 seconds
var game_ui: CanvasLayer

@onready var typing_sound = preload("res://sounds/laptop_typing2.wav")
@onready var computerOn_sound = preload("res://sounds/computer_start.wav")

func _ready():
	# Setup audio
	add_child(audio_player)
	
	# Find the GameUI node for progress bar
	game_ui = get_tree().get_first_node_in_group("game_ui")
	
	# Connect signals
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	
	# Hide both initially
	task_bubble.visible = false
	instruction_bubble.visible = false

func _process(delta):
	# Handle holding Space key
	if has_active_task and player_nearby:
		if Input.is_action_pressed("ui_accept"):  # Space key
			if not is_holding_space:
				# Start holding Space
				is_holding_space = true
				space_hold_time = 0.0
				if game_ui:
					game_ui.show_progress_bar(space_hold_duration, "Working on task (hold Space)...")
			
			# Update hold time
			space_hold_time += delta
			
			# Update progress bar value
			var progress = (space_hold_time / space_hold_duration) * 100
			if game_ui and game_ui.progress_bar.visible:
				game_ui.progress_bar.value = progress
			
			# Check if hold duration is complete
			if space_hold_time >= space_hold_duration:
				complete_task()
		else:
			# Player let go of Space key - reset progress
			if is_holding_space:
				reset_space_hold()

func reset_space_hold():
	is_holding_space = false
	space_hold_time = 0.0
	if game_ui and game_ui.progress_bar.visible:
		game_ui.hide_progress_bar()

func _on_player_entered(body):
	if body.name == "Player":
		player_nearby = true
		update_visual_state()

func _on_player_exited(body):
	if body.name == "Player":
		player_nearby = false
		update_visual_state()
		# Reset progress if player leaves
		if is_holding_space:
			reset_space_hold()

func complete_task():
	is_holding_space = false
	space_hold_time = 0.0
	
	# Hide progress bar
	if game_ui:
		game_ui.hide_progress_bar()
	
	computerOn()
	typing()
	
	var main_room = get_parent()
	main_room.complete_task(name)

func computerOn():
	audio_player.stream = computerOn_sound
	audio_player.play()
	
func typing():
	audio_player.stream = typing_sound
	audio_player.play()
	
func set_task_active(active: bool):
	has_active_task = active
	update_visual_state()
	$DeskBody/ComputerSprite.animation = "on"

func update_visual_state():
	if has_active_task:
		if player_nearby:
			# Show hold space instruction, hide task bubble
			task_bubble.visible = false
			instruction_bubble.visible = true
			instruction_bubble.texture = bubble_hold_space  # Use hold space bubble
		else:
			# Show task bubble, hide instruction
			task_bubble.visible = true
			instruction_bubble.visible = false
			task_bubble.texture = bubble_exclamation  # Use exclamation bubble
	else:
		# No active task - hide both
		task_bubble.visible = false
		instruction_bubble.visible = false
