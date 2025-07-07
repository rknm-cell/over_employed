extends CharacterBody2D

@export var speed: float = 400.0

var screen_size: Vector2
var current_interactable: Node2D = null

func _ready():
	add_to_group("player")
	screen_size = get_viewport_rect().size

func _physics_process(delta):
	var velocity = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	self.velocity = velocity
	move_and_slide()

	# Clamp position to stay inside screen
	position = position.clamp(Vector2.ZERO, screen_size)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("Spacebar pressed!")
		if current_interactable:
			print("Interacting with object in range!")
			if current_interactable.has_method("computer_activate"):
				print("Activating computer!")
				current_interactable.computer_activate()
		else:
			print("Nothing to interact with nearby")

func _on_interactable_entered(area: Area2D):
	if area.get_parent().has_method("computer_activate"):
		current_interactable = area.get_parent()
		print("Entered interaction range - Press spacebar to interact!")

func _on_interactable_exited(area: Area2D):
	if current_interactable and area.get_parent() == current_interactable:
		current_interactable = null
		print("Left interaction range")
