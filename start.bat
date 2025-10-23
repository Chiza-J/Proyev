@echo off
REM Script de inicio para TechAssist en Windows
REM Ejecuta: start.bat

echo =========================================
echo   🎫 TechAssist - Sistema de Tickets
echo =========================================
echo.

REM Verificar Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker no está instalado
    echo    Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo ✓ Docker está disponible
echo.

echo 📦 Iniciando contenedores...
echo.

docker-compose up --build -d

if %errorlevel% equ 0 (
    echo.
    echo =========================================
    echo   ✅ TechAssist iniciado correctamente
    echo =========================================
    echo.
    echo 📱 Accede a la aplicación:
    echo    Frontend: http://localhost:3000
    echo    API Docs: http://localhost:8001/docs
    echo.
    echo 🔐 Credenciales de prueba:
    echo    Admin:    admin@techassist.com / password123
    echo    Técnico:  tecnico1@techassist.com / password123
    echo    Cliente:  cliente1@empresa.com / password123
    echo.
    echo 📊 SQL Server:
    echo    Host: localhost:1433
    echo    User: sa
    echo    Pass: TechAssist2025!
    echo    DB:   TechAssistDB
    echo.
    echo 📋 Comandos útiles:
    echo    Ver logs:    docker-compose logs -f
    echo    Detener:     docker-compose down
    echo    Reiniciar:   docker-compose restart
    echo.
    echo ⏳ Espera 30 segundos para que se inicialice...
    echo.
    pause
) else (
    echo.
    echo ❌ Error al iniciar los contenedores
    pause
    exit /b 1
)
