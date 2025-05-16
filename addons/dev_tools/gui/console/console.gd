@tool
class_name Console
extends Control

## Console heavily inspired by this addon: https://godotengine.org/asset-library/asset/3533

var _commands: Array[ConsoleCommand] = []

var _console_container : VBoxContainer
var _console_output : RichTextLabel
var _console_input : LineEdit

var _autocomplete_match: String = ""
var _last_input_was_autocomplete: bool = false

var _history: PackedStringArray = []
var _history_index: int = -1

var _output_bg_color : Color = ProjectSettings.get_setting("dev_tools/console/output_background_color", Color(0, 0, 0, 0.784))
var _input_bg_color : Color = ProjectSettings.get_setting("dev_tools/console/input_background_color", Color(0.098, 0.098, 0.098, 0.784))
var _font_color : Color = ProjectSettings.get_setting("dev_tools/console/font_color", Color(1, 1, 1, 1))
var _max_history_size : int = ProjectSettings.get_setting("dev_tools/console/max_history_size", 100)

func _init() -> void:
	_init_gui()

	assert(_console_container is VBoxContainer, "Container not assigned")
	assert(_console_output is RichTextLabel, "Output not assigned")
	assert(_console_input is LineEdit, "Input not assigned")

	process_mode = PROCESS_MODE_ALWAYS

	_console_input.text_submitted.connect(_execute_command)
	_console_input.draw.connect(_on_console_input_draw)

	create_command(_help, "help", "Displays available commands.")
	create_command(_clear, "clear", "Clears console output.")
	create_command(_exit, "exit", "Exits the console.")
	create_command(_quit, "quit", "Quits the game.")
	create_command(_tag_info, "tag_info", "Shows information regarding console tags")
	create_command(_list_tags, "list_tags", "Lists all currently enabled tags")
	create_command(add_tags, "add_tags", "Adds tags to be shown in the console. Arguments are passed by space-delimited strings typed exactly as shown by \"list_tags\".")
	create_command(remove_tags, "remove_tags", "Removes tags to be shown in the console. Arguments are passed by space-delimited strings typed exactly as shown by \"list_tags\".")

	print_line("Hello, World!")
	print_line("Use 'help' to see list of available commands.")

func _init_gui() -> void:
	var v_box_container : VBoxContainer = VBoxContainer.new()
	var rich_text_label : RichTextLabel = RichTextLabel.new()
	var line_edit : LineEdit = LineEdit.new()

	_console_container = v_box_container
	_console_output = rich_text_label
	_console_input = line_edit

	v_box_container.anchor_left = Control.ANCHOR_BEGIN
	v_box_container.anchor_top = Control.ANCHOR_BEGIN
	v_box_container.anchor_right = Control.ANCHOR_END
	v_box_container.anchor_bottom = Control.ANCHOR_END

	rich_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rich_text_label.scroll_following = true

	line_edit.placeholder_text = "Type here..."
	line_edit.caret_blink = true
	line_edit.context_menu_enabled = false
	line_edit.keep_editing_on_text_submit = true

	_init_styles()

	add_child(v_box_container)
	v_box_container.add_child(rich_text_label)
	v_box_container.add_child(line_edit)


func _init_styles() -> void:
	_console_container.add_theme_constant_override("separation", 0)

	var output_stylebox : StyleBoxFlat = StyleBoxFlat.new()
	output_stylebox.bg_color = _output_bg_color

	_console_output.add_theme_stylebox_override("normal", output_stylebox)
	_console_output.add_theme_font_override("normal_font", DevTools._NORMAL_FONT)
	_console_output.add_theme_font_override("bold_font", DevTools._BOLD_FONT)
	_console_output.add_theme_color_override("default_color", _font_color)

	var input_stylebox : StyleBoxFlat = StyleBoxFlat.new()
	input_stylebox.bg_color = _input_bg_color

	_console_input.add_theme_stylebox_override("normal", input_stylebox)
	_console_input.add_theme_stylebox_override("focus", input_stylebox)
	_console_input.add_theme_font_override("font", DevTools._NORMAL_FONT)
	_console_input.add_theme_color_override("font_color", _font_color)

