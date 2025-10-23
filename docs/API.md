# 🔌 API Documentation - TechAssist

Base URL: `http://localhost:8001/api`

Documentación interactiva: http://localhost:8001/docs

---

## 🔐 Autenticación

Todos los endpoints protegidos requieren el header:
```
Authorization: Bearer <token>
```

### POST /auth/register
Registrar nuevo usuario.

**Request:**
```json
{
  "nombre": "Juan",
  "apellido": "Pérez",
  "correo": "juan@ejemplo.com",
  "password": "password123",
  "telefono": "555-1234",
  "rol": "Cliente"  // Admin, Tecnico, Cliente
}
```

**Response:**
```json
{
  "user": {
    "id_usuario": 1,
    "nombre": "Juan",
    "apellido": "Pérez",
    "correo": "juan@ejemplo.com",
    "rol": "Cliente"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

### POST /auth/login
Iniciar sesión con JWT.

**Request:**
```json
{
  "correo": "juan@ejemplo.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "user": {...},
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

### GET /auth/google
Obtener URL para login con Google OAuth.

**Query Params:**
- `redirect_url`: URL donde redirigir después del login

**Response:**
```json
{
  "auth_url": "https://auth.emergentagent.com/?redirect=..."
}
```

---

### POST /auth/session
Crear sesión desde Google OAuth.

**Query Params:**
- `session_id`: ID de sesión de Emergent

**Response:**
```json
{
  "user": {...},
  "session_token": "emergent-token-xyz"
}
```

---

### GET /auth/me
Obtener información del usuario actual.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id_usuario": 1,
  "nombre": "Juan",
  "apellido": "Pérez",
  "correo": "juan@ejemplo.com",
  "rol": "Cliente",
  "telefono": "555-1234"
}
```

---

### POST /auth/logout
Cerrar sesión.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "Logged out successfully"
}
```

---

## 🎫 Tickets

### GET /tickets
Listar tickets según el rol del usuario.

**Headers:**
```
Authorization: Bearer <token>
```

**Comportamiento:**
- **Cliente**: Solo ve sus propios tickets
- **Técnico/Admin**: Ve todos los tickets

**Response:**
```json
[
  {
    "id_ticket": 1,
    "titulo": "Laptop no enciende",
    "descripcion": "Mi laptop Dell no responde...",
    "prioridad": "Alta",
    "estado": "En proceso",
    "fecha_creacion": "2025-01-20T10:30:00",
    "usuario": {
      "nombre": "Juan Pérez"
    },
    "tecnico": {
      "nombre": "Carlos Técnico"
    },
    "categoria": {
      "nombre": "Hardware"
    }
  }
]
```

---

### POST /tickets
Crear nuevo ticket.

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "titulo": "Problema con impresora",
  "descripcion": "La impresora HP no responde",
  "id_categoria": 1,
  "id_equipo": 2,  // opcional
  "attachments": [  // opcional
    {
      "filename": "error_screen.jpg",
      "file_data": "base64_string_here..."
    }
  ]
}
```

**Response:**
```json
{
  "id_ticket": 5,
  "titulo": "Problema con impresora",
  "descripcion": "La impresora HP no responde",
  "prioridad": "Baja",
  "estado": "Abierto",
  "fecha_creacion": "2025-01-20T15:30:00"
}
```

---

### GET /tickets/{id}
Obtener detalles completos de un ticket.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id_ticket": 1,
  "titulo": "Laptop no enciende",
  "descripcion": "Mi laptop Dell no responde...",
  "prioridad": "Alta",
  "estado": "En proceso",
  "fecha_creacion": "2025-01-20T10:30:00",
  "usuario": {
    "id_usuario": 4,
    "nombre": "Juan",
    "apellido": "Pérez",
    "correo": "juan@ejemplo.com"
  },
  "tecnico": {
    "id_usuario": 2,
    "nombre": "Carlos",
    "apellido": "Técnico"
  },
  "categoria": {
    "id_categoria": 1,
    "nombre": "Hardware"
  },
  "equipo": {
    "id_equipo": 1,
    "nombre": "Laptop Dell Latitude"
  },
  "comentarios": [
    {
      "id_comentario": 1,
      "comentario": "He revisado el equipo...",
      "fecha_comentario": "2025-01-20T14:30:00",
      "usuario": {
        "nombre": "Carlos Técnico"
      }
    }
  ],
  "archivos": [
    {
      "id_archivo": 1,
      "nombre_archivo": "error_screen.jpg",
      "ruta_archivo": "base64_string...",
      "fecha_subida": "2025-01-20T10:32:00"
    }
  ],
  "historial": [
    {
      "id_historial": 1,
      "accion_realizada": "Ticket creado con prioridad Baja",
      "fecha_accion": "2025-01-20T10:30:00",
      "usuario": {
        "nombre": "Juan Pérez"
      }
    }
  ]
}
```

---

### PUT /tickets/{id}
Actualizar ticket (solo técnicos/admins).

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "estado": "En proceso",      // opcional
  "prioridad": "Media",         // opcional
  "id_tecnico": 2              // opcional
}
```

**Response:**
```json
{
  "id_ticket": 1,
  "titulo": "Laptop no enciende",
  "estado": "En proceso",
  "prioridad": "Media",
  "id_tecnico": 2
}
```

---

### DELETE /tickets/{id}
Eliminar ticket (solo admins).

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "Ticket deleted successfully"
}
```

---

### GET /tickets/my-assigned
Obtener tickets asignados al técnico actual.

