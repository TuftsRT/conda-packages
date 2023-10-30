set MENU_DIR="%PREFIX%\Menu"
if not exist %MENU_DIR% mkdir %MENU_DIR%
copy "%RECIPE_DIR%\deeplabcut.ico" %MENU_DIR%
copy "%RECIPE_DIR%\deeplabcut.json" %MENU_DIR%
