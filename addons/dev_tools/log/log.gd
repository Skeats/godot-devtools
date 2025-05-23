## Log.gd - colorized pretty printing functions
##
## [code]Log.pr(...)[/code] and [code]Log.prn(...)[/code] are drop-in replacements for [code]print(...)[/code].
##
## [br][br]
## You can also [code]Log.warn(...)[/code] or [code]Log.error(...)[/code] to both print and push_warn/push_error.
##
## [br][br]
## Custom object output is supported by implementing [code]to_pretty()[/code] on the object.
##
## [br][br]
## For objects you don't own (built-ins or addons you don't want to edit),
## there is a [code]register_type_overwrite(key, handler)[/code] helper.
##
## [br][br]
## You can find up to date docs and examples in the Log.gd repo and docs site:
## [br]
## - https://github.com/russmatney/log.gd
## [br]
## - https://russmatney.github.io/log.gd
##

@tool
extends Object
class_name Log

const THEME_PATH = "res://addons/dev_tools/log/color_themes/"

static var max_array_size: int = 0
static var dictionary_skip_keys: Array = []
static var colors_disabled: bool = false
static var current_theme: ColorTheme

static func _static_init() -> void:
	ProjectSettings.settings_changed.connect(update_settings)

# helpers ####################################

static func assoc(opts: Dictionary, key: String, val: Variant) -> Dictionary:
	var _opts: Dictionary = opts.duplicate(true)
	_opts[key] = val
	return _opts

# project setting getters ###################################################################

static func update_settings() -> void:
	max_array_size = get_max_array_size()
	dictionary_skip_keys = get_dictionary_skip_keys()
	colors_disabled = get_disable_colors()
	current_theme = get_config_color_theme()

static func get_max_array_size() -> int:
	return ProjectSettings.get_setting("dev_tools/log.gd/max_array_size", -1)

static func get_dictionary_skip_keys() -> Array:
	return ProjectSettings.get_setting("dev_tools/log.gd/dictionary_skip_keys", [])

static func get_disable_colors() -> bool:
	return ProjectSettings.get_setting("dev_tools/log.gd/disable_colors", false)

static func get_config_color_theme() -> ColorTheme:
	var theme_id: String = ProjectSettings.get_setting("dev_tools/log.gd/color_theme", "")

	var theme_files: PackedStringArray =  ResourceLoader.list_directory(THEME_PATH)
	var theme_resources: Array[Resource]

	for file in theme_files:
		var res: Resource = ResourceLoader.load(THEME_PATH + file, "ColorTheme")
		theme_resources.append(res)

	var filtered_themes = theme_resources.filter(func(theme: ColorTheme):
		return theme.theme_name == theme_id
	)

	if filtered_themes.size():
		return filtered_themes[0]
	else:
		return null

# project setting setters ###################################################################

## Disable color-wrapping output.
static func disable_colors() -> void:
	if ProjectSettings.has_setting("dev_tools/log.gd/disable_colors"):
		ProjectSettings.set_setting("dev_tools/log.gd/disable_colors", true)

## Re-enable color-wrapping output.
static func enable_colors() -> void:
	if ProjectSettings.has_setting("dev_tools/log.gd/disable_colors"):
		ProjectSettings.set_setting("dev_tools/log.gd/disable_colors", false)

static func set_color_theme(theme: String) -> void:
	if ProjectSettings.has_setting("dev_tools/log.gd/color_theme"):
		ProjectSettings.set_setting("dev_tools/log.gd/color_theme", theme)

## colors ###########################################################################

static var theme_overwrites: Dictionary = {}

## Merge per type color adjustments.
##
## [br][br]
## Expects a Dictionary from [code]{typeof(obj): Color}[/code].
## See [code]COLORS_TERMINAL_SAFE[/code] for an example.
static func merge_theme_overwrites(colors: Dictionary) -> void:
	theme_overwrites.merge(colors, true)

static func clear_theme_overwrites() -> void:
	theme_overwrites = {}

static func should_use_color(opts: Dictionary = {}) -> bool:
	if colors_disabled:
		return false
	# supports per-print color skipping
	if opts.get("disable_colors", false):
		return false
	return true

