set SCRIPTS_DIR="%PREFIX%\Scripts"
if not exist "%SCRIPTS_DIR%" mkdir "%SCRIPTS_DIR%"
if exist "%SCRIPTS_DIR%\glue-script.py" del "%SCRIPTS_DIR%\glue-script.py"
copy "%RECIPE_DIR%\glue-script.py" "%SCRIPTS_DIR%"

set MENU_DIR="%PREFIX%\Menu"
if not exist "%MENU_DIR%" mkdir "%MENU_DIR%"
copy "%RECIPE_DIR%\glue.ico" "%MENU_DIR%"
copy "%RECIPE_DIR%\glue.json" "%MENU_DIR%"
