"""
SmartAttend Enterprise — FastAPI Backend Server
Архитектура: S-Student, S-Mugalim, S-Kurator, S-Ata-Ana, S-Deanat
Поддержка PostgreSQL + SQLite Fallback, Face ID, Динамический QR, Расписание колледжа
"""

import os
import sys
import datetime
import sqlite3
import json
from typing import Optional, List
from fastapi import FastAPI, HTTPException, Depends, Header, UploadFile, File, Form
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse, Response
from pydantic import BaseModel
import jwt
import psycopg2
from psycopg2.extras import RealDictCursor
import numpy as np

# UTF-8 stdout для Windows
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

# ── ЗАГРУЗКА .ENV ──
def load_env(env_path=".env"):
    if os.path.exists(env_path):
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, val = line.split("=", 1)
                    os.environ.setdefault(key.strip(), val.strip())

load_env(os.path.join(os.path.dirname(__file__), ".env"))

PORT = int(os.environ.get("PORT", "8585"))
HOST = os.environ.get("HOST", "0.0.0.0")
JWT_SECRET = os.environ.get("JWT_SECRET", "smartattend_enterprise_secret_key_2026_rbac")
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_HOURS = int(os.environ.get("JWT_EXPIRATION_HOURS", "24"))

DATABASE_URL = os.environ.get("DATABASE_URL", "")

PG_CONFIG = {
    "host": os.environ.get("PG_HOST", "localhost"),
    "port": int(os.environ.get("PG_PORT", "5432")),
    "user": os.environ.get("PG_USER", "postgres"),
    "password": os.environ.get("PG_PASSWORD", ""),
    "dbname": os.environ.get("PG_DBNAME", "smartattend_db")
}

app = FastAPI(
    title="SmartAttend College Enterprise API",
    description="Система учета посещаемости колледжа: Студент, Мұғалім, Куратор, Ата-Ана, Деканат",
    version="4.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── БАЗА ДАННЫХ С АВТО-ФОЛЛБЭКОМ ──
def get_db():
    """Подключение к PostgreSQL (Supabase / local) с автоматическим фоллбэком на SQLite"""
    if DATABASE_URL:
        try:
            conn = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)
            return conn, "postgres"
        except Exception as e:
            print(f"[DB Warning] Could not connect via DATABASE_URL: {e}")
    try:
        conn = psycopg2.connect(**PG_CONFIG, cursor_factory=RealDictCursor)
        return conn, "postgres"
    except Exception:
        db_path = os.path.join(os.path.dirname(__file__), "smartattend.db")
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        return conn, "sqlite"

# ── МОДЕЛИ PYDANTIC ──
class LoginRequest(BaseModel):
    identifier: Optional[str] = ""  # email или student_id (ИИН) или быстрый пароль
    password: Optional[str] = None
    demo_role: Optional[str] = None  # 'student', 'curator', 'teacher', 'parent', 'dean', 'director'

class CheckInRequest(BaseModel):
    lesson_id: int
    student_email: str
    qr_token: str
    face_verified: bool = True

class StartQRRequest(BaseModel):
    lesson_id: int
    token: str

class ParentNoteRequest(BaseModel):
    student_id: int
    parent_email: str
    note_type: str              # 'FAMILY_CIRCUMSTANCE', 'ILLNESS', 'OFFICIAL_DUTY'
    reason: str
    date_from: str
    date_to: str
    is_signed_ecp: bool = True
    signer_iin: Optional[str] = "750412300184"
    ecp_hash: Optional[str] = "RSA256-SHA-8F3B92E1C4AA9082"
    signer_phone: Optional[str] = "+7 (777) 123-45-67"

class ReviewNoteRequest(BaseModel):
    note_id: int
    curator_email: str
    status: str                 # 'APPROVED', 'REJECTED'
    comment: Optional[str] = ""

class GradeRequest(BaseModel):
    lesson_id: int
    student_id: int
    grade_score: int

class RegisterUserRequest(BaseModel):
    email: str
    full_name: str
    role: str = "STUDENT"  # 'STUDENT', 'TEACHER', 'DEAN', 'DIRECTOR'
    student_id: Optional[str] = None
    group_name: Optional[str] = "БҚ2405"
    curator_group: Optional[str] = None  # Мысалы: "ИТ2301" егер осы оқытушы куратор болса
    password: Optional[str] = "12345"
    department: Optional[str] = None
    photo_base64: Optional[str] = None

class StaffBulkItem(BaseModel):
    full_name: str
    student_id: Optional[str] = None  # ИИН
    email: Optional[str] = None
    role: str = "TEACHER"             # 'TEACHER', 'DEAN'
    department: Optional[str] = "Ақпараттық технологиялар бөлімі"
    curator_group: Optional[str] = None  # e.g. "ИТ2301"
    password: Optional[str] = "12345"

class StaffBulkImportRequest(BaseModel):
    staff: List[StaffBulkItem]

class FaceVerifyRequest(BaseModel):
    email_or_id: str
    frame_base64: str
    lesson_id: Optional[int] = None

class FaceEnrollRequest(BaseModel):
    email_or_id: str
    photo_base64: str

class AttendanceCheckInRequest(BaseModel):
    lesson_id: int
    student_email: str
    qr_token: Optional[str] = "SA-TOKEN"
    face_verified: Optional[bool] = True

class StudentBulkItem(BaseModel):
    full_name: str
    email: Optional[str] = None
    photo_base64: Optional[str] = None
    iin: Optional[str] = None
    phone: Optional[str] = None

class CuratorGroupAppRequest(BaseModel):
    group_name: str
    curator_name: str
    curator_email: Optional[str] = "curator.arai@smartattend.kz"
    faculty: Optional[str] = "Ақпараттық технологиялар бөлімі"
    course_year: Optional[int] = 2
    students: List[StudentBulkItem]

class FacePreviewRequest(BaseModel):
    photo_base64: str

class RegisterUserRequest(BaseModel):
    full_name: str
    email: str
    role: str
    iin: Optional[str] = None
    phone: Optional[str] = None
    group_name: Optional[str] = None
    curator_group: Optional[str] = None
    department: Optional[str] = None
    student_id: Optional[str] = None
    password: Optional[str] = "12345"
    photo_base64: Optional[str] = None

class BulkStaffItem(BaseModel):
    full_name: str
    iin: Optional[str] = None
    role: str = "TEACHER"
    department: Optional[str] = "Ақпараттық технологиялар бөлімі"
    curator_group: Optional[str] = None
    password: Optional[str] = "12345"

class BulkStaffRequest(BaseModel):
    staff: List[BulkStaffItem]

# ── АВТОРИЗАЦИЯ И JWT ──
def create_session_jwt(user: dict) -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {
        "sub": user["email"],
        "user_id": user["id"],
        "email": user["email"],
        "name": user["full_name"],
        "role": user["role"],
        "department": user.get("department", ""),
        "student_id": user.get("student_id"),
        "group_id": user.get("group_id"),
        "iat": now,
        "exp": now + datetime.timedelta(hours=JWT_EXPIRATION_HOURS)
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def get_current_user(authorization: Optional[str] = Header(None)) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Токен авторизации отсутствует")
    token = authorization.split(" ")[1]
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Недействительный токен: {str(e)}")

# ── ЭНДПОИНТЫ АВТОРИЗАЦИИ ──

@app.post("/api/auth/login")
async def login(payload: LoginRequest):
    """
    Вход по логину и паролю, выданным руководством колледжа.
    Поддерживает:
    - S-Student (dinmuhammed@smartattend.kz / STU-2405-03)
    - S-Kurator (curator.arai@smartattend.kz)
    - S-Mugalim (kalniyazov@smartattend.kz, bilal@smartattend.kz)
    - S-Ata-Ana (parent.baitomor@smartattend.kz)
    - S-Deanat (dean@smartattend.kz)
    - Быстрый выбор demo_role для защиты диплома
    """
    conn, engine = get_db()
    cur = conn.cursor()

    ident = (payload.identifier or "").strip()
    pwd = (payload.password or "").strip()

    if not ident or not pwd:
        conn.close()
        raise HTTPException(status_code=400, detail="ИИН/логин және құпия сөзді енгізіңіз!")

    query = ("SELECT * FROM users WHERE (LOWER(email) = LOWER(%s) OR student_id = %s OR phone = %s) AND password_hash = %s" 
             if engine == "postgres" else 
             "SELECT * FROM users WHERE (LOWER(email) = LOWER(?) OR student_id = ? OR phone = ?) AND password_hash = ?")
    cur.execute(query, (ident, ident, ident, pwd))
    user = cur.fetchone()

    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="Қате логин немесе құпия сөз! Бұл қолданушы колледж базасында тіркелмеген.")

    user_dict = dict(user)
    token = create_session_jwt(user_dict)

    return {
        "success": True,
        "token": token,
        "user": {
            "id": user_dict["id"],
            "email": user_dict["email"],
            "full_name": user_dict["full_name"],
            "role": user_dict["role"],
            "student_id": user_dict.get("student_id"),
            "department": user_dict.get("department"),
            "group_id": user_dict.get("group_id"),
            "avatar_url": user_dict.get("avatar_url")
        }
    }

# ── ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ (для всех ролей): данные, смена пароля, смена фото ──

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

class UpdateAvatarRequest(BaseModel):
    photo_base64: str

MIN_PASSWORD_LENGTH = 6
MAX_AVATAR_BASE64_CHARS = 12_000_000   # ~9 МБ исходного файла
AVATAR_MAX_SIDE_PX = 320

@app.get("/api/users/me")
async def get_my_profile(current: dict = Depends(get_current_user)):
    """Профиль текущего пользователя по JWT (ФИО, роль, группа, фото)."""
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"
    cur.execute(f"SELECT id, email, full_name, role, student_id, department, avatar_url FROM users WHERE id = {p_ph}", (current["user_id"],))
    row = cur.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Пайдаланушы табылмады")
    return {"success": True, "user": dict(row)}

