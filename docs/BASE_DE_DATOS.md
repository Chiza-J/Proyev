# 🗄️ Base de Datos SQL Server - TechAssist

## Esquema Completo

### Diagrama de Relaciones

```
usuarios
├── ticket (como cliente)
├── ticket (como técnico)
├── comentario
├── historial_ticket
├── equipo
└── user_sessions

departamento
├── equipo
└── usuarios

categoria
└── ticket

equipo
└── ticket

ticket
├── comentario
├── archivo_adjunto
└── historial_ticket
```

---

## Tablas Detalladas

### 1. usuarios
Almacena información de todos los usuarios del sistema.

```sql
CREATE TABLE usuarios (
    id_usuario INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL,
    apellido NVARCHAR(100) NOT NULL,
    correo NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255),
    telefono NVARCHAR(20),
    rol NVARCHAR(20) NOT NULL,  -- 'Admin', 'Tecnico', 'Cliente'
    estado BIT DEFAULT 1,
    picture NVARCHAR(MAX),
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);
```

**Ejemplo:**
```sql
INSERT INTO usuarios (nombre, apellido, correo, password_hash, rol)
VALUES ('Juan', 'Pérez', 'juan@empresa.com', '$2b$12$...', 'Cliente');
```

---

### 2. departamento
Define las áreas de la empresa.

```sql
CREATE TABLE departamento (
    id_departamento INT PRIMARY KEY IDENTITY(1,1),
    nombre_departamento NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(MAX)
);
```

**Datos precargados:**
- IT
- Ventas
- RRHH
- Finanzas

---

### 3. categoria
Clasifica los tipos de incidencias.

```sql
CREATE TABLE categoria (
    id_categoria INT PRIMARY KEY IDENTITY(1,1),
    nombre_categoria NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(MAX)
);
```

**Datos precargados:**
- Hardware
- Software
- Red
- Acceso
- Otro

---

### 4. equipo
Registra dispositivos tecnológicos.

```sql
CREATE TABLE equipo (
    id_equipo INT PRIMARY KEY IDENTITY(1,1),
    nombre_equipo NVARCHAR(100) NOT NULL,
    tipo_equipo NVARCHAR(50) NOT NULL,
    marca NVARCHAR(50),
    modelo NVARCHAR(50),
    numero_serie NVARCHAR(100) UNIQUE,
    id_usuario INT,
    id_departamento INT,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento)
);
```

---

### 5. prioridad
Define niveles de prioridad parametrizables.

```sql
CREATE TABLE prioridad (
    id_prioridad INT PRIMARY KEY IDENTITY(1,1),
    nombre_prioridad NVARCHAR(20) NOT NULL,  -- 'Baja', 'Media', 'Alta'
    tiempo_respuesta INT NOT NULL,  -- en horas
    color NVARCHAR(20) NOT NULL
);
```

**Datos precargados:**
| Prioridad | Tiempo Respuesta | Color |
|-----------|------------------|-------|
| Baja | 72h | #10B981 |
| Media | 24h | #F59E0B |
| Alta | 4h | #EF4444 |

---

### 6. estado_ticket
Define estados posibles de un ticket.

```sql
CREATE TABLE estado_ticket (
    id_estado INT PRIMARY KEY IDENTITY(1,1),
    nombre_estado NVARCHAR(20) NOT NULL,  -- 'Abierto', 'En proceso', 'Cerrado'
    descripcion NVARCHAR(MAX)
);
```

---

### 7. ticket ⭐
Tabla principal del sistema.

```sql
CREATE TABLE ticket (
    id_ticket INT PRIMARY KEY IDENTITY(1,1),
    id_usuario INT NOT NULL,
    id_tecnico INT,
    id_equipo INT,
    id_categoria INT NOT NULL,
    titulo NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX) NOT NULL,
    prioridad NVARCHAR(20) NOT NULL DEFAULT 'Baja',
    estado NVARCHAR(20) NOT NULL DEFAULT 'Abierto',
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    fecha_asignacion DATETIME2,
    fecha_cierre DATETIME2,
    ultima_actualizacion_prioridad DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_tecnico) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_equipo) REFERENCES equipo(id_equipo),
    FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);
```

---

### 8. comentario
Historial de comunicación en cada ticket.

```sql
CREATE TABLE comentario (
    id_comentario INT PRIMARY KEY IDENTITY(1,1),
    id_ticket INT NOT NULL,
    id_usuario INT NOT NULL,
    comentario NVARCHAR(MAX) NOT NULL,
    fecha_comentario DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (id_ticket) REFERENCES ticket(id_ticket) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);
```

---

### 9. archivo_adjunto
Almacena archivos adjuntos (imágenes en Base64).

