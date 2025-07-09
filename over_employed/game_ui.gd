# GameUI.gd - Attach this to a CanvasLayer node in your main scene
extends CanvasLayer

@onready var text_input_container = VBoxContainer.new()
@onready var text_input_label = Label.new()
@onready var text_input_field = LineEdit.new()
@onready var player_status_label = Label.new()
@onready var progress_bar = ProgressBar.new()

var current_interaction_target = null
var player_inventory = []

signal text_submitted(text: String, target: Node)

func _ready():
	setup_ui()

func setup_ui():
	# Text input container (hidden by default)
	text_input_container.position = Vector2(50, 50)
	text_input_container.size = Vector2(300, 100)
	text_input_container.visible = false
	
	# Text input label
	text_input_label.text = "Type command:"
	text_input_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Text input field
	text_input_field.placeholder_text = "Enter command..."
	text_input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Player status label (for inventory)
	player_status_label.position = Vector2(0, 0)  # Will be positioned near player
	player_status_label.add_theme_color_override("font_color", Color.YELLOW)
	player_status_label.visible = false
	
	# Progress bar (for printer fixing)
	progress_bar.position = Vector2(400, 300)
	progress_bar.size = Vector2(200, 30)
	progress_bar.visible = false
	progress_bar.max_value = 100
	
	# Add to scene
	text_input_container.add_child(text_input_label)
	text_input_container.add_child(text_input_field)
	add_child(text_input_container)
	add_child(player_status_label)
	add_child(progress_bar)
	
	# Connect signals
	text_input_field.text_submitted.connect(_on_text_submitted)

func show_text_input(target: Node, prompt: String = "Type command:"):
	current_interaction_target = target
	text_input_label.text = prompt
	text_input_field.text = ""
	text_input_container.visible = true
	text_input_field.grab_focus()

func hide_text_input():
	text_input_container.visible = false
	current_interaction_target = null
	text_input_field.release_focus()

func _on_text_submitted(text: String):
	if current_interaction_target:
		text_submitted.emit(text.strip_edges().to_lower(), current_interaction_target)
	hide_text_input()

func add_to_inventory(item: String):
	if not item in player_inventory:
		player_inventory.append(item)
		show_inventory_status()

func remove_from_inventory(item: String):
	player_inventory.erase(item)
	if player_inventory.is_empty():
		hide_inventory_status()
	else:
		show_inventory_status()

func has_item(item: String) -> bool:
	return item in player_inventory

func show_inventory_status():
	player_status_label.text = "Carrying: " + ", ".join(player_inventory)
	player_status_label.visible = true
	
	# Position near player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_status_label.global_position = player.global_position + Vector2(30, -50)
	
	# Hide after 3 seconds
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(hide_inventory_status)

func hide_inventory_status():
	player_status_label.visible = false

func show_progress_bar(duration: float, description: String = "Processing..."):
	progress_bar.visible = true
	progress_bar.value = 0
	
	var label = progress_bar.get_child(0) if progress_bar.get_child_count() > 0 else null
	if not label:
		label = Label.new()
		label.position = Vector2(0, -25)
		progress_bar.add_child(label)
	
	label.text = description
	
	# Animate progress bar
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100, duration)
	tween.tween_callback(hide_progress_bar)

func hide_progress_bar():
	progress_bar.visible = false
