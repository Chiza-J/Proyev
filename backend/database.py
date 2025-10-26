import pyodbc
from config import settings
from contextlib import contextmanager
from typing import Optional, List, Dict, Any

class Database:
    """Clase para manejar la conexión a SQL Server"""
    
    def __init__(self):
        self.connection_string = settings.connection_string
    
    def get_connection(self):
        """Crear y retornar una conexión a SQL Server"""
        try:
            conn = pyodbc.connect(self.connection_string)
            return conn
        except pyodbc.Error as e:
            print(f"❌ Error de conexión a la base de datos: {e}")
            raise
    
    @contextmanager
    def get_cursor(self):
        """Context manager para manejar conexiones y cursores"""
        conn = self.get_connection()
        cursor = conn.cursor()
        try:
            yield cursor
            conn.commit()
        except Exception as e:
            conn.rollback()
            print(f"❌ Error en transacción: {e}")
            raise
        finally:
            cursor.close()
            conn.close()
    
    def execute_query(self, query: str, params: Optional[tuple] = None, fetch: bool = True) -> Any:
        """Ejecutar una query de manera segura"""
        try:
            with self.get_cursor() as cursor:
                if params:
                    cursor.execute(query, params)
                else:
                    cursor.execute(query)
                
                if fetch:
                    columns = [column[0] for column in cursor.description] if cursor.description else []
                    results = []
                    for row in cursor.fetchall():
                        results.append(dict(zip(columns, row)))
                    return results
                else:
                    return cursor.rowcount
        except Exception as e:
            print(f"❌ Error ejecutando query: {e}")
            raise
    
    def test_connection(self) -> bool:
        """Probar la conexión a la base de datos"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT @@VERSION")
            version = cursor.fetchone()[0]
            cursor.close()
            conn.close()
            print(f"✅ Conexión exitosa a SQL Server")
            print(f"Version: {version[:80]}...")
            return True
        except Exception as e:
            print(f"❌ Error al conectar: {e}")
            return False

# Instancia global
db = Database()