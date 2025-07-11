#computer.gd
extends Node2D

@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

# Use the existing speech bubble animation system like desk 1's simple sprites
@onready var task_bubble = $ComputerBody/SpeechBubbleAnimation
@onready var instruction_bubble = $ComputerBody/SpeechBubbleAnimation  # Same node, different animations

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
	
	# Hide speech bubble initially (use default animation which has no frames)
	task_bubble.animation = "default"
	task_bubble.visible = false

func _input(event):
	if event.is_action_pressed("ui_accept") and player_nearby and has_active_task:
		complete_task()

func _on_player_entered(body):
	if body.name == "Player":
		player_nearby = true
		update_visual_state()

func _on_player_exited(body):
	if body.name == "Player":
		player_nearby = false
		update_visual_state()

func complete_task():
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
	
	# Computer screen logic: on when task active, off when completed
	if active:
		$ComputerBody/ComputerSprite.animation = "on"  # Black screen when task active
	else:
		$ComputerBody/ComputerSprite.animation = "off"  # White screen when task completed

func update_visual_state():
	if has_active_task:
		if player_nearby:
			# Show press space instruction, hide task bubble
			task_bubble.visible = true
			task_bubble.animation = "press"
		else:
			# Show task exclamation, hide instruction
			task_bubble.visible = true
			task_bubble.animation = "task"
	else:
		# No active task - hide speech bubble completely
		task_bubble.visible = false
		task_bubble.animation = "default"
