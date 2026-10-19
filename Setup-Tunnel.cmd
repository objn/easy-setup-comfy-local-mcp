@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Tunnel.ps1" -Setup
if errorlevel 1 pause
