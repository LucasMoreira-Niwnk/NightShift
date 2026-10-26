extends StaticBody3D

var prompt := "Examinar"
var action: Callable

func interaction_prompt() -> String:
	return "E — " + prompt

func interact() -> void:
	if action.is_valid():
		action.call()