static func color_wrap(s: Variant, opts: Dictionary = {}) -> String:
	if not should_use_color(opts):
		return str(s)

	var color: String = opts.get("color", "")
	if color == "":
		var s_type: Variant = opts.get("typeof", typeof(s))
		if s_type is String:
			# type overwrites
			color = colors.get(s_type)
		elif s_type is int and s_type == TYPE_STRING:
			# specific strings/punctuation
			var s_trimmed: String = str(s).strip_edges()
			if s_trimmed in colors:
				color = colors.get(s_trimmed)
			else:
				# fallback string color
				color = colors.get(s_type)
		else:
			# all other types
			color = colors.get(s_type)

	if color == "":
		print("Log.gd could not determine color for object: %s type: (%s)" % [str(s), typeof(s)])

	return "[color=%s]%s[/color]" % [color, s]

## overwrites ###########################################################################

static var type_overwrites: Dictionary = {}

## Register a single type overwrite.
##
## [br][br]
## The key should be either obj.get_class() or typeof(var). (Note that using typeof(var) may overwrite more broadly than expected).
##
## [br][br]
## The handler is called with the object and an options dict.
## [code]func(obj): return {name=obj.name}[/code]
static func register_type_overwrite(key: String, handler: Callable) -> void:
	# TODO warning on key exists? support multiple handlers for same type?
	# validate the key/handler somehow?
	type_overwrites[key] = handler

## Register a dictionary of type overwrite.
##
## [br][br]
## Expects a Dictionary like [code]{obj.get_class(): func(obj): return {key=obj.get_key()}}[/code].
##
## [br][br]
## It depends on [code]obj.get_class()[/code] then [code]typeof(obj)[/code] for the key.
## The handler is called with the object as the only argument. (e.g. [code]func(obj): return {name=obj.name}[/code]).
static func register_type_overwrites(overwrites: Dictionary) -> void:
	type_overwrites.merge(overwrites, true)

static func clear_type_overwrites() -> void:
	type_overwrites = {}

## to_pretty ###########################################################################

