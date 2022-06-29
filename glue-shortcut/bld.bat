set MENU_DIR="%PREFIX%\Menu"
if not exist %MENU_DIR% mkdir %MENU_DIR%
copy "%RECIPE_DIR%\glue.ico" %MENU_DIR%
copy "%RECIPE_DIR%\glue.json" %MENU_DIR%
