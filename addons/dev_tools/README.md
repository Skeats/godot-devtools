I don't know how to write a README so bear with me:

Step 1: The Console
The console was graciously stolen and modified from this plugin: https://godotengine.org/asset-library/asset/3533
so if you have any additional questions about it then hopefully that will help.

Otherwise, the way it works is simple, once you enable the plugin a new autoload called DevTools will be
added to your autoload list, in which will contain all sorts of goodies for you to muck about with.
in the autoload, the most notable things are the constant for the key to open the console
(defaults to KEY_QUOTELEFT, or that key right below the escape key), as well as an enum containing tags.

These tags, in combination with a new console_print function, allow you to filter your output based
on what is relevant at the moment. This way you can leave all of the helpful debugging print statements
that you used while developing something, but not have it clutter up your console/stdout when you are
working on other things. for more information, you can just use the tag_info builtin command on the console.

Speaking of console commands, I have done almost nothing to change the original plugin's handling of that.
I had even tried my hand at my own naive approach for the same sort of design, but this plugin was much
more sophisticated in things such as autocomplete (in which my version had none), and argument parsing
(of which my approach also had none). I did however feel like it was important for me to implement a
way to granularly customize the arguments if needed, so I made it so that if the function that the
command calls has an array as an argument it will bypass all argument parsing, leaving you to handle
the raw strings as you wish.

A simple explanation of how the commands work, if you call the create_command function, pass it a name
callable, and description, it will create a command that you can use in the console. If the callable
returns anything, it will print the return value in the console, which is nice for providing confirmation
that the command has ran.

Finally, there are the other tabs. These are my overengineered attempt at a really convenient property
monitor, similar to the likes of Minecraft's F3 menu. All you need to do to add your own properties to
the tab is add a DevMenuUpdater node in the scene that your properties are, then add new DevProperty
resources, each of which contain a name, path to the node that the property is on, property path, and
a few other variables that you can hover over for more detailed descriptions of. This was my first
attempt at making this process easy, as before I was simply handling all of it mostly manually. I
do plan on returning and making this feature nicer in the future, but I just wanted to get something
working to start.

You may note that there is a nde Dev Tools tab in the bottom dock, which doesn't contain anything.
Yes, that is intentional. No, I do not care. Yes, I will add something there eventually.
