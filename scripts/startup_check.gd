# realized belatedly that the exe Godot exports does not embed the required passthrough dll
# easiest way to handle missing dll would be to just terminate and point user to the releases page

# originally put the checks in overlay_main.gd > ready()
# but it turns out that ready() can't run if dll is missing
# this .gd is run as an autoload in Project Settings to get around that limitation

extends Node

func _ready() -> void:
	if Engine.has_singleton("WinSetFlags"):
		return

	var err := DisplayServer.dialog_show(
		"SlothOfExile Overlay",
		"win_set_flags.windows.template_release.x86_64.dll is missing or failed to load.\n\n"
		+ "Keep the DLL in the same folder as the overlay .exe, then start it again.\n\n"
		+ "The DLL can also be downloaded from the releases page at "
		+ "https://github.com/slothofexile/slothofexile-overlay/releases",
		["OK"],
		func(_button: int) -> void: get_tree().quit(1)
	)
	if err != OK:
		get_tree().quit(1)
