@echo off
Echo Create Recipes library for current user (run in user context)
shlib create "%userprofile%\AppData\Roaming\Microsoft\Windows\Libraries\Recipes.library-ms"
pause

Echo Add two folders to Recipes library
shlib add "%userprofile%\AppData\Roaming\Microsoft\Windows\Libraries\Recipes.library-ms" "C:\Baking Recipes"
shlib add "%userprofile%\AppData\Roaming\Microsoft\Windows\Libraries\Recipes.library-ms" "C:\Pastry Recipes"
pause

Echo Since the 1st folder added is the default save location, change it to the other folder
shlib setsaveloc "%userprofile%\AppData\Roaming\Microsoft\Windows\Libraries\Recipes.library-ms" "C:\Pastry Recipes"
pause

Echo Remove the 2nd folder and the default save location will go back to the remaining folder
shlib remove "%userprofile%\AppData\Roaming\Microsoft\Windows\Libraries\Recipes.library-ms" "C:\Pastry Recipes"
pause

Echo Just delete the file to remove the library
del "%userprofile%\AppData\Roaming\Microsoft\Windows\Libraries\Recipes.library-ms"
pause