"""
SmartAttend — Инициализация и миграция реальной базы данных PostgreSQL (smartattend_db)
"""
import psycopg2
from psycopg2.extras import RealDictCursor

PG_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "user": "postgres",
    "password": "",
    "dbname": "smartattend_db"
}

def init_postgres():
    conn = psycopg2.connect(**PG_CONFIG)
    cur = conn.cursor()

    # 1. Таблица групп (Groups)
    cur.execute("""
    CREATE TABLE IF NOT EXISTS academic_groups (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50) UNIQUE NOT NULL,
        faculty VARCHAR(100) NOT NULL,
        course_year INT DEFAULT 3,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # 2. Таблица пользователей (Users: Студенты, Преподаватели, Деканат, Директор)
    cur.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        full_name VARCHAR(255) NOT NULL,
        role VARCHAR(50) NOT NULL, -- 'DIRECTOR', 'TEACHER', 'DEAN', 'STUDENT'
        student_id VARCHAR(50) UNIQUE,
        group_id INT REFERENCES academic_groups(id) ON DELETE SET NULL,
        department VARCHAR(100),
        avatar_url TEXT,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # 3. Таблица расписания и занятий (Lessons)
    cur.execute("""
    CREATE TABLE IF NOT EXISTS lessons (
        id SERIAL PRIMARY KEY,
        title VARCHAR(150) NOT NULL,
        teacher_id INT REFERENCES users(id) ON DELETE CASCADE,
        group_id INT REFERENCES academic_groups(id) ON DELETE CASCADE,
        classroom VARCHAR(50) NOT NULL,
        start_time VARCHAR(20) NOT NULL,
        end_time VARCHAR(20) NOT NULL,
        is_qr_active BOOLEAN DEFAULT FALSE,
        current_qr_token VARCHAR(255),
        qr_updated_at TIMESTAMP,
        status VARCHAR(50) DEFAULT 'ACTIVE'
    );
    """)

    # 4. Таблица посещаемости (Attendance Records)
    cur.execute("""
    CREATE TABLE IF NOT EXISTS attendance_records (
        id SERIAL PRIMARY KEY,
        lesson_id INT REFERENCES lessons(id) ON DELETE CASCADE,
        student_id INT REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(50) NOT NULL, -- 'PRESENT', 'LATE', 'ABSENT', 'EXCUSED'
        check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        delay_minutes INT DEFAULT 0,
        face_verified BOOLEAN DEFAULT TRUE,
        ip_address VARCHAR(50),
        UNIQUE(lesson_id, student_id)
    );
    """)

    # 5. Таблица экстренных оповещений (SOS Alerts)
    cur.execute("""
    CREATE TABLE IF NOT EXISTS sos_alerts (
        id SERIAL PRIMARY KEY,
        lesson_id INT REFERENCES lessons(id) ON DELETE SET NULL,
        student_id INT REFERENCES users(id) ON DELETE SET NULL,
        alert_type VARCHAR(50) NOT NULL, -- 'LATE_SOS', 'TEACHER_DELAY', 'SECURITY_BREACH'
        message TEXT NOT NULL,
        severity VARCHAR(20) DEFAULT 'HIGH',
        is_resolved BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # 6. Таблица справок по болезни (Medical Excuses)
    cur.execute("""
    CREATE TABLE IF NOT EXISTS medical_excuses (
        id SERIAL PRIMARY KEY,
        student_id INT REFERENCES users(id) ON DELETE CASCADE,
        reason TEXT NOT NULL,
        document_url TEXT,
        status VARCHAR(50) DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED'
        reviewed_by INT REFERENCES users(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # ── SEED INITIAL DATA ──
    # Группы
    groups = [
        ('ИС-21-01', 'Факультет Инженерии и Компьютерных Наук', 3),
        ('ВТиПО-20-02', 'Факультет Инженерии и Компьютерных Наук', 4),
        ('КБ-22-03', 'Факультет Кибербезопасности', 2),
        ('АИ-21-01', 'Факультет Искусственного Интеллекта', 3),
    ]
    for g in groups:
        cur.execute("""
            INSERT INTO academic_groups (name, faculty, course_year) 
            VALUES (%s, %s, %s) ON CONFLICT (name) DO NOTHING
        """, g)

    # Получаем id группы ИС-21-01
    cur.execute("SELECT id FROM academic_groups WHERE name = 'ИС-21-01'")
    group_id = cur.fetchone()[0]

    # Главный Администратор / Директор
    cur.execute("""
        INSERT INTO users (email, full_name, role, department, is_active)
        VALUES ('p82041180@gmail.com', 'Главный администратор / Директор', 'DIRECTOR', 'Ректорат', TRUE)
        ON CONFLICT (email) DO UPDATE SET role = 'DIRECTOR', department = 'Ректорат'
    """)

    # Преподаватель
    cur.execute("""
        INSERT INTO users (email, full_name, role, department, is_active)
        VALUES ('teacher@smartattend.edu.kz', 'Профессор А. Сейітов', 'TEACHER', 'Кафедра Компьютерных Наук', TRUE)
        ON CONFLICT (email) DO NOTHING
    """)

    # Деканат
    cur.execute("""
        INSERT INTO users (email, full_name, role, department, is_active)
        VALUES ('dean@smartattend.edu.kz', 'Деканат Инженерного Факультета', 'DEAN', 'Деканат', TRUE)
        ON CONFLICT (email) DO NOTHING
    """)

    # Студенты (12 человек)
    students = [
        ('STU-001', 'Айдар Сейітов', 'student@smartattend.edu.kz'),
        ('STU-002', 'Нұрай Бекова', 'nuray.bekova@smartattend.edu.kz'),
        ('STU-003', 'Марат Қасымов', 'marat.kasymov@smartattend.edu.kz'),
        ('STU-004', 'Зарина Ахметова', 'zarina.a@smartattend.edu.kz'),
        ('STU-005', 'Дамир Жұмабеков', 'damir.zh@smartattend.edu.kz'),
        ('STU-006', 'Алия Мансурова', 'aliya.m@smartattend.edu.kz'),
        ('STU-007', 'Ерлан Дүйсенов', 'erlan.d@smartattend.edu.kz'),
        ('STU-008', 'Сания Назарова', 'saniya.n@smartattend.edu.kz'),
        ('STU-009', 'Тимур Байдільдін', 'timur.b@smartattend.edu.kz'),
        ('STU-010', 'Жансая Ермекова', 'zhansaya.e@smartattend.edu.kz'),
        ('STU-011', 'Ақерке Мусина', 'akerke.m@smartattend.edu.kz'),
        ('STU-012', 'Руслан Сейлханов', 'ruslan.s@smartattend.edu.kz'),
    ]
    for sid, name, email in students:
        cur.execute("""
            INSERT INTO users (email, full_name, role, student_id, group_id, department, is_active)
            VALUES (%s, %s, 'STUDENT', %s, %s, 'ИС-21-01', TRUE)
            ON CONFLICT (email) DO NOTHING
        """, (email, name, sid, group_id))

    # Преподаватель ID
    cur.execute("SELECT id FROM users WHERE email = 'teacher@smartattend.edu.kz'")
    teacher_id = cur.fetchone()[0]

    # Учебные занятия (Lessons)
    lessons = [
        ('Информатика негіздері', teacher_id, group_id, '312А', '14:00', '15:30'),
        ('Жоғары математика', teacher_id, group_id, '210Б', '16:00', '17:30'),
        ('Физика', teacher_id, group_id, '105В', '10:00', '11:30'),
    ]
    for title, tid, gid, room, st, et in lessons:
        cur.execute("""
            INSERT INTO lessons (title, teacher_id, group_id, classroom, start_time, end_time, is_qr_active)
            VALUES (%s, %s, %s, %s, %s, %s, TRUE)
            ON CONFLICT DO NOTHING
        """, (title, tid, gid, room, st, et))

    conn.commit()
    conn.close()
    print(">>> PostgreSQL SmartAttend Database initialized successfully with all tables and seeds!")

if __name__ == "__main__":
    init_postgres()
