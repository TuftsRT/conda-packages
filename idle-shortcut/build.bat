set MENU_DIR="%PREFIX%\Menu"
if not exist %MENU_DIR% mkdir %MENU_DIR%
copy "%RECIPE_DIR%\idle-shortcut.ico" %MENU_DIR%
copy "%RECIPE_DIR%\idle-shortcut.json" %MENU_DIR%
