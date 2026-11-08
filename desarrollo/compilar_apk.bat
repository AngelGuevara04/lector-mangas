@echo off
echo ==============================================
echo  Compilando AppParaMiAmors (Modo Ligero)...
echo ==============================================
call flutter build apk --debug
if %errorlevel% neq 0 (
    echo Error al compilar el APK.
    exit /b %errorlevel%
)
echo.
echo Copiando APK a la carpeta principal...
copy /Y build\app\outputs\flutter-apk\app-debug.apk ..\AppParaMiAmors.apk
echo.
echo ==============================================
echo  Listo! APK actualizado en: ..\AppParaMiAmors.apk
echo ==============================================
