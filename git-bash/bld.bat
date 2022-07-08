7za x PortableGit-%PKG_VERSION%-%ARCH%-bit.7z.exe -o"%LIBRARY_PREFIX%\" -aoa
if errorlevel 1 exit 1

call %LIBRARY_PREFIX%\post-install.bat
del %LIBRARY_PREFIX%\git_bash.exe
del %LIBRARY_PREFIX%\git_cmd.exe
del %LIBRARY_PREFIX%\README.portable
del %LIBRARY_PREFIX%\post-install.bat

IF NOT EXIST %PREFIX%\Menu mkdir %PREFIX%\Menu
copy %RECIPE_DIR%\git-bash.json %PREFIX%\Menu\
copy %RECIPE_DIR%\git-bash.ico %PREFIX%\Menu\

del %LIBRARY_PREFIX%\etc\profile.d\git-prompt.sh
copy %RECIPE_DIR%\git-prompt.sh %LIBRARY_PREFIX%\etc\profile.d\ /y

echo export PATH=$(cygpath -a %PREFIX:\=/%)/Library/bin:$PATH >> %LIBRARY_PREFIX%\etc\profile.d\env.sh
echo. >> %LIBRARY_PREFIX%\etc\profile.d\env.sh

exit 0
