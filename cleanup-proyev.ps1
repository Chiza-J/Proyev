# cleanup-proyev.ps1
# Script para limpiar el proyecto TechAssist

Write-Host "Limpiando proyecto TechAssist..." -ForegroundColor Cyan
Write-Host "Este script eliminara archivos innecesarios" -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "Continuar? (S/N)"
if ($confirmation -ne 'S' -and $confirmation -ne 's') {
    Write-Host "Operacion cancelada" -ForegroundColor Red
    exit
}

# ========================================
# 1. CARPETAS COMPLETAS A ELIMINAR
# ========================================
Write-Host ""
Write-Host "Eliminando carpetas innecesarias..." -ForegroundColor Yellow

$foldersToDelete = @(
    ".emergent",
    "tests",
    "test_reports",
    "docker"
)

foreach ($folder in $foldersToDelete) {
    if (Test-Path $folder) {
        Remove-Item -Path $folder -Recurse -Force
        Write-Host "  Eliminado: $folder" -ForegroundColor Green
    } else {
        Write-Host "  No existe: $folder" -ForegroundColor Gray
    }
}

# ========================================
# 2. ARCHIVOS EN RAIZ A ELIMINAR
# ========================================
Write-Host ""
Write-Host "Eliminando archivos innecesarios en raiz..." -ForegroundColor Yellow

$rootFilesToDelete = @(
    "auth_testing.md",
    "backend_test.py",
    "database_schema.md",
    "mongodb_commands.md",
    "README_OLD.md",
    "seed_database.py",
    "start.bat",
    "start.sh",
    "test_result.md",
    "yarn.lock"
)

foreach ($file in $rootFilesToDelete) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Force
        Write-Host "  Eliminado: $file" -ForegroundColor Green
    } else {
        Write-Host "  No existe: $file" -ForegroundColor Gray
    }
}

# ========================================
# 3. ARCHIVOS DEL BACKEND
# ========================================
Write-Host ""
Write-Host "Limpiando Backend..." -ForegroundColor Yellow

$backendFilesToDelete = @(
    "backend\requirements_sqlserver.txt"
)

foreach ($file in $backendFilesToDelete) {
    if (Test-Path $file) {
        $delete = Read-Host "  Eliminar $file? (S/N)"
        if ($delete -eq 'S' -or $delete -eq 's') {
            Remove-Item -Path $file -Force
            Write-Host "    Eliminado: $file" -ForegroundColor Green
        }
    }
}

# ========================================
# 4. ARCHIVOS DEL FRONTEND
# ========================================
Write-Host ""
Write-Host "Limpiando Frontend..." -ForegroundColor Yellow

$frontendFoldersToDelete = @(
    "frontend\plugins"
)

foreach ($folder in $frontendFoldersToDelete) {
    if (Test-Path $folder) {
        Remove-Item -Path $folder -Recurse -Force
        Write-Host "  Eliminado: $folder" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "  Hay 50+ componentes UI en frontend\src\components\ui\" -ForegroundColor Cyan
Write-Host "  Revisa manualmente y elimina los que NO uses" -ForegroundColor Cyan

# ========================================
# 5. CREAR .dockerignore
# ========================================
Write-Host ""
Write-Host "Creando archivos .dockerignore..." -ForegroundColor Yellow

$backendDockerignore = @"
venv/
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
*.so
.env
.venv
env/
ENV/
.git
.gitignore
*.log
.DS_Store
*.db
*.sqlite
"@

$backendPath = "backend\.dockerignore"
Set-Content -Path $backendPath -Value $backendDockerignore
Write-Host "  Creado: $backendPath" -ForegroundColor Green

$frontendDockerignore = @"
node_modules/
build/
.git
.gitignore
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.DS_Store
coverage/
"@

$frontendPath = "frontend\.dockerignore"
Set-Content -Path $frontendPath -Value $frontendDockerignore
Write-Host "  Creado: $frontendPath" -ForegroundColor Green

# ========================================
# 6. ACTUALIZAR .gitignore
# ========================================
Write-Host ""
Write-Host "Actualizando .gitignore..." -ForegroundColor Yellow

$gitignore = @"
# Backend
backend/venv/
backend/__pycache__/
backend/*.pyc
backend/.env

# Frontend
frontend/node_modules/
frontend/build/
frontend/.env
frontend/.env.local

# Docker
.docker/

# Database
sqlserver_data/

# Tests
tests/
test_reports/
*.test.js

# Logs
*.log

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Temp
*.tmp
*.bak
"@

Set-Content -Path ".gitignore" -Value $gitignore
Write-Host "  Actualizado: .gitignore" -ForegroundColor Green

# ========================================
# 7. RESUMEN
# ========================================
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "LIMPIEZA COMPLETADA" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Estructura limpia:" -ForegroundColor Yellow
Write-Host "  Eliminadas carpetas: .emergent, tests, test_reports, docker" -ForegroundColor White
Write-Host "  Eliminados archivos obsoletos de raiz" -ForegroundColor White
Write-Host "  Creados .dockerignore en backend y frontend" -ForegroundColor White
Write-Host "  Actualizado .gitignore" -ForegroundColor White
Write-Host ""
Write-Host "REVISAR MANUALMENTE:" -ForegroundColor Yellow
Write-Host "  frontend\src\components\ui\ - Eliminar componentes no usados" -ForegroundColor White
Write-Host "  backend\google_oauth.py - Eliminar si no usas Google OAuth" -ForegroundColor White
Write-Host "  docs\ - Revisar documentacion obsoleta" -ForegroundColor White
Write-Host ""
Write-Host "Siguiente paso: docker-compose up --build" -ForegroundColor Cyan