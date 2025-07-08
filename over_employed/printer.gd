extends Node2D

var player_in_range = false
var task_done = false
var hold_time = 0.0
var hold_duration = 3.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if task_done:
		return

	if player_in_range and Input.is_key_pressed(KEY_SPACE):
		hold_time += delta
		
		if hold_time >= hold_duration:
			task_done = true
			print("Task complete!")
	else:
		hold_time = 0.0


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("user entred zone")
		player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("user left zone")
		player_in_range = false
		
