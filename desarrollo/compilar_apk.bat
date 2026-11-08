@echo off
echo ==============================================
echo  Compilando MangaFlow (Modo Ligero)...
echo ==============================================
call flutter build apk --debug
if %errorlevel% neq 0 (
    echo Error al compilar el APK.
    exit /b %errorlevel%
)
echo.
echo Copiando APK a la carpeta principal...
copy /Y build\app\outputs\flutter-apk\app-debug.apk ..\MangaFlow.apk
echo.
echo ==============================================
echo  Listo! APK actualizado en: ..\MangaFlow.apk
echo ==============================================
