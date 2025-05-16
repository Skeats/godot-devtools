class_name DevMenuUpdater
extends Node
## This class should be used similarly to a [MultiplayerSynchronizer], in that it should be placed
## within a scene that contains properties you wish to track, which will send the properties to
## the dev menu and keep them updated

## This contains a [Dictionary] of [StringName]'s, which are the names of the properties to track
## as well as an [Array] containing the property's [NodePath] and a [String] containing additional
## to be displayed alongside the value, using format strings
@export var props: Array[DevProperty] = []

func _ready() -> void:
	for prop in props:
		prop._parent = self
		prop.add_to_tab()
