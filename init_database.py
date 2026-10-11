"""
SmartAttend Enterprise — Миграция и инициализация базы данных
"""
import os
import sys
import psycopg2
from psycopg2.extras import RealDictCursor
import sqlite3

# UTF-8 stdout fix
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

PG_CONFIG = {
    "host": os.environ.get("PG_HOST", "localhost"),
    "port": int(os.environ.get("PG_PORT", "5432")),
    "user": os.environ.get("PG_USER", "postgres"),
    "password": os.environ.get("PG_PASSWORD", ""),
    "dbname": os.environ.get("PG_DBNAME", "smartattend_db")
}

def run_postgres_migration():
    print(">>> [1/2] Запуск миграции PostgreSQL (smartattend_db)...")
    try:
        conn = psycopg2.connect(**PG_CONFIG)
        cur = conn.cursor()

        # Дропаем старые демонстрационные таблицы с каскадом
        cur.execute("""
            DROP TABLE IF EXISTS parent_notes CASCADE;
            DROP TABLE IF EXISTS sos_alerts CASCADE;
            DROP TABLE IF EXISTS attendance_records CASCADE;
            DROP TABLE IF EXISTS lessons CASCADE;
            DROP TABLE IF EXISTS rooms CASCADE;
            DROP TABLE IF EXISTS users CASCADE;
            DROP TABLE IF EXISTS academic_groups CASCADE;
            DROP TABLE IF EXISTS staff_users CASCADE;
            DROP TABLE IF EXISTS medical_excuses CASCADE;
        """)
        conn.commit()

        # Читаем schema.sql
        with open("schema.sql", "r", encoding="utf-8") as f:
            sql_script = f.read()

        cur.execute(sql_script)
        conn.commit()

        cur.execute("SELECT COUNT(*) FROM users;")
        user_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM lessons;")
        lesson_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM academic_groups;")
        group_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM rooms;")
        room_count = cur.fetchone()[0]

        print(f"[OK] PostgreSQL обновлен: {group_count} групп, {user_count} пользователей (20 студентов БҚ2405 + куратор + преподаватели + ата-ана), {lesson_count} пар, {room_count} аудиторий!")
        cur.close()
        conn.close()
        return True
    except Exception as e:
        print(f"[ERROR] Ошибка миграции PostgreSQL: {e}")
        return False

def run_sqlite_migration():
    print(">>> [2/2] Синхронизация локальной базы SQLite (smartattend.db)...")
    try:
        db_path = "smartattend.db"
        if os.path.exists(db_path):
            try:
                os.remove(db_path)
            except Exception:
                pass
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()

        cur.executescript("""
        CREATE TABLE IF NOT EXISTS academic_groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            faculty TEXT NOT NULL,
            course_year INTEGER DEFAULT 2,
            curator_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT DEFAULT '123456',
            full_name TEXT NOT NULL,
            role TEXT NOT NULL,
            student_id TEXT UNIQUE,
            group_id INTEGER REFERENCES academic_groups(id),
            child_student_id INTEGER REFERENCES users(id),
            phone TEXT,
            department TEXT,
            avatar_url TEXT,
            is_active BOOLEAN DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS rooms (
            code TEXT PRIMARY KEY,
            svg_id TEXT,
            floor INTEGER NOT NULL DEFAULT 2,
            block TEXT DEFAULT 'C1.3',
            name_kk TEXT NOT NULL,
            name_ru TEXT NOT NULL,
            name_en TEXT NOT NULL,
            capacity INTEGER DEFAULT 30
        );

        CREATE TABLE IF NOT EXISTS lessons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            teacher_id INTEGER REFERENCES users(id),
            group_id INTEGER REFERENCES academic_groups(id),
            room_code TEXT REFERENCES rooms(code),
            day_of_week TEXT NOT NULL,
            pair_number INTEGER DEFAULT 1,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            is_qr_active BOOLEAN DEFAULT 0,
            current_qr_token TEXT,
            qr_updated_at TIMESTAMP,
            status TEXT DEFAULT 'SCHEDULED'
        );

        CREATE TABLE IF NOT EXISTS attendance_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lesson_id INTEGER REFERENCES lessons(id),
            student_id INTEGER REFERENCES users(id),
            status TEXT NOT NULL,
            delay_minutes INTEGER DEFAULT 0,
            grade_score INTEGER,
            face_verified BOOLEAN DEFAULT 1,
            qr_token TEXT,
            check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(lesson_id, student_id)
        );

        CREATE TABLE IF NOT EXISTS parent_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER REFERENCES users(id),
            parent_id INTEGER REFERENCES users(id),
            note_type TEXT NOT NULL,
            reason TEXT NOT NULL,
            date_from DATE NOT NULL,
            date_to DATE NOT NULL,
            document_url TEXT,
            status TEXT DEFAULT 'PENDING',
            reviewed_by INTEGER REFERENCES users(id),
            review_comment TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS sos_alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lesson_id INTEGER REFERENCES lessons(id),
            student_id INTEGER REFERENCES users(id),
            group_id INTEGER REFERENCES academic_groups(id),
            alert_type TEXT NOT NULL,
            message TEXT NOT NULL,
            severity TEXT DEFAULT 'HIGH',
            is_resolved BOOLEAN DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """)

        conn.commit()
        conn.close()
        print("[OK] SQLite база smartattend.db синхронизирована!")
        return True
    except Exception as e:
        print(f"[ERROR] Ошибка SQLite: {e}")
        return False

if __name__ == "__main__":
    pg_ok = run_postgres_migration()
    sq_ok = run_sqlite_migration()
    print("\n" + "="*50)
    print(f"РЕЗУЛЬТАТ МИГРАЦИИ: Postgres={'OK' if pg_ok else 'ERR'}, SQLite={'OK' if sq_ok else 'ERR'}")
    print("="*50)
