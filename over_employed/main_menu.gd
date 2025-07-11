extends Control

# Main menu script for the Over Employed game
# Handles navigation between main menu and game

# Preload the main game scene
const MainGameScene = preload("res://main_room.tscn")

# UI elements
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready():
	# Connect button signals
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Connect mouse hover signals
	start_button.mouse_entered.connect(_on_start_button_mouse_entered)
	start_button.mouse_exited.connect(_on_start_button_mouse_exited)
	settings_button.mouse_entered.connect(_on_settings_button_mouse_entered)
	settings_button.mouse_exited.connect(_on_settings_button_mouse_exited)
	quit_button.mouse_entered.connect(_on_quit_button_mouse_entered)
	quit_button.mouse_exited.connect(_on_quit_button_mouse_exited)
	
	# Set focus to start button for keyboard navigation
	start_button.grab_focus()
	
	# Make sure this scene can process input
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	# Allow ESC key to quit from main menu
	if event.is_action_pressed("ui_cancel"):
		_on_quit_button_pressed()

func _on_start_button_pressed():
	# Transition to the main game scene
	# Use change_scene_to_file for Godot 4.x
	get_tree().change_scene_to_file("res://main_room.tscn")

func _on_settings_button_pressed():
	# Transition to the settings menu
	get_tree().change_scene_to_file("res://settings_menu.tscn")

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()

# Optional: Add some visual feedback for button interactions
func _on_start_button_mouse_entered():
	start_button.modulate = Color(1.1, 1.1, 1.1)

func _on_start_button_mouse_exited():
	start_button.modulate = Color(1, 1, 1)

func _on_settings_button_mouse_entered():
	settings_button.modulate = Color(1.1, 1.1, 1.1)

func _on_settings_button_mouse_exited():
	settings_button.modulate = Color(1, 1, 1)

func _on_quit_button_mouse_entered():
	quit_button.modulate = Color(1.1, 1.1, 1.1)

func _on_quit_button_mouse_exited():
	quit_button.modulate = Color(1, 1, 1) 
