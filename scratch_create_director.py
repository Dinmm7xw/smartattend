import psycopg2
import sqlite3
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

from main import PG_CONFIG

# Ensure director has both email, IIN, and password 12345
d = {
    "email": "p82041180@gmail.com",
    "full_name": "Колледж директоры",
    "role": "DIRECTOR",
    "student_id": "080524554184",
    "password_hash": "12345",
    "phone": "+77080524554",
    "department": "Басқару аппараты / Ректорат",
    "is_active": True
}

# 1. PostgreSQL
conn = psycopg2.connect(**PG_CONFIG)
cur = conn.cursor()
cur.execute("""
    UPDATE users 
    SET email = %(email)s,
        full_name = %(full_name)s,
        role = %(role)s,
        student_id = %(student_id)s,
        password_hash = %(password_hash)s
    WHERE role = 'DIRECTOR' OR email = %(email)s OR student_id = %(student_id)s;
""", d)
if cur.rowcount == 0:
    cur.execute("""
        INSERT INTO users (email, full_name, role, student_id, password_hash, phone, department, is_active)
        VALUES (%(email)s, %(full_name)s, %(role)s, %(student_id)s, %(password_hash)s, %(phone)s, %(department)s, %(is_active)s);
    """, d)
conn.commit()
cur.execute("SELECT id, email, full_name, role, student_id, password_hash FROM users WHERE role = 'DIRECTOR'")
print("PostgreSQL Director:", cur.fetchall())
conn.close()

# 2. SQLite
sq = sqlite3.connect("smartattend.db")
sc = sq.cursor()
sc.execute("""
    UPDATE users 
    SET email = :email,
        full_name = :full_name,
        role = :role,
        student_id = :student_id,
        password_hash = :password_hash
    WHERE role = 'DIRECTOR' OR email = :email OR student_id = :student_id;
""", d)
if sc.rowcount == 0:
    sc.execute("""
        INSERT INTO users (email, full_name, role, student_id, password_hash, phone, department, is_active)
        VALUES (:email, :full_name, :role, :student_id, :password_hash, :phone, :department, :is_active);
    """, d)
sq.commit()
sc.execute("SELECT id, email, full_name, role, student_id, password_hash FROM users WHERE role = 'DIRECTOR'")
print("SQLite Director:", sc.fetchall())
sq.close()
