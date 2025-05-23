class_name DevProperty
extends Resource

## This defines how often the properties will be updated, in ticks. Setting this value to 0
## will only update the property once when it is initialized
@export var update_frequency: int = 1000

## The name of the property, as shown in the dev menu
@export var prop_name: StringName = "Property"

## The [Nodepath] pointing to the node the property is on
@export var prop_value: NodePath = NodePath("")

## The path to the property starting from the node it is on
@export var prop_property: String = ""

## Additional text to be provided alongside the [param prop_value]
@export var value_text: String = "%s"

@export var tab_name: String = "General"

var _parent: Node

func _init(
	init_prop_name: StringName = prop_name,
	init_prop_value: NodePath = prop_value,
	init_prop_property: String = prop_property,
	init_value_text: String = value_text,
	init_update_frequency: int = update_frequency,
	init_tab_name: StringName = tab_name
	) -> void:
		if not OS.is_debug_build(): return

		prop_name = init_prop_name
		prop_value = init_prop_value
		prop_property = init_prop_property
		value_text = init_value_text
		update_frequency = init_update_frequency
		tab_name = init_tab_name

func add_to_tab() -> void:
	# Checks if the tab that this property wants to go to exists, and if not it will create the
	# tab
	var tabs: Array = DevTools.info_tabs.filter(func(tab): return tab.name == tab_name)
	if tabs.size() == 0:
		tabs.append(MenuTab.new(tab_name))
		DevTools.dev_menu.add_tab(tabs[0])

	tabs[0].add_prop(self)

func get_property() -> Variant:
	if _parent and prop_value and prop_property:
		return _parent.get_node(prop_value).get_indexed(prop_property)
	else:
		return null
