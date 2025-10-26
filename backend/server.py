from fastapi import FastAPI, HTTPException, Depends, status, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime, timedelta
import jwt
from passlib.context import CryptContext
import os
from pathlib import Path

from config import settings
from database import db

# Crear app FastAPI
app = FastAPI(
    title="TechAssist API",
    description="Sistema de gestión de tickets de soporte técnico",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Crear carpeta de uploads
settings.create_upload_folder()
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_FOLDER), name="uploads")

# Configuración de seguridad
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# ==================== MODELOS PYDANTIC ====================

class UserBase(BaseModel):
    username: str
    email: EmailStr
    role: str = "cliente"

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class TicketBase(BaseModel):
    title: str
    description: Optional[str] = None
    priority: str = "media"

class TicketCreate(TicketBase):
    pass

class TicketUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    priority: Optional[str] = None
    assigned_to: Optional[int] = None

class TicketResponse(TicketBase):
    id: int
    user_id: int
    status: str
    assigned_to: Optional[int]
    created_at: datetime
    updated_at: datetime
    created_by: Optional[str]
    assigned_to_name: Optional[str]
    
    class Config:
        from_attributes = True

# ==================== UTILIDADES ====================

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verificar contraseña"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hashear contraseña"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Crear token JWT"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    """Obtener usuario actual desde el token"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except jwt.PyJWTError:
        raise credentials_exception
    
    # Obtener usuario de la base de datos
    query = "SELECT id, username, email, role, created_at FROM Users WHERE id = ?"
    users = db.execute_query(query, (user_id,))
    if not users:
        raise credentials_exception
    return users[0]

# ==================== ENDPOINTS ====================

@app.on_event("startup")
async def startup_event():
    """Evento al iniciar la aplicación"""
    print("🚀 Iniciando TechAssist API...")
    print(f"📊 Base de datos: {settings.DB_NAME}")
    print(f"🖥️  Servidor: {settings.DB_SERVER}")
    db.test_connection()

@app.get("/")
async def root():
    """Endpoint raíz"""
    return {
        "message": "TechAssist API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/api/health"
    }

