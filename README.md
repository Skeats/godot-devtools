# Kiki's DevTools
This is a collection of Dev Tools I have created (and found) that are designed to mesh seamlessly with each other. Some features include a full featured console , console output filtering, property monitoring, and more to come.

### Full Feature List
- Resizable Dev Menu
- Feature-Rich Console courtesy of [takanazwa5](https://github.com/takanazwa5) | [Asset Library Link](https://godotengine.org/asset-library/asset/3533)
- Console Output Filter Tags
- Highly Customizable Property Monitoring Tabs

### Todo List
- Module System (idea courtesy of [Mark Velez](https://github.com/MarkVelez)'s console, found [here](https://github.com/MarkVelez/godot-simply-console)
- Refactor Property Monitors (the current implementation is clunky to use, and I would like something a bit more intuitive, something closer to how the MultiplayerSynchronizer node works in Godot already)
- Figure out why project settings didn't seem to be working properly
- Add an easy way to change things like the output tags or the open key that don't require going into the plugin code

# Overview
All of the functionality described below can be accessed using the new `DevTools` autoload, or through specific nodes and resources such as the `DevMenuUpdater` node or the `DevProperty` resource. More information on all of this can be found below. 

> [!NOTE] 
> To open the dev menu, press the `~` key.

## The Console
The most basic way to use the console is fairly easy. First, you create a function that does whatever you want the command to do. Some basic rules about the function are as follows:
- It is HIGHLY recommended (if not required) that you statically type the arguments in your functions.
- Primitive data types, such as ints, floats, and strings are all reliable types for your function arguments.
- Other data types may also work, but it behavior can be odd. For more information on how the parser handles arguments, you can read up on [this function](https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html#class-globalscope-method-type-convert) from Godot, as that is what it uses in the backend
- I have modified the original console to handle Array data types slightly differently. If your function uses an array, the parser will skip any argument parsing and feed the raw arguments into the function, which will allow you to parse them on a function-by-function basis. It is recommended that you only use one argument when using an Array, as using more than that is not intended behavior and can have unexpected effects.
- The return value of the function (if any) will be printed to the console. This can be used to provide confirmation that the function has run, without needing to include a print statement inside of the function itself.

Once you have created your function, all you need to do is add a function call in the `_ready` function of the script where the function is located, which should look something like this:
```
func _ready() -> void:
	DevTools.create_command(my_function)
```
Passing additional arguments into the `create_command` call will allow you to do things like set a different name for the command than the function name (helpful for making commands out of private methods), as well as adding a description to the command, which will be shown when the `help` command is used.

### Printing to the Console from Code
Printing to the console is fairly simple. There is a `console_print` function inside of the DevTools autoload, which takes 2 parameters: The text that you wish to print, and an array containing tags that you would like to tag this statement with. This allows you to filter your output based on what is relevant at the moment. This way you can leave all of the helpful debugging print statements that you used while developing something, but not have it clutter up your console/stdout when you are working on other things. For more information, you can just use the tag_info command on the console.

## Property Monitoring
You can monitor any property on any node easily using the tabs to the right of the console in the menu. To add properties to be monitored, add a `DevMenuUpdater` node to the scene in which the properties you want to track are. Then, in the Inspector, you can add properties to the array on the updater, which will automatically be registered and added to the menu at project runtime.

Inside of the DevProperty resource which the updater uses to track properties, you will find multiple values that control how the property works:
- The update frequency defines how long the updater will wait before updating that property again, in milliseconds.
- The prop name is the exact name of the property, as it will appear in the menu.
- The prop value is the node that the property is on, and the prop property is the actual property path.[^1]
- The value text contains any additional text that you want to be displayed alongside your property value, for example adding units to the end for clarification. The value text uses simple [format strings](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html).
- Finally, the tab name is the name of the tab that this property should be added under. If the tab does not exist already, a new one will be created using this name.

Here is an example of a functional tracked property:

![A property being tracked](https://github.com/user-attachments/assets/c33c0035-1a0e-44ec-86a0-f0aaebe35a41)
![image](https://github.com/user-attachments/assets/26ac3145-cb08-48f6-b209-1af943d1144c)

The property is a simple counter that adds the delta of each process frame to it. This logic is held on the root node of the scene where the `DevMenuUpdater` is located, and it updates every 0.1 seconds, or 100 milliseconds. It was added to a new Test tab that it created, and using format strings the float value is being truncated to 3 decimal places.
