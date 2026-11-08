@echo off
setlocal enabledelayedexpansion

:: Esperar 8 segundos para que la conexion a internet y los servicios de Windows se inicialicen al encender
timeout /t 8 /nobreak >nul 2>&1

set "REPO=AngelGuevara04/lector-mangas"
set "WORKSPACE=C:\Users\ajgm1\Desktop\Amors"
set "ANTIGRAVITY_EXE=C:\Users\ajgm1\AppData\Local\Programs\antigravity\Antigravity.exe"
set "AGENT_API=C:\Users\ajgm1\.gemini\antigravity\bin\agentapi.bat"
set "LOG_FILE=%WORKSPACE%\auto_resolver_incidencias.log"

set "HAS_ISSUES="
for /f "delims=" %%i in ('gh issue list --repo %REPO% --state open 2^>nul') do (
    set "HAS_ISSUES=1"
)

if not defined HAS_ISSUES (
    :: No hay incidencias pendientes, salir silenciosamente
    exit /b 0
)

echo ========================================================================= >> "%LOG_FILE%"
echo [%date% %time%] INCIDENCIAS DETECTADAS EN %REPO% >> "%LOG_FILE%"
echo ========================================================================= >> "%LOG_FILE%"
gh issue list --repo %REPO% --state open >> "%LOG_FILE%" 2>&1

:: 1. Abrir la interfaz de Antigravity en el workspace del proyecto
if exist "%ANTIGRAVITY_EXE%" (
    start "" "%ANTIGRAVITY_EXE%" "%WORKSPACE%"
)

:: Esperar 5 segundos a que el entorno de Antigravity termine de cargar
timeout /t 5 /nobreak >nul 2>&1

:: 2. Instruir al agente de Antigravity para que resuelva las incidencias de forma autonoma y suba el parche
set PROMPT_TASK=Se han reportado incidencias abiertas en el repositorio AngelGuevara04/lector-mangas de AppParaMiAmors. Revisa las incidencias abiertas usando 'gh issue list --repo AngelGuevara04/lector-mangas --state open' y 'gh issue view <id>'. Analiza el codigo fuente en C:\Users\ajgm1\Desktop\Amors\desarrollo, implementa las correcciones o mejoras solicitadas, verifica que compile sin errores con 'dart analyze lib' y 'flutter test', genera el APK actualizado ejecutando 'compilar_apk.bat', sube los cambios a git, publica una nueva version con 'gh release create' que incluya el archivo AppParaMiAmors.apk y cierra las incidencias resueltas con 'gh issue close <id>'.

if exist "%AGENT_API%" (
    echo [%date% %time%] Lanzando conversacion autonoma en Antigravity para resolver incidencias... >> "%LOG_FILE%"
    call "%AGENT_API%" new-conversation --title="Auto-Resolucion Incidencias GitHub" "%PROMPT_TASK%" >> "%LOG_FILE%" 2>&1
)

exit /b 0