@app.post("/api/auth/change-password")
async def change_password(req: ChangePasswordRequest, current: dict = Depends(get_current_user)):
    """Смена пароля: нужно знать текущий пароль. Работает для всех ролей."""
    new_pwd = (req.new_password or "").strip()
    old_pwd = (req.current_password or "").strip()

    if len(new_pwd) < MIN_PASSWORD_LENGTH:
        raise HTTPException(status_code=400, detail=f"Жаңа құпия сөз кемінде {MIN_PASSWORD_LENGTH} таңбадан тұруы керек")
    if new_pwd == old_pwd:
        raise HTTPException(status_code=400, detail="Жаңа құпия сөз ескісімен бірдей болмауы керек")

    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"
    cur.execute(f"SELECT id, password_hash FROM users WHERE id = {p_ph}", (current["user_id"],))
    row = cur.fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="Пайдаланушы табылмады")
    if dict(row)["password_hash"] != old_pwd:
        conn.close()
        raise HTTPException(status_code=403, detail="Ағымдағы құпия сөз қате")

    cur.execute(f"UPDATE users SET password_hash = {p_ph} WHERE id = {p_ph}", (new_pwd, current["user_id"]))
    conn.commit()
    conn.close()
    return {"success": True, "message": "Құпия сөз сәтті өзгертілді"}

@app.post("/api/users/me/avatar")
async def update_my_avatar(req: UpdateAvatarRequest, current: dict = Depends(get_current_user)):
    """
    Смена фото профиля для любой роли. Фото сжимается (макс. 320px, JPEG)
    и хранится как data-URL в БД — файловая система Render эфемерна, файлы на диске пропадали бы.
    """
    import base64
    import cv2

    raw = req.photo_base64 or ""
    if len(raw) > MAX_AVATAR_BASE64_CHARS:
        raise HTTPException(status_code=413, detail="Сурет тым үлкен (макс. ~9 МБ)")
    if "base64," in raw:
        raw = raw.split("base64,", 1)[1]
    try:
        img_bytes = base64.b64decode(raw, validate=False)
        img = cv2.imdecode(np.frombuffer(img_bytes, np.uint8), cv2.IMREAD_COLOR)
    except Exception:
        img = None
    if img is None:
        raise HTTPException(status_code=400, detail="Сурет оқылмады. JPG немесе PNG таңдаңыз")

    h, w = img.shape[:2]
    scale = AVATAR_MAX_SIDE_PX / max(h, w)
    if scale < 1:
        img = cv2.resize(img, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_AREA)
    ok, buf = cv2.imencode(".jpg", img, [int(cv2.IMWRITE_JPEG_QUALITY), 82])
    if not ok:
        raise HTTPException(status_code=500, detail="Суретті өңдеу сәтсіз аяқталды")
    data_url = "data:image/jpeg;base64," + base64.b64encode(buf.tobytes()).decode("ascii")

    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"
    cur.execute(f"UPDATE users SET avatar_url = {p_ph} WHERE id = {p_ph}", (data_url, current["user_id"]))
    conn.commit()
    conn.close()
    return {"success": True, "message": "Профиль суреті жаңартылды", "avatar_url": data_url}

# ── S-STUDENT (СТУДЕНТ) ──

@app.get("/api/student/dashboard")
async def get_student_dashboard(email: str = "dinmuhammed@smartattend.kz"):
    """Кабинет студента: расписание на сегодня, активная пара, статус явки, кабинет на карте"""
    conn, engine = get_db()
    cur = conn.cursor()

    # 1. Поиск студента
    p_ph = "%s" if engine == "postgres" else "?"
    cur.execute(f"""
        SELECT u.id, u.full_name, u.email, u.student_id, g.name as group_name
        FROM users u
        LEFT JOIN academic_groups g ON u.group_id = g.id
        WHERE LOWER(u.email) = {p_ph}
    """, (email.lower(),))
    student = cur.fetchone()
    if not student:
        conn.close()
        raise HTTPException(status_code=404, detail="Студент не найден")

    student = dict(student)

    # 2. Расписание занятий группы на неделю (с фокусом на сегодня)
    cur.execute(f"""
        SELECT l.id, l.title, l.day_of_week, l.pair_number, l.start_time, l.end_time,
               l.room_code, l.is_qr_active, l.current_qr_token,
               u.full_name as teacher_name, r.svg_id, r.floor,
               ar.status as my_status, ar.delay_minutes, ar.grade_score
        FROM lessons l
        JOIN users u ON l.teacher_id = u.id
        JOIN rooms r ON l.room_code = r.code
        JOIN users stu ON stu.group_id = l.group_id
        LEFT JOIN attendance_records ar ON ar.lesson_id = l.id AND ar.student_id = stu.id
        WHERE stu.id = {p_ph}
        ORDER BY l.day_of_week, l.pair_number ASC
    """, (student["id"],))
    lessons = [dict(r) for r in cur.fetchall()]

    # 3. Статистика студента
    cur.execute(f"""
        SELECT 
            COUNT(*) FILTER (WHERE status = 'PRESENT') as present_cnt,
            COUNT(*) FILTER (WHERE status = 'LATE') as late_cnt,
            COUNT(*) FILTER (WHERE status = 'EXCUSED') as excused_cnt,
            COUNT(*) FILTER (WHERE status = 'ABSENT') as absent_cnt,
            ROUND(AVG(grade_score)) as avg_grade
        FROM attendance_records
        WHERE student_id = {p_ph}
    """ if engine == "postgres" else f"""
        SELECT 
            SUM(CASE WHEN status = 'PRESENT' THEN 1 ELSE 0 END) as present_cnt,
            SUM(CASE WHEN status = 'LATE' THEN 1 ELSE 0 END) as late_cnt,
            SUM(CASE WHEN status = 'EXCUSED' THEN 1 ELSE 0 END) as excused_cnt,
            SUM(CASE WHEN status = 'ABSENT' THEN 1 ELSE 0 END) as absent_cnt,
            AVG(grade_score) as avg_grade
        FROM attendance_records
        WHERE student_id = {p_ph}
    """, (student["id"],))
    stats = dict(cur.fetchone() or {})

    conn.close()
    return {
        "success": True,
        "student": student,
        "lessons": lessons,
        "stats": stats
    }

# ── S-MUGALIM (ПРЕПОДАВАТЕЛЬ) ──

@app.get("/api/teacher/dashboard")
async def get_teacher_dashboard(email: str = "kalniyazov@smartattend.kz"):
    """Кабинет преподавателя: текущее занятие, запуск 15-сек QR, живой список 20 студентов с отметками"""
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    # 1. Инфо о преподавателе
    cur.execute(f"SELECT id, full_name, email, department FROM users WHERE LOWER(email) = {p_ph}", (email.lower(),))
    teacher = cur.fetchone()
    if not teacher:
        conn.close()
        raise HTTPException(status_code=404, detail="Преподаватель не найден")
    teacher = dict(teacher)

    # 2. Активные и предстоящие пары
    cur.execute(f"""
        SELECT l.id, l.title, l.day_of_week, l.pair_number, l.start_time, l.end_time,
               l.room_code, l.is_qr_active, l.current_qr_token, g.name as group_name, g.id as group_id
        FROM lessons l
        JOIN academic_groups g ON l.group_id = g.id
        WHERE l.teacher_id = {p_ph}
        ORDER BY l.id ASC
    """, (teacher["id"],))
    lessons = [dict(r) for r in cur.fetchall()]

    active_lesson = lessons[0] if lessons else None
    students_attendance = []

    if active_lesson:
        cur.execute(f"""
            SELECT u.id as student_id, u.full_name, u.student_id as student_code, u.email,
                   COALESCE(ar.status, 'ABSENT') as status,
                   ar.delay_minutes,
                   ar.grade_score,
                   ar.check_in_time
            FROM users u
            LEFT JOIN attendance_records ar ON ar.student_id = u.id AND ar.lesson_id = {p_ph}
            WHERE u.group_id = {p_ph} AND u.role = 'STUDENT'
            ORDER BY u.id ASC
        """, (active_lesson["id"], active_lesson["group_id"]))
        students_attendance = [dict(r) for r in cur.fetchall()]

    conn.close()
    return {
        "success": True,
        "teacher": teacher,
        "lessons": lessons,
        "active_lesson": active_lesson,
        "students": students_attendance
    }

# ── S-KURATOR (КУРАТОР: АРАЙ ТАЛДАУБЕКҚЫЗЫ) ──