## Returns the passed object as a bb-colorized string.
##
## [br][br]
## Useful for feeding directly into a RichTextLabel, but also the core
## of Log.gd's functionality.
static func to_pretty(msg: Variant, opts: Dictionary = {}) -> String:
	var newlines: bool = opts.get("newlines", false)
	var indent_level: int = opts.get("indent_level", 0)
	if not "indent_level" in opts:
		opts["indent_level"] = indent_level

	var theme: Dictionary = opts.get("built_color_theme", get_color_theme(opts))
	if not "built_color_theme" in opts:
		opts["built_color_theme"] = theme

	if not is_instance_valid(msg) and typeof(msg) == TYPE_OBJECT:
		return str("invalid instance: ", msg)

	if msg == null:
		return Log.color_wrap(msg, opts)

	if msg is Object and (msg as Object).get_class() in type_overwrites:
		var fn: Callable = type_overwrites.get((msg as Object).get_class())
		return Log.to_pretty(fn.call(msg), opts)
	elif typeof(msg) in type_overwrites:
		var fn: Callable = type_overwrites.get(typeof(msg))
		return Log.to_pretty(fn.call(msg), opts)

	# objects
	if msg is Object and (msg as Object).has_method("to_pretty"):
		# using a cast and `call.("blah")` here it's "type safe"
		return Log.to_pretty((msg as Object).call("to_pretty"), opts)
	if msg is Object and (msg as Object).has_method("data"):
		return Log.to_pretty((msg as Object).call("data"), opts)
	# DEPRECATED
	if msg is Object and (msg as Object).has_method("to_printable"):
		return Log.to_pretty((msg as Object).call("to_printable"), opts)

	# arrays
	if msg is Array or msg is PackedStringArray:
		var msg_array: Array = msg
		if len(msg) > Log.get_max_array_size():
			pr("[DEBUG]: truncating large array. total:", len(msg))
			msg_array = msg_array.slice(0, Log.get_max_array_size() - 1)
			if newlines:
				msg_array.append("...")

		var tmp: String = Log.color_wrap("[ ", opts)
		var last: int = len(msg) - 1
		for i: int in range(len(msg)):
			if newlines and last > 1:
				tmp += "\n\t"
			tmp += Log.to_pretty(msg[i],
				# duplicate here to prevent indenting-per-msg
				# e.g. when printing an array of dictionaries
				opts.duplicate(true))
			if i != last:
				tmp += Log.color_wrap(", ", opts)
		tmp += Log.color_wrap(" ]", opts)
		return tmp

	# dictionary
	elif msg is Dictionary:
		var tmp: String = Log.color_wrap("{ ", opts)
		var ct: int = len(msg)
		var last: Variant
		if len(msg) > 0:
			last = (msg as Dictionary).keys()[-1]
		var indent_updated = false
		for k: Variant in (msg as Dictionary).keys():
			var val: Variant
			if k in Log.get_dictionary_skip_keys():
				val = "..."
			else:
				if not indent_updated:
					indent_updated = true
					# prints("updating opts.indent_level", opts.indent_level)
					opts.indent_level += 1
				val = Log.to_pretty(msg[k], opts)
			if newlines and ct > 1:
				# prints("applying more tabs", indent_level)
				tmp += "\n\t" \
					+ range(indent_level)\
					.map(func(_i: int) -> String: return "\t")\
					.reduce(func(a: String, b: Variant) -> String: return str(a, b), "")
			var key: String = Log.color_wrap('"%s"' % k, Log.assoc(opts, "typeof", "dict_key"))
			tmp += "%s: %s" % [key, val]
			if last and str(k) != str(last):
				tmp += Log.color_wrap(", ", opts)
		tmp += Log.color_wrap(" }", opts)
		opts.indent_level -= 1 # ugh! updating the dict in-place
		return tmp

	# strings
	elif msg is String:
		if msg == "":
			return '""'
		if "[color=" in msg and "[/color]" in msg:
			# assumes the string is already colorized
			# NOT PERFECT! could use a regex for something more robust
			return msg
		return Log.color_wrap(msg, opts)
	elif msg is StringName:
		return str(Log.color_wrap("&", opts), '"%s"' % msg)
	elif msg is NodePath:
		return str(Log.color_wrap("^", opts), '"%s"' % msg)

	# vectors
	elif msg is Vector2 or msg is Vector2i:
		return '%s%s%s%s%s' % [
			Log.color_wrap("(", opts),
			Log.color_wrap(msg.x, Log.assoc(opts, "typeof", "vector_value")),
			Log.color_wrap(",", opts),
			Log.color_wrap(msg.y, Log.assoc(opts, "typeof", "vector_value")),
			Log.color_wrap(")", opts),
		]

	elif msg is Vector3 or msg is Vector3i:
		return '%s%s%s%s%s%s%s' % [
			Log.color_wrap("(", opts),
			Log.color_wrap(msg.x, Log.assoc(opts, "typeof", "vector_value")),
			Log.color_wrap(",", opts),
			Log.color_wrap(msg.y, Log.assoc(opts, "typeof", "vector_value")),
			Log.color_wrap(",", opts),
			Log.color_wrap(msg.z, Log.assoc(opts, "typeof", "vector_value")),
			Log.color_wrap(")", opts),
			]
	elif msg is Vector4 or msg is Vector4i:
		return '%s%s%s%s%s%s%s%s%s' % [
			Log.color_wrap("(", opts),
			Log.color_wrap(msg.x, Log.assoc(opts, "typeof", "vector_value")),
			Log.color_wrap(",", opts),
			Log.color_wrap(msg.y, Log.assoc(opts, "typeof", "vector_value")),
			Log.color_wrap(",", opts),
			Log.color_wrap(msg.z, Log.assoc(opts, "typeof", "vector_value")),
			Log.color_wrap(",", opts),
			Log.color_wrap(msg.w, Log.assoc(opts, "typeof", "vector_value")),
			Log.color_wrap(")", opts),
			]

	# packed scene
	elif msg is PackedScene:
		var msg_ps: PackedScene = msg
		if msg_ps.resource_path != "":
			return str(Log.color_wrap("PackedScene:", opts), '%s' % msg_ps.resource_path.get_file())
		elif msg_ps.get_script() != null and msg_ps.get_script().resource_path != "":
			var path: String = msg_ps.get_script().resource_path
			return Log.color_wrap(path.get_file(), Log.assoc(opts, "typeof", "class_name"))
		else:
			return Log.color_wrap(msg_ps, opts)

	# resource
	elif msg is Resource:
		var msg_res: Resource = msg
		if msg_res.get_script() != null and msg_res.get_script().resource_path != "":
			var path: String = msg_res.get_script().resource_path
			return Log.color_wrap(path.get_file(), Log.assoc(opts, "typeof", "class_name"))
		elif msg_res.resource_path != "":
			var path: String = msg_res.resource_path
			return str(Log.color_wrap("Resource:", opts), '%s' % path.get_file())
		else:
			return Log.color_wrap(msg_res, opts)

	# refcounted
	elif msg is RefCounted:
		var msg_ref: RefCounted = msg
		if msg_ref.get_script() != null and msg_ref.get_script().resource_path != "":
			var path: String = msg_ref.get_script().resource_path
			return Log.color_wrap(path.get_file(), Log.assoc(opts, "typeof", "class_name"))
		else:
			return Log.color_wrap(msg_ref.get_class(), Log.assoc(opts, "typeof", "class_name"))

	# fallback to primitive-type lookup
	else:
		return Log.color_wrap(msg, opts)

