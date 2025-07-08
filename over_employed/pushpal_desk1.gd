extends Node2D

@onready var monitor = $DeskBody/Monitor
@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

var player_nearby = false
var has_active_task = false

@onready var typing_sound = preload("res://sounds/laptop_typing.wav")
@onready var computerOn_sound = preload("res://sounds/computer_start.wav")

func _ready():
    # Setup audio
    add_child(audio_player)
    
    # Connect signals
    interaction_area.body_entered.connect(_on_player_entered)
    interaction_area.body_exited.connect(_on_player_exited)

func _input(event):
    if event.is_action_pressed("ui_accept") and player_nearby and has_active_task:
        complete_task()

func _on_player_entered(body):
    if body.name == "Player":
        player_nearby = true
        print("Player can interact with desk")

func _on_player_exited(body):
    if body.name == "Player":
        player_nearby = false
        print("Player left desk area")

func complete_task():
    print("Completing task at ", name)
    
    # Play sounds
    computerOn()
    typing()
    
    # Complete the task immediately
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
    if active:
        monitor.color = Color.YELLOW  # Yellow for active task
        print(name, " now has an active task!")
    else:
        monitor.color = Color.BLACK   # Black when no task
        print(name, " task cleared")
