set MENU_DIR="%PREFIX%\Menu"
if not exist %MENU_DIR% mkdir %MENU_DIR%
copy "%RECIPE_DIR%\jupyterlab-shortcut.ico" %MENU_DIR%
copy "%RECIPE_DIR%\jupyterlab-shortcut.json" %MENU_DIR%