func _input(p_event: InputEvent) -> void:

	if not (p_event is InputEventKey and p_event.pressed and not p_event.echo):
		return

	var input_handled : bool = true

	match p_event.physical_keycode:
		KEY_PAGEUP:
			var scroll_bar : VScrollBar = _console_output.get_v_scroll_bar()
			scroll_bar.value -= scroll_bar.page

		KEY_PAGEDOWN:
			var scroll_bar : VScrollBar = _console_output.get_v_scroll_bar()
			scroll_bar.value += scroll_bar.page

		KEY_UP:
			if _history.is_empty():
				return

			_history_index = clampi(_history_index + 1, 0, _history.size() - 1)
			_console_input.text = _history[_history_index]
			_console_input.caret_column = _console_input.text.length()

		KEY_DOWN:
			if _history.is_empty():
				return

			_history_index = clampi(_history_index - 1, -1, _history.size() - 1)
			if _history_index < 0:
				_console_input.clear()
			else:
				_console_input.text = _history[_history_index]
				_console_input.caret_column = _console_input.text.length()

		KEY_TAB:
			_autocomplete()
			_last_input_was_autocomplete = true

		_:
			_last_input_was_autocomplete = false
			input_handled = false

	if input_handled:
		get_viewport().set_input_as_handled()

	if visible and not _console_input.has_focus():
		_console_input.grab_focus()

## Outputs a standard message to the console.
func print_line(p_text: String) -> void:
	var adjusted_text: String = "[" + Time.get_time_string_from_system() + "]: " + p_text
	_console_output.append_text(adjusted_text + "\n")
	print(adjusted_text)

## Outputs a bold-styled message to the console.
func print_bold(p_text: String) -> void:
	_console_output.push_bold()
	print_line(p_text)
	_console_output.pop()

## Outputs an error-styled message to the console.
func print_error(p_text: String) -> void:
	_console_output.push_color(Color.RED)
	_console_output.append_text(p_text + "\n")
	push_error(p_text)
	_console_output.pop()

## Outputs a warning-styled message to the console.
func print_warning(p_text: String) -> void:
	_console_output.push_color(Color.YELLOW)
	_console_output.append_text(p_text + "\n")
	push_warning(p_text)
	_console_output.pop()

## Registers a new [param p_command] command in the console.
## Executing command will call [param p_callable]. [br]
## Optional [param p_description] can be provided that will be displayed by the help command.
##
## [br][br]
##
## If [param p_command] is left empty, it will be set to [param p_callable] method name
## with trimmed underscore prefix if needed.
##
## [br][br]
##
## Example:
## [codeblock]
## func _ready():
##     GDConsole.create_command(hello, "greet", "Greets the world.")
##
## func hello():
##     print("Hello, World!")
## [/codeblock]
## This example creates a command [i]greet[/i] that calls [code]hello()[/code].
func create_command(p_callable: Callable, p_command: StringName = "", p_description: String = "") -> void:
	var new_command : ConsoleCommand = ConsoleCommand.new(p_callable, p_command, p_description)

	if _has_command(new_command.command_name):
		push_warning("Command '%s' already exists." % new_command.command_name)
		return

	_commands.append(new_command)

## Removes a command.
func remove_command(p_command: StringName) -> void:
	if not _has_command(p_command):
		push_warning("Command '%s' does not exist." % p_command)
		return

	_commands.erase(_get_command(p_command))

func _has_command(p_command: StringName) -> bool:
	for command : ConsoleCommand in _commands:
		if command.command_name == p_command:
			return true
	return false

func _get_command(p_command: StringName) -> ConsoleCommand:
	for command : ConsoleCommand in _commands:
		if command.command_name == p_command:
			return command
	return null

func _parse_command(p_text: String) -> String:
	var split : PackedStringArray = p_text.split(" ", false)
	if split.size() > 0:
		return split[0]
	return ""

func _parse_args(p_text: String) -> PackedStringArray:
	var split : PackedStringArray = p_text.split(" ", false)
	if split.size() > 1:
		split.remove_at(0)
		return split
	return []

func _add_to_history(p_command: String) -> void:
	if _history.size() >= _max_history_size:
		_history.resize(_max_history_size - 1)

	_history.reverse()
	_history.append(p_command)
	_history.reverse()

func _execute_command(p_command: String) -> void:
	_console_input.clear()
	print_bold("> %s" % p_command)

	var command : String = _parse_command(p_command)
	var args : PackedStringArray = _parse_args(p_command)

	if command.is_empty() and args.is_empty():
		return

	if command.is_empty():
		print_error("'%s' is not a valid command." % p_command)
		return

	_add_to_history(p_command)
	_history_index = -1

	if not _has_command(command):
		print_error("'%s' is not a valid command." % command)
		return

	var result : Dictionary = _get_command(command)._execute(args)

	if not result.error == OK:
		print_error(result.string)
		return

	if not result.string.is_empty():
		print_line(result.string)


