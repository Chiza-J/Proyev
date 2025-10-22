-- Crear base de datos TechAssist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TechAssistDB')
BEGIN
    CREATE DATABASE TechAssistDB;
END
GO

USE TechAssistDB;
GO

-- Tabla: Usuarios
CREATE TABLE usuarios (
    id_usuario INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL,
    apellido NVARCHAR(100) NOT NULL,
    correo NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255),
    telefono NVARCHAR(20),
    rol NVARCHAR(20) NOT NULL CHECK (rol IN ('Admin', 'Tecnico', 'Cliente')),
    estado BIT DEFAULT 1,
    picture NVARCHAR(MAX),
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);
GO

-- Tabla: Departamento
CREATE TABLE departamento (
    id_departamento INT PRIMARY KEY IDENTITY(1,1),
    nombre_departamento NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(MAX)
);
GO

-- Tabla: Equipo
CREATE TABLE equipo (
    id_equipo INT PRIMARY KEY IDENTITY(1,1),
    nombre_equipo NVARCHAR(100) NOT NULL,
    tipo_equipo NVARCHAR(50) NOT NULL,
    marca NVARCHAR(50),
    modelo NVARCHAR(50),
    numero_serie NVARCHAR(100) UNIQUE,
    id_usuario INT,
    id_departamento INT,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento) ON DELETE SET NULL
);
GO

-- Tabla: Categoria
CREATE TABLE categoria (
    id_categoria INT PRIMARY KEY IDENTITY(1,1),
    nombre_categoria NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(MAX)
);
GO

-- Tabla: Prioridad
CREATE TABLE prioridad (
    id_prioridad INT PRIMARY KEY IDENTITY(1,1),
    nombre_prioridad NVARCHAR(20) NOT NULL CHECK (nombre_prioridad IN ('Baja', 'Media', 'Alta')),
    tiempo_respuesta INT NOT NULL, -- en horas
    color NVARCHAR(20) NOT NULL
);
GO

-- Tabla: Estado_ticket
CREATE TABLE estado_ticket (
    id_estado INT PRIMARY KEY IDENTITY(1,1),
    nombre_estado NVARCHAR(20) NOT NULL CHECK (nombre_estado IN ('Abierto', 'En proceso', 'Cerrado')),
    descripcion NVARCHAR(MAX)
);
GO

-- Tabla: Ticket
CREATE TABLE ticket (
    id_ticket INT PRIMARY KEY IDENTITY(1,1),
    id_usuario INT NOT NULL,
    id_tecnico INT,
    id_equipo INT,
    id_categoria INT NOT NULL,
    titulo NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX) NOT NULL,
    prioridad NVARCHAR(20) NOT NULL DEFAULT 'Baja' CHECK (prioridad IN ('Baja', 'Media', 'Alta')),
    estado NVARCHAR(20) NOT NULL DEFAULT 'Abierto' CHECK (estado IN ('Abierto', 'En proceso', 'Cerrado')),
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    fecha_asignacion DATETIME2,
    fecha_cierre DATETIME2,
    ultima_actualizacion_prioridad DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_tecnico) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_equipo) REFERENCES equipo(id_equipo) ON DELETE SET NULL,
    FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);
GO

-- Tabla: Comentario
CREATE TABLE comentario (
    id_comentario INT PRIMARY KEY IDENTITY(1,1),
    id_ticket INT NOT NULL,
    id_usuario INT NOT NULL,
    comentario NVARCHAR(MAX) NOT NULL,
    fecha_comentario DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (id_ticket) REFERENCES ticket(id_ticket) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);
GO

-- Tabla: archivo_adjunto
CREATE TABLE archivo_adjunto (
    id_archivo INT PRIMARY KEY IDENTITY(1,1),
    id_ticket INT NOT NULL,
    nombre_archivo NVARCHAR(255) NOT NULL,
    ruta_archivo NVARCHAR(MAX) NOT NULL, -- Base64 o URL
    fecha_subida DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (id_ticket) REFERENCES ticket(id_ticket) ON DELETE CASCADE
);
GO

-- Tabla: historial_ticket
CREATE TABLE historial_ticket (
    id_historial INT PRIMARY KEY IDENTITY(1,1),
    id_ticket INT NOT NULL,
    id_usuario INT,
    accion_realizada NVARCHAR(MAX) NOT NULL,
    fecha_accion DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (id_ticket) REFERENCES ticket(id_ticket) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
);
GO

-- Tabla: user_sessions (para OAuth)
CREATE TABLE user_sessions (
    id_session INT PRIMARY KEY IDENTITY(1,1),
    id_usuario INT NOT NULL,
    session_token NVARCHAR(255) NOT NULL UNIQUE,
    expires_at DATETIME2 NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);
GO

-- Índices para mejor rendimiento
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
GO

-- ====================
-- DATOS INICIALES
-- ====================