@app.get("/api/health")
async def health_check():
    """Verificar el estado de la aplicación"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        conn.close()
        
        return {
            "status": "healthy",
            "database": "connected",
            "server": settings.DB_SERVER,
            "database_name": settings.DB_NAME
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/api/test-db")
async def test_database():
    """Probar conexión a la base de datos"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT @@VERSION")
        version = cursor.fetchone()[0]
        
        cursor.execute("SELECT DB_NAME()")
        db_name = cursor.fetchone()[0]
        
        cursor.execute("""
            SELECT TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_TYPE = 'BASE TABLE'
        """)
        tables = [row[0] for row in cursor.fetchall()]
        
        cursor.close()
        conn.close()
        
        return {
            "success": True,
            "database": db_name,
            "version": version[:100],
            "tables": tables
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== AUTENTICACIÓN ====================

@app.post("/auth/register", response_model=UserResponse)
async def register(user: UserCreate):
    """Registrar un nuevo usuario"""
    try:
        # Verificar si el usuario ya existe
        check_query = "SELECT id FROM Users WHERE username = ? OR email = ?"
        existing = db.execute_query(check_query, (user.username, user.email))
        if existing:
            raise HTTPException(status_code=400, detail="Usuario o email ya existe")
        
        # Crear usuario
        hashed_password = get_password_hash(user.password)
        insert_query = """
            INSERT INTO Users (username, email, password_hash, role)
            OUTPUT INSERTED.id, INSERTED.username, INSERTED.email, INSERTED.role, INSERTED.created_at
            VALUES (?, ?, ?, ?)
        """
        result = db.execute_query(insert_query, (user.username, user.email, hashed_password, user.role))
        return result[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """Login y obtener token"""
    try:
        query = "SELECT id, username, email, password_hash, role, created_at FROM Users WHERE email = ?"
        users = db.execute_query(query, (form_data.username,))
        
        if not users or not verify_password(form_data.password, users[0]['password_hash']):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciales incorrectas",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        user = users[0]
        access_token = create_access_token(data={"sub": user['id']})
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "id": user['id'],
                "username": user['username'],
                "email": user['email'],
                "role": user['role'],
                "created_at": user['created_at']
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/auth/me", response_model=UserResponse)
async def get_me(current_user: dict = Depends(get_current_user)):
    """Obtener usuario actual"""
    return current_user

# ==================== USUARIOS ====================

@app.get("/api/users", response_model=List[UserResponse])
async def get_users(current_user: dict = Depends(get_current_user)):
    """Obtener todos los usuarios"""
    if current_user['role'] not in ['admin', 'tecnico']:
        raise HTTPException(status_code=403, detail="No autorizado")
    
    query = "SELECT id, username, email, role, created_at FROM Users ORDER BY created_at DESC"
    return db.execute_query(query)

@app.get("/api/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, current_user: dict = Depends(get_current_user)):
    """Obtener un usuario por ID"""
    query = "SELECT id, username, email, role, created_at FROM Users WHERE id = ?"
    users = db.execute_query(query, (user_id,))
    if not users:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return users[0]

# ==================== TICKETS ====================

@app.get("/api/tickets", response_model=List[TicketResponse])
async def get_tickets(current_user: dict = Depends(get_current_user)):
    """Obtener tickets según el rol del usuario"""
    try:
        if current_user['role'] == 'cliente':
            # Clientes solo ven sus tickets
            query = """
                SELECT t.*, u.username as created_by, a.username as assigned_to_name
                FROM Tickets t
                LEFT JOIN Users u ON t.user_id = u.id
                LEFT JOIN Users a ON t.assigned_to = a.id
                WHERE t.user_id = ?
                ORDER BY t.created_at DESC
            """
            return db.execute_query(query, (current_user['id'],))
        else:
            # Admin y técnicos ven todos los tickets
            query = """
                SELECT t.*, u.username as created_by, a.username as assigned_to_name
                FROM Tickets t
                LEFT JOIN Users u ON t.user_id = u.id
                LEFT JOIN Users a ON t.assigned_to = a.id
                ORDER BY t.created_at DESC
            """
            return db.execute_query(query)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/tickets/{ticket_id}", response_model=TicketResponse)
async def get_ticket(ticket_id: int, current_user: dict = Depends(get_current_user)):
    """Obtener un ticket por ID"""
    try:
        query = """
            SELECT t.*, u.username as created_by, a.username as assigned_to_name
            FROM Tickets t
            LEFT JOIN Users u ON t.user_id = u.id
            LEFT JOIN Users a ON t.assigned_to = a.id
            WHERE t.id = ?
        """
        tickets = db.execute_query(query, (ticket_id,))
        
        if not tickets:
            raise HTTPException(status_code=404, detail="Ticket no encontrado")
        
        # Verificar permisos
        ticket = tickets[0]
        if current_user['role'] == 'cliente' and ticket['user_id'] != current_user['id']:
            raise HTTPException(status_code=403, detail="No autorizado")
        
        return ticket
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/tickets", response_model=TicketResponse, status_code=status.HTTP_201_CREATED)
async def create_ticket(ticket: TicketCreate, current_user: dict = Depends(get_current_user)):
    """Crear un nuevo ticket"""
    try:
        query = """
            INSERT INTO Tickets (user_id, title, description, priority)
            OUTPUT INSERTED.*
            VALUES (?, ?, ?, ?)
        """
        result = db.execute_query(query, (
            current_user['id'],
            ticket.title,
            ticket.description,
            ticket.priority
        ))
        
        # Obtener el ticket completo con joins
        get_query = """
            SELECT t.*, u.username as created_by, a.username as assigned_to_name
            FROM Tickets t
            LEFT JOIN Users u ON t.user_id = u.id
            LEFT JOIN Users a ON t.assigned_to = a.id
            WHERE t.id = ?
        """
        return db.execute_query(get_query, (result[0]['id'],))[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/tickets/{ticket_id}", response_model=TicketResponse)
async def update_ticket(
    ticket_id: int,
    ticket_update: TicketUpdate,
    current_user: dict = Depends(get_current_user)
):
    """Actualizar un ticket"""
    try:
        # Verificar que el ticket existe
        check_query = "SELECT user_id FROM Tickets WHERE id = ?"
        tickets = db.execute_query(check_query, (ticket_id,))
        if not tickets:
            raise HTTPException(status_code=404, detail="Ticket no encontrado")
        
        # Verificar permisos
        if current_user['role'] == 'cliente' and tickets[0]['user_id'] != current_user['id']:
            raise HTTPException(status_code=403, detail="No autorizado")
        
        # Construir query de actualización dinámicamente
        update_fields = []
        params = []
        
        if ticket_update.title is not None:
            update_fields.append("title = ?")
            params.append(ticket_update.title)
        if ticket_update.description is not None:
            update_fields.append("description = ?")
            params.append(ticket_update.description)
        if ticket_update.status is not None:
            update_fields.append("status = ?")
            params.append(ticket_update.status)
        if ticket_update.priority is not None:
            update_fields.append("priority = ?")
            params.append(ticket_update.priority)
        if ticket_update.assigned_to is not None:
            update_fields.append("assigned_to = ?")
            params.append(ticket_update.assigned_to)
        
        if not update_fields:
            raise HTTPException(status_code=400, detail="No hay campos para actualizar")
        
        update_fields.append("updated_at = GETDATE()")
        params.append(ticket_id)
        
        query = f"UPDATE Tickets SET {', '.join(update_fields)} WHERE id = ?"
        db.execute_query(query, tuple(params), fetch=False)
        
        # Obtener el ticket actualizado
        get_query = """
            SELECT t.*, u.username as created_by, a.username as assigned_to_name
            FROM Tickets t
            LEFT JOIN Users u ON t.user_id = u.id
            LEFT JOIN Users a ON t.assigned_to = a.id
            WHERE t.id = ?
        """
        return db.execute_query(get_query, (ticket_id,))[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/tickets/{ticket_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_ticket(ticket_id: int, current_user: dict = Depends(get_current_user)):
    """Eliminar un ticket"""
    if current_user['role'] not in ['admin', 'tecnico']:
        raise HTTPException(status_code=403, detail="No autorizado")
    
    try:
        query = "DELETE FROM Tickets WHERE id = ?"
        rows = db.execute_query(query, (ticket_id,), fetch=False)
        if rows == 0:
            raise HTTPException(status_code=404, detail="Ticket no encontrado")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== UPLOADS ====================

@app.post("/api/upload")
async def upload_file(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    """Subir un archivo"""
    try:
        # Verificar extensión
        file_ext = file.filename.split('.')[-1].lower()
        if file_ext not in settings.ALLOWED_EXTENSIONS:
            raise HTTPException(status_code=400, detail="Tipo de archivo no permitido")
        
        # Generar nombre único
        filename = f"{datetime.now().timestamp()}_{file.filename}"
        file_path = os.path.join(settings.UPLOAD_FOLDER, filename)
        
        # Guardar archivo
        with open(file_path, "wb") as buffer:
            content = await file.read()
            if len(content) > settings.MAX_UPLOAD_SIZE:
                raise HTTPException(status_code=400, detail="Archivo demasiado grande")
            buffer.write(content)
        
        return {
            "filename": filename,
            "url": f"/uploads/{filename}",
            "size": len(content)
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== ESTADÍSTICAS ====================

@app.get("/api/stats")
async def get_stats(current_user: dict = Depends(get_current_user)):
    """Obtener estadísticas"""
    try:
        stats = {}
        
        # Total de usuarios
        result = db.execute_query("SELECT COUNT(*) as count FROM Users")
        stats['total_users'] = result[0]['count']
        
        # Total de tickets
        result = db.execute_query("SELECT COUNT(*) as count FROM Tickets")
        stats['total_tickets'] = result[0]['count']
        
        # Tickets por estado
        result = db.execute_query("""
            SELECT status, COUNT(*) as count
            FROM Tickets
            GROUP BY status
        """)
        stats['tickets_by_status'] = {row['status']: row['count'] for row in result}
        
        # Tickets por prioridad
        result = db.execute_query("""
            SELECT priority, COUNT(*) as count
            FROM Tickets
            GROUP BY priority
        """)
        stats['tickets_by_priority'] = {row['priority']: row['count'] for row in result}
        
        # Si es cliente, solo sus tickets
        if current_user['role'] == 'cliente':
            result = db.execute_query(
                "SELECT COUNT(*) as count FROM Tickets WHERE user_id = ?",
                (current_user['id'],)
            )
            stats['my_tickets'] = result[0]['count']
        
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "server:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=settings.DEBUG
    )