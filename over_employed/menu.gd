extends Control

@onready var start_button = $StartButton
@onready var quit_button = $QuitButton

func _ready():
	print("=== MENU DEBUG ===")
	print("Menu scene loaded successfully!")
	print("Viewport size: ", get_viewport().size)
	print("Window size: ", DisplayServer.window_get_size())
	print("Scene tree: ", get_tree().current_scene.name)
	
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Set focus to start button
	start_button.grab_focus()
	print("Menu buttons connected and ready!")
	print("==================")

func _on_start_pressed():
	print("Starting game...")
	get_tree().change_scene_to_file("res://main_room.tscn")

func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit() 