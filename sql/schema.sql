-- ============================================
-- TechAssist Database Schema
-- SQL Server 2022
-- ============================================

-- Eliminar base de datos si existe (solo desarrollo)
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'TechAssistDB')
BEGIN
    USE master;
    ALTER DATABASE TechAssistDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE TechAssistDB;
    PRINT '🗑️  Base de datos anterior eliminada';
END
GO

-- Crear base de datos
CREATE DATABASE TechAssistDB;
GO

USE TechAssistDB;
GO

PRINT '📊 Creando base de datos TechAssistDB...';
GO

-- ============================================
-- Tabla: Users
-- ============================================
CREATE TABLE Users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(100) NOT NULL UNIQUE,
    email NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,
    role NVARCHAR(50) NOT NULL DEFAULT 'cliente' CHECK (role IN ('admin', 'tecnico', 'cliente')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT CK_email_format CHECK (email LIKE '%@%.%')
);
GO

PRINT '✅ Tabla Users creada';
GO

-- ============================================
-- Tabla: Tickets
-- ============================================
CREATE TABLE Tickets (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    title NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    status NVARCHAR(50) DEFAULT 'abierto' CHECK (status IN ('abierto', 'en_proceso', 'resuelto', 'cerrado')),
    priority NVARCHAR(50) DEFAULT 'media' CHECK (priority IN ('baja', 'media', 'alta', 'urgente')),
    assigned_to INT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Tickets_Users FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE NO ACTION,
    CONSTRAINT FK_Tickets_Assigned FOREIGN KEY (assigned_to) REFERENCES Users(id) ON DELETE NO ACTION
);
GO

PRINT '✅ Tabla Tickets creada';
GO

-- ============================================
-- Tabla: Comments (Opcional - para comentarios en tickets)
-- ============================================
CREATE TABLE Comments (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ticket_id INT NOT NULL,
    user_id INT NOT NULL,
    comment NVARCHAR(MAX) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Comments_Tickets FOREIGN KEY (ticket_id) REFERENCES Tickets(id) ON DELETE CASCADE,
    CONSTRAINT FK_Comments_Users FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE NO ACTION
);
GO

PRINT '✅ Tabla Comments creada';
GO

-- ============================================
-- Tabla: Attachments (Opcional - para archivos adjuntos)
-- ============================================
CREATE TABLE Attachments (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ticket_id INT NOT NULL,
    filename NVARCHAR(255) NOT NULL,
    file_url NVARCHAR(500) NOT NULL,
    file_size INT NOT NULL,
    uploaded_by INT NOT NULL,
    uploaded_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Attachments_Tickets FOREIGN KEY (ticket_id) REFERENCES Tickets(id) ON DELETE CASCADE,
    CONSTRAINT FK_Attachments_Users FOREIGN KEY (uploaded_by) REFERENCES Users(id) ON DELETE NO ACTION
);
GO

PRINT '✅ Tabla Attachments creada';
GO

-- ============================================
-- ÍNDICES para mejorar performance
-- ============================================
CREATE INDEX idx_tickets_user_id ON Tickets(user_id);
CREATE INDEX idx_tickets_assigned_to ON Tickets(assigned_to);
CREATE INDEX idx_tickets_status ON Tickets(status);
CREATE INDEX idx_tickets_priority ON Tickets(priority);
CREATE INDEX idx_tickets_created_at ON Tickets(created_at DESC);
CREATE INDEX idx_comments_ticket_id ON Comments(ticket_id);
CREATE INDEX idx_comments_created_at ON Comments(created_at DESC);
CREATE INDEX idx_attachments_ticket_id ON Attachments(ticket_id);
GO

PRINT '✅ Índices creados';
GO

-- ============================================
-- TRIGGERS para updated_at automático
-- ============================================
CREATE TRIGGER trg_users_update 
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users
    SET updated_at = GETDATE()
    FROM Users u
    INNER JOIN inserted i ON u.id = i.id;
END;
GO

CREATE TRIGGER trg_tickets_update 
ON Tickets
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Tickets
    SET updated_at = GETDATE()
    FROM Tickets t
    INNER JOIN inserted i ON t.id = i.id;
END;
GO

PRINT '✅ Triggers creados';
GO

-- ============================================
-- DATOS DE PRUEBA
-- ============================================

-- Usuarios de prueba (contraseñas hasheadas con bcrypt)
-- password123 -> $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.i1QuZqSW
INSERT INTO Users (username, email, password_hash, role) VALUES
('admin', 'admin@techassist.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.i1QuZqSW', 'admin'),
('tecnico1', 'tecnico1@techassist.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.i1QuZqSW', 'tecnico'),
('tecnico2', 'tecnico2@techassist.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.i1QuZqSW', 'tecnico'),
('cliente1', 'cliente1@empresa.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.i1QuZqSW', 'cliente'),
('cliente2', 'cliente2@empresa.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyB.i1QuZqSW', 'cliente');
GO

