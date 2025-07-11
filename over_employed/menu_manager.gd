# menu_manager.gd
extends Control

const MenuPanelScene = preload("res://components/MenuPanel.tscn")
const CustomButtonScene = preload("res://components/CustomButton.tscn")

enum GameState { START_MENU, PLAYING, PAUSED, GAME_OVER }
var current_game_state = GameState.START_MENU

# Menu UI nodes
var start_menu: Control
var pause_menu: Control
var game_over_menu: Control
var pause_button: Button

# Reference to main room and player
var main_room: Node2D
var player_node: CharacterBody2D

# Signals to communicate with MainRoom
signal start_game_requested
signal restart_game_requested
signal resume_game_requested

func _ready():
	# Set up full screen control and make sure it can process when paused
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_menus()
	show_start_menu()

func initialize(main_room_ref: Node2D, player_ref: CharacterBody2D):
	main_room = main_room_ref
	player_node = player_ref

func _input(event):
	# Handle ESC key for pause - make it toggle
	if event.is_action_pressed("ui_cancel"):
		if current_game_state == GameState.PLAYING:
			show_pause_menu()
		elif current_game_state == GameState.PAUSED:
			hide_pause_menu()
			resume_game_requested.emit()

func setup_menus():
	create_start_menu()
	create_pause_menu()
	create_game_over_menu()
	create_pause_button()

# Helper function to setup any menu panel
func setup_menu_panel(menu_panel: Control, title_text: String, instructions_text: String):
	# Get the main panel and center it
	var main_panel = menu_panel.get_node("MainPanel")
	
	# Center the main panel on screen
	var viewport_size = Vector2(get_viewport().size)
	main_panel.position = (viewport_size - main_panel.size) / 2
	
	# Setup title and instructions text
	var title = main_panel.get_node("Title")
	title.text = title_text
	# Hide title if empty (for start menu with image)
	if title_text.is_empty():
		title.visible = false
	
	var instructions = main_panel.get_node("Instructions")
	instructions.text = instructions_text

########### START MENU LOGIC & HELPER FUNCs
func create_start_menu():
	start_menu = MenuPanelScene.instantiate()
	start_menu.name = "StartMenu"
	add_child(start_menu)
	
	setup_menu_panel(start_menu, "", "Complete tasks before time runs out!\n\nUse WASD to move around\nPress SPACE to interact with tasks\nDon't let too many tasks fail!")
	
	# Add menu title image
	var title_texture = preload("res://art/static_assets/menu/menu_title.png")
	var title_image = TextureRect.new()
	title_image.texture = title_texture
	title_image.size = Vector2(400, 100)  # Adjust size as needed
	title_image.position = Vector2(100, 20)  # Position at top
	title_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	start_menu.get_node("MainPanel").add_child(title_image)
	
	# Add start button
	var start_button = CustomButtonScene.instantiate()
	start_button.text = "START GAME"
	start_button.size = Vector2(200, 50)  # Make button bigger
	start_button.position = Vector2(200, 350)  # Center it
	start_button.add_theme_font_size_override("font_size", 20)
	start_button.pressed.connect(_on_start_game_pressed)
	start_menu.get_node("MainPanel").add_child(start_button)

func _on_start_game_pressed():
	hide_start_menu()
	start_game_requested.emit()

func show_start_menu():
	current_game_state = GameState.START_MENU
	start_menu.visible = true
	disable_player()

func hide_start_menu():
	start_menu.visible = false
	current_game_state = GameState.PLAYING
	pause_button.visible = true
	enable_player()

########### PAUSE MENU LOGIC & HELPER FUNCs
func create_pause_menu():
	pause_menu = MenuPanelScene.instantiate()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false
	add_child(pause_menu)
	
	setup_menu_panel(pause_menu, "GAME PAUSED", "Controls:\n\n• WASD: Move around\n• SPACE: Interact with tasks\n• P: Pick up items\n• ESC: Pause/Resume game")
	
	# Add resume button
	var resume_button = CustomButtonScene.instantiate()
	resume_button.text = "RESUME GAME"
	resume_button.size = Vector2(200, 50)
	resume_button.position = Vector2(200, 350)
	resume_button.add_theme_font_size_override("font_size", 20)
	resume_button.pressed.connect(_on_resume_game_pressed)
	pause_menu.get_node("MainPanel").add_child(resume_button)

func _on_resume_game_pressed():
	hide_pause_menu()
	resume_game_requested.emit()

func show_pause_menu():
	current_game_state = GameState.PAUSED
	pause_menu.visible = true
	pause_button.visible = false
	disable_player()

func hide_pause_menu():
	pause_menu.visible = false
	current_game_state = GameState.PLAYING
	pause_button.visible = true
	enable_player()

########### GAME OVER MENU LOGIC & HELPER FUNCs
var game_over_title_label: Label
var game_over_stats_label: Label

func create_game_over_menu():
	game_over_menu = MenuPanelScene.instantiate()
	game_over_menu.name = "GameOverMenu"
	game_over_menu.visible = false
	add_child(game_over_menu)
	
	# We'll set this up dynamically in show_game_over_menu
	# because the text changes based on win/lose

func show_game_over_menu(won: bool, final_score: int, time_survived: float):
	current_game_state = GameState.GAME_OVER
	pause_button.visible = false
	
	# Setup the menu panel
	var title_text = "YOU WIN!" if won else "GAME OVER"
	var minutes = int(time_survived) / 60
	var seconds = int(time_survived) % 60
	var stats_text = "Final Score: %d\nTime Survived: %02d:%02d\n\n%s" % [
		final_score, 
		minutes, 
		seconds,
		"Congratulations!" if won else "Tasks failed too many times!\nTry again?"
	]
	
	setup_menu_panel(game_over_menu, title_text, stats_text)
	
	# Color the title based on win/lose
	var title = game_over_menu.get_node("MainPanel/Title")
	if won:
		title.add_theme_color_override("font_color", Color.GREEN)
	else:
		title.add_theme_color_override("font_color", Color.RED)
	
	# Add restart button
	var restart_button = CustomButtonScene.instantiate()
	restart_button.text = "START NEW GAME"
	restart_button.size = Vector2(200, 50)
	restart_button.position = Vector2(200, 350)
	restart_button.add_theme_font_size_override("font_size", 20)
	restart_button.pressed.connect(_on_restart_game_pressed)
	game_over_menu.get_node("MainPanel").add_child(restart_button)
	
	game_over_menu.visible = true
	disable_player()

func _on_restart_game_pressed():
	hide_game_over_menu()
	restart_game_requested.emit()

func hide_game_over_menu():
	game_over_menu.visible = false
	# Clean up the restart button for next time
	var main_panel = game_over_menu.get_node("MainPanel")
	for child in main_panel.get_children():
		if child is Button:
			child.queue_free()
			
	enable_player()

######## PAUSE BTN TOP Left
func create_pause_button():
	pause_button = Button.new()
	pause_button.text = "⏸"
	pause_button.size = Vector2(50, 50)
	pause_button.position = Vector2(10, 10)
	pause_button.add_theme_font_size_override("font_size", 24)
	pause_button.visible = false
	
	pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
		
	pause_button.pressed.connect(_on_pause_button_pressed)
	add_child(pause_button)

func _on_pause_button_pressed():
	show_pause_menu()

# PROPER PAUSE SYSTEM
func disable_player():
	# Use Godot's built-in pause system
	get_tree().paused = true

func enable_player():
	# Unpause the game
	get_tree().paused = false
