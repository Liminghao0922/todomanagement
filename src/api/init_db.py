#!/usr/bin/env python3
"""
Database initialization and migration script
This script applies migrations to add new fields to existing SQLite database
"""

import sqlite3
import sys
from pathlib import Path

def get_db_path():
    """Get database path from config"""
    # Default SQLite path
    return "todo.db"

def apply_sqlite_migration():
    """Apply migration to add new columns to existing SQLite database"""
    db_path = get_db_path()
    
    if not Path(db_path).exists():
        print(f"Database file not found at {db_path}")
        print("Please run 'python main.py' first to create the database")
        sys.exit(1)
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get existing columns
        cursor.execute("PRAGMA table_info(todos)")
        existing_cols = {row[1] for row in cursor.fetchall()}
        
        print(f"Current columns in todos table: {existing_cols}\n")
        
        # Define migration DDL statements
        migrations = [
            ("estimated_hours", "ALTER TABLE todos ADD COLUMN estimated_hours INTEGER"),
            ("complexity", "ALTER TABLE todos ADD COLUMN complexity TEXT"),
            ("project", "ALTER TABLE todos ADD COLUMN project TEXT"),
            ("category", "ALTER TABLE todos ADD COLUMN category TEXT"),
            ("actual_hours", "ALTER TABLE todos ADD COLUMN actual_hours INTEGER"),
            ("dependencies", "ALTER TABLE todos ADD COLUMN dependencies TEXT"),
            ("required_skills", "ALTER TABLE todos ADD COLUMN required_skills TEXT"),
            ("completed_at", "ALTER TABLE todos ADD COLUMN completed_at DATETIME"),
            ("completed_content", "ALTER TABLE todos ADD COLUMN completed_content TEXT"),
        ]
        
        applied = []
        skipped = []
        for col_name, ddl in migrations:
            if col_name not in existing_cols:
                try:
                    cursor.execute(ddl)
                    applied.append(col_name)
                    print(f"✅ Added column: {col_name}")
                except sqlite3.OperationalError as e:
                    if "already exists" in str(e):
                        skipped.append(col_name)
                    else:
                        raise
            else:
                skipped.append(col_name)
        
        # Add indexes if they don't exist
        index_statements = [
            "CREATE INDEX IF NOT EXISTS idx_owner_project ON todos(owner_id, project)",
            "CREATE INDEX IF NOT EXISTS idx_owner_category ON todos(owner_id, category)",
        ]
        
        for idx_sql in index_statements:
            cursor.execute(idx_sql)
        
        conn.commit()
        conn.close()
        
        print(f"\n✅ Migration completed successfully!")
        print(f"   Added: {len(applied)} columns - {', '.join(applied)}")
        if skipped:
            print(f"   Already exist: {len(skipped)} columns")
            
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

def init_postgres_db():
    """Initialize PostgreSQL database (just create tables)"""
    try:
        from sqlalchemy import create_engine
        from models import Base
        
        # PostgreSQL URL should be in environment or config
        db_url = "postgresql://..."  # Configure as needed
        engine = create_engine(db_url)
        Base.metadata.create_all(bind=engine)
        print("✅ PostgreSQL database tables created/updated successfully")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    print("=" * 60)
    print("Todo Management - Database Migration")
    print("=" * 60 + "\n")
    
    db_path = get_db_path()
    print(f"SQLite Database: {db_path}\n")
    
    if Path(db_path).exists():
        print(f"✅ Database exists\n")
        apply_sqlite_migration()
    else:
        print(f"⚠️  Database not found at {db_path}")
        print("Please run 'python main.py' first to initialize the database")
        print("\nThe application will automatically create the database with all new fields on first run.")

