@tool
extends EditorPlugin

const PLUGIN_NAME = "dev_tools"
const AUTOLOAD_NAME = "DevTools"

const SETTINGS: Dictionary = {
	"general" : {
		"capture_mouse_on_close" : {
			"type" : TYPE_BOOL,
			"default_value" : false
		},
		"remember_last_tab" : {
			"type" : TYPE_BOOL,
			"default_value" : true
		},
	},
	"console" : {
		"max_history_size" : {
			"type" : TYPE_INT,
			"default_value" : 100
		},
		"output_background_color" : {
			"type" : TYPE_COLOR,
			"default_value" : Color(0, 0, 0, 0.784)
		},
		"input_background_color" : {
			"type" : TYPE_COLOR,
			"default_value" : Color(0.098, 0.098, 0.098, 0.784)
		},
		"font_color" : {
			"type" : TYPE_COLOR,
			"default_value" : Color(1, 1, 1, 1)
		},
	},
	"menu_tabs" : {
		"properties_background_color" : {
			"type" : TYPE_COLOR,
			"default_value" : Color(0.098, 0.098, 0.098, 0.784)
		},
		"font_color" : {
			"type" : TYPE_COLOR,
			"default_value" : Color(1, 1, 1, 1)
		},
	},
	"log.gd" : {
		"color_theme" :{
			"type" : TYPE_STRING,
			"default_value" : Log.LOG_THEME_TERMSAFE
		},
		"disable_colors" :{
			"type" : TYPE_BOOL,
			"default_value" : false
		},
		"max_array_size" :{
			"type" : TYPE_INT,
			"default_value" : 20
		},
		"dictionary_skip_keys" :{
			"type" : TYPE_ARRAY,
			"default_value" : [
				"layer_0/tile_data", # skip huge tilemap arrays
				]
		}
	}
}

var _bottom_panel: Control = null

func _enter_tree() -> void:
	# Adds the editor UI to the bottom panel
	_bottom_panel = preload("res://addons/dev_tools/gui/bottom_panel/bottom_panel.tscn").instantiate()

	var button = add_control_to_bottom_panel(_bottom_panel, "Dev Tools")
	button.shortcut_in_tooltip = true

func _exit_tree() -> void:
	remove_control_from_bottom_panel(_bottom_panel)
	_bottom_panel.free()


func _enable_plugin():
	# registers autoloads
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/dev_tools/dev_tools.gd")
	_add_project_settings()

func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)
	_remove_project_settings()


func _add_project_settings() -> void:
	for section : String in SETTINGS:
		for setting : String in SETTINGS[section]:
			var setting_name : String = "dev_tools/%s/%s" % [section, setting]
			if not ProjectSettings.has_setting(setting_name):
				ProjectSettings.set_setting(setting_name, \
				SETTINGS[section][setting]["default_value"])

			ProjectSettings.set_initial_value(setting_name, SETTINGS[section][setting]["default_value"])
			ProjectSettings.set_as_basic(setting_name, true)

			var error : int = ProjectSettings.save()
			if not error == OK:
				push_error("Dev Tools - error %s while saving project settings." % error_string(error))


func _remove_project_settings() -> void:
	for section : String in SETTINGS:
		for setting : String in SETTINGS[section]:
			var setting_name : String = "dev_tools/%s/%s" % [section, setting]
			if ProjectSettings.has_setting(setting_name):
				ProjectSettings.set_setting(setting_name, null)

			var error : int = ProjectSettings.save()
			if not error == OK:
				push_error("Dev Tools - error %s while saving project settings." % error_string(error))
