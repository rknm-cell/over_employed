# paper_shelf.gd - Attach this to your shelf node
extends Node2D

@onready var shelf_visual = $ShelfBody/ShelfVisual  # Your shelf rectangle
@onready var paper_visual = $ShelfBody/PaperVisual  # Create a smaller white rectangle for paper
@onready var interaction_area = $InteractionArea
@onready var audio_player = AudioStreamPlayer2D.new()

var player_nearby = false
var has_paper = true

# Sounds
@onready var sounds = {
	"paper_pickup": preload("res://sounds/paper_pickup.wav"),
	"error": preload("res://sounds/error.wav")
}

var game_ui: CanvasLayer

func _ready():
	add_child(audio_player)
	add_to_group("paper_shelf")
	
	# Find the GameUI node
	game_ui = get_tree().get_first_node_in_group("game_ui")
	if not game_ui:
		print("Warning: GameUI not found!")
	else:
		game_ui.text_submitted.connect(_on_text_submitted)
	
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	
	# Setup paper visual
	setup_paper_visual()
	update_shelf_visual()

func setup_paper_visual():
	# Create paper visual if it doesn't exist
	if not paper_visual:
		paper_visual = ColorRect.new()
		paper_visual.name = "PaperVisual"
		add_child(paper_visual)
	
	# Make paper smaller than shelf and white
	var shelf_size = shelf_visual.size if shelf_visual else Vector2(100, 100)
	paper_visual.size = Vector2(shelf_size.x * 0.6, shelf_size.y * 0.3)
	paper_visual.position = Vector2(shelf_size.x * 0.2, shelf_size.y * 0.35)
	paper_visual.color = Color.WHITE

func _input(event):
	if event.is_action_pressed("ui_accept") and player_nearby:
		interact_with_shelf()

func interact_with_shelf():
	if has_paper:
		game_ui.show_text_input(self, "Type 'paper' to take paper:")
	else:
		print("No paper available on shelf")

func _on_text_submitted(text: String, target: Node):
	if target != self:
		return
	
	if text == "paper":
		attempt_take_paper()
	else:
		print("Unknown command: " + text)
		play_sound("error")

func attempt_take_paper():
	if not has_paper:
		print("No paper on shelf!")
		play_sound("error")
		return
	
	if game_ui.has_item("paper"):
		print("You already have paper!")
		play_sound("error")
		return
	
	# Take the paper
	take_paper()

func take_paper():
	has_paper = false
	game_ui.add_to_inventory("paper")
	update_shelf_visual()
	play_sound("paper_pickup")
	print("Picked up paper!")

func respawn_paper():
	# Called when printer is fixed
	has_paper = true
	update_shelf_visual()
	print("Paper restocked on shelf!")

func update_shelf_visual():
	if paper_visual:
		paper_visual.visible = has_paper

func _on_player_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		if has_paper:
			print("Press Space to get paper")
		else:
			print("Shelf is empty")

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		audio_player.stream = sounds[sound_name]
		audio_player.play()
	else:
		print("Sound not found: ", sound_name)
