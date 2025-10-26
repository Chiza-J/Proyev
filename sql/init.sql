import os
import time
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')

def wait_for_sql_server():
    """Esperar a que SQL Server esté disponible"""
    print("=" * 50)
    print("Esperando que SQL Server esté disponible...")
    print("=" * 50)
    
    # Conectar a master primero (no a TechAssistDB)
    master_url = DATABASE_URL.replace('/TechAssistDB?', '/master?')
    
    max_retries = 30
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            engine = create_engine(master_url, pool_pre_ping=True)
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
                conn.commit()
            engine.dispose()
            print("✓ SQL Server está disponible")
            return True
        except Exception as e:
            retry_count += 1
            print(f"Intento {retry_count}/{max_retries}: SQL Server no está listo...")
            if retry_count % 5 == 0:
                print(f"  Error: {str(e)[:100]}")
            time.sleep(2)
    
    print("✗ No se pudo conectar a SQL Server")
    return False

def create_database():
    """Crear la base de datos TechAssistDB si no existe"""
    print("\n" + "=" * 50)
    print("Creando base de datos TechAssistDB...")
    print("=" * 50)
    
    try:
        # Conectar a master para crear la base de datos
        master_url = DATABASE_URL.replace('/TechAssistDB?', '/master?')
        engine = create_engine(master_url, pool_pre_ping=True)
        
        with engine.connect() as conn:
            # Usar AUTOCOMMIT para CREATE DATABASE
            conn.execute(text("SET IMPLICIT_TRANSACTIONS OFF"))
            conn.execution_options(isolation_level="AUTOCOMMIT")
            
            # Verificar si existe
            result = conn.execute(text(
                "SELECT database_id FROM sys.databases WHERE name = 'TechAssistDB'"
            ))
            
            if result.fetchone() is None:
                print("Base de datos no existe, creando...")
                conn.execute(text("CREATE DATABASE TechAssistDB"))
                print("✓ Base de datos TechAssistDB creada")
            else:
                print("✓ Base de datos TechAssistDB ya existe")
        
        engine.dispose()
        
        # Esperar a que la base de datos esté lista
        print("Esperando a que la base de datos esté lista...")
        time.sleep(3)
        
        return True
        
    except Exception as e:
        print(f"✗ Error al crear base de datos: {e}")
        import traceback
        traceback.print_exc()
        return False

def execute_init_sql():
    """Ejecutar el archivo init.sql"""
    print("\n" + "=" * 50)
    print("Ejecutando script de inicialización...")
    print("=" * 50)
    
    sql_file_paths = [
        '/app/sql/init.sql',
        './sql/init.sql',
        '../sql/init.sql'
    ]
    
    sql_file_path = None
    for path in sql_file_paths:
        if os.path.exists(path):
            sql_file_path = path
            break
    
    if not sql_file_path:
        print("⚠ Archivo init.sql no encontrado")
        print("  Continuando sin inicialización de tablas...")
        return True
    
    try:
        print(f"Leyendo archivo: {sql_file_path}")
        
        with open(sql_file_path, 'r', encoding='utf-8') as file:
            sql_script = file.read()
        
        # Conectar a TechAssistDB
        engine = create_engine(DATABASE_URL, pool_pre_ping=True)
        
        # Separar por GO statements
        batches = [b.strip() for b in sql_script.split('GO') if b.strip()]
        
        print(f"Ejecutando {len(batches)} batches SQL...")
        
        with engine.connect() as conn:
            for i, batch in enumerate(batches):
                try:
                    # Limpiar comentarios
                    lines = [line for line in batch.split('\n') 
                            if line.strip() and not line.strip().startswith('--')]
                    clean_batch = '\n'.join(lines)
                    
                    if clean_batch:
                        conn.execute(text(clean_batch))
                        conn.commit()
                        print(f"  ✓ Batch {i+1}/{len(batches)} ejecutado")
                except Exception as e:
                    error_msg = str(e).lower()
                    if any(x in error_msg for x in ['already exists', 'already an object', 'duplicate']):
                        print(f"  ⚠ Batch {i+1}: Objeto ya existe (ignorado)")
                    else:
                        print(f"  ✗ Error en batch {i+1}: {e}")
        
        engine.dispose()
        print("✓ Inicialización de base de datos completada")
        return True
        
    except Exception as e:
        print(f"✗ Error al ejecutar init.sql: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("\n" + "=" * 50)
    print("INICIANDO CONFIGURACIÓN DE BASE DE DATOS")
    print("=" * 50)
    
    # Paso 1: Esperar a que SQL Server esté listo
    if not wait_for_sql_server():
        print("\n" + "=" * 50)
        print("✗ ERROR: SQL Server no respondió")
        print("=" * 50)
        exit(1)
    
    # Paso 2: Crear la base de datos
    if not create_database():
        print("\n" + "=" * 50)
        print("✗ ERROR: No se pudo crear la base de datos")
        print("=" * 50)
        exit(1)
    
    # Paso 3: Ejecutar init.sql
    if not execute_init_sql():
        print("\n" + "=" * 50)
        print("⚠ ADVERTENCIA: Error en inicialización de tablas")
        print("=" * 50)
        # No hacer exit aquí, puede que las tablas ya existan
    
    print("\n" + "=" * 50)
    print("✓ CONFIGURACIÓN COMPLETADA CON ÉXITO")
    print("=" * 50)
    print("\nSQL Server está listo en: sqlserver:1433")
    print("Base de datos: TechAssistDB")
    print("Usuario: sa")
    print("=" * 50 + "\n")