```sql
CREATE TABLE archivo_adjunto (
    id_archivo INT PRIMARY KEY IDENTITY(1,1),
    id_ticket INT NOT NULL,
    nombre_archivo NVARCHAR(255) NOT NULL,
    ruta_archivo NVARCHAR(MAX) NOT NULL,  -- Base64 string
    fecha_subida DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (id_ticket) REFERENCES ticket(id_ticket) ON DELETE CASCADE
);
```

**Nota sobre imágenes:**
- Se almacenan en Base64 directamente en la base de datos
- El frontend puede ampliarlas en un modal al hacer clic
- Para optimización en producción, considerar almacenamiento externo (Azure Blob, AWS S3)

---

### 10. historial_ticket
Registra todos los cambios realizados en un ticket.

```sql
CREATE TABLE historial_ticket (
    id_historial INT PRIMARY KEY IDENTITY(1,1),
    id_ticket INT NOT NULL,
    id_usuario INT,  -- NULL para acciones del sistema
    accion_realizada NVARCHAR(MAX) NOT NULL,
    fecha_accion DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (id_ticket) REFERENCES ticket(id_ticket) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);
```

---

### 11. user_sessions
Almacena sesiones de Google OAuth.

```sql
CREATE TABLE user_sessions (
    id_session INT PRIMARY KEY IDENTITY(1,1),
    id_usuario INT NOT NULL,
    session_token NVARCHAR(255) NOT NULL UNIQUE,
    expires_at DATETIME2 NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);
```

---

## Consultas Útiles

### Estadísticas de Tickets

```sql
-- Total de tickets por estado
SELECT estado, COUNT(*) as total
FROM ticket
GROUP BY estado;

-- Total de tickets por prioridad
SELECT prioridad, COUNT(*) as total
FROM ticket
GROUP BY prioridad;

-- Tickets por categoría con nombre
SELECT c.nombre_categoria, COUNT(*) as total
FROM ticket t
INNER JOIN categoria c ON t.id_categoria = c.id_categoria
GROUP BY c.nombre_categoria;
```

### Tickets de un Cliente

```sql
-- Todos los tickets de un cliente
SELECT t.*, u.nombre + ' ' + u.apellido as cliente
FROM ticket t
INNER JOIN usuarios u ON t.id_usuario = u.id_usuario
WHERE t.id_usuario = 4;
```

### Tickets Asignados a un Técnico

```sql
-- Tickets asignados a un técnico específico
SELECT t.*, 
       u1.nombre + ' ' + u1.apellido as cliente,
       u2.nombre + ' ' + u2.apellido as tecnico
FROM ticket t
INNER JOIN usuarios u1 ON t.id_usuario = u1.id_usuario
LEFT JOIN usuarios u2 ON t.id_tecnico = u2.id_usuario
WHERE t.id_tecnico = 2
AND t.estado != 'Cerrado';
```

### Historial Completo de un Ticket

```sql
-- Obtener ticket con todo su historial
SELECT 
    t.id_ticket,
    t.titulo,
    h.accion_realizada,
    h.fecha_accion,
    u.nombre + ' ' + u.apellido as usuario
FROM ticket t
LEFT JOIN historial_ticket h ON t.id_ticket = h.id_ticket
LEFT JOIN usuarios u ON h.id_usuario = u.id_usuario
WHERE t.id_ticket = 1
ORDER BY h.fecha_accion DESC;
```

### Tickets que Necesitan Escalamiento

```sql
-- Tickets Baja > 24 horas
SELECT id_ticket, titulo, prioridad, 
       DATEDIFF(HOUR, ultima_actualizacion_prioridad, GETDATE()) as horas_transcurridas
FROM ticket
WHERE estado IN ('Abierto', 'En proceso')
AND prioridad = 'Baja'
AND DATEDIFF(HOUR, ultima_actualizacion_prioridad, GETDATE()) >= 24;

-- Tickets Media > 48 horas
SELECT id_ticket, titulo, prioridad,
       DATEDIFF(HOUR, ultima_actualizacion_prioridad, GETDATE()) as horas_transcurridas
FROM ticket
WHERE estado IN ('Abierto', 'En proceso')
AND prioridad = 'Media'
AND DATEDIFF(HOUR, ultima_actualizacion_prioridad, GETDATE()) >= 48;
```

### Performance de Técnicos

```sql
-- Estadísticas por técnico
SELECT 
    u.nombre + ' ' + u.apellido as tecnico,
    COUNT(t.id_ticket) as total_tickets,
    SUM(CASE WHEN t.estado = 'Cerrado' THEN 1 ELSE 0 END) as tickets_cerrados,
    AVG(DATEDIFF(HOUR, t.fecha_creacion, ISNULL(t.fecha_cierre, GETDATE()))) as promedio_horas_resolucion
FROM usuarios u
LEFT JOIN ticket t ON u.id_usuario = t.id_tecnico
WHERE u.rol = 'Tecnico'
GROUP BY u.id_usuario, u.nombre, u.apellido;
```

