@echo off
setlocal enabledelayedexpansion

:: Esperar 8 segundos para que la conexion a internet y los servicios de Windows se inicialicen al encender
timeout /t 8 /nobreak >nul 2>&1

set "REPO=AngelGuevara04/lector-mangas"
set "WORKSPACE=C:\Users\ajgm1\Desktop\Amors"
set "ANTIGRAVITY_EXE=C:\Users\ajgm1\AppData\Local\Programs\antigravity\Antigravity.exe"
set "AGENT_API=C:\Users\ajgm1\.gemini\antigravity\bin\agentapi.bat"
set "DOCKER_EXE=C:\Program Files\Docker\Docker\Docker Desktop.exe"
set "LOG_FILE=%WORKSPACE%\auto_resolver_incidencias.log"
set "SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxdmx3Y3FmanFydWtndndmaG5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5MjQ5MzYsImV4cCI6MjA5ODUwMDkzNn0.F1AYU6R5ri3DnZEdfsHA9dTRbZXEpNdjalZWd5nfWp8"

:: 1. Verificar si hay incidencias abiertas en GitHub
set "HAS_ISSUES="
for /f "delims=" %%i in ('gh issue list --repo %REPO% --state open 2^>nul') do (
    set "HAS_ISSUES=1"
)

:: 2. Verificar si hay incidencias o sugerencias pendientes enviadas directamente desde la app en Supabase
set "HAS_DB_ISSUES="
for /f "tokens=* usebackq" %%a in (`curl.exe -s -H "apikey: %SUPABASE_KEY%" "https://pqvlwcqfjqrukgvwfhnh.supabase.co/rest/v1/app_suggestions?select=id&status=eq.pending&or=(message.ilike.*AppParaMiAmors*,type.eq.capitulo_caido)" 2^>nul`) do (
    set "RES_DB=%%a"
    if not "!RES_DB!"=="[]" (
        if not "!RES_DB!"=="" (
            set "HAS_DB_ISSUES=1"
        )
    )
)

if not defined HAS_ISSUES (
    if not defined HAS_DB_ISSUES (
        :: No hay incidencias pendientes, salir silenciosamente
        exit /b 0
    )
)

echo ========================================================================= >> "%LOG_FILE%"
echo [%date% %time%] INCIDENCIAS ABIERTAS O SUGERENCIAS DETECTADAS >> "%LOG_FILE%"
echo ========================================================================= >> "%LOG_FILE%"
if defined HAS_ISSUES (
    echo [GitHub Issues]: >> "%LOG_FILE%"
    gh issue list --repo %REPO% --state open >> "%LOG_FILE%" 2>&1
)
if defined HAS_DB_ISSUES (
    echo [Supabase In-App Reports]: >> "%LOG_FILE%"
    curl.exe -s -H "apikey: %SUPABASE_KEY%" "https://pqvlwcqfjqrukgvwfhnh.supabase.co/rest/v1/app_suggestions?select=id,type,message&status=eq.pending&or=(message.ilike.*AppParaMiAmors*,type.eq.capitulo_caido)" >> "%LOG_FILE%" 2>&1
)

:: 3. Verificar si Docker esta corriendo; si no lo esta y existe el ejecutable, iniciarlo
docker info >nul 2>&1
if %errorlevel% neq 0 (
    if exist "%DOCKER_EXE%" (
        echo [%date% %time%] Iniciando Docker Desktop... >> "%LOG_FILE%"
        start "" "%DOCKER_EXE%"
        timeout /t 10 /nobreak >nul 2>&1
    )
)

:: 4. Abrir la interfaz de Antigravity en el workspace del proyecto
if exist "%ANTIGRAVITY_EXE%" (
    start "" "%ANTIGRAVITY_EXE%" "%WORKSPACE%"
)

:: Esperar 5 segundos a que el entorno de Antigravity termine de cargar
timeout /t 5 /nobreak >nul 2>&1

:: 5. Instruir al agente de Antigravity para que resuelva las incidencias, suba todo y cierre todo lo usado al terminar
set PROMPT_TASK=Se han detectado incidencias o reportes pendientes para AppParaMiAmors (AngelGuevara04/lector-mangas o Supabase app_suggestions). SIGUE ESTOS PASOS HASTA TERMINAR: 1) Si se requiere Docker para alguna operacion y no esta activo, verificalo con 'docker info' o inicialo con 'C:\Program Files\Docker\Docker\Docker Desktop.exe'. 2) Revisa las incidencias abiertas usando 'gh issue list --repo AngelGuevara04/lector-mangas --state open' y consulta la tabla app_suggestions de Supabase (con status=pending). 3) Analiza el codigo fuente en C:\Users\ajgm1\Desktop\Amors\desarrollo, implementa las correcciones o mejoras solicitadas. 4) Verifica que el codigo compile limpiamente con 'dart analyze lib' y 'flutter test'. 5) Compila el APK actualizado con 'compilar_apk.bat'. 6) Incrementa la version en pubspec.yaml y update_service.dart, haz git add, commit y 'git push origin main'. 7) Publica la nueva version en GitHub Releases con 'gh release create' adjuntando 'AppParaMiAmors.apk'. 8) Cierra las incidencias resueltas en GitHub con 'gh issue close' y actualiza en Supabase a status='resolved'. 9) CIERRE TOTAL: Una vez publicado todo y resueltas las incidencias, CIERRA TODO lo que abriste/usaste para no dejar procesos consumiendo memoria. Si Docker fue abierto, cierralo con 'taskkill /F /IM "Docker Desktop.exe" /IM "com.docker.backend.exe" /T 2>nul'. Y finalmente cierra la ventana de Antigravity ejecutando 'taskkill /F /IM Antigravity.exe /T'.

if exist "%AGENT_API%" (
    echo [%date% %time%] Lanzando agente autonomo en Antigravity para resolver y cerrar todo... >> "%LOG_FILE%"
    call "%AGENT_API%" new-conversation --title="Auto-Resolucion y Cierre de Incidencias" "%PROMPT_TASK%" >> "%LOG_FILE%" 2>&1
)

exit /b 0
