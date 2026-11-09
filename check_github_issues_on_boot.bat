@echo off
:: Esperar 10 segundos para que la red y servicios de Windows se inicialicen al encender la PC
timeout /t 10 /nobreak >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\ajgm1\Desktop\Amors\auto_check_issues.ps1"
exit /b 0
