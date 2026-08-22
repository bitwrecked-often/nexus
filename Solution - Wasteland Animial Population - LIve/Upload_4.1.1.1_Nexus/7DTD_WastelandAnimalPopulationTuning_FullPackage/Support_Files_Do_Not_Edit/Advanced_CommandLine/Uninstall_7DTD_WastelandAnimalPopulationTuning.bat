@echo off
rem 7DTD 3.0 Wasteland Animal Population Tuning - advanced command-line uninstaller launcher
rem Copyright (C) 2026 Bit Wrecked
rem SPDX-License-Identifier: GPL-3.0-or-later
rem See ..\LICENSE.txt for details.
setlocal

set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Uninstall_7DTD_WastelandAnimalPopulationTuning.ps1"

echo.
pause