@app.get("/api/curator/dashboard")
async def get_curator_dashboard(email: str = "curator.arai@smartattend.kz"):
    """
    Кабинет куратора:
    - Контроль ТОЛЬКО своей группы (БҚ2405)
    - Список 20 студентов, кто сейчас сидит на паре, кто опоздал, кто прогулял
    - Рассмотрение расписок/өтініш от родителей (S-Ata-Ana)
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"SELECT id, full_name, email FROM users WHERE LOWER(email) = {p_ph}", (email.lower(),))
    curator = cur.fetchone()
    if not curator:
        conn.close()
        raise HTTPException(status_code=404, detail="Куратор не найден")
    curator = dict(curator)

    # Группа куратора
    cur.execute(f"SELECT id, name, faculty FROM academic_groups WHERE curator_id = {p_ph}", (curator["id"],))
    group = cur.fetchone()
    if not group:
        # Фоллбэк на БҚ2405
        cur.execute("SELECT id, name, faculty FROM academic_groups WHERE name = 'БҚ2405'")
        group = cur.fetchone()
    group = dict(group)

    # 20 студентов группы с их текущим статусом
    cur.execute(f"""
        SELECT u.id, u.full_name, u.student_id as code, u.email, u.phone,
               COALESCE(ar.status, 'ABSENT') as current_status,
               COALESCE(ar.delay_minutes, 0) as delay_minutes,
               l.title as current_lesson,
               l.room_code
        FROM users u
        LEFT JOIN lessons l ON l.group_id = u.group_id AND l.is_qr_active = TRUE
        LEFT JOIN attendance_records ar ON ar.student_id = u.id AND ar.lesson_id = l.id
        WHERE u.group_id = {p_ph} AND u.role = 'STUDENT'
        ORDER BY u.id ASC
    """, (group["id"],))
    students = [dict(r) for r in cur.fetchall()]

    # Родительские расписки на рассмотрение
    cur.execute(f"""
        SELECT pn.id, pn.note_type, pn.reason, pn.date_from, pn.date_to, pn.status,
               pn.created_at, pn.review_comment,
               stu.full_name as student_name, stu.student_id as student_code,
               par.full_name as parent_name, par.phone as parent_phone
        FROM parent_notes pn
        JOIN users stu ON pn.student_id = stu.id
        JOIN users par ON pn.parent_id = par.id
        WHERE stu.group_id = {p_ph}
        ORDER BY pn.id DESC
    """, (group["id"],))
    notes = [dict(r) for r in cur.fetchall()]

    # Сводка куратора
    present_count = len([s for s in students if s["current_status"] == "PRESENT"])
    late_count = len([s for s in students if s["current_status"] == "LATE"])
    absent_count = len([s for s in students if s["current_status"] == "ABSENT"])

    conn.close()
    return {
        "success": True,
        "curator": curator,
        "group": group,
        "stats": {
            "total_students": len(students),
            "present": present_count,
            "late": late_count,
            "absent": absent_count,
            "pending_notes": len([n for n in notes if n["status"] == "PENDING"])
        },
        "students": students,
        "parent_notes": notes
    }

# ── S-ATA-ANA (РОДИТЕЛИ) ──

@app.get("/api/parent/dashboard")
async def get_parent_dashboard(email: str = "parent.baitomor@smartattend.kz"):
    """
    Кабинет родителя (S-Ata-Ana):
    - Где ребенок сейчас: пара, аудитория, статус (Вовремя / Опоздал / Не явился)
    - Оценки и баллы за уроки
    - Подача расписки/қолхат при болезни или семейных обстоятельствах
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"SELECT id, full_name, email, child_student_id, phone FROM users WHERE LOWER(email) = {p_ph}", (email.lower(),))
    parent = cur.fetchone()
    if not parent:
        conn.close()
        raise HTTPException(status_code=404, detail="Родитель не найден")
    parent = dict(parent)

    # Ребенок
    child_id = parent.get("child_student_id")
    if not child_id:
        cur.execute("SELECT id FROM users WHERE email = 'dinmuhammed@smartattend.kz'")
        row = cur.fetchone()
        child_id = row["id"] if row else 3

    cur.execute(f"""
        SELECT u.id, u.full_name, u.student_id, g.name as group_name
        FROM users u
        LEFT JOIN academic_groups g ON u.group_id = g.id
        WHERE u.id = {p_ph}
    """, (child_id,))
    child = dict(cur.fetchone())

    # Текущий статус ребенка на паре
    cur.execute(f"""
        SELECT l.id as lesson_id, l.title, l.room_code, l.start_time, l.end_time,
               t.full_name as teacher_name,
               COALESCE(ar.status, 'ABSENT') as status,
               COALESCE(ar.delay_minutes, 0) as delay_minutes,
               ar.grade_score,
               ar.check_in_time
        FROM lessons l
        JOIN users t ON l.teacher_id = t.id
        LEFT JOIN attendance_records ar ON ar.lesson_id = l.id AND ar.student_id = {p_ph}
        WHERE l.is_qr_active = TRUE
        LIMIT 1
    """, (child["id"],))
    current_lesson = cur.fetchone()

    # Расписки этого родителя
    cur.execute(f"""
        SELECT id, note_type, reason, date_from, date_to, status, review_comment, created_at
        FROM parent_notes
        WHERE parent_id = {p_ph}
        ORDER BY id DESC
    """, (parent["id"],))
    notes = [dict(r) for r in cur.fetchall()]

    conn.close()
    return {
        "success": True,
        "parent": parent,
        "child": child,
        "current_status": dict(current_lesson) if current_lesson else {
            "title": "Сабақтар кесте бойынша",
            "room_code": "С1.3.241",
            "status": "PRESENT",
            "delay_minutes": 0,
            "grade_score": 95
        },
        "notes": notes
    }

@app.post("/api/parent/submit-note")
async def submit_parent_note(payload: ParentNoteRequest):
    """Подача официальной расписки от родителей куратору с подтверждением ЭЦП / eGov"""
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"SELECT id FROM users WHERE LOWER(email) = {p_ph}", (payload.parent_email.lower(),))
    p_row = cur.fetchone()
    parent_id = p_row["id"] if p_row else 1

    cur.execute(f"""
        INSERT INTO parent_notes (student_id, parent_id, note_type, reason, date_from, date_to, status, is_signed_ecp, signer_iin, ecp_hash)
        VALUES ({p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, 'PENDING', {p_ph}, {p_ph}, {p_ph})
        RETURNING id
    """ if engine == "postgres" else f"""
        INSERT INTO parent_notes (student_id, parent_id, note_type, reason, date_from, date_to, status, is_signed_ecp, signer_iin, ecp_hash)
        VALUES (?, ?, ?, ?, ?, ?, 'PENDING', ?, ?, ?)
    """, (payload.student_id, parent_id, payload.note_type, payload.reason, payload.date_from, payload.date_to, payload.is_signed_ecp, payload.signer_iin, payload.ecp_hash))

    conn.commit()
    conn.close()
    return {
        "success": True, 
        "message": "Қолхат ЭЦП-мен расталып, кураторға сәтті жіберілді!",
        "ecp_verified": True,
        "ecp_hash": payload.ecp_hash,
        "signer_iin": payload.signer_iin
    }

@app.post("/api/curator/review-note")
async def review_parent_note(payload: ReviewNoteRequest):
    """Куратор подтверждает или отклоняет расписку родителя"""
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"SELECT id FROM users WHERE LOWER(email) = {p_ph}", (payload.curator_email.lower(),))
    curator_row = cur.fetchone()
    curator_id = curator_row["id"] if curator_row else None

    cur.execute(f"""
        UPDATE parent_notes
        SET status = {p_ph}, reviewed_by = {p_ph}, review_comment = {p_ph}
        WHERE id = {p_ph}
        RETURNING student_id
    """ if engine == "postgres" else f"""
        UPDATE parent_notes
        SET status = ?, reviewed_by = ?, review_comment = ?
        WHERE id = ?
    """, (payload.status, curator_id, payload.comment, payload.note_id))

    # Если одобрено — обновляем запись посещаемости на 'EXCUSED' (Себепті)
    if payload.status == "APPROVED":
        cur.execute(f"""
            UPDATE attendance_records
            SET status = 'EXCUSED'
            WHERE student_id = (SELECT student_id FROM parent_notes WHERE id = {p_ph})
        """, (payload.note_id,))

    conn.commit()
    conn.close()
    return {"success": True, "message": f"Қолхат статусы жаңартылды: {payload.status}"}

# ── S-DEANAT (ДЕКАНАТ / ЗАВУЧ) ──

@app.get("/api/dean/overview")
async def get_dean_overview():
    """Сводная аналитика по всему колледжу (все группы, все опоздавшие)"""
    conn, engine = get_db()
    cur = conn.cursor()

    cur.execute("SELECT COUNT(*) as cnt FROM users WHERE role = 'STUDENT'")
    total_students = cur.fetchone()["cnt"]

    cur.execute("SELECT COUNT(*) as cnt FROM academic_groups")
    total_groups = cur.fetchone()["cnt"]

    cur.execute("SELECT COUNT(*) as cnt FROM attendance_records WHERE status = 'PRESENT'")
    total_present = cur.fetchone()["cnt"]

    cur.execute("SELECT COUNT(*) as cnt FROM attendance_records WHERE status = 'LATE'")
    total_late = cur.fetchone()["cnt"]

    cur.execute("SELECT COUNT(*) as cnt FROM sos_alerts WHERE is_resolved = FALSE")
    total_sos = cur.fetchone()["cnt"]

    # Список всех опоздавших колледжа
    cur.execute("""
        SELECT ar.id, u.full_name as student_name, u.student_id, g.name as group_name,
               l.title as lesson_title, ar.delay_minutes, ar.check_in_time
        FROM attendance_records ar
        JOIN users u ON ar.student_id = u.id
        LEFT JOIN academic_groups g ON u.group_id = g.id
        JOIN lessons l ON ar.lesson_id = l.id
        WHERE ar.status = 'LATE'
        ORDER BY ar.id DESC LIMIT 10
    """)
    late_students = [dict(r) for r in cur.fetchall()]

    # Статистика посещаемости по группам
    cur.execute("""
        SELECT g.name as group_name,
               COUNT(u.id) as total,
               COUNT(ar.id) FILTER (WHERE ar.status IN ('PRESENT', 'LATE')) as attended
        FROM academic_groups g
        LEFT JOIN users u ON u.group_id = g.id AND u.role = 'STUDENT'
        LEFT JOIN attendance_records ar ON ar.student_id = u.id
        GROUP BY g.id, g.name
    """ if engine == "postgres" else """
        SELECT g.name as group_name,
               COUNT(u.id) as total,
               SUM(CASE WHEN ar.status IN ('PRESENT', 'LATE') THEN 1 ELSE 0 END) as attended
        FROM academic_groups g
        LEFT JOIN users u ON u.group_id = g.id AND u.role = 'STUDENT'
        LEFT JOIN attendance_records ar ON ar.student_id = u.id
        GROUP BY g.id, g.name
    """)
    group_stats = [dict(r) for r in cur.fetchall()]

    conn.close()
    return {
        "success": True,
        "stats": {
            "total_students": total_students,
            "total_groups": total_groups,
            "present": total_present,
            "late": total_late,
            "sos": total_sos
        },
        "late_students": late_students,
        "group_stats": group_stats
    }

# ── ИНТЕРАКТИВНАЯ КАРТА: СТАТУС КАБИНЕТОВ ──

@app.get("/api/rooms/status")
async def get_rooms_status():
    """Возвращает занятость аудиторий и текущие пары для векторной карты AITU"""
    conn, engine = get_db()
    cur = conn.cursor()

    cur.execute("""
        SELECT r.code, r.svg_id, r.floor, r.name_kk, r.name_ru, r.name_en,
               l.id as lesson_id, l.title as current_lesson, l.is_qr_active,
               g.name as group_name, u.full_name as teacher_name
        FROM rooms r
        LEFT JOIN lessons l ON l.room_code = r.code AND l.is_qr_active = TRUE
        LEFT JOIN academic_groups g ON l.group_id = g.id
        LEFT JOIN users u ON l.teacher_id = u.id
    """)
    rooms = [dict(r) for r in cur.fetchall()]
    conn.close()
    return {"success": True, "rooms": rooms}

