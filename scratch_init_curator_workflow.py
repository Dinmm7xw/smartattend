import os
import json
import psycopg2
from psycopg2.extras import RealDictCursor
import sqlite3

PG_CONFIG = {
    "dbname": "smartattend_db",
    "user": "postgres",
    "password": "password",
    "host": "localhost",
    "port": 5432
}

def init_tables():
    # PostgreSQL
    try:
        conn = psycopg2.connect(**PG_CONFIG)
        cur = conn.cursor()
        cur.execute("""
            ALTER TABLE users ADD COLUMN IF NOT EXISTS one_time_password VARCHAR(100);
        """)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS group_applications (
                id SERIAL PRIMARY KEY,
                group_name VARCHAR(50) NOT NULL,
                curator_name VARCHAR(255) NOT NULL,
                curator_email VARCHAR(255),
                faculty VARCHAR(150) DEFAULT 'Ақпараттық қауіпсіздік бөлімі',
                course_year INT DEFAULT 2,
                status VARCHAR(50) DEFAULT 'PENDING',
                students_json TEXT NOT NULL,
                credentials_json TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                approved_at TIMESTAMP,
                approved_by VARCHAR(255)
            );
        """)
        conn.commit()
        conn.close()
        print("[PostgreSQL] Tables updated successfully!")
    except Exception as e:
        print("[PostgreSQL] Error:", e)

    # SQLite
    try:
        db_path = os.path.join(os.path.dirname(__file__), "smartattend.db")
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        try:
            cur.execute("ALTER TABLE users ADD COLUMN one_time_password TEXT;")
        except Exception:
            pass
        cur.execute("""
            CREATE TABLE IF NOT EXISTS group_applications (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                group_name TEXT NOT NULL,
                curator_name TEXT NOT NULL,
                curator_email TEXT,
                faculty TEXT DEFAULT 'Ақпараттық қауіпсіздік бөлімі',
                course_year INTEGER DEFAULT 2,
                status TEXT DEFAULT 'PENDING',
                students_json TEXT NOT NULL,
                credentials_json TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                approved_at TIMESTAMP,
                approved_by TEXT
            );
        """)
        conn.commit()
        conn.close()
        print("[SQLite] Tables updated successfully!")
    except Exception as e:
        print("[SQLite] Error:", e)

if __name__ == "__main__":
    init_tables()
