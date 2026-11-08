@echo off
setlocal enabledelayedexpansion

:: Esperar 5 segundos para que la conexion a internet se establezca al arrancar
timeout /t 5 /nobreak >nul 2>&1

set "HAS_ISSUES="
for /f "delims=" %%i in ('gh issue list --repo AngelGuevara04/lector-mangas --state open 2^>nul') do (
    set "HAS_ISSUES=1"
)

if defined HAS_ISSUES (
    echo =========================================================================
    echo  [APPPARAMIAMORS] SE HAN REPORTADO INCIDENCIAS O SUGERENCIAS PENDIENTES
    echo =========================================================================
    echo.
    gh issue list --repo AngelGuevara04/lector-mangas --state open
    echo.
    echo Abriendo incidencias en tu navegador para revisarlas...
    start https://github.com/AngelGuevara04/lector-mangas/issues
    pause
) else (
    :: No hay incidencias pendientes, salir silenciosamente
    exit /b 0
)