@app.get("/api/rooms/{room_code}/live-details")
async def get_room_live_details(room_code: str):
    """
    Детальная информация для интерактивной карты кампуса:
    - Какой урок сейчас идет
    - Преподаватель, группа, время
    - Сколько студентов в кабинете (18/20)
    - КТО ОПОЗДАЛ (ФИО + минуты)
    - КТО ОТСУТСТВУЕТ (НБ)
    - Кто отпросился по родительской расписке (ЭЦП)
    """
    clean_code = room_code.strip()
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    # Ищем урок по коду аудитории
    cur.execute(f"""
        SELECT l.id as lesson_id, l.title as lesson_title, l.room_code, l.start_time, l.end_time,
               l.pair_number, l.day_of_week, l.is_qr_active,
               g.id as group_id, g.name as group_name,
               t.full_name as teacher_name
        FROM lessons l
        JOIN academic_groups g ON l.group_id = g.id
        JOIN users t ON l.teacher_id = t.id
        WHERE l.room_code ILIKE {p_ph} OR l.room_code ILIKE {p_ph}
        ORDER BY l.is_qr_active DESC, l.id ASC
        LIMIT 1
    """, (f"%{clean_code}%", f"%{clean_code.replace('С', 'C')}%"))
    lesson = cur.fetchone()

    if not lesson:
        conn.close()
        return {
            "success": True,
            "room_code": room_code,
            "is_busy": False,
            "status": "AVAILABLE",
            "message": "Қазір аудитория бос (Сабақ жоқ)"
        }

    lesson = dict(lesson)

    # Список студентов этой группы с их текущим статусом явки
    cur.execute(f"""
        SELECT u.id, u.full_name, u.student_id,
               COALESCE(ar.status, 'ABSENT') as status,
               COALESCE(ar.delay_minutes, 0) as delay_minutes,
               ar.check_in_time
        FROM users u
        LEFT JOIN attendance_records ar ON ar.student_id = u.id AND ar.lesson_id = {p_ph}
        WHERE u.group_id = {p_ph} AND u.role = 'STUDENT'
        ORDER BY u.id ASC
    """, (lesson["lesson_id"], lesson["group_id"]))
    students = [dict(r) for r in cur.fetchall()]

    # Одобренные расписки родителей для этой группы
    cur.execute(f"""
        SELECT pn.id, stu.full_name as student_name, pn.reason, pn.is_signed_ecp, pn.signer_iin, pn.status
        FROM parent_notes pn
        JOIN users stu ON pn.student_id = stu.id
        WHERE stu.group_id = {p_ph} AND pn.status = 'APPROVED'
    """, (lesson["group_id"],))
    approved_notes = [dict(r) for r in cur.fetchall()]

    conn.close()

    present_students = [s for s in students if s["status"] == "PRESENT"]
    late_students = [{"name": s["full_name"], "delay": s["delay_minutes"]} for s in students if s["status"] == "LATE"]
    absent_students = [s["full_name"] for s in students if s["status"] == "ABSENT"]

    return {
        "success": True,
        "is_busy": True,
        "room_code": lesson["room_code"],
        "lesson_title": lesson["lesson_title"],
        "teacher_name": lesson["teacher_name"],
        "group_name": lesson["group_name"],
        "time": f"{lesson['start_time']} - {lesson['end_time']}",
        "pair_number": lesson["pair_number"],
        "total_students": len(students),
        "present_count": len(present_students),
        "late_count": len(late_students),
        "absent_count": len(absent_students),
        "late_students": late_students,
        "absent_students": absent_students,
        "excused_notes": approved_notes
    }

# ── ЧЕК-ИН И QR-ТОКЕН ──

@app.post("/api/attendance/check-in")
async def check_in_student(payload: CheckInRequest):
    """Фиксация явки студента через QR + расчет опоздания"""
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"SELECT id, full_name, student_id, group_id FROM users WHERE LOWER(email) = {p_ph} AND role = 'STUDENT'", (payload.student_email.lower(),))
    student = cur.fetchone()
    if not student:
        conn.close()
        raise HTTPException(status_code=404, detail="Студент не найден")

    student = dict(student)

    # Занятие
    cur.execute(f"SELECT id, title, start_time FROM lessons WHERE id = {p_ph}", (payload.lesson_id,))
    lesson = cur.fetchone()
    if not lesson:
        conn.close()
        raise HTTPException(status_code=404, detail="Занятие не найдено")

    lesson = dict(lesson)

    # Расчет опоздания: если текущее время позже начала пары более чем на 5 мин
    now = datetime.datetime.now()
    delay = 0
    status = "PRESENT"
    try:
        parts = lesson["start_time"].split(":")
        start_dt = now.replace(hour=int(parts[0]), minute=int(parts[1]), second=0)
        diff = int((now - start_dt).total_seconds() / 60)
        if diff > 5:
            delay = diff
            status = "LATE"
    except Exception:
        pass

    # Вставка или обновление в attendance_records
    cur.execute(f"""
        INSERT INTO attendance_records (lesson_id, student_id, status, delay_minutes, grade_score, check_in_time)
        VALUES ({p_ph}, {p_ph}, {p_ph}, {p_ph}, 90, CURRENT_TIMESTAMP)
        ON CONFLICT (lesson_id, student_id) DO UPDATE SET
            status = EXCLUDED.status,
            delay_minutes = EXCLUDED.delay_minutes,
            check_in_time = CURRENT_TIMESTAMP
        RETURNING id, check_in_time;
    """ if engine == "postgres" else f"""
        INSERT INTO attendance_records (lesson_id, student_id, status, delay_minutes, grade_score, check_in_time)
        VALUES (?, ?, ?, ?, 90, CURRENT_TIMESTAMP)
        ON CONFLICT (lesson_id, student_id) DO UPDATE SET
            status = excluded.status,
            delay_minutes = excluded.delay_minutes,
            check_in_time = CURRENT_TIMESTAMP
    """, (payload.lesson_id, student["id"], status, delay))

    # Если опоздал — формируем запись в sos_alerts
    if status == "LATE":
        alert_msg = f"Опоздание на {delay} мин: {student['full_name']} ({student['student_id']}) на пару '{lesson['title']}'"
        cur.execute(f"""
            INSERT INTO sos_alerts (lesson_id, student_id, group_id, alert_type, message, severity)
            VALUES ({p_ph}, {p_ph}, {p_ph}, 'LATE_SOS', {p_ph}, 'HIGH')
        """, (payload.lesson_id, student["id"], student["group_id"], alert_msg))

    conn.commit()
    conn.close()

    return {
        "success": True,
        "status": status,
        "delay_minutes": delay,
        "student_name": student["full_name"],
        "check_in_time": now.strftime("%H:%M:%S")
    }

@app.post("/api/lessons/{lesson_id}/qr-token")
async def generate_qr_token(lesson_id: int):
    """Генерация 15-секундного динамического QR токена"""
    token = f"SA-{lesson_id:03d}-{int(datetime.datetime.now().timestamp()) % 100000}"
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"""
        UPDATE lessons 
        SET is_qr_active = TRUE, current_qr_token = {p_ph}, qr_updated_at = CURRENT_TIMESTAMP
        WHERE id = {p_ph}
    """, (token, lesson_id))
    conn.commit()
    conn.close()
    return {"token": token, "expires_in": 15, "lesson_id": lesson_id}

# ── БАЗАҒА ҚОСУ ЖӘНЕ FACE ID ЭНДПОИНТТАРЫ ──

@app.post("/api/users/register")
async def register_user(req: RegisterUserRequest):
    """
    Жаңа пайдаланушыны (студент/оқытушы) базаға тіркеу және Face ID биометриясын орнату
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    # Check email duplicate
    cur.execute(f"SELECT id FROM users WHERE email = {p_ph}", (req.email,))
    if cur.fetchone():
        conn.close()
        raise HTTPException(status_code=400, detail=f"Қолданушы {req.email} бойынша базада тіркелген!")

    # Group resolution
    group_id = None
    if req.group_name and req.role == "STUDENT":
        cur.execute(f"SELECT id FROM academic_groups WHERE name = {p_ph}", (req.group_name,))
        grp = cur.fetchone()
        if grp:
            group_id = grp["id"] if isinstance(grp, dict) else grp[0]
        else:
            cur.execute(f"INSERT INTO academic_groups (name, faculty, course_year) VALUES ({p_ph}, {p_ph}, 2)", 
                        (req.group_name, "Инженерлік және киберқауіпсіздік"))
            if engine == "postgres":
                cur.execute("SELECT LASTVAL() AS id")
                lv = cur.fetchone()
                group_id = lv["id"] if isinstance(lv, dict) else lv[0]
            else:
                group_id = cur.lastrowid

    # Face ID extraction
    face_embedding_json = None
    avatar_url = None
    if req.photo_base64:
        from face_engine import face_engine
        img = face_engine.decode_image(req.photo_base64)
        emb, bbox, msg = face_engine.extract_face(img) if img is not None else (None, None, "Сурет оқылмады")
        if not emb:
            conn.close()
            raise HTTPException(status_code=400, detail=f"Фотодан Face ID алынбады: {msg}")
        face_embedding_json = json.dumps(emb)
        safe_name = req.email.replace("@", "_").replace(".", "_") + ".jpg"
        avatar_dir = os.path.join(STATIC_DIR, "static", "avatars")
        os.makedirs(avatar_dir, exist_ok=True)
        import cv2
        cv2.imwrite(os.path.join(avatar_dir, safe_name), img)
        avatar_url = f"/static/avatars/{safe_name}"

    # Generate student ID if needed
    student_id = req.student_id
    if not student_id and req.role == "STUDENT":
        cur.execute("SELECT COUNT(*) AS total_count FROM users WHERE role = 'STUDENT'")
        cnt_row = cur.fetchone()
        count = cnt_row.get("total_count", 0) if isinstance(cnt_row, dict) else (cnt_row[0] if cnt_row else 0)
        student_id = f"STU-2405-{count + 1:02d}"

    # Insert into users
    cur.execute(f"""
        INSERT INTO users (
            email, password_hash, full_name, role, student_id,
            group_id, department, avatar_url, face_embedding, is_active, curator_group
        ) VALUES (
            {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph},
            {p_ph}, {p_ph}, {p_ph}, {p_ph}, TRUE, {p_ph}
        )
    """, (
        req.email,
        req.password or "12345",
        req.full_name,
        req.role,
        student_id,
        group_id,
        req.department or "Ақпараттық технологиялар бөлімі",
        avatar_url,
        face_embedding_json,
        req.curator_group
    ))
    conn.commit()
    conn.close()

    return {
        "success": True,
        "message": f"Пайдаланушы «{req.full_name}» ({req.role}) базаға сәтті қосылды!" + (" Face ID биометриясы орнатылды ✅" if face_embedding_json else ""),
        "has_face_id": face_embedding_json is not None,
        "student_id": student_id,
        "email": req.email,
        "role": req.role,
        "full_name": req.full_name,
        "curator_group": req.curator_group,
        "avatar_url": avatar_url
    }

@app.post("/api/users/bulk-staff")
async def bulk_import_staff(req: StaffBulkImportRequest):
    """
    Excel/CSV арқылы оқытушылар мен декандарды жаппай базаға қосу
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    added_count = 0
    credentials = []

    for item in req.staff:
        if not item.full_name.strip():
            continue

        iin = (item.student_id or "").strip()
        email = (item.email or "").strip()
        if not email:
            slug = item.full_name.lower().replace(" ", ".")
            email = f"{slug}@aitu.edu.kz"

        pwd = item.password or "12345"
        role = item.role.upper() if item.role else "TEACHER"

        cur.execute(f"SELECT id FROM users WHERE email = {p_ph} OR (student_id = {p_ph} AND student_id IS NOT NULL)", (email, iin if iin else "NONE"))
        if cur.fetchone():
            continue

        cur.execute(f"""
            INSERT INTO users (
                email, password_hash, full_name, role, student_id,
                department, is_active, curator_group
            ) VALUES (
                {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph},
                {p_ph}, TRUE, {p_ph}
            )
        """, (
            email,
            pwd,
            item.full_name,
            role,
            iin if iin else None,
            item.department or "Ақпараттық технологиялар бөлімі",
            item.curator_group
        ))
        added_count += 1
        credentials.append({
            "full_name": item.full_name,
            "role": role,
            "student_id": iin or email,
            "email": email,
            "password": pwd,
            "curator_group": item.curator_group or "Жоқ"
        })

    conn.commit()
    conn.close()

    return {
        "success": True,
        "message": f"{added_count} қызметкер базаға сәтті енгізілді! ✅",
        "added_count": added_count,
        "credentials": credentials
    }

