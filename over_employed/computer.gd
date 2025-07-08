extends StaticBody2D

@onready var sprite = $Sprite2D
@export var pc_off_texture: Texture2D = preload("res://art/pc_0000_pc_off.png")
@export var pc_on_texture: Texture2D = preload("res://art/pc_0001_pc_on.png")
@export var speed = 400

var player_in_range = false
var is_on = false

func _ready():
	sprite.texture = pc_off_texture
	print("Computer ready - waiting for interaction")

func _input(event):
	if event.is_action_pressed("interact") and player_in_range:
		print("Interact key pressed while in range!")
		computer_activate()
	elif event.is_action_pressed("interact"):
		print("Interact pressed but player not in range")

func computer_activate():
	is_on = !is_on
	sprite.texture = pc_on_texture if is_on else pc_off_texture
	print("Computer activated! State: ", "ON" if is_on else "OFF")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		print("Player entered interaction range")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		print("Player left interaction range") 
