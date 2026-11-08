@echo off
setlocal enabledelayedexpansion

echo =========================================================================
echo  [APPPARAMIAMORS] REVISOR Y AUTO-RESOLUTOR DE INCIDENCIAS GITHUB
echo =========================================================================
echo.

set "REPO=AngelGuevara04/lector-mangas"
set "WORKSPACE=C:\Users\ajgm1\Desktop\Amors"
set "ANTIGRAVITY_EXE=C:\Users\ajgm1\AppData\Local\Programs\antigravity\Antigravity.exe"
set "AGENT_API=C:\Users\ajgm1\.gemini\antigravity\bin\agentapi.bat"
set "DOCKER_EXE=C:\Program Files\Docker\Docker\Docker Desktop.exe"

echo Consultando incidencias abiertas en %REPO%...
set "HAS_ISSUES="
for /f "delims=" %%i in ('gh issue list --repo %REPO% --state open 2^>nul') do (
    set "HAS_ISSUES=1"
)

if not defined HAS_ISSUES (
    echo.
    echo  [OK] No hay incidencias abiertas pendientes en el repositorio.
    echo       Todo el sistema esta al dia.
    echo.
    pause
    exit /b 0
)

echo.
echo Se encontraron las siguientes incidencias abiertas:
gh issue list --repo %REPO% --state open
echo.

:: 1. Docker
docker info >nul 2>&1
if %errorlevel% neq 0 (
    if exist "%DOCKER_EXE%" (
        echo Iniciando Docker Desktop por si se requiere...
        start "" "%DOCKER_EXE%"
        timeout /t 5 /nobreak >nul 2>&1
    )
)

:: 2. Antigravity
echo Abriendo Antigravity...
if exist "%ANTIGRAVITY_EXE%" (
    start "" "%ANTIGRAVITY_EXE%" "%WORKSPACE%"
)

timeout /t 4 /nobreak >nul 2>&1

:: 3. Lanzar agente
set PROMPT_TASK=Se han detectado incidencias abiertas en el repositorio AngelGuevara04/lector-mangas de AppParaMiAmors. SIGUE ESTOS PASOS HASTA TERMINAR: 1) Si se requiere Docker para alguna operacion y no esta activo, verificalo con 'docker info' o inicialo con 'C:\Program Files\Docker\Docker\Docker Desktop.exe'. 2) Revisa cada incidencia abierta usando 'gh issue list --repo AngelGuevara04/lector-mangas --state open' y 'gh issue view <id>'. 3) Analiza el codigo fuente en C:\Users\ajgm1\Desktop\Amors\desarrollo, implementa las correcciones o mejoras solicitadas. 4) Verifica que el codigo compile limpiamente con 'dart analyze lib' y 'flutter test'. 5) Compila el APK actualizado con 'compilar_apk.bat'. 6) Incrementa la version en pubspec.yaml y update_service.dart, haz git add, commit y 'git push origin main'. 7) Publica la nueva version en GitHub Releases con 'gh release create' adjuntando 'AppParaMiAmors.apk'. 8) Cierra las incidencias resueltas en GitHub con 'gh issue close <id> --comment ...'. 9) CIERRE TOTAL: Una vez publicado todo y resueltas las incidencias, CIERRA TODO lo que abriste/usaste para no dejar procesos consumiendo memoria. Si Docker fue abierto, cierralo con 'taskkill /F /IM "Docker Desktop.exe" /IM "com.docker.backend.exe" /T 2>nul'. Y finalmente cierra la ventana de Antigravity ejecutando 'taskkill /F /IM Antigravity.exe /T'.

if exist "%AGENT_API%" (
    echo Iniciando resolucion automatica y cierre de programas en Antigravity...
    call "%AGENT_API%" new-conversation --title="Auto-Resolucion y Cierre de Incidencias" "%PROMPT_TASK%"
)

echo.
echo =========================================================================
echo  Agente asignado exitosamente. Se resolvera, subira y cerrara todo solo.
echo =========================================================================
pause
exit /b 0
