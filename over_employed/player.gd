extends CharacterBody2D

@export var speed: float = 1000.0

var screen_size: Vector2
var current_interactable: Node2D = null
var is_holding_space = false

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

	# Check if space is being held down for interactions
	is_holding_space = Input.is_action_pressed("ui_accept") and current_interactable != null

	# Set animation based on movement and interaction state
	if is_holding_space:
		# Use typing animation when holding space for interactions
		$AnimatedSprite2D.animation = "typing"
	elif velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x > 0
	elif velocity.y != 0:
		if velocity.y > 0:
			$AnimatedSprite2D.animation = "down"
		else:
			$AnimatedSprite2D.animation = "up"
	else:
		$AnimatedSprite2D.animation = "idle"

	self.velocity = velocity
	move_and_slide()
	
	# Clamp position to stay inside screen
	position = position.clamp(Vector2.ZERO, screen_size)

func _on_interactable_entered(area: Area2D):
	# Store reference to the interactable object
	current_interactable = area.get_parent()
	print("Player entered interaction area with: ", current_interactable.name)

func _on_interactable_exited(area: Area2D):
	# Clear reference when leaving interaction area
	current_interactable = null
	is_holding_space = false
	print("Player left interaction area")
