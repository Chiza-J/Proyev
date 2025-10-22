# 🎫 TechAssist - Sistema de Tickets de Soporte TI

## 🚀 Inicio Rápido con Docker (UN SOLO COMANDO)

### Prerrequisitos
- Docker Desktop instalado
- Docker Compose instalado
- 8GB RAM disponible
- Puertos 1433, 3000, 8001 disponibles

### Ejecutar TODO con un solo comando:

```bash
docker-compose up --build
```

¡Eso es todo! El sistema:
1. ✓ Descarga SQL Server
2. ✓ Crea la base de datos automáticamente
3. ✓ Inserta datos de ejemplo
4. ✓ Inicia el backend FastAPI
5. ✓ Inicia el frontend React

### Acceder a la aplicación:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8001/docs
- **SQL Server**: localhost:1433

### Credenciales de prueba:

```
Admin:     admin@techassist.com / password123
Técnico 1: tecnico1@techassist.com / password123
Técnico 2: tecnico2@techassist.com / password123
Cliente 1: cliente1@empresa.com / password123
Cliente 2: cliente2@empresa.com / password123
```

### Credenciales SQL Server:

```
Server: localhost,1433
Usuario: sa
Password: TechAssist2025!
Database: TechAssistDB
```

---

## 📋 Comandos Útiles

### Detener todos los contenedores:
```bash
docker-compose down
```

### Detener y eliminar volúmenes (reset completo):
```bash
docker-compose down -v
```

### Ver logs:
```bash
# Todos los servicios
docker-compose logs -f

# Solo backend
docker-compose logs -f backend

# Solo SQL Server
docker-compose logs -f sqlserver
```

### Reiniciar un servicio específico:
```bash
docker-compose restart backend
docker-compose restart frontend
```

### Acceder a la shell de un contenedor:
```bash
# Backend
docker exec -it techassist-backend bash

# SQL Server
docker exec -it techassist-sqlserver bash
```

---

## 🗄️ Base de Datos

### Conectarse a SQL Server desde la línea de comandos:

```bash
docker exec -it techassist-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'TechAssist2025!' -d TechAssistDB
```

### Consultas SQL útiles:

```sql
-- Ver todos los usuarios
SELECT * FROM usuarios;

-- Ver todos los tickets
SELECT * FROM ticket;

-- Tickets por estado
SELECT estado, COUNT(*) as total FROM ticket GROUP BY estado;

-- Tickets por prioridad
SELECT prioridad, COUNT(*) as total FROM ticket GROUP BY prioridad;
```

### Backup de la base de datos:

```bash
# Crear backup
docker exec techassist-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'TechAssist2025!' \
  -Q "BACKUP DATABASE TechAssistDB TO DISK = '/var/opt/mssql/backup/TechAssist.bak'"

# Copiar backup a tu máquina
docker cp techassist-sqlserver:/var/opt/mssql/backup/TechAssist.bak ./backup.bak
```

---

## 🏗️ Arquitectura

```
┌─────────────────┐
│  React Frontend │ :3000
│  (Node 18)      │
└────────┬────────┘
         │
         │ HTTP
         ▼
┌─────────────────┐
│ FastAPI Backend │ :8001
│  (Python 3.11)  │
└────────┬────────┘
         │
         │ SQLAlchemy + pyodbc
         ▼
┌─────────────────┐
│   SQL Server    │ :1433
│     2022        │
└─────────────────┘
```

---

## 🔧 Desarrollo

### Modo desarrollo con hot-reload:

El `docker-compose.yml` ya está configurado con volúmenes para hot-reload:

```yaml
volumes:
  - ./backend:/app        # Backend con hot-reload
  - ./frontend/src:/app/src  # Frontend con hot-reload
```

Cualquier cambio en el código se refleja automáticamente.

### Instalar nuevas dependencias:

**Backend:**
```bash
docker exec -it techassist-backend pip install nombre-paquete
docker exec -it techassist-backend pip freeze > requirements.txt
```

**Frontend:**
```bash
docker exec -it techassist-frontend yarn add nombre-paquete
```

---

## 📊 Características del Sistema

### ✅ Implementado:

- **Autenticación Dual**:
  - JWT con email/contraseña
  - Google OAuth (Emergent)
  
- **Base de Datos SQL Server**:
  - 12 tablas relacionales
  - Datos de ejemplo precargados
  - Foreign keys y constraints
  
- **Sistema de Tickets**:
  - 3 Prioridades: Baja 🟢, Media 🟡, Alta 🔴
  - 3 Estados: Abierto, En Proceso, Cerrado
  - Subir múltiples imágenes (Base64)
  - **Ampliar imágenes en modal** 🔍
  
- **Panel Cliente**:
  - Ver solo sus tickets
  - Crear tickets con adjuntos
  - Comentar en tickets
  
- **Panel Técnico**:
  - Ver todos los tickets
  - Filtros: Todos / Asignados / Resueltos
  - Asignar técnicos
  - Cambiar estado y prioridad
  
- **Timer Automático**:
  - Baja → Media: 24 horas
  - Media → Alta: 48 horas
  - Background scheduler
  
- **UI Moderna**:
  - Diseño glassmorphism
  - Colores verde menta / teal
  - Responsive
  - Shadcn/UI components

---

## 🐛 Solución de Problemas

### Puerto ocupado:
```bash
# Windows
netstat -ano | findstr :1433
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :1433
kill -9 <PID>
```

### Contenedor no inicia:
```bash
# Ver logs completos
docker-compose logs sqlserver

# Eliminar y recrear
docker-compose down -v
docker-compose up --build
```

### Base de datos no se crea:
```bash
# Ejecutar manualmente el script SQL
docker exec -it techassist-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'TechAssist2025!' \
  -i /docker-entrypoint-initdb.d/init.sql
```

### Permisos en Linux:
```bash
sudo chown -R $USER:$USER .
sudo chmod -R 755 .
```

---

## 📚 Documentación Adicional

- [Base de Datos](./BASE_DE_DATOS.md) - Esquema completo y ejemplos
- [API Endpoints](./API.md) - Documentación de todos los endpoints
- [Frontend](./FRONTEND.md) - Estructura y componentes
- [Despliegue](./DEPLOYMENT.md) - Guía de producción

---

## 🔒 Seguridad

**IMPORTANTE**: Antes de producción:

1. Cambiar contraseñas:
   - SQL Server: `SA_PASSWORD` en docker-compose.yml
   - JWT: `JWT_SECRET` en docker-compose.yml
   
2. Actualizar CORS:
   ```yaml
   - CORS_ORIGINS=https://tu-dominio.com
   ```

3. Usar SSL/TLS

4. Habilitar firewall

---

## 📞 Soporte

Para reportar problemas o solicitar funcionalidades:

1. Revisar la documentación en `/docs`
2. Verificar los logs: `docker-compose logs -f`
3. Consultar la sección de troubleshooting

---

## 📄 Licencia

MIT License - Uso libre para proyectos personales y comerciales.

---

## 🎉 ¡Listo!

El sistema está completamente funcional con un solo comando:

```bash
docker-compose up --build
```

Accede a http://localhost:3000 y comienza a crear tickets! 🚀