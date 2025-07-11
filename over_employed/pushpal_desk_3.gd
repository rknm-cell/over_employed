# pushpal_desk_3.gd
extends Node2D

@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

# New sprite nodes for visual indicators
@onready var task_bubble = $TaskBubble
@onready var instruction_bubble = $InstructionBubble

var player_nearby = false
var has_active_task = false

# Zone task variables
var player_in_zone = false
var zone_timer = 0.0
var zone_duration = 2.0  # 2 seconds to complete
var game_ui: CanvasLayer
var zone_indicator: ColorRect  # Visual zone indicator

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
	
	# Setup zone visual indicator
	setup_zone_indicator()
	
	# Hide both initially
	task_bubble.visible = false
	instruction_bubble.visible = false

func setup_zone_indicator():
	# Create a visual indicator for the zone
	zone_indicator = ColorRect.new()
	
	# Match the size and position of the interaction area
	var interaction_shape = interaction_area.get_child(0).shape as RectangleShape2D
	zone_indicator.size = interaction_shape.size
	zone_indicator.position = interaction_area.get_child(0).position - (interaction_shape.size / 2)
	
	# Style the zone indicator
	zone_indicator.color = Color(0.8, 0.8, 0.8, 0.3)  # Light grey with transparency
	zone_indicator.visible = false
	
	add_child(zone_indicator)

func _process(delta):
	if has_active_task and player_in_zone:
		zone_timer += delta
		
		# Update progress bar (counting UP like desk 2)
		var progress = (zone_timer / zone_duration) * 100
		if game_ui and game_ui.progress_bar.visible:
			game_ui.progress_bar.value = progress
		
		if zone_timer >= zone_duration:
			complete_task()

func _on_player_entered(body):
	if body.name == "Player":
		player_nearby = true
		
		if has_active_task:
			player_in_zone = true
			zone_timer = 0.0  # Reset timer when entering
			
			# Show progress bar
			if game_ui:
				game_ui.show_progress_bar(zone_duration, "Stay in zone...")
			
			print("Player entered zone - starting countdown")
		
		update_visual_state()

func _on_player_exited(body):
	if body.name == "Player":
		player_nearby = false
		player_in_zone = false
		zone_timer = 0.0  # Reset timer when leaving
		
		# Hide progress bar
		if game_ui and game_ui.progress_bar.visible:
			game_ui.hide_progress_bar()
		
		print("Player left zone - resetting countdown")
		update_visual_state()

func complete_task():
	print("Zone task completed at ", name)
	
	# Hide progress bar
	if game_ui:
		game_ui.hide_progress_bar()
	
	player_in_zone = false
	zone_timer = 0.0
	
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
	$DeskBody/ComputerSprite.animation = "on" if active else "off"
	
	# Show/hide zone indicator
	zone_indicator.visible = active
	
	if not active:
		# Clean up zone task state when task becomes inactive
		player_in_zone = false
		zone_timer = 0.0
		if game_ui and game_ui.progress_bar.visible:
			game_ui.hide_progress_bar()
	
	update_visual_state()
	
	if active:
		print(name, " now has an active zone task!")
	else:
		print(name, " task cleared")

func update_visual_state():
	if has_active_task:
		if player_nearby:
			# For zone task, show different instruction
			task_bubble.visible = false
			instruction_bubble.visible = true  # You might want to change this sprite to show "Stay in zone"
		else:
			# Show task bubble, hide instruction
			task_bubble.visible = true
			instruction_bubble.visible = false
	else:
		# No active task - hide both
		task_bubble.visible = false
		instruction_bubble.visible = false