## to_printable ###########################################################################

static func log_prefix(stack: Array) -> String:
	if len(stack) > 1:
		var call_site: Dictionary = stack[1]
		var call_site_source: String = call_site.get("source", "")
		var basename: String = call_site_source.get_file().get_basename()
		var line_num: String = str(call_site.get("line", 0))
		if call_site_source.match("*/test/*"):
			return "{" + basename + ":" + line_num + "}: "
		elif call_site_source.match("*/addons/*"):
			return "<" + basename + ":" + line_num + ">: "
		else:
			return "[" + basename + ":" + line_num + "]: "
	return ""

static func to_printable(msgs: Array, opts: Dictionary = {}) -> String:

	if not msgs is Array:
		msgs = [msgs]
	var stack: Array = opts.get("stack", [])
	var pretty: bool = opts.get("pretty", true)
	var m: String = ""
	if len(stack) > 0:
		var prefix: String = Log.log_prefix(stack)
		var prefix_type: String
		if prefix != null and prefix[0] == "[":
			prefix_type = "SRC"
		elif prefix != null and prefix[0] == "{":
			prefix_type = "TEST"
		elif prefix != null and prefix[0] == "<":
			prefix_type = "ADDONS"
		if pretty:
			m += Log.color_wrap(prefix, Log.assoc(opts, "typeof", prefix_type))
		else:
			m += prefix
	for msg: Variant in msgs:
		# add a space between msgs
		if pretty:
			m += "%s " % Log.to_pretty(msg, opts)
		else:
			m += "%s " % str(msg)
	return m.trim_suffix(" ")

## public print fns ###########################################################################

static func is_not_default(v: Variant) -> bool:
	return not v is String or (v is String and v != "ZZZDEF")

## Pretty-print the passed arguments in a single line.
static func pr(msg: Variant, msg2: Variant = "ZZZDEF", msg3: Variant = "ZZZDEF", msg4: Variant = "ZZZDEF", msg5: Variant = "ZZZDEF", msg6: Variant = "ZZZDEF", msg7: Variant = "ZZZDEF") -> void:
	var msgs: Array = [msg, msg2, msg3, msg4, msg5, msg6, msg7]
	msgs = msgs.filter(Log.is_not_default)
	var m: String = Log.to_printable(msgs, {stack=get_stack()})
	print_rich(m)

## Pretty-print the passed arguments in a single line.
static func info(msg: Variant, msg2: Variant = "ZZZDEF", msg3: Variant = "ZZZDEF", msg4: Variant = "ZZZDEF", msg5: Variant = "ZZZDEF", msg6: Variant = "ZZZDEF", msg7: Variant = "ZZZDEF") -> void:
	var msgs: Array = [msg, msg2, msg3, msg4, msg5, msg6, msg7]
	msgs = msgs.filter(Log.is_not_default)
	var m: String = Log.to_printable(msgs, {stack=get_stack()})
	print_rich(m)

## Pretty-print the passed arguments in a single line.
static func log(msg: Variant, msg2: Variant = "ZZZDEF", msg3: Variant = "ZZZDEF", msg4: Variant = "ZZZDEF", msg5: Variant = "ZZZDEF", msg6: Variant = "ZZZDEF", msg7: Variant = "ZZZDEF") -> void:
	var msgs: Array = [msg, msg2, msg3, msg4, msg5, msg6, msg7]
	msgs = msgs.filter(Log.is_not_default)
	var m: String = Log.to_printable(msgs, {stack=get_stack()})
	print_rich(m)

