#!/bin/bash

# Script de inicio para TechAssist
# Ejecuta: bash start.sh

echo "========================================="
echo "  🎫 TechAssist - Sistema de Tickets"
echo "========================================="
echo ""

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado"
    echo "   Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Verificar si Docker está corriendo
if ! docker info &> /dev/null; then
    echo "❌ Docker no está corriendo"
    echo "   Inicia Docker Desktop y vuelve a intentar"
    exit 1
fi

echo "✓ Docker está disponible"
echo ""

# Verificar si docker-compose está disponible
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "❌ docker-compose no está disponible"
    exit 1
fi

echo "✓ Docker Compose está disponible"
echo ""

echo "📦 Iniciando contenedores..."
echo ""

# Iniciar con docker-compose
$COMPOSE_CMD up --build -d

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "  ✅ TechAssist iniciado correctamente"
    echo "========================================="
    echo ""
    echo "📱 Accede a la aplicación:"
    echo "   Frontend: http://localhost:3000"
    echo "   API Docs: http://localhost:8001/docs"
    echo ""
    echo "🔐 Credenciales de prueba:"
    echo "   Admin:    admin@techassist.com / password123"
    echo "   Técnico:  tecnico1@techassist.com / password123"
    echo "   Cliente:  cliente1@empresa.com / password123"
    echo ""
    echo "📊 SQL Server:"
    echo "   Host: localhost:1433"
    echo "   User: sa"
    echo "   Pass: TechAssist2025!"
    echo "   DB:   TechAssistDB"
    echo ""
    echo "📋 Comandos útiles:"
    echo "   Ver logs:    docker-compose logs -f"
    echo "   Detener:     docker-compose down"
    echo "   Reiniciar:   docker-compose restart"
    echo ""
    echo "⏳ Espera 30 segundos para que se inicialice la BD..."
    echo ""
    
    # Mostrar logs
    echo "Mostrando logs (Ctrl+C para salir)..."
    $COMPOSE_CMD logs -f
else
    echo ""
    echo "❌ Error al iniciar los contenedores"
    echo "   Revisa los errores arriba"
    exit 1
fi