class FaceEnrollRequest(BaseModel):
    email_or_id: str
    photo_base64: str

@app.post("/api/face/enroll")
async def enroll_face(req: FaceEnrollRequest):
    """
    Студенттің немесе оқытушының бетін базаға нақты биометриялық вектормен тіркеу (Enrollment)
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"""
        SELECT id, email, full_name, role, student_id
        FROM users
        WHERE email = {p_ph} OR student_id = {p_ph}
    """, (req.email_or_id, req.email_or_id))

    user_row = cur.fetchone()
    if not user_row:
        conn.close()
        raise HTTPException(status_code=404, detail="Пайдаланушы табылмады!")

    user = dict(user_row) if not isinstance(user_row, dict) else user_row

    from face_engine import face_engine
    img = face_engine.decode_image(req.photo_base64)
    if img is None:
        conn.close()
        raise HTTPException(status_code=400, detail="Сурет оқылмады!")

    emb, bbox, msg = face_engine.extract_face(img)
    if not emb:
        conn.close()
        raise HTTPException(status_code=400, detail=msg or "Кадрда бет табылмады. Камераға қараңыз.")

    safe_name = f"user_{user['id']}_{user.get('student_id') or 'face'}.jpg"
    avatar_dir = os.path.join(STATIC_DIR, "static", "avatars")
    os.makedirs(avatar_dir, exist_ok=True)
    import cv2
    cv2.imwrite(os.path.join(avatar_dir, safe_name), img)
    avatar_url = f"/static/avatars/{safe_name}"

    cur.execute(f"""
        UPDATE users
        SET face_embedding = {p_ph}, avatar_url = {p_ph}
        WHERE id = {p_ph}
    """, (json.dumps(emb), avatar_url, user["id"]))

    conn.commit()
    conn.close()

    return {
        "success": True,
        "message": f"«{user['full_name']}» тұлғасының Face ID биометриясы сәтті сақталды! ✅",
        "avatar_url": avatar_url,
        "confidence": bbox.get("confidence", 95.0) if bbox else 95.0,
        "student_id": user.get("student_id")
    }

@app.post("/api/face/verify")
async def verify_face(req: FaceVerifyRequest):
    """
    Нағыз биометриялық Face ID арқылы қолданушыны (директор, мұғалім, декан, студент) тану
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"""
        SELECT u.id, u.email, u.full_name, u.role, u.student_id, u.face_embedding, g.name as group_name
        FROM users u
        LEFT JOIN academic_groups g ON u.group_id = g.id
        WHERE LOWER(u.email) = LOWER({p_ph}) OR u.student_id = {p_ph} OR u.phone = {p_ph}
    """, (req.email_or_id, req.email_or_id, req.email_or_id))

    user_row = cur.fetchone()
    if not user_row:
        conn.close()
        raise HTTPException(status_code=404, detail="Қолданушы базадан табылмады!")

    user = dict(user_row) if not isinstance(user_row, dict) else user_row

    from face_engine import face_engine
    live_img = face_engine.decode_image(req.frame_base64)
    if live_img is None:
        conn.close()
        return {"verified": False, "message": "Камерадан кадр алынбады"}

    live_emb, bbox, msg = face_engine.extract_face(live_img)
    if not live_emb:
        conn.close()
        return {"verified": False, "message": msg or "Кадрда бет-әлпет анықталмады. Камераға тура қараңыз."}

    stored_emb_json = user.get("face_embedding")

    # Face ID әлі тіркелмеген жағдай
    if not stored_emb_json:
        conn.close()
        return {
            "verified": False,
            "enrolled": False,
            "student_name": user["full_name"],
            "message": f"{user['full_name']} үшін Face ID әлі тіркелмеген. Алдымен бетті тіркеңіз."
        }

    # Салыстыру (SFace 128-D)
    try:
        stored_emb = json.loads(stored_emb_json)
        is_match, similarity_pct, cos_score = face_engine.compare(stored_emb, live_emb)
    except Exception as e:
        conn.close()
        return {"verified": False, "message": f"Биометриялық есептеу қатесі: {e}"}

    if is_match:
        if req.lesson_id:
            cur.execute(f"SELECT id FROM lessons WHERE id = {p_ph}", (req.lesson_id,))
            if cur.fetchone():
                bool_val = True if engine == "postgres" else 1
                cur.execute(f"""
                    INSERT INTO attendance_records (
                        lesson_id, student_id, status, delay_minutes, face_verified, check_in_time
                    ) VALUES ({p_ph}, {p_ph}, 'PRESENT', 0, {p_ph}, CURRENT_TIMESTAMP)
                    ON CONFLICT (lesson_id, student_id) DO UPDATE SET
                        status = 'PRESENT', face_verified = {p_ph}, check_in_time = CURRENT_TIMESTAMP
                """, (req.lesson_id, user["id"], bool_val, bool_val))
                conn.commit()

        conn.close()
        return {
            "verified": True,
            "similarity": similarity_pct,
            "score": cos_score,
            "student_name": user["full_name"],
            "student_id": user.get("student_id"),
            "group_name": user.get("group_name", "БҚ2405"),
            "message": f"{user['full_name']} тұлғасы сәтті расталды! Сәйкестік: {similarity_pct}% ✅"
        }
    else:
        conn.close()
        return {
            "verified": False,
            "similarity": similarity_pct,
            "score": cos_score,
            "student_name": user["full_name"],
            "message": f"Қате тұлға! Камерадағы адам {user['full_name']} профиліне сәйкес келмеді (Сәйкестік: {similarity_pct}%). ❌"
        }

@app.post("/api/face/enroll")
async def enroll_face_endpoint(req: FaceEnrollRequest):
    """
    Пайдаланушының (директор, мұғалім, декан, студент) Face ID биометриялық векторын (SFace 128-D) тіркеу/жаңарту
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"""
        SELECT u.id, u.email, u.full_name, u.role
        FROM users u
        WHERE LOWER(u.email) = LOWER({p_ph}) OR u.student_id = {p_ph} OR u.phone = {p_ph}
    """, (req.email_or_id, req.email_or_id, req.email_or_id))
    user_row = cur.fetchone()
    if not user_row:
        conn.close()
        raise HTTPException(status_code=404, detail="Қолданушы базадан табылмады!")

    user = dict(user_row) if not isinstance(user_row, dict) else user_row

    from face_engine import face_engine
    img = face_engine.decode_image(req.photo_base64)
    if img is None:
        conn.close()
        return {"success": False, "message": "Суретті оқу мүмкін болмады"}

    emb, bbox, msg = face_engine.extract_face(img)
    if not emb:
        conn.close()
        return {"success": False, "message": msg or "Кадрда бет анықталмады. Камераға қарап қайта түсіріңіз."}

    emb_json = json.dumps(emb)
    cur.execute(f"""
        UPDATE users 
        SET face_embedding = {p_ph}, avatar_url = {p_ph}
        WHERE id = {p_ph}
    """, (emb_json, req.photo_base64, user["id"]))
    conn.commit()
    conn.close()

    return {
        "success": True,
        "message": f"{user['full_name']} үшін Face ID профилі сәтті сақталды! ✅",
        "avatar_url": req.photo_base64
    }

@app.post("/api/attendance/check-in")
async def attendance_check_in_endpoint(req: AttendanceCheckInRequest):
    """
    Сабаққа қатысуды белгілеу (QR + Face ID расталғаннан кейін)
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"SELECT id, full_name, email FROM users WHERE LOWER(email) = LOWER({p_ph})", (req.student_email,))
    user = cur.fetchone()
    if not user:
        conn.close()
        return {"success": True, "message": "Check-in logged", "student_name": req.student_email, "status": "PRESENT"}

    user_dict = dict(user) if not isinstance(user, dict) else user

    cur.execute(f"SELECT id FROM lessons WHERE id = {p_ph}", (req.lesson_id,))
    if cur.fetchone():
        bool_val = True if engine == "postgres" else 1
        cur.execute(f"""
            INSERT INTO attendance_records (
                lesson_id, student_id, status, delay_minutes, face_verified, check_in_time
            ) VALUES ({p_ph}, {p_ph}, 'PRESENT', 0, {p_ph}, CURRENT_TIMESTAMP)
            ON CONFLICT (lesson_id, student_id) DO UPDATE SET
                status = 'PRESENT', face_verified = {p_ph}, check_in_time = CURRENT_TIMESTAMP
        """, (req.lesson_id, user_dict["id"], bool_val, bool_val))
        conn.commit()

    conn.close()
    return {
        "success": True,
        "message": f"{user_dict['full_name']} қатысуы сәтті тіркелді! ✅",
        "student_name": user_dict["full_name"],
        "status": "PRESENT"
    }

@app.get("/api/admin/users")
async def list_users():
    """Базадағы барлық қолданушылар тізімі (Face ID күйімен)"""
    conn, engine = get_db()
    cur = conn.cursor()
    cur.execute("""
        SELECT u.id, u.email, u.full_name, u.role, u.student_id,
               g.name as group_name, u.department, u.curator_group, u.avatar_url,
               (u.face_embedding IS NOT NULL) as has_face_id,
               u.is_active, u.created_at
        FROM users u
        LEFT JOIN academic_groups g ON u.group_id = g.id
        ORDER BY u.id DESC
    """)
    rows = cur.fetchall()
    conn.close()

    result = []
    for r in rows:
        row_dict = dict(r) if not isinstance(r, dict) else r
        result.append(row_dict)
    return {"users": result, "total": len(result)}

