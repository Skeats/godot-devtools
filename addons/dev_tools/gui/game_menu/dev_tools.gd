extends VSplitContainer

@onready var tab_container: TabContainer = %TabContainer

## Adds a tab to this menu
func add_tab(tab: Control) -> void:
	await ready
	tab_container.add_child(tab, true)

## Removes a tab from this menu
func remove_tab(tab: Control) -> void:
	await ready
	tab_container.remove_child(tab)

## Removes all tabs from this menu
func remove_all_tabs() -> void:
	await ready
	for child in tab_container.get_children():
		tab_container.remove_child(child)
