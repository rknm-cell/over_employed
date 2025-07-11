# pushpal_desk_2.gd
extends Node2D

@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

# Use the existing speech bubble animation system like computer
@onready var task_bubble = $DeskBody/ComputerSprite/SpeechBubbleAnimation
@onready var instruction_bubble = $DeskBody/ComputerSprite/SpeechBubbleAnimation  # Same node, different animations

var player_nearby = false
var has_active_task = false

# Blinking variables
var is_blinking = false
var blink_timer: Timer
var task_start_time = 0.0
var slow_blink_timer: Timer
var fast_blink_timer: Timer
var solid_red_timer: Timer

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
	
	# Setup blinking timers
	blink_timer = Timer.new()
	blink_timer.one_shot = false
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	add_child(blink_timer)
	
	# Setup phase timers
	slow_blink_timer = Timer.new()
	slow_blink_timer.one_shot = true
	slow_blink_timer.timeout.connect(start_slow_blinking)
	add_child(slow_blink_timer)
	
	fast_blink_timer = Timer.new()
	fast_blink_timer.one_shot = true
	fast_blink_timer.timeout.connect(start_fast_blinking)
	add_child(fast_blink_timer)
	
	solid_red_timer = Timer.new()
	solid_red_timer.one_shot = true
	solid_red_timer.timeout.connect(start_solid_red)
	add_child(solid_red_timer)
	
	# Find the GameUI node for progress bar
	game_ui = get_tree().get_first_node_in_group("game_ui")
	
	# Connect signals
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	
	# Hide speech bubble initially (use default animation which has no frames)
	task_bubble.animation = "default"
	task_bubble.visible = false

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
	
	if active:
		# Start task timing and blinking only when task is assigned
		task_start_time = Time.get_time_dict_from_system()["second"]
		start_blinking_timers()
		$DeskBody/ComputerSprite.animation = "on"
	else:
		# Stop blinking when task is completed or failed
		stop_blinking()
		$DeskBody/ComputerSprite.animation = "off"
	
	update_visual_state()

func update_visual_state():
	if has_active_task:
		if player_nearby:
			# Show hold space instruction
			task_bubble.visible = true
			task_bubble.animation = "hold"
		else:
			# Show task exclamation
			task_bubble.visible = true
			task_bubble.animation = "task"
	else:
		# No active task - hide speech bubble completely
		task_bubble.visible = false
		task_bubble.animation = "default"

func start_blinking_timers():
	# Start 5-second timer for initial blinking
	slow_blink_timer.wait_time = 5.0
	slow_blink_timer.start()
	
	# Start 10-second timer for fast blinking (5 seconds after slow blinking starts)
	fast_blink_timer.wait_time = 10.0
	fast_blink_timer.start()
	
	# Start 14-second timer for solid red (4 seconds after fast blinking starts)
	solid_red_timer.wait_time = 14.0
	solid_red_timer.start()

func start_slow_blinking():
	if has_active_task:
		is_blinking = true
		blink_timer.wait_time = 0.5
		blink_timer.start()
		task_bubble.modulate = Color.WHITE  # Reset to white when starting

func start_fast_blinking():
	if has_active_task:
		is_blinking = true
		blink_timer.wait_time = 0.25
		blink_timer.start()
		task_bubble.modulate = Color.WHITE  # Reset to white when starting

func start_solid_red():
	if has_active_task:
		is_blinking = false
		blink_timer.stop()
		task_bubble.modulate = Color.RED

func stop_blinking():
	is_blinking = false
	blink_timer.stop()
	task_bubble.modulate = Color.WHITE

func reset_blinking():
	"""Reset blinking system completely - called when game resets"""
	is_blinking = false
	blink_timer.stop()
	slow_blink_timer.stop()
	fast_blink_timer.stop()
	solid_red_timer.stop()
	task_bubble.modulate = Color.WHITE
	task_start_time = 0.0

func _on_blink_timer_timeout():
	if is_blinking and has_active_task and not player_nearby:
		# Only blink when player is not nearby (task bubble is visible)
		if task_bubble.modulate == Color.WHITE:
			task_bubble.modulate = Color.RED
		else:
			task_bubble.modulate = Color.WHITE
