@echo off
title VetCare - servidor
cd /d "%~dp0"
echo ==========================================================
echo   VetCare - Sistema veterinario
echo   Abriendo http://localhost:8080  (Ctrl+C para detener)
echo   Companeros en la misma red: http://IP-DE-ESTA-PC:8080
echo ==========================================================
if not exist config\db.properties (
    echo.
    echo  Falta config\db.properties: copie config\db.properties.example y ponga su clave.
    pause
    exit /b 1
)
start "" cmd /c "timeout /t 12 >nul & start http://localhost:8080"
mvn -q spring-boot:run
pause
