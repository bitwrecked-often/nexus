@echo off
rem 7DTD 3.0 Wasteland Animal Population Tuning - GUI launcher
rem Copyright (C) 2026 Bit Wrecked
rem SPDX-License-Identifier: GPL-3.0-or-later
rem See Support_Files_Do_Not_Edit\LICENSE.txt for details.
setlocal

set "SCRIPT_DIR=%~dp0"
set "TOOL_SCRIPT=%SCRIPT_DIR%7DTD_WastelandAnimalPopulationTuning_Tool.ps1"

if not exist "%TOOL_SCRIPT%" (
  set "TOOL_SCRIPT=%SCRIPT_DIR%Support_Files_Do_Not_Edit\7DTD_WastelandAnimalPopulationTuning_Tool.ps1"
)

if not exist "%TOOL_SCRIPT%" (
  echo Could not find the installer tool.
  echo Re-extract the zip and keep the support folder next to this file.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%TOOL_SCRIPT%"