---

## Stored Procedures Útiles

### Escalar Prioridad de Ticket

```sql
CREATE PROCEDURE EscalarPrioridad
    @id_ticket INT
AS
BEGIN
    DECLARE @prioridad_actual NVARCHAR(20);
    DECLARE @nueva_prioridad NVARCHAR(20);
    
    SELECT @prioridad_actual = prioridad FROM ticket WHERE id_ticket = @id_ticket;
    
    IF @prioridad_actual = 'Baja'
        SET @nueva_prioridad = 'Media';
    ELSE IF @prioridad_actual = 'Media'
        SET @nueva_prioridad = 'Alta';
    ELSE
        SET @nueva_prioridad = @prioridad_actual;
    
    IF @prioridad_actual != @nueva_prioridad
    BEGIN
        UPDATE ticket
        SET prioridad = @nueva_prioridad,
            ultima_actualizacion_prioridad = GETDATE()
        WHERE id_ticket = @id_ticket;
        
        INSERT INTO historial_ticket (id_ticket, id_usuario, accion_realizada)
        VALUES (@id_ticket, NULL, 'Prioridad escalada automáticamente de ' + @prioridad_actual + ' a ' + @nueva_prioridad);
    END
END;
GO
```

---

## Índices para Performance

```sql
-- Índices ya creados en init.sql
CREATE INDEX idx_usuarios_correo ON usuarios(correo);
CREATE INDEX idx_usuarios_rol ON usuarios(rol);
CREATE INDEX idx_ticket_usuario ON ticket(id_usuario);
CREATE INDEX idx_ticket_tecnico ON ticket(id_tecnico);
CREATE INDEX idx_ticket_estado ON ticket(estado);
CREATE INDEX idx_ticket_prioridad ON ticket(prioridad);
CREATE INDEX idx_ticket_fecha ON ticket(fecha_creacion);
CREATE INDEX idx_comentario_ticket ON comentario(id_ticket);
CREATE INDEX idx_archivo_ticket ON archivo_adjunto(id_ticket);
CREATE INDEX idx_historial_ticket ON historial_ticket(id_ticket);
CREATE INDEX idx_session_token ON user_sessions(session_token);
```

---

## Backup y Restauración

### Crear Backup

```bash
# Desde el contenedor Docker
docker exec techassist-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'TechAssist2025!' \
  -Q "BACKUP DATABASE TechAssistDB TO DISK = '/var/opt/mssql/backup/TechAssist.bak' WITH FORMAT"
```

### Restaurar Backup

```bash
# Restaurar desde backup
docker exec techassist-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'TechAssist2025!' \
  -Q "RESTORE DATABASE TechAssistDB FROM DISK = '/var/opt/mssql/backup/TechAssist.bak' WITH REPLACE"
```

---

## Migración desde MongoDB

Si tienes datos en MongoDB y quieres migrarlos a SQL Server:

1. Exportar colecciones de MongoDB a JSON
2. Usar un script Python para transformar y cargar en SQL Server
3. Validar integridad de datos
4. Actualizar referencias (IDs)

Ver script de migración en `/docs/scripts/mongo_to_sql.py`

---

## Mantenimiento

### Limpieza de Sesiones Expiradas

```sql
-- Ejecutar diariamente
DELETE FROM user_sessions WHERE expires_at < GETDATE();
```

### Estadísticas de Uso de Base de Datos

```sql
-- Tamaño de tablas
SELECT 
    t.NAME AS TableName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY t.Name, p.Rows
ORDER BY TotalSpaceKB DESC;
```

---

## Conexión desde Aplicaciones Externas

### Connection String

```
Server=localhost,1433;Database=TechAssistDB;User Id=sa;Password=TechAssist2025!;TrustServerCertificate=True;
```

### Python (SQLAlchemy)

```python
from sqlalchemy import create_engine

DATABASE_URL = "mssql+pyodbc://sa:TechAssist2025!@localhost:1433/TechAssistDB?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
engine = create_engine(DATABASE_URL)
```

### .NET (C#)

```csharp
string connectionString = "Server=localhost,1433;Database=TechAssistDB;User Id=sa;Password=TechAssist2025!;TrustServerCertificate=True;";
using (SqlConnection connection = new SqlConnection(connectionString))
{
    connection.Open();
    // ...
}
```

### Node.js (mssql)

```javascript
const sql = require('mssql');

const config = {
    server: 'localhost',
    port: 1433,
    database: 'TechAssistDB',
    user: 'sa',
    password: 'TechAssist2025!',
    options: {
        encrypt: true,
        trustServerCertificate: true
    }
};

const pool = await sql.connect(config);
```
