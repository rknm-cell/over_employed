extends Node2D

@onready var kitchenBody = $KitchenBody/IslandVisual
@onready var interaction_area = $KitchenInteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()
var player_nearby = false
var is_active = false

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
		print("Player can interact with kitchen")

func _on_player_exited(body):

	if body.name == "Player":
		player_nearby = false
		print("Player left kitchen area")

func activate_monitor():
	is_active = true
	kitchenBody.color = Color.GREEN
	play_ding_sound()
	print("Kitchen activated!")

func play_ding_sound():

	# Generate a simple ding sound
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.1
	audio_player.stream = stream
	audio_player.play()
