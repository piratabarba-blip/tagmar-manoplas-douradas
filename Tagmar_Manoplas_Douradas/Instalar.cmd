@echo off
title Instalar cursores Tagmar
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar.ps1"
if errorlevel 1 echo Nao foi possivel concluir. Veja a mensagem acima.
echo.
pause
