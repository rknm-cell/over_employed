extends Control

# Settings menu script for the Over Employed game
# Handles game settings and navigation

# Preload the main menu scene
const MainMenuScene = preload("res://main_menu.tscn")

# UI elements
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var volume_slider: HSlider = $VBoxContainer/VolumeContainer/VolumeSlider
@onready var fullscreen_checkbox: CheckBox = $VBoxContainer/FullscreenContainer/FullscreenCheckBox
@onready var volume_label: Label = $VBoxContainer/VolumeContainer/VolumeLabel

func _ready():
	# Connect button signals
	back_button.pressed.connect(_on_back_button_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	
	# Set focus to back button for keyboard navigation
	back_button.grab_focus()
	
	# Load current settings
	_load_settings()
	
	# Make sure this scene can process input
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	# Allow ESC key to go back to main menu
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

func _load_settings():
	# Load volume setting (default to 50%)
	var volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	volume_slider.value = db_to_linear(volume) * 100
	
	# Load fullscreen setting
	fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _on_back_button_pressed():
	# Save settings before going back
	_save_settings()
	# Transition back to the main menu
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_volume_changed(value: float):
	# Update volume in real-time
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
	
	# Update volume label
	volume_label.text = "Volume: " + str(int(value)) + "%"

func _on_fullscreen_toggled(button_pressed: bool):
	# Toggle fullscreen mode
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _save_settings():
	# Save volume setting
	var volume_percent = volume_slider.value
	# You could save this to a config file here
	print("Settings saved - Volume: ", volume_percent, "%, Fullscreen: ", fullscreen_checkbox.button_pressed)

# Optional: Add some visual feedback for button interactions
func _on_back_button_mouse_entered():
	back_button.modulate = Color(1.1, 1.1, 1.1)

func _on_back_button_mouse_exited():
	back_button.modulate = Color(1, 1, 1) 