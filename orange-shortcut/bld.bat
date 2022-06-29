set MENU_DIR="%PREFIX%\Menu"
if not exist %MENU_DIR% mkdir %MENU_DIR%
copy "%RECIPE_DIR%\orange.ico" %MENU_DIR%
copy "%RECIPE_DIR%\orange.json" %MENU_DIR%
