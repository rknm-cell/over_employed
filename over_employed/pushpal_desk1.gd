extends Node2D

@onready var monitor = $DeskBody/Monitor
@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

var player_nearby = false
var is_active = false

@onready var typing_sound = preload("res://sounds/laptop_typing.wav")
@onready var computerOn_sound = preload("res://sounds/computer_start.wav")
func _ready():
	# Setup audio
	add_child(audio_player)
	
	# Connect signals
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)

func _input(event):
	if event.is_action_pressed("ui_accept") and player_nearby and not is_active:
		activate_monitor()

func _on_player_entered(body):
	if body.name == "Player":
		player_nearby = true
		print("Player can interact with desk")

func _on_player_exited(body):
	if body.name == "Player":
		player_nearby = false
		monitor.color = Color.BLACK
		audio_player.stop()
		print("Player left desk area")
		
	is_active = false

func activate_monitor():
	is_active = true
	monitor.color = Color.GREEN
	computerOn()
	await get_tree().create_timer(4.0).timeout
	print("Monitor activated!")
	typing()
	print("player typing")

func computerOn():
	audio_player.stream = computerOn_sound
	audio_player.play()
	
func typing():
	# Generate a simple ding sound
	audio_player.stream = typing_sound
	audio_player.play()
