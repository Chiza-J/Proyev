# 🎫 TechAssist - Sistema de Tickets de Soporte TI

Sistema completo de gestión de tickets de soporte técnico con SQL Server, FastAPI y React.

## 🚀 Inicio Rápido (UN SOLO COMANDO)

```bash
docker-compose up --build
```

¡Eso es todo! Accede a:
- **Aplicación**: http://localhost:3000
- **API Docs**: http://localhost:8001/docs

### 🔐 Credenciales de Prueba

```
Admin:     admin@techassist.com / password123
Técnico:   tecnico1@techassist.com / password123
Cliente:   cliente1@empresa.com / password123
```

---

## 📋 Requisitos

- Docker Desktop
- 8GB RAM disponible
- Puertos libres: 1433, 3000, 8001

---

## 🎯 Características

- ✅ **Autenticación Dual**: JWT + Google OAuth
- ✅ **Base de Datos**: SQL Server 2022
- ✅ **Prioridades**: Baja 🟢, Media 🟡, Alta 🔴
- ✅ **Timer Automático**: Escalamiento de prioridades
- ✅ **Adjuntar Imágenes**: Con función de ampliar 🔍
- ✅ **Panel Cliente**: Ver solo sus tickets
- ✅ **Panel Técnico**: Gestión completa de tickets

---

## 📚 Documentación Completa en `/docs`

- [README.md](./docs/README.md) - Guía completa
- [BASE_DE_DATOS.md](./docs/BASE_DE_DATOS.md) - Esquema SQL
- Ver más en la carpeta `/docs`

---

## 🛠️ Comandos

```bash
docker-compose up -d        # Iniciar
docker-compose logs -f      # Ver logs
docker-compose down         # Detener
docker-compose down -v      # Reset completo
```

---

**Ver documentación completa en [/docs/README.md](./docs/README.md)**