## Pretty-print the passed arguments, expanding dictionaries and arrays with newlines and indentation.
static func prn(msg: Variant, msg2: Variant = "ZZZDEF", msg3: Variant = "ZZZDEF", msg4: Variant = "ZZZDEF", msg5: Variant = "ZZZDEF", msg6: Variant = "ZZZDEF", msg7: Variant = "ZZZDEF") -> void:
	var msgs: Array = [msg, msg2, msg3, msg4, msg5, msg6, msg7]
	msgs = msgs.filter(Log.is_not_default)
	var m: String = Log.to_printable(msgs, {stack=get_stack(), newlines=true})
	print_rich(m)

## Like [code]Log.prn()[/code], but also calls push_warning() with the pretty string.
static func warn(msg: Variant, msg2: Variant = "ZZZDEF", msg3: Variant = "ZZZDEF", msg4: Variant = "ZZZDEF", msg5: Variant = "ZZZDEF", msg6: Variant = "ZZZDEF", msg7: Variant = "ZZZDEF") -> void:
	var msgs: Array = [msg, msg2, msg3, msg4, msg5, msg6, msg7]
	msgs = msgs.filter(Log.is_not_default)
	var rich_msgs: Array = msgs.duplicate()
	rich_msgs.push_front("[color=yellow][WARN][/color]")
	print_rich(Log.to_printable(rich_msgs, {stack=get_stack(), newlines=true}))
	var m: String = Log.to_printable(msgs, {stack=get_stack(), newlines=true, pretty=false})
	push_warning(m)

## Like [code]Log.prn()[/code], but prepends a "[TODO]" and calls push_warning() with the pretty string.
static func todo(msg: Variant, msg2: Variant = "ZZZDEF", msg3: Variant = "ZZZDEF", msg4: Variant = "ZZZDEF", msg5: Variant = "ZZZDEF", msg6: Variant = "ZZZDEF", msg7: Variant = "ZZZDEF") -> void:
	var msgs: Array = [msg, msg2, msg3, msg4, msg5, msg6, msg7]
	msgs = msgs.filter(Log.is_not_default)
	msgs.push_front("[TODO]")
	var rich_msgs: Array = msgs.duplicate()
	rich_msgs.push_front("[color=yellow][WARN][/color]")
	print_rich(Log.to_printable(rich_msgs, {stack=get_stack(), newlines=true}))
	var m: String = Log.to_printable(msgs, {stack=get_stack(), newlines=true, pretty=false})
	push_warning(m)

## Like [code]Log.prn()[/code], but also calls push_error() with the pretty string.
static func err(msg: Variant, msg2: Variant = "ZZZDEF", msg3: Variant = "ZZZDEF", msg4: Variant = "ZZZDEF", msg5: Variant = "ZZZDEF", msg6: Variant = "ZZZDEF", msg7: Variant = "ZZZDEF") -> void:
	var msgs: Array = [msg, msg2, msg3, msg4, msg5, msg6, msg7]
	msgs = msgs.filter(Log.is_not_default)
	var rich_msgs: Array = msgs.duplicate()
	rich_msgs.push_front("[color=red][ERR][/color]")
	print_rich(Log.to_printable(rich_msgs, {stack=get_stack(), newlines=true}))
	var m: String = Log.to_printable(msgs, {stack=get_stack(), newlines=true, pretty=false})
	push_error(m)

## Like [code]Log.prn()[/code], but also calls push_error() with the pretty string.
static func error(msg: Variant, msg2: Variant = "ZZZDEF", msg3: Variant = "ZZZDEF", msg4: Variant = "ZZZDEF", msg5: Variant = "ZZZDEF", msg6: Variant = "ZZZDEF", msg7: Variant = "ZZZDEF") -> void:
	var msgs: Array = [msg, msg2, msg3, msg4, msg5, msg6, msg7]
	msgs = msgs.filter(Log.is_not_default)
	var rich_msgs: Array = msgs.duplicate()
	rich_msgs.push_front("[color=red][ERR][/color]")
	print_rich(Log.to_printable(rich_msgs, {stack=get_stack(), newlines=true}))
	var m: String = Log.to_printable(msgs, {stack=get_stack(), newlines=true, pretty=false})
	push_error(m)
