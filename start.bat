@echo off
:: Проверяем, есть ли dead.ps1 в той же папке
if not exist "%~dp0dead.ps1" (
    echo dead.ps1 not found in current folder!
    pause
    exit /b
)

:: Запускаем dead.ps1 через PowerShell с правами администратора
powershell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0dead.ps1\"'"
