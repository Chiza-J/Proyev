import os
import time
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')

def wait_for_db():
    """Esperar a que SQL Server esté disponible"""
    print("Esperando que SQL Server esté disponible...")
    max_retries = 30
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            engine = create_engine(DATABASE_URL)
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            print("✓ SQL Server está disponible")
            engine.dispose()
            return True
        except Exception as e:
            retry_count += 1
            print(f"Intento {retry_count}/{max_retries}: SQL Server no está listo. Esperando...")
            time.sleep(2)
    
    print("✗ No se pudo conectar a SQL Server después de varios intentos")
    return False

def execute_sql_file():
    """Ejecutar el archivo SQL de inicialización"""
    print("\nEjecutando script de inicialización SQL...")
    
    try:
        # Leer el archivo SQL
        sql_file_path = '/app/sql/init.sql'
        if not os.path.exists(sql_file_path):
            sql_file_path = '../sql/init.sql'
        
        with open(sql_file_path, 'r', encoding='utf-8') as file:
            sql_script = file.read()
        
        # Crear engine
        engine = create_engine(DATABASE_URL)
        
        # Separar por GO statements (SQL Server batch separator)
        batches = [batch.strip() for batch in sql_script.split('GO') if batch.strip()]
        
        # Ejecutar cada batch
        with engine.connect() as conn:
            for i, batch in enumerate(batches):
                try:
                    conn.execute(text(batch))
                    conn.commit()
                except Exception as e:
                    # Ignorar errores de objetos que ya existen
                    if 'already exists' not in str(e) and 'There is already an object' not in str(e):
                        print(f"Warning en batch {i+1}: {e}")
        
        engine.dispose()
        print("✓ Base de datos inicializada correctamente")
        return True
        
    except Exception as e:
        print(f"✗ Error al inicializar base de datos: {e}")
        return False

if __name__ == "__main__":
    if wait_for_db():
        execute_sql_file()
    else:
        exit(1)
