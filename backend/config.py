import os
from dotenv import load_dotenv
from pathlib import Path

load_dotenv()

class Settings:
    """Configuración centralizada de la aplicación"""
    
    # SQL Server
    DB_SERVER: str = os.getenv('DB_SERVER', 'localhost')
    DB_NAME: str = os.getenv('DB_NAME', 'TechAssistDB')
    DB_USER: str = os.getenv('DB_USER', 'sa')
    DB_PASSWORD: str = os.getenv('DB_PASSWORD', 'TechAssist2024!')
    DB_PORT: str = os.getenv('DB_PORT', '1433')
    DB_DRIVER: str = os.getenv('DB_DRIVER', 'ODBC Driver 18 for SQL Server')
    
    # JWT
    SECRET_KEY: str = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    ALGORITHM: str = os.getenv('ALGORITHM', 'HS256')
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv('ACCESS_TOKEN_EXPIRE_MINUTES', '30'))
    
    # FastAPI
    API_HOST: str = os.getenv('API_HOST', '0.0.0.0')
    API_PORT: int = int(os.getenv('API_PORT', '8001'))
    DEBUG: bool = os.getenv('DEBUG', 'True').lower() == 'true'
    CORS_ORIGINS: list = os.getenv('CORS_ORIGINS', 'http://localhost:3000').split(',')
    
    # Uploads
    UPLOAD_FOLDER: str = os.getenv('UPLOAD_FOLDER', './uploads')
    MAX_UPLOAD_SIZE: int = int(os.getenv('MAX_UPLOAD_SIZE', '5242880'))  # 5MB
    ALLOWED_EXTENSIONS: set = set(os.getenv('ALLOWED_EXTENSIONS', 'jpg,jpeg,png,gif,pdf').split(','))
    
    @property
    def connection_string(self) -> str:
        """Retorna la cadena de conexión de SQL Server"""
        return (
            f"DRIVER={{{self.DB_DRIVER}}};"
            f"SERVER={self.DB_SERVER},{self.DB_PORT};"
            f"DATABASE={self.DB_NAME};"
            f"UID={self.DB_USER};"
            f"PWD={self.DB_PASSWORD};"
            f"TrustServerCertificate=yes;"
            f"Encrypt=yes;"
        )
    
    def create_upload_folder(self):
        """Crear carpeta de uploads si no existe"""
        Path(self.UPLOAD_FOLDER).mkdir(parents=True, exist_ok=True)

settings = Settings()