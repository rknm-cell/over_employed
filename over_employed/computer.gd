extends Node2D

@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

# New sprite nodes for visual indicators
@onready var task_bubble = $TaskBubble
@onready var instruction_bubble = $InstructionBubble

var player_nearby = false
var has_active_task = false

@onready var typing_sound = preload("res://sounds/laptop_typing2.wav")
@onready var computerOn_sound = preload("res://sounds/computer_start.wav")


func _ready():
	# Setup audio
	add_child(audio_player)
	
	# Connect signals
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	
	# Hide both initially
	task_bubble.visible = false
	instruction_bubble.visible = false

func _input(event):
	if event.is_action_pressed("ui_accept") and player_nearby and has_active_task:
		complete_task()

func _on_player_entered(body):
	if body.name == "Player":
		player_nearby = true
		update_visual_state()
		print("Player can interact with computer")

func _on_player_exited(body):
	if body.name == "Player":
		player_nearby = false
		update_visual_state()
		print("Player left computer area")

func complete_task():
	print("Completing task at ", name)
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
	update_visual_state()  # Add this line
	$ComputerBody/ComputerSprite.animation = "on"
	
	if active:
		print(name, " now has an active task!")
	else:
		print(name, " task cleared")

func update_visual_state():
	if has_active_task:
		if player_nearby:
			# Show instruction, hide task bubble
			task_bubble.visible = false
			instruction_bubble.visible = true
		else:
			# Show task bubble, hide instruction
			task_bubble.visible = true
			instruction_bubble.visible = false
	else:
		# No active task - hide both
		task_bubble.visible = false
		instruction_bubble.visible = false 
