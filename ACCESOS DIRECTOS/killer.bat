@echo off
:: Cerrar ventanas del explorador (sin cerrar la barra de tareas)
powershell -Command "(New-Object -ComObject Shell.Application).Windows() | ForEach-Object { $_.Quit() }" >nul 2>&1
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM firefox.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1
taskkill /F /IM opera.exe >nul 2>&1
taskkill /F /IM brave.exe >nul 2>&1
taskkill /F /IM notepad.exe >nul 2>&1
taskkill /F /IM notepad++.exe >nul 2>&1
taskkill /F /IM WINWORD.EXE >nul 2>&1
taskkill /F /IM EXCEL.EXE >nul 2>&1
taskkill /F /IM POWERPNT.EXE >nul 2>&1
taskkill /F /IM vlc.exe >nul 2>&1
taskkill /F /IM olk.exe >nul 2>&1
taskkill /F /IM Spotify.exe >nul 2>&1
taskkill /F /IM WhatsApp.exe >nul 2>&1
exit
