class_name ConsoleCommand
extends RefCounted
## A class for containing console commands in the dev console

## The name of the command
var command_name: StringName

## The description of what the command does
var description: String

## Arguments of the backing callable, calculated automatically
var args: Array[Dictionary]

## Any default/optional arguments of the backing callable, calculated automatically
var default_args: Array

## The callable that this command calls when used
var _callable: Callable

## Creates a new [ConsoleCommand] instance from the values passed in [param p_callable],
## [param p_command], and [param p_description].
##
## [br][br]
##
## The [Callable] that is passed in [param p_callable] can only reliably take primitve arguments,
## other arguments may not work as expected.
##
## [br][br]
##
## [b][color=yellow]NOTE:[/color][/b] The exception to using primitive arguments is using a simple [Array].
## Using an [Array] will override all built-in argument parsing and will just pass the unmodified
## argument strings for you to do with as you please.
##
## [br][br]
##
## The console will print the return value of the provided [Callable], which is useful for providing
## confirmation that the command has successfully executed.
func _init(p_callable: Callable, p_command: StringName, p_description: String) -> void:
	_callable = p_callable
	command_name = p_callable.get_method().trim_prefix("_") if p_command.is_empty() else p_command
	description = p_description
	_init_args(p_callable.get_object())

func _init_args(p_object: Object) -> void:
	var method_list : Array[Dictionary] = p_object.get_script().get_script_method_list()
	for method : Dictionary in method_list:
		if method.name == _callable.get_method():
			for arg : Dictionary in method.args:
				args.append({"name": arg.name, "type": arg.type})
			default_args = method.default_args
			return

func _execute(p_args: PackedStringArray) -> Dictionary:
	var required_args_count : int = args.size() - default_args.size()
	var result : Variant

	# Checks if the command uses an array/variable arguments, otherwise parses the arguments individually
	if required_args_count > 0 and args[0].type == TYPE_ARRAY:
		result = _callable.call(p_args)
	else:
		# Checks for if the provided arguments are fewer than needed
		if p_args.size() < required_args_count:
			if default_args.is_empty():
				var s : String = "Expected %s arguments, received %s" % \
				[required_args_count, p_args.size()]
				return {"error" : FAILED, "string" : s}
			else:
				var s : String = "Expected at least %s of %s arguments, received %s" % \
				[required_args_count, args.size(), p_args.size()]
				return {"error" : FAILED, "string" : s}
		# Checks if there were too many arguments provided
		elif p_args.size() > args.size():
			var s : String = "Too many arguments for \"%s\" call. Expected at most %s but received %s." % \
			[_callable.get_method(), args.size(), p_args.size()]
			return {"error" : FAILED, "string" : s}

		# Calls the function without arguments if there are no arguments that need to be provided
		if args.size() == 0:
			result = _callable.call()

		# Parses all of the passed arguments
		else:
			var converted_args : Array
			for i : int in p_args.size():
				match args[i].type:
					TYPE_INT when p_args[i].is_valid_int():
						converted_args.append(p_args[i].to_int())
					TYPE_INT:
						if not p_args[i].is_empty():
							return {"error" : FAILED, "string" : "Argument %s is not a valid int." % [i + 1]}
						break
					TYPE_FLOAT when p_args[i].is_valid_float():
						converted_args.append(p_args[i].to_float())
					TYPE_FLOAT:
						if not p_args[i].is_empty():
							return {"error" : FAILED, "string" : "Argument %s is not a valid float." % [i + 1]}
						break
					_: # Catches any abstract data types
						converted_args.append(type_convert(p_args[i], args[i].type))
						if converted_args[i] == null:
							var s : String = "Cannot convert argument %s from String to %s" % \
							[i + 1, type_string(args[i].type)]
							return {"error" : FAILED, "string" : s}
			result = _callable.callv(converted_args)

	if not result == null:
		return {"error" : OK, "string" : str(result)}

	return {"error" : OK, "string" : ""}
