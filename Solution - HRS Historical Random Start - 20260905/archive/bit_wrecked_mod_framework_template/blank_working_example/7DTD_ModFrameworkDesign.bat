@echo off
setlocal DisableDelayedExpansion

call "%~dp0Blank_BitWreckedMod.bat"
set "LAUNCHER_EXIT_CODE=%ERRORLEVEL%"

endlocal & exit /b %LAUNCHER_EXIT_CODE%