**Headers:**
```
Authorization: Bearer <token>
```

**Permisos:** Solo técnicos/admins

**Response:**
```json
[
  {
    "id_ticket": 1,
    "titulo": "Laptop no enciende",
    "estado": "En proceso",
    "prioridad": "Alta"
  }
]
```

---

### GET /tickets/my-resolved
Obtener tickets resueltos por el técnico actual.

**Headers:**
```
Authorization: Bearer <token>
```

**Permisos:** Solo técnicos/admins

**Response:**
```json
[
  {
    "id_ticket": 3,
    "titulo": "Sin acceso a internet",
    "estado": "Cerrado",
    "fecha_cierre": "2025-01-20T16:00:00"
  }
]
```

---

## 💬 Comentarios

### POST /tickets/{id}/comments
Agregar comentario a un ticket.

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "comentario": "He revisado el equipo y parece ser un problema con la fuente de poder."
}
```

**Response:**
```json
{
  "id_comentario": 5,
  "id_ticket": 1,
  "comentario": "He revisado el equipo...",
  "fecha_comentario": "2025-01-20T14:30:00"
}
```

---

### GET /tickets/{id}/comments
Listar comentarios de un ticket.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
[
  {
    "id_comentario": 1,
    "comentario": "He revisado el equipo...",
    "fecha_comentario": "2025-01-20T14:30:00",
    "usuario": {
      "nombre": "Carlos Técnico"
    }
  }
]
```

---

## 📎 Archivos Adjuntos

### POST /tickets/{id}/attachments
Agregar archivo adjunto (imagen).

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "filename": "error_screen.jpg",
  "file_data": "base64_encoded_image_string..."
}
```

**Response:**
```json
{
  "id_archivo": 3,
  "nombre_archivo": "error_screen.jpg",
  "fecha_subida": "2025-01-20T10:35:00"
}
```

---

## 🏢 Departamentos

### GET /departments
Listar todos los departamentos.

**Response:**
```json
[
  {
    "id_departamento": 1,
    "nombre_departamento": "IT",
    "descripcion": "Departamento de TI"
  }
]
```

---

### POST /departments
Crear departamento (solo admins).

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "nombre_departamento": "Marketing",
  "descripcion": "Departamento de Marketing"
}
```

---

## 🏷️ Categorías

### GET /categories
Listar todas las categorías.

**Response:**
```json
[
  {
    "id_categoria": 1,
    "nombre_categoria": "Hardware",
    "descripcion": "Problemas de hardware"
  }
]
```

---

### POST /categories
Crear categoría (solo admins).

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "nombre_categoria": "Seguridad",
  "descripcion": "Problemas de seguridad"
}
```

---

## 💻 Equipos

### GET /equipments
Listar equipos.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
[
  {
    "id_equipo": 1,
    "nombre_equipo": "Laptop Dell Latitude",
    "tipo_equipo": "Laptop",
    "marca": "Dell",
    "modelo": "Latitude 5420",
    "numero_serie": "DELL-001"
  }
]
```

---

### POST /equipments
Crear equipo.

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "nombre_equipo": "Impresora HP",
  "tipo_equipo": "Impresora",
  "marca": "HP",
  "modelo": "LaserJet Pro",
  "numero_serie": "HP-123",
  "id_usuario": 4,
  "id_departamento": 1
}
```

---

## 👥 Usuarios

### GET /users
Listar usuarios (técnicos/admins).

**Headers:**
```
Authorization: Bearer <token>
```

**Permisos:** Solo técnicos/admins

---

### GET /users/technicians
Listar solo técnicos.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
[
  {
    "id_usuario": 2,
    "nombre": "Carlos",
    "apellido": "Técnico",
    "correo": "tecnico1@techassist.com",
    "rol": "Tecnico"
  }
]
```

---

## 📊 Códigos de Estado HTTP

- `200` - OK
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

---

## 🔒 Permisos por Rol

### Cliente
- ✅ Ver sus propios tickets
- ✅ Crear tickets
- ✅ Agregar comentarios
- ✅ Subir archivos
- ❌ Ver tickets de otros
- ❌ Asignar técnicos
- ❌ Cambiar estado/prioridad

### Técnico
- ✅ Ver todos los tickets
- ✅ Filtrar tickets asignados/resueltos
- ✅ Asignar técnicos
- ✅ Cambiar estado
- ✅ Cambiar prioridad
- ✅ Agregar comentarios
- ❌ Eliminar tickets
- ❌ Administrar usuarios

### Admin
- ✅ Acceso completo
- ✅ Eliminar tickets
- ✅ Administrar usuarios
- ✅ Crear categorías/departamentos

---

## 🧪 Ejemplos con cURL

### Login
```bash
curl -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "correo": "cliente1@empresa.com",
    "password": "password123"
  }'
```

### Crear Ticket
```bash
curl -X POST http://localhost:8001/api/tickets \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "titulo": "Problema con mouse",
    "descripcion": "El mouse no responde",
    "id_categoria": 1
  }'
```

### Listar Tickets
```bash
curl -X GET http://localhost:8001/api/tickets \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Agregar Comentario
```bash
curl -X POST http://localhost:8001/api/tickets/1/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "comentario": "Estoy revisando el problema"
  }'
```

---

## 🔗 Documentación Interactiva

Visita http://localhost:8001/docs para:
- Ver todos los endpoints
- Probar requests en tiempo real
- Ver esquemas de datos
- Autenticarte y probar APIs
