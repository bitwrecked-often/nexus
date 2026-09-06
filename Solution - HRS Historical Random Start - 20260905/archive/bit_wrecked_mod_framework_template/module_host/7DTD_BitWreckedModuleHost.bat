@echo off
rem Bit Wrecked Module Host 0.0.1
rem Copyright (C) 2026 Bit Wrecked contributors
rem SPDX-License-Identifier: GPL-3.0-or-later
setlocal
set "TOOL_PATH=%~dp0BitWrecked_ModuleHost_Tool.ps1"
powershell.exe -NoProfile -STA -File "%TOOL_PATH%" %*
set "TOOL_EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %TOOL_EXIT_CODE%