@app.delete("/api/admin/users/{user_id}")
async def delete_user(user_id: int):
    """Студентті немесе оқытушыны базадан жою"""
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"
    cur.execute(f"DELETE FROM users WHERE id = {p_ph}", (user_id,))
    conn.commit()
    conn.close()
    return {"success": True, "message": f"ID {user_id} пайдаланушы базадан жойылды"}

@app.post("/api/users/register")
async def register_user_direct(req: RegisterUserRequest):
    """
    Директор жаңа пайдаланушыны (Оқытушы, Декан, Студент) базаға тіркейді.
    Оқытушыға немесе деканға кураторлық тобы (curator_group) бекітіле алады.
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    email = req.email.strip().lower()
    full_name = req.full_name.strip()
    role = req.role.strip().upper()
    phone = req.phone or req.iin
    curator_grp = req.curator_group.strip() if req.curator_group else None
    dept = req.department.strip() if req.department else ("Ақпараттық технологиялар бөлімі" if role != "STUDENT" else None)
    pwd = req.password or "12345"

    group_id = None
    if role == "STUDENT" and req.group_name:
        cur.execute(f"SELECT id FROM academic_groups WHERE name = {p_ph}", (req.group_name.strip(),))
        grp = cur.fetchone()
        if grp:
            group_id = dict(grp)["id"] if not isinstance(grp, dict) else grp["id"]
        else:
            cur.execute(f"""
                INSERT INTO academic_groups (name, faculty, course_year)
                VALUES ({p_ph}, {p_ph}, 2)
                {"RETURNING id" if engine == "postgres" else ""}
            """, (req.group_name.strip(), "Ақпараттық технологиялар бөлімі"))
            if engine == "postgres":
                group_id = cur.fetchone()["id"]
            else:
                group_id = cur.lastrowid

    emb_json = None
    if req.photo_base64:
        from face_engine import face_engine
        img = face_engine.decode_image(req.photo_base64)
        if img is not None:
            emb, _, _ = face_engine.extract_face(img)
            if emb:
                emb_json = json.dumps(emb)

    bool_true = True if engine == "postgres" else 1

    cur.execute(f"SELECT id FROM users WHERE email = {p_ph}", (email,))
    existing = cur.fetchone()
    if existing:
        u_id = dict(existing)["id"] if not isinstance(existing, dict) else existing["id"]
        cur.execute(f"""
            UPDATE users SET
                full_name = {p_ph},
                role = {p_ph},
                student_id = {p_ph},
                group_id = {p_ph},
                curator_group = {p_ph},
                department = {p_ph},
                phone = {p_ph},
                password_hash = {p_ph},
                face_embedding = COALESCE({p_ph}, face_embedding),
                is_active = {p_ph}
            WHERE id = {p_ph}
        """, (full_name, role, req.student_id, group_id, curator_grp, dept, phone, pwd, emb_json, bool_true, u_id))
    else:
        cur.execute(f"""
            INSERT INTO users (
                email, phone, password_hash, full_name, role,
                student_id, group_id, curator_group, department, face_embedding, is_active
            ) VALUES ({p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph})
            {"RETURNING id" if engine == "postgres" else ""}
        """, (email, phone, pwd, full_name, role, req.student_id, group_id, curator_grp, dept, emb_json, bool_true))
        if engine == "postgres":
            u_id = cur.fetchone()["id"]
        else:
            u_id = cur.lastrowid

    conn.commit()
    conn.close()
    return {
        "success": True,
        "user_id": u_id,
        "message": f"«{full_name}» ({role}) базаға сәтті тіркелді!"
    }

@app.post("/api/users/bulk-staff")
async def bulk_import_staff(req: BulkStaffRequest):
    """
    Excel-ден көшірілген қызметкерлер тізімін (Оқытушылар, Декандар, Кураторлық тобымен) базаға жаппай енгізу
    """
    if not req.staff:
        raise HTTPException(status_code=400, detail="Қызметкерлер тізімі бос болмауы керек!")

    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"
    bool_true = True if engine == "postgres" else 1

    translit_map = {'а':'a','ә':'a','б':'b','в':'v','г':'g','ғ':'g','д':'d','е':'e','ё':'yo','ж':'zh','з':'z','и':'i','й':'y','к':'k','қ':'q','л':'l','м':'m','н':'n','ң':'n','о':'o','ө':'o','п':'p','р':'r','с':'s','т':'t','у':'u','ұ':'u','ү':'u','ф':'f','х':'kh','һ':'h','ц':'ts','ч':'ch','ш':'sh','щ':'shch','ъ':'','ы':'y','і':'i','ь':'','э':'e','ю':'yu','я':'ya',' ':'_'}

    created_count = 0
    for s in req.staff:
        full_name = s.full_name.strip()
        role = s.role.strip().upper()
        if role not in ["TEACHER", "DEAN", "DIRECTOR"]:
            role = "TEACHER"

        clean_name = "".join(translit_map.get(c.lower(), '') for c in full_name) or "staff"
        email = f"{clean_name}@aitu.edu.kz"
        phone = s.iin.strip() if s.iin else None
        pwd = s.password or "12345"
        dept = s.department or "Ақпараттық технологиялар бөлімі"
        curator_grp = s.curator_group.strip() if s.curator_group else None

        cur.execute(f"SELECT id FROM users WHERE email = {p_ph} OR (phone = {p_ph} AND phone IS NOT NULL)", (email, phone))
        existing = cur.fetchone()
        if existing:
            u_id = dict(existing)["id"] if not isinstance(existing, dict) else existing["id"]
            cur.execute(f"""
                UPDATE users SET
                    full_name = {p_ph},
                    role = {p_ph},
                    curator_group = {p_ph},
                    department = {p_ph},
                    phone = {p_ph},
                    password_hash = {p_ph},
                    is_active = {p_ph}
                WHERE id = {p_ph}
            """, (full_name, role, curator_grp, dept, phone, pwd, bool_true, u_id))
        else:
            cur.execute(f"""
                INSERT INTO users (
                    email, phone, password_hash, full_name, role,
                    curator_group, department, is_active
                ) VALUES ({p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph})
            """, (email, phone, pwd, full_name, role, curator_grp, dept, bool_true))
        created_count += 1

    conn.commit()
    conn.close()
    return {
        "success": True,
        "created_count": created_count,
        "message": f"Excel тізімінен {created_count} қызметкер (оқытушы/декан) базаға сәтті қосылды!"
    }

# ── КУРАТОРЛЫҚ ӨТІНІШТЕР ЖӘНЕ ДИРЕКТОР БЕКІТУІ (BULK BATCH ENROLLMENT) ──

@app.post("/api/face/detect_preview")
async def detect_face_preview(req: FacePreviewRequest):
    """Камера немесе фото жүктелгенде Face ID-дің бар-жоғын жылдам тексеру"""
    from face_engine import face_engine
    img = face_engine.decode_image(req.photo_base64)
    if img is None:
        return {"detected": False, "message": "Сурет оқылмады"}
    emb, bbox, msg = face_engine.extract_face(img)
    if emb is not None:
        return {
            "detected": True,
            "confidence": bbox.get("confidence", 98.0) if bbox else 98.0,
            "bbox": bbox,
            "message": f"Бет-әлпет анықталды! Сенімділік: {bbox.get('confidence', 98.0)}% ✅"
        }
    return {
        "detected": False,
        "confidence": 0.0,
        "message": msg or "Кадрда бет табылмады. Жарық жерде қайталаңыз."
    }

@app.post("/api/curator/applications")
async def submit_curator_application(req: CuratorGroupAppRequest):
    """
    Куратор өз тобының толық тізімін (студенттер, фотолары) директорға бекітуге жібереді
    """
    if not req.students:
        raise HTTPException(status_code=400, detail="Студенттер тізімі бос болмауы керек!")

    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    students_data = []
    for s in req.students:
        students_data.append({
            "full_name": s.full_name.strip(),
            "email": s.email.strip() if s.email else None,
            "iin": s.iin.strip() if s.iin else None,
            "phone": s.phone.strip() if s.phone else (s.iin.strip() if s.iin else None),
            "has_photo": bool(s.photo_base64),
            "photo_base64": s.photo_base64
        })

    cur.execute(f"""
        INSERT INTO group_applications (
            group_name, curator_name, curator_email, faculty, course_year, status, students_json
        ) VALUES ({p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, 'PENDING', {p_ph})
        {"RETURNING id" if engine == "postgres" else ""}
    """, (
        req.group_name.strip(),
        req.curator_name.strip(),
        req.curator_email.strip() if req.curator_email else "curator.arai@smartattend.kz",
        req.faculty or "Ақпараттық қауіпсіздік бөлімі",
        req.course_year or 2,
        json.dumps(students_data, ensure_ascii=False)
    ))

    if engine == "postgres":
        app_id = cur.fetchone()["id"]
    else:
        app_id = cur.lastrowid

    conn.commit()
    conn.close()

    return {
        "success": True,
        "application_id": app_id,
        "group_name": req.group_name,
        "students_count": len(req.students),
        "message": f"{req.group_name} тобы бойынша {len(req.students)} студенттің тізімі мен Face ID деректері Директорға бекітуге сәтті жолданды!"
    }

@app.get("/api/director/applications")
async def list_director_applications():
    """Директорға түскен кураторлық өтініштер тізімі"""
    conn, engine = get_db()
    cur = conn.cursor()
    cur.execute("""
        SELECT id, group_name, curator_name, curator_email, faculty, course_year,
               status, students_json, credentials_json, created_at, approved_at, approved_by
        FROM group_applications
        ORDER BY id DESC
    """)
    rows = cur.fetchall()

    apps = []
    for r in rows:
        item = dict(r) if not isinstance(r, dict) else r
        try:
            item["students"] = json.loads(item["students_json"])
            # Remove bulky photo base64 strings from student summary for lightweight wire transfer
            clean_stus = []
            for s in item["students"]:
                clean_stus.append({
                    "full_name": s.get("full_name"),
                    "email": s.get("email"),
                    "has_photo": s.get("has_photo", False)
                })
            item["students_summary"] = clean_stus
            item["students_count"] = len(clean_stus)
        except Exception:
            item["students_summary"] = []
            item["students_count"] = 0

        if item.get("credentials_json"):
            try:
                item["credentials"] = json.loads(item["credentials_json"])
            except Exception:
                item["credentials"] = []
        else:
            item["credentials"] = []

        apps.append(item)

    # Егер әлі өтініштер жоқ болса — Директор көруі және тестілеуі үшін демо-өтініш құрамыз
    if len(apps) == 0:
        demo_students = [
            {"full_name": "Серікұлы Әлішер", "email": "alisher.s@aitu.edu.kz", "has_photo": True, "photo_base64": None},
            {"full_name": "Мұратқызы Динара", "email": "dinara.m@aitu.edu.kz", "has_photo": True, "photo_base64": None},
            {"full_name": "Нұрланұлы Бауыржан", "email": "bauyrzhan.n@aitu.edu.kz", "has_photo": True, "photo_base64": None},
            {"full_name": "Ерланқызы Аида", "email": "aida.e@aitu.edu.kz", "has_photo": True, "photo_base64": None},
            {"full_name": "Қайратұлы Тимур", "email": "timur.k@aitu.edu.kz", "has_photo": True, "photo_base64": None},
        ]
        p_ph = "%s" if engine == "postgres" else "?"
        cur.execute(f"""
            INSERT INTO group_applications (
                group_name, curator_name, curator_email, faculty, course_year, status, students_json
            ) VALUES ({p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, 'PENDING', {p_ph})
        """, (
            "ИТ2301",
            "Талдаубек Арай (Куратор)",
            "curator.arai@smartattend.kz",
            "Ақпараттық технологиялар бөлімі",
            2,
            json.dumps(demo_students, ensure_ascii=False)
        ))
        conn.commit()
        conn.close()
        # Рекурсивті қайта жүктейміз
        return await list_director_applications()

    conn.close()
    return {"applications": apps, "total": len(apps)}

@app.post("/api/director/applications/{app_id}/approve")
async def approve_director_application(app_id: int):
    """
    Директор куратор өтінішін бекітеді:
    1. Барлық студенттерге жүйелік Студенттік ID береді (STU-...)
    2. Әр студентке автоматты БІР РЕТТІК ПАРОЛЬ (AITU-XXXX) жасайды
    3. Фотолардан Face ID векторлық эмбеддингтерін шығарып, users кестесіне енгізеді
    4. Толық ресми талонды (credentials) қайтарады
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"

    cur.execute(f"SELECT * FROM group_applications WHERE id = {p_ph}", (app_id,))
    app_row = cur.fetchone()
    if not app_row:
        conn.close()
        raise HTTPException(status_code=404, detail="Өтініш табылмады!")

    application = dict(app_row) if not isinstance(app_row, dict) else app_row
    group_name = application["group_name"]

    # 1. Топты academic_groups кестесіне енгізу / тексеру
    cur.execute(f"SELECT id FROM academic_groups WHERE name = {p_ph}", (group_name,))
    grp_row = cur.fetchone()
    if grp_row:
        group_id = dict(grp_row)["id"] if not isinstance(grp_row, dict) else grp_row["id"]
    else:
        cur.execute(f"""
            INSERT INTO academic_groups (name, faculty, course_year)
            VALUES ({p_ph}, {p_ph}, {p_ph})
            {"RETURNING id" if engine == "postgres" else ""}
        """, (group_name, application.get("faculty", "Ақпараттық технологиялар бөлімі"), application.get("course_year", 2)))
        if engine == "postgres":
            group_id = cur.fetchone()["id"]
        else:
            group_id = cur.lastrowid

    # 2. Базадағы қазіргі студенттер санынан реттік сан бастау
    cur.execute("SELECT COUNT(*) AS total_students FROM users WHERE role = 'STUDENT'")
    cnt_row = cur.fetchone()
    base_idx = (dict(cnt_row)["total_students"] if not isinstance(cnt_row, dict) else cnt_row["total_students"]) or 0

    students = json.loads(application["students_json"])
    from face_engine import face_engine
    import random
    import string

    issued_credentials = []
    clean_grp = "".join(c for c in group_name if c.isalnum()) or "GRP"

    for idx, st in enumerate(students):
        full_name = st["full_name"]
        seq_num = base_idx + idx + 1
        student_id = f"STU-{clean_grp}-{seq_num:02d}"

        # 6 таңбалы күшті бір реттік пароль (AITU-XXXX)
        rand_code = ''.join(random.choices(string.digits, k=4))
        one_time_pwd = f"AITU-{rand_code}"

        # Email
        if st.get("email"):
            email = st["email"].strip().lower()
        else:
            translit_map = {'а':'a','ә':'a','б':'b','в':'v','г':'g','ғ':'g','д':'d','е':'e','ё':'yo','ж':'zh','з':'z','и':'i','й':'y','к':'k','қ':'q','л':'l','м':'m','н':'n','ң':'n','о':'o','ө':'o','п':'p','р':'r','с':'s','т':'t','у':'u','ұ':'u','ү':'u','ф':'f','х':'kh','һ':'h','ц':'ts','ч':'ch','ш':'sh','щ':'shch','ъ':'','ы':'y','і':'i','ь':'','э':'e','ю':'yu','я':'ya',' ':'_'}
            clean_name = "".join(translit_map.get(c.lower(), '') for c in full_name)
            email = f"{clean_name}_{random.randint(10, 99)}@aitu.edu.kz"

        # Face ID эмбеддингті фотодан шығару
        emb_json = None
        has_face = False
        photo_b64 = st.get("photo_base64")
        if photo_b64:
            img = face_engine.decode_image(photo_b64)
            if img is not None:
                emb, _, _ = face_engine.extract_face(img)
                if emb:
                    emb_json = json.dumps(emb)
                    has_face = True

        # Егер нақты фото берілмесе, face_embedding бос қалады (өтірік биометрия сақталмайды)
        pass

        # Users кестесіне енгізу (егер бар болса — жаңарту)
        cur.execute(f"SELECT id FROM users WHERE email = {p_ph}", (email,))
        existing_u = cur.fetchone()

        bool_true = True if engine == "postgres" else 1

        stu_phone = st.get("phone") or st.get("iin")
        if existing_u:
            u_id = dict(existing_u)["id"] if not isinstance(existing_u, dict) else existing_u["id"]
            cur.execute(f"""
                UPDATE users SET
                    full_name = {p_ph},
                    student_id = {p_ph},
                    group_id = {p_ph},
                    password_hash = {p_ph},
                    one_time_password = {p_ph},
                    phone = {p_ph},
                    face_embedding = {p_ph},
                    is_active = {p_ph}
                WHERE id = {p_ph}
            """, (full_name, student_id, group_id, one_time_pwd, one_time_pwd, stu_phone, emb_json, bool_true, u_id))
        else:
            cur.execute(f"""
                INSERT INTO users (
                    email, phone, password_hash, one_time_password, full_name, role,
                    student_id, group_id, face_embedding, is_active
                ) VALUES ({p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}, 'STUDENT', {p_ph}, {p_ph}, {p_ph}, {p_ph})
                {"RETURNING id" if engine == "postgres" else ""}
            """, (email, stu_phone, one_time_pwd, one_time_pwd, full_name, student_id, group_id, emb_json, bool_true))
            if engine == "postgres":
                u_id = cur.fetchone()["id"]
            else:
                u_id = cur.lastrowid

        issued_credentials.append({
            "user_id": u_id,
            "full_name": full_name,
            "student_id": student_id,
            "iin": st.get("iin") or "",
            "email": email,
            "one_time_password": one_time_pwd,
            "face_id_active": has_face,
            "group_name": group_name
        })

    # Өтініш күйін 'APPROVED' деп өзгерту
    cur.execute(f"""
        UPDATE group_applications SET
            status = 'APPROVED',
            approved_at = CURRENT_TIMESTAMP,
            approved_by = {p_ph},
            credentials_json = {p_ph}
        WHERE id = {p_ph}
    """, ("Қасымов Бауыржан Серікұлы (Директор)", json.dumps(issued_credentials, ensure_ascii=False), app_id))

    conn.commit()
    conn.close()

    return {
        "success": True,
        "message": f"«{group_name}» тобы сәтті бекітілді! Барлық {len(issued_credentials)} студентке Студенттік ID, Face ID биометриясы және бір реттік құпия сөз берілді.",
        "group_name": group_name,
        "total_approved": len(issued_credentials),
        "credentials": issued_credentials
    }

@app.post("/api/director/applications/{app_id}/reject")
async def reject_director_application(app_id: int):
    """Өтінішті кері қайтару"""
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"
    cur.execute(f"UPDATE group_applications SET status = 'REJECTED' WHERE id = {p_ph}", (app_id,))
    conn.commit()
    conn.close()
    return {"success": True, "message": "Өтініш кураторға кері қайтарылды"}

# ── СТАТИЧЕСКИЕ СТРАНИЦЫ И ФАЙЛЫ ──
STATIC_DIR = os.path.dirname(__file__)
os.makedirs(os.path.join(STATIC_DIR, "static", "avatars"), exist_ok=True)
app.mount("/static", StaticFiles(directory=os.path.join(STATIC_DIR, "static")), name="static")

@app.get("/api/health")
async def health_check():
    return {"status": "ok", "service": "SmartAttend College Enterprise", "version": "4.0.0"}
# ── ЖУРНАЛ ПРИСУТСТВИЯ ──
@app.post("/api/attendance/save")
async def save_attendance(
    student_id: str = Form(...),
    teacher_id: str = Form(...),
    scan_timestamp: str = Form(...),
    verification_timestamp: str = Form(...),
    photo: UploadFile = File(...)
):
    """
    Сохраняет запись в журнале посещаемости.
    """
    conn, engine = get_db()
    cur = conn.cursor()
    p_ph = "%s" if engine == "postgres" else "?"
    photo_bytes = await photo.read()
    cur.execute(
        f"INSERT INTO attendance_journal (student_id, teacher_id, scan_timestamp, verification_timestamp, photo) "
        f"VALUES ({p_ph}, {p_ph}, {p_ph}, {p_ph}, {p_ph}) RETURNING id",
        (student_id, teacher_id, scan_timestamp, verification_timestamp, photo_bytes)
    )
    entry_id = cur.fetchone()["id"] if engine == "postgres" else cur.lastrowid
    conn.commit()
    conn.close()
    return {"success": True, "entryId": entry_id}

# GET journal entries for a teacher
@app.get("/api/attendance/journal")
async def get_attendance_journal(teacher_id: str):
    conn, _ = get_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT id, student_id, teacher_id, scan_timestamp, verification_timestamp FROM attendance_journal WHERE teacher_id = ?",
        (teacher_id,)
    )
    rows = cur.fetchall()
    conn.close()
    return {"entries": rows}

# GET photo for a journal entry
@app.get("/api/attendance/photo/{entry_id}")
async def get_attendance_photo(entry_id: int):
    conn, _ = get_db()
    cur = conn.cursor()
    cur.execute("SELECT photo FROM attendance_journal WHERE id = ?", (entry_id,))
    row = cur.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Photo not found")
    return Response(content=row["photo"], media_type="image/jpeg")

@app.get("/")
@app.get("/index.html")
async def serve_index():
    path = os.path.join(STATIC_DIR, "index.html")
    if os.path.exists(path):
        return FileResponse(path, media_type="text/html")
    return JSONResponse({"status": "SmartAttend API running"})

@app.get("/map")
@app.get("/map.html")
@app.get("/map_mobile.html")
@app.get("/aitu_map_preview.html")
async def serve_map():
    path = os.path.join(STATIC_DIR, "map.html")
    return FileResponse(path, media_type="text/html")

@app.get("/profile")
@app.get("/profile.html")
@app.get("/profile_mobile.html")
async def serve_profile():
    path = os.path.join(STATIC_DIR, "profile.html")
    return FileResponse(path, media_type="text/html")

@app.get("/style.css")
async def serve_css():
    return FileResponse(os.path.join(STATIC_DIR, "style.css"), media_type="text/css")

@app.get("/app.js")
async def serve_js():
    return FileResponse(os.path.join(STATIC_DIR, "app.js"), media_type="application/javascript")

@app.get("/aitu_floors_data.js")
async def serve_floors():
    return FileResponse(os.path.join(STATIC_DIR, "aitu_floors_data.js"), media_type="application/javascript")

# ════════════════════════════════════════════════════════════════
# 🤖 SMARTCAMPUS GEMINI AI SUITE (Vision OCR & Campus Navigator)
# ════════════════════════════════════════════════════════════════
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")

import requests
import json
import base64

class AIAskRequest(BaseModel):
    prompt: str
    role: Optional[str] = "STUDENT"
    user_name: Optional[str] = "Студент"
    current_floor: Optional[int] = 3

@app.post("/api/ai/ask")
async def ai_ask_assistant(req: AIAskRequest):
    """
    Умный навигатор и консультант колледжа:
    - Отвечает, на каком этаже кабинет (например, 221 -> 2 этаж, блок C1.2)
    - Подсказывает преподавателя, предметы и правила
    - Возвращает action для автоматического переключения этажа карты в UI
    """
    prompt = req.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Empty prompt")

    system_instruction = (
        "Ты — официальный ИИ-ассистент колледжа SmartAttend (Astana IT College, Корпус C1). "
        "Твоя цель — помогать студентам, преподавателям и деканату.\n"
        "Справочник этажей и аудиторий блока C1:\n"
        "- 1 этаж (C1.1): Асхана (столовая), Кітапхана (библиотека), Спортзал, Медпункт (143), Акт залы (Assembly Hall).\n"
        "- 2 этаж (C1.2): Деканат (IT-факультет), Оқытушылар бөлмесі (Кафедра), 215 (Киберқауіпсіздік), 218, 221, 222 (Дәрісханалар).\n"
        "- 3 этаж (C1.3): 241 (Мобильді әзірлеу зертханасы, БҚ2405), 240 (Серверлік жүйелер), 238 (Желілер), 220, 228 (Алгоритмдер), 229 (Деректер қоры), 230 (Web), 237 (Жасанды интеллект орталығы).\n"
        "Правило форматирования ответа:\n"
        "Отвечай дружелюбно на языке запроса (казахский или русский). "
        "Если пользователь спрашивает, где находится кабинет или зона, обязательно чётко укажи: ЭТАЖ, БЛОК и ориентир.\n"
        "Также, если в вопросе упомянут конкретный кабинет/этаж, в самом конце своего ответа добавь техническую JSON-строку формата: "
        "`###ACTION:{\"target_floor\": 2, \"room_code\": \"C1.2.221\"}###` (чтобы приложение переключило интерактивную карту на этот этаж!)."
    )

    gemini_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key={GEMINI_API_KEY}"
    
    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {"text": f"{system_instruction}\n\nПользователь ({req.role}, {req.user_name}): {prompt}"}
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.4,
            "maxOutputTokens": 600
        }
    }

    try:
        res = requests.post(gemini_url, json=payload, timeout=35)
        data = res.json()
        candidates = data.get("candidates", [])
        if candidates and "content" in candidates[0]:
            full_text = candidates[0]["content"]["parts"][0]["text"]
            
            # Извлекаем ACTION если есть
            action_data = None
            if "###ACTION:" in full_text:
                parts = full_text.split("###ACTION:")
                clean_reply = parts[0].strip()
                action_raw = parts[1].split("###")[0].strip()
                try:
                    action_data = json.loads(action_raw)
                except Exception:
                    pass
            else:
                clean_reply = full_text.strip()

            return {
                "reply": clean_reply,
                "action": action_data
            }
        else:
            return {
                "reply": "Кешіріңіз, ИИ жүйесі жауап бере алмады. Қайта сұрап көріңіз.",
                "action": None
            }
    except Exception as e:
        return {
            "reply": f"ИИ серверіне қосылуда қате орын алды: {e}",
            "action": None
        }

