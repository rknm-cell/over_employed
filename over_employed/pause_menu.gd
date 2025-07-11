extends Control

# Pause menu script for the Over Employed game
# Handles pause functionality during gameplay

# Preload scenes
const MainMenuScene = preload("res://main_menu.tscn")
const SettingsMenuScene = preload("res://settings_menu.tscn")

# UI elements
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

# Store the previous scene to return to
var previous_scene: String = ""

func _ready():
	# Connect button signals
	resume_button.pressed.connect(_on_resume_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Connect mouse hover signals
	resume_button.mouse_entered.connect(_on_resume_button_mouse_entered)
	resume_button.mouse_exited.connect(_on_resume_button_mouse_exited)
	settings_button.mouse_entered.connect(_on_settings_button_mouse_entered)
	settings_button.mouse_exited.connect(_on_settings_button_mouse_exited)
	main_menu_button.mouse_entered.connect(_on_main_menu_button_mouse_entered)
	main_menu_button.mouse_exited.connect(_on_main_menu_button_mouse_exited)
	quit_button.mouse_entered.connect(_on_quit_button_mouse_entered)
	quit_button.mouse_exited.connect(_on_quit_button_mouse_exited)
	
	# Set focus to resume button for keyboard navigation
	resume_button.grab_focus()
	
	# Hide the pause menu initially
	visible = false
	
	# Make sure this scene can process input
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	# Toggle pause menu with ESC key
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume_button_pressed()
		else:
			show_pause_menu()

func show_pause_menu():
	# Store the current scene
	previous_scene = get_tree().current_scene.scene_file_path
	
	# Show the pause menu
	visible = true
	
	# Pause the game
	get_tree().paused = true
	
	# Set focus to resume button
	resume_button.grab_focus()

func hide_pause_menu():
	# Hide the pause menu
	visible = false
	
	# Resume the game
	get_tree().paused = false

func _on_resume_button_pressed():
	hide_pause_menu()

func _on_settings_button_pressed():
	# Hide pause menu and go to settings
	hide_pause_menu()
	get_tree().change_scene_to_file("res://settings_menu.tscn")

func _on_main_menu_button_pressed():
	# Resume the game first, then go to main menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()

# Mouse hover effects
func _on_resume_button_mouse_entered():
	resume_button.modulate = Color(1.1, 1.1, 1.1)

func _on_resume_button_mouse_exited():
	resume_button.modulate = Color(1, 1, 1)

func _on_settings_button_mouse_entered():
	settings_button.modulate = Color(1.1, 1.1, 1.1)

func _on_settings_button_mouse_exited():
	settings_button.modulate = Color(1, 1, 1)

func _on_main_menu_button_mouse_entered():
	main_menu_button.modulate = Color(1.1, 1.1, 1.1)

func _on_main_menu_button_mouse_exited():
	main_menu_button.modulate = Color(1, 1, 1)

func _on_quit_button_mouse_entered():
	quit_button.modulate = Color(1.1, 1.1, 1.1)

func _on_quit_button_mouse_exited():
	quit_button.modulate = Color(1, 1, 1) 