@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\godot.ps1" -Mode run
if errorlevel 1 (
    echo Nao foi possivel iniciar o jogo. Confira a mensagem acima.
    pause
    exit /b 1
)
