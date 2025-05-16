extends Node

## Global Autoload for the in-game dev tools menu

## These tags are for use in printing things to the console, it helps filter output and make the console more readable
enum Tags {
	ERROR, ## Prints error messages. Automatically enabled
	WARN, ## Prints warning messages. Automatically enabled
	IMPORTANT, ## Prints messages that are important, but not a warning or error. Automatically enabled
	DEBUG, ## Prints messages used for debugging.
	ALL, ## Prints all messages.
	CONSOLE,## Prints messages pertaining to the console window
}

const _DEV_MENU_PREFAB := preload("res://addons/dev_tools/gui/game_menu/dev_tools.tscn")
const _NORMAL_FONT : FontFile = preload("res://addons/dev_tools/fonts/JetBrainsMono-Regular.ttf")
const _BOLD_FONT : FontFile = preload("res://addons/dev_tools/fonts/JetBrainsMono-Bold.ttf")

## The additional tabs that will appear beside the console tab
@export var info_tabs: Array[MenuTab]

## The input used to open the menu
@export var open_input: Key = KEY_QUOTELEFT

## The currently enabled tags. Error, warn, and important are enabled by default
var enabled_tags: Array[Tags] = [
	Tags.ERROR,
	Tags.WARN,
	Tags.IMPORTANT,
]

## The reference to the dev menu instance
var dev_menu: Control

## The reference to the console tab
var dev_console: Console

func _ready() -> void:
	if OS.is_debug_build():
		if not dev_menu:
			dev_menu = _DEV_MENU_PREFAB.instantiate()
			get_tree().root.add_child.call_deferred(dev_menu, true)

		if not dev_console:
			dev_console = Console.new()
			dev_console.name = "Console"

		dev_menu.visible = false
		process_mode = PROCESS_MODE_ALWAYS

		info_tabs.append(MenuTab.new("General", [
			DevProperty.new("Version", ^"", ^"", ProjectSettings.get_setting("application/config/version"), 0)
		]))

		update_tabs()
	else:
		process_mode = PROCESS_MODE_DISABLED
		return

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == open_input and not event.is_echo() and event.is_pressed():
		if not dev_menu.visible:
			if not ProjectSettings.get_setting("dev_tools/general/remember_last_tab", true):
				dev_console.visible = true
			dev_menu.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			dev_menu.visible = false
			if ProjectSettings.get_setting("dev_tools/general/capture_mouse_on_close", false):
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		dev_console._console_input.clear()
		get_viewport().set_input_as_handled()

## Updates the tabs currently shown on the dev menu
func update_tabs() -> void:
	dev_menu.remove_all_tabs()
	dev_menu.add_tab(dev_console)
	for tab in info_tabs:
		dev_menu.add_tab(tab)

## Prints the value provided to [param text] in the console and stdout, but only
## if one of the passed [param tags] are currently enabled. [param tags] defaults
## to [constant ALL] if no array is passed.
##
## [br][br]
##
## Printing using [constant ERROR] or [constant WARN] will automatically change
## the text color in the console, and push an error or warning to stdout respectively.
func console_print(text: String, tags: Array[Tags] = [Tags.ALL]) -> void:
	var can_print: bool = false

	for tag in tags:
		if enabled_tags.has(tag) || enabled_tags.has(Tags.ALL):
			can_print = true
			break

	if can_print and dev_menu and dev_console:
		if tags.has(Tags.ERROR):
			dev_console.print_error(text)
		elif tags.has(Tags.WARN):
			dev_console.print_warning(text)
		else:
			dev_console.print_line(text)
