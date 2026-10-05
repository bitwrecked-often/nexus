@echo off
setlocal
call "%~dp0customer\HistoricalRandomStart_1.2.7\START.bat" %*
exit /b %errorlevel%
