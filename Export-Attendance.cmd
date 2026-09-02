@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Export-Attendance.ps1"
set "MOS_EXIT_CODE=%ERRORLEVEL%"
echo.
if not "%MOS_EXIT_CODE%"=="0" echo Export failed. See the error above.
if "%MOS_EXIT_CODE%"=="0" echo Export completed. The CSV file is in: %~dp0exports
echo.
pause
exit /b %MOS_EXIT_CODE%