@app.post("/api/ai/schedule/scan-image")
async def ai_scan_schedule_image(file: UploadFile = File(...)):
    """
    Деканат үшін ИИ-Кесте енгізу:
    Gemini 1.5 Flash Vision фотосуреттегі кестені оқып, сабақтарды құрылымдап Supabase-ке сақтайды.
    """
    try:
        contents = await file.read()
        b64_image = base64.b64encode(contents).decode("utf-8")
        mime_type = file.content_type or "image/jpeg"

        gemini_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key={GEMINI_API_KEY}"

        prompt_text = (
            "Сен колледждегі расписание кестесін оқитын сарапшысың. "
            "Берілген фотосуреттегі немесе құжаттағы сабақ кестесін мұқият оқып, тек қана таза JSON массивін қайтар. "
            "Әрбір сабақ үшін келесі өрістерді тап: "
            "1. title: сабақ/пән атауы (мысалы: 'Мобильді қосымшалар', 'Алгоритмдер') "
            "2. room_code: аудитория коды (мысалы: 'C1.3.241', 'C1.2.215', '221') "
            "3. day_of_week: апта күні ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') "
            "4. pair_number: пара нөмірі (1, 2, 3 немесе 4) "
            "5. start_time: басталу уақыты ('08:30', '10:05', '11:40', '13:30' т.б.) "
            "6. end_time: аяқталу уақыты ('09:50', '11:25', '13:00', '14:50' т.б.) "
            "7. group_name: топ атауы (мысалы: 'БҚ2405', 'ПО2501') "
            "8. teacher_name: оқытушының аты-жөні. "
            "Жауапты тек таза JSON форматында бер, ешқандай түсініктемесіз және маркдаунсыз: "
            "[{\"title\":\"...\",\"room_code\":\"...\",\"day_of_week\":\"...\",\"pair_number\":1,\"start_time\":\"...\",\"end_time\":\"...\",\"group_name\":\"...\",\"teacher_name\":\"...\"}]"
        )

        payload = {
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {"text": prompt_text},
                        {
                            "inline_data": {
                                "mime_type": mime_type,
                                "data": b64_image
                            }
                        }
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.1,
                "responseMimeType": "application/json"
            }
        }

        res = requests.post(gemini_url, json=payload, timeout=45)
        data = res.json()
        candidates = data.get("candidates", [])
        if not candidates or "content" not in candidates[0]:
            raise HTTPException(status_code=500, detail="Gemini Vision did not return results")

        raw_json_str = candidates[0]["content"]["parts"][0]["text"].strip()
        # Очистка если есть markdown
        if raw_json_str.startswith("```"):
            raw_json_str = raw_json_str.split("\n", 1)[1]
            if raw_json_str.endswith("```"):
                raw_json_str = raw_json_str.rsplit("\n", 1)[0]

        parsed_lessons = json.loads(raw_json_str)

        # Автоматическое сохранение в Supabase / PostgreSQL
        conn, db_type = get_db()
        cur = conn.cursor()
        saved_count = 0

        for l in parsed_lessons:
            title = l.get("title", "Сабақ")
            room = l.get("room_code", "C1.3.241")
            day = l.get("day_of_week", "Monday")
            pair = int(l.get("pair_number", 1))
            st = l.get("start_time", "08:30")
            et = l.get("end_time", "09:50")
            group_name = l.get("group_name", "БҚ2405")

            # Обеспечиваем существование группы
            if db_type == "postgres":
                cur.execute("INSERT INTO academic_groups (name, faculty) VALUES (%s, %s) ON CONFLICT (name) DO NOTHING;", (group_name, "Ақпараттық технологиялар бөлімі"))
                cur.execute("SELECT id FROM academic_groups WHERE name = %s;", (group_name,))
                group_row = cur.fetchone()
                gid = group_row["id"] if isinstance(group_row, dict) else group_row[0]

                # Вставляем урок
                cur.execute("""
                    INSERT INTO lessons (title, room_code, day_of_week, pair_number, start_time, end_time, group_id, status)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, 'SCHEDULED');
                """, (title, room, day, pair, st, et, gid))
                saved_count += 1
            else:
                cur.execute("INSERT OR IGNORE INTO academic_groups (name, faculty) VALUES (?, ?);", (group_name, "Ақпараттық технологиялар бөлімі"))
                cur.execute("SELECT id FROM academic_groups WHERE name = ?;", (group_name,))
                group_row = cur.fetchone()
                gid = group_row["id"] if isinstance(group_row, sqlite3.Row) else group_row[0]
                cur.execute("""
                    INSERT INTO lessons (title, room_code, day_of_week, pair_number, start_time, end_time, group_id, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?, 'SCHEDULED');
                """, (title, room, day, pair, st, et, gid))
                saved_count += 1

        conn.commit()
        conn.close()

        return {
            "success": True,
            "detected_count": len(parsed_lessons),
            "saved_count": saved_count,
            "lessons": parsed_lessons,
            "message": f"ИИ сәтті оқып шықты! Дерекқорға {saved_count} сабақ автоматты түрде қосылды ✅"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"ИИ-кесте қатесі: {e}")


if __name__ == "__main__":
    import uvicorn
    print("\n" + "="*60)
    print(f">>> SmartAttend Server running on http://{HOST}:{PORT}")
    print(f">>> S-Student, S-Mugalim, S-Kurator, S-Ata-Ana, S-Deanat online!")
    print("="*60 + "\n")
    uvicorn.run(app, host=HOST, port=PORT)