func _autocomplete() -> void:
	if _autocomplete_match.is_empty():
		return

	var parsed_command : String = _parse_command(_console_input.text)
	var parsed_args : PackedStringArray = _parse_args(_console_input.text)

	_console_input.text = "help " + _autocomplete_match if parsed_command == "help" else _autocomplete_match
	_autocomplete_match = ""
	_console_input.caret_column = _console_input.text.length()


func _on_console_input_draw() -> void:
	var parsed_command : String = _parse_command(_console_input.text)

	if parsed_command.is_empty():
		_autocomplete_match = ""
		return

	elif _console_input.text.get_slice(" ", \
	_console_input.text.get_slice_count(" ") - 1).is_empty():
		_autocomplete_match = ""
		return

	var parsed_args : PackedStringArray = _parse_args(_console_input.text)

	var string_size : Vector2 = DevTools._NORMAL_FONT.get_string_size(_console_input.text, \
	HORIZONTAL_ALIGNMENT_LEFT, -1, _console_input.get_theme_font_size("font_size"))

	if parsed_command == "help" and parsed_args.size() == 1:

		for command : ConsoleCommand in _commands:
			if command.command_name.begins_with(parsed_args[0]) \
			and not command.command_name == parsed_args[0]:
				_autocomplete_match = command.command_name
				_console_input.draw_string(DevTools._NORMAL_FONT, string_size + Vector2(0, -1), \
				_autocomplete_match.trim_prefix(parsed_args[0]), HORIZONTAL_ALIGNMENT_LEFT, \
				-1, 16, Color.DIM_GRAY)
				return

	elif not parsed_command.is_empty() and parsed_args.is_empty():

		for command : ConsoleCommand in _commands:
			if command.command_name.begins_with(parsed_command) \
			and not command.command_name == parsed_command:
				_autocomplete_match = command.command_name
				_console_input.draw_string(DevTools._NORMAL_FONT, string_size + Vector2(0, -1), \
				_autocomplete_match.trim_prefix(parsed_command), HORIZONTAL_ALIGNMENT_LEFT, \
				-1, 16, Color.DIM_GRAY)
				return


#region Built-In Commands
func _help(p_command: StringName = "") -> void:
	if p_command.is_empty():
		print_line("List of available commands:")
		for command : ConsoleCommand in _commands:
			print_line(command.command_name)

		return

	for command : ConsoleCommand in _commands:

		if command.command_name == p_command:

			print_line(command.description \
			if not command.description.is_empty() else "No description")

			if command.args.is_empty():
				return

			print_line("args:")

			var i : int = 0
			var required_args_count : int = command.args.size() - command.default_args.size()

			for arg : Dictionary in command.args:
				if i >= required_args_count:
					print_line("\t%s: %s (default = %s)" % [arg.name, type_string(arg.type),\
					command.default_args[-required_args_count + i]])

				else:
					print_line("\t%s: %s" % [arg.name, type_string(arg.type)])
				i += 1

			return

	print_error("Command '%s' was not recognized" % p_command)

func _clear() -> void:
	_console_output.clear()

func _exit() -> void:
	DevTools.dev_menu.visible = false

func _quit() -> void:
	get_tree().quit()

func _list_tags() -> String:
	var return_text: String = "Available Tags: (Enabled tags will have a checkmark)"

	for tag in DevTools.Tags:
		return_text += "\n " + tag

		if DevTools.enabled_tags.has(DevTools.Tags.get(tag)):
			return_text += " (✔️)"
		else:
			return_text += " (❌)"

	return return_text

func _tag_info() -> String:
	return "Tags allow you to enable or disable certain console messages based on what you want shown. Each tag will enable any messages that have that tag, regardless of what other tags that message has."

func add_tags(args: Array) -> String:
	var return_text: String = "Added tags:"

	for arg in args:
		var tag = arg.to_upper()

		if DevTools.Tags.has(tag) && !DevTools.enabled_tags.has(DevTools.Tags.get(tag)):
			DevTools.enabled_tags.append(DevTools.Tags.get(tag))
			return_text += " " + tag

	return return_text

func remove_tags(args: Array) -> String:
	var return_text: String = "Removed tags:"

	for arg in args:
		var tag = arg.to_upper()

		if DevTools.enabled_tags.has(DevTools.Tags.get(tag)):
			DevTools.enabled_tags.erase(DevTools.Tags.get(tag))
			return_text += " " + tag

	return return_text
#endregion
