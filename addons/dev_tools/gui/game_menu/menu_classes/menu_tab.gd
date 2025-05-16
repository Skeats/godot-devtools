@tool
class_name MenuTab
extends Control

var _properties_container: VFlowContainer
var properties: Array[DevProperty] = []
var property_labels: Array[RichTextLabel] = []

var _properties_bg_color : Color = ProjectSettings.get_setting("dev_tools/menu_tabs/properties_background_color", Color(0, 0, 0, 0.784))
var _font_color : Color = ProjectSettings.get_setting("dev_tools/menu_tabs/font_color", Color(1, 1, 1, 1))

func _init(
	p_name: StringName = "General",
	p_properties: Array[DevProperty] = []
	) -> void:
	_init_gui(p_properties)

	name = p_name
	process_mode = PROCESS_MODE_ALWAYS

	# Signals

	# Commands

func _init_gui(p_properties: Array[DevProperty]) -> void:

	# Panel Setup
	var bg_panel := PanelContainer.new()

	bg_panel.anchor_left = Control.ANCHOR_BEGIN
	bg_panel.anchor_top = Control.ANCHOR_BEGIN
	bg_panel.anchor_right = Control.ANCHOR_END
	bg_panel.anchor_bottom = Control.ANCHOR_END

	add_child(bg_panel)

	# VFlowContainer Setup
	_properties_container = VFlowContainer.new()

	_properties_container.anchor_left = Control.ANCHOR_BEGIN
	_properties_container.anchor_top = Control.ANCHOR_BEGIN
	_properties_container.anchor_right = Control.ANCHOR_END
	_properties_container.anchor_bottom = Control.ANCHOR_END

	bg_panel.add_child(_properties_container)

	# Properties
	for prop in p_properties:
		_create_new_label(prop)

	_init_styles()


func _init_styles() -> void:
	_properties_container.add_theme_constant_override("separation", 0)

	var properties_stylebox : StyleBoxFlat = StyleBoxFlat.new()
	properties_stylebox.bg_color = _properties_bg_color

	_properties_container.add_theme_stylebox_override("normal", properties_stylebox)

func _init_prop_styles(p_prop: RichTextLabel) -> void:
	p_prop.add_theme_font_override("normal_font", DevTools._NORMAL_FONT)
	p_prop.add_theme_font_override("bold_font", DevTools._BOLD_FONT)
	p_prop.add_theme_color_override("default_color", _font_color)

func _create_new_label(prop: DevProperty) -> void:
	var label = RichTextLabel.new()
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	property_labels.append(label)
	properties.append(prop)
	_init_prop_styles(label)
	_properties_container.add_child(label)
	update_label(property_labels.size() - 1)

## Adds a new prop to the menu tab
func add_prop(prop: DevProperty) -> void:
	if not is_node_ready():
		await ready

	_create_new_label(prop)

## Updates the [RichTextLabel] assigned to a property at the given [param index]
func update_label(index: int) -> void:
	if not is_node_ready():
		await ready

	var label = property_labels[index]
	var prop = properties[index]

	label.text = get_prop_value_as_string(prop)

	DevTools.console_print("Updating property %s with value \"%s\" after delay of %sms" % [prop.prop_name, label.text, prop.update_frequency], [DevTools.Tags.CONSOLE])

	if prop.update_frequency > 0:
		get_tree().create_timer(prop.update_frequency / 1000.0).timeout.connect(update_label.bind(index))

## Gets the value from a [DevProperty] as a string
func get_prop_value_as_string(prop: DevProperty) -> String:
	DevTools.console_print(str(prop.prop_property), [DevTools.Tags.CONSOLE])
	if prop.prop_value:
		var node: Node = get_node(prop.prop_value)

		return "%s: " % prop.prop_name + prop.value_text % prop.get_property()
	else:
		return "%s: " % prop.prop_name + prop.value_text
