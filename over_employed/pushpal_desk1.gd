extends Node2D

@onready var monitor = $DeskBody/Monitor
@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

var player_nearby = false
var is_active = false
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
    if event.is_action_pressed("ui_accept") and player_nearby and not is_active and has_active_task:
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
    # Check if this desk has an active task
    if not has_active_task:
        print("No active task at this desk!")
        return  # Exit early - can't activate without a task
    
    is_active = true
    monitor.color = Color.GREEN  # Green when being worked on
    computerOn()
    await get_tree().create_timer(4.0).timeout
    print("Monitor activated!")
    typing()
    print("player typing")
    
    # Complete the task
    var main_room = get_parent()
    main_room.complete_task(name)
    
    is_active = false # Reset the desk (set_task_active will be called by MainRoom)

func computerOn():
    audio_player.stream = computerOn_sound
    audio_player.play()
    
func typing():
    # Generate a simple ding sound
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