PRINT '✅ Usuarios de prueba creados';
PRINT '   📧 admin@techassist.com / password123 (Admin)';
PRINT '   📧 tecnico1@techassist.com / password123 (Técnico)';
PRINT '   📧 cliente1@empresa.com / password123 (Cliente)';
GO

-- Tickets de prueba
INSERT INTO Tickets (user_id, title, description, status, priority, assigned_to) VALUES
(4, 'Problema con la impresora de red', 'La impresora del piso 3 no imprime desde ayer por la tarde', 'abierto', 'alta', 2),
(4, 'Solicitud de instalación de software', 'Necesito Adobe Photoshop CC 2024 instalado en mi PC', 'en_proceso', 'media', 2),
(5, 'Error en sistema de correo', 'No puedo recibir correos desde esta mañana, sale error de conexión', 'abierto', 'urgente', NULL),
(5, 'Solicitud de acceso a carpeta compartida', 'Necesito acceso a la carpeta de ventas del servidor', 'resuelto', 'baja', 3),
(4, 'PC muy lenta', 'Mi computadora está muy lenta desde la última actualización de Windows', 'abierto', 'media', NULL),
(5, 'Cambio de contraseña', 'Olvidé mi contraseña del sistema ERP', 'cerrado', 'baja', 2);
GO

PRINT '✅ Tickets de prueba creados';
GO

-- Comentarios de prueba
INSERT INTO Comments (ticket_id, user_id, comment) VALUES
(1, 2, 'Revisaré la impresora en 30 minutos'),
(1, 4, 'Gracias, estaré esperando'),
(2, 2, 'Photoshop ya está instalado, por favor verifica'),
(3, 5, 'Es urgente, necesito recibir correos importantes'),
(6, 2, 'Contraseña restablecida exitosamente');
GO

PRINT '✅ Comentarios de prueba creados';
GO

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista con información completa de tickets
CREATE VIEW vw_tickets_full AS
SELECT 
    t.id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.created_at,
    t.updated_at,
    u.username as created_by,
    u.email as creator_email,
    u.role as creator_role,
    a.username as assigned_to_name,
    a.email as assigned_to_email,
    (SELECT COUNT(*) FROM Comments WHERE ticket_id = t.id) as comments_count,
    (SELECT COUNT(*) FROM Attachments WHERE ticket_id = t.id) as attachments_count
FROM Tickets t
LEFT JOIN Users u ON t.user_id = u.id
LEFT JOIN Users a ON t.assigned_to = a.id;
GO

PRINT '✅ Vista vw_tickets_full creada';
GO

-- ============================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================

-- Obtener estadísticas generales
CREATE PROCEDURE sp_get_general_stats
AS
BEGIN
    SELECT 
        (SELECT COUNT(*) FROM Users) as total_users,
        (SELECT COUNT(*) FROM Users WHERE role = 'admin') as total_admins,
        (SELECT COUNT(*) FROM Users WHERE role = 'tecnico') as total_tecnicos,
        (SELECT COUNT(*) FROM Users WHERE role = 'cliente') as total_clientes,
        (SELECT COUNT(*) FROM Tickets) as total_tickets,
        (SELECT COUNT(*) FROM Tickets WHERE status = 'abierto') as tickets_abiertos,
        (SELECT COUNT(*) FROM Tickets WHERE status = 'en_proceso') as tickets_en_proceso,
        (SELECT COUNT(*) FROM Tickets WHERE status = 'resuelto') as tickets_resueltos,
        (SELECT COUNT(*) FROM Tickets WHERE status = 'cerrado') as tickets_cerrados,
        (SELECT COUNT(*) FROM Tickets WHERE priority = 'urgente') as tickets_urgentes,
        (SELECT COUNT(*) FROM Comments) as total_comments,
        (SELECT COUNT(*) FROM Attachments) as total_attachments;
END;
GO

PRINT '✅ Procedimiento sp_get_general_stats creado';
GO

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================

PRINT '================================================';
PRINT '✅ BASE DE DATOS CREADA EXITOSAMENTE';
PRINT '================================================';
PRINT '';

-- Mostrar resumen de tablas
SELECT 
    'Users' as [Tabla], 
    COUNT(*) as [Registros] 
FROM Users
UNION ALL
SELECT 'Tickets', COUNT(*) FROM Tickets
UNION ALL
SELECT 'Comments', COUNT(*) FROM Comments
UNION ALL
SELECT 'Attachments', COUNT(*) FROM Attachments;
GO

-- Ejecutar procedimiento de estadísticas
EXEC sp_get_general_stats;
GO

PRINT '';
PRINT '================================================';
PRINT '🎉 TechAssist DB está lista para usar';
PRINT '================================================';
GO