# Debug test script for Over Employed project
# Run this to check if the project structure is correct

extends Node

func _ready():
	print("=== OVER EMPLOYED DEBUG TEST ===")
	print("Testing project structure...")
	
	# Check if main scenes exist
	var scenes_to_check = [
		"res://menu.tscn",
		"res://main_room.tscn",
		"res://player.tscn",
		"res://printer.tscn"
	]
	
	for scene_path in scenes_to_check:
		var file = FileAccess.open(scene_path, FileAccess.READ)
		if file:
			print("✅ ", scene_path, " - EXISTS")
			file.close()
		else:
			print("❌ ", scene_path, " - MISSING")
	
	# Check if scripts exist
	var scripts_to_check = [
		"res://menu.gd",
		"res://main_room.gd",
		"res://player.gd",
		"res://printer.gd"
	]
	
	for script_path in scripts_to_check:
		var file = FileAccess.open(script_path, FileAccess.READ)
		if file:
			print("✅ ", script_path, " - EXISTS")
			file.close()
		else:
			print("❌ ", script_path, " - MISSING")
	
	print("=== DEBUG TEST COMPLETE ===")
	print("If all files show ✅, the project structure is correct!")
	print("If any show ❌, those files need to be created or fixed.") 