-- Insertar Departamentos
INSERT INTO departamento (nombre_departamento, descripcion) VALUES
('IT', 'Departamento de Tecnología de la Información'),
('Ventas', 'Departamento de Ventas'),
('RRHH', 'Recursos Humanos'),
('Finanzas', 'Departamento Financiero');
GO

-- Insertar Categorías
INSERT INTO categoria (nombre_categoria, descripcion) VALUES
('Hardware', 'Problemas relacionados con hardware'),
('Software', 'Problemas relacionados con software'),
('Red', 'Problemas de conectividad y red'),
('Acceso', 'Problemas de acceso y permisos'),
('Otro', 'Otros problemas técnicos');
GO

-- Insertar Prioridades
INSERT INTO prioridad (nombre_prioridad, tiempo_respuesta, color) VALUES
('Baja', 72, '#10B981'),
('Media', 24, '#F59E0B'),
('Alta', 4, '#EF4444');
GO

-- Insertar Estados
INSERT INTO estado_ticket (nombre_estado, descripcion) VALUES
('Abierto', 'Ticket recién creado, pendiente de asignación'),
('En proceso', 'Ticket asignado y en proceso de resolución'),
('Cerrado', 'Ticket resuelto y cerrado');
GO

-- Insertar Usuarios de ejemplo
-- Password para todos: password123 (hasheado con bcrypt)
INSERT INTO usuarios (nombre, apellido, correo, password_hash, telefono, rol, estado) VALUES
('Admin', 'Sistema', 'admin@techassist.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7WmKIVEq4i', '555-0001', 'Admin', 1),
('Carlos', 'Técnico', 'tecnico1@techassist.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7WmKIVEq4i', '555-0002', 'Tecnico', 1),
('María', 'Soporte', 'tecnico2@techassist.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7WmKIVEq4i', '555-0003', 'Tecnico', 1),
('Juan', 'Pérez', 'cliente1@empresa.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7WmKIVEq4i', '555-1001', 'Cliente', 1),
('Ana', 'García', 'cliente2@empresa.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7WmKIVEq4i', '555-1002', 'Cliente', 1);
GO

-- Insertar Equipos de ejemplo
INSERT INTO equipo (nombre_equipo, tipo_equipo, marca, modelo, numero_serie, id_usuario, id_departamento) VALUES
('Laptop Dell Latitude', 'Laptop', 'Dell', 'Latitude 5420', 'DELL-001', 4, 1),
('HP LaserJet', 'Impresora', 'HP', 'LaserJet Pro M404dn', 'HP-002', NULL, 1),
('Monitor Samsung', 'Monitor', 'Samsung', 'S24R350', 'SAM-003', 5, 2);
GO

-- Insertar Tickets de ejemplo
INSERT INTO ticket (id_usuario, id_tecnico, id_equipo, id_categoria, titulo, descripcion, prioridad, estado, fecha_asignacion) VALUES
(4, 2, 1, 1, 'Laptop no enciende', 'Mi laptop Dell no responde al presionar el botón de encendido. La luz LED parpadea en naranja.', 'Alta', 'En proceso', GETDATE()),
(5, NULL, NULL, 2, 'Error al abrir Excel', 'Cuando intento abrir archivos de Excel me sale un error de archivo corrupto.', 'Media', 'Abierto', NULL),
(4, 2, NULL, 3, 'Sin acceso a internet', 'No puedo conectarme a la red WiFi de la oficina.', 'Baja', 'Cerrado', DATEADD(hour, -2, GETDATE()));
GO

-- Insertar Comentarios de ejemplo
INSERT INTO comentario (id_ticket, id_usuario, comentario) VALUES
(1, 2, 'He revisado el equipo. Parece ser un problema con la fuente de poder. Voy a reemplazarla.'),
(1, 4, 'Gracias por la actualización. ¿Cuánto tiempo tomará?'),
(3, 2, 'Problema resuelto. El router estaba desconectado.');
GO

-- Insertar Historial de ejemplo
INSERT INTO historial_ticket (id_ticket, id_usuario, accion_realizada) VALUES
(1, 4, 'Ticket creado con prioridad Baja'),
(1, NULL, 'Prioridad escalada automáticamente de Baja a Media'),
(1, 2, 'Asignado a técnico Carlos Técnico | Estado cambiado a En proceso | Prioridad cambiada de Media a Alta'),
(3, 4, 'Ticket creado con prioridad Baja'),
(3, 2, 'Estado cambiado a Cerrado');
GO

PRINT 'Base de datos TechAssist inicializada correctamente con datos de ejemplo';
PRINT 'Usuarios de prueba:';
PRINT '  Admin: admin@techassist.com / password123';
PRINT '  Tecnico 1: tecnico1@techassist.com / password123';
PRINT '  Tecnico 2: tecnico2@techassist.com / password123';
PRINT '  Cliente 1: cliente1@empresa.com / password123';
PRINT '  Cliente 2: cliente2@empresa.com / password123';
GO
