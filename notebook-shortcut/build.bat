set MENU_DIR="%PREFIX%\Menu"
if not exist %MENU_DIR% mkdir %MENU_DIR%
copy "%RECIPE_DIR%\notebook-shortcut.ico" %MENU_DIR%
copy "%RECIPE_DIR%\notebook-shortcut.json" %MENU_DIR%
