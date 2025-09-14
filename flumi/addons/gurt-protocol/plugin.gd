@tool
extends EditorPlugin

func _enter_tree():
	print("GURT Protocol plugin enabled")

func _exit_tree():
	print("GURT Protocol plugin disabled")