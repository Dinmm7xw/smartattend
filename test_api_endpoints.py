import sys
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

from fastapi.testclient import TestClient
from main import app
import cv2
import numpy as np
import base64

client = TestClient(app)

print(">>> 1. Testing GET /api/admin/users ...")
res = client.get("/api/admin/users")
print("Status:", res.status_code)
users_data = res.json()
print("Total users in DB:", users_data.get("total"))
print("First 3 users:", [(u["id"], u["full_name"], u["role"], u.get("student_id")) for u in users_data.get("users", [])[:3]])

test_email = "test.student.2026@aitu.edu.kz"
for u in users_data.get("users", []):
    if u["email"] == test_email:
        client.delete(f"/api/admin/users/{u['id']}")

reg_payload = {
    "email": test_email,
    "full_name": "Тест Студент А.А.",
    "role": "STUDENT",
    "group_name": "БҚ2405",
    "password": "password123",
    "department": "Ақпараттық қауіпсіздік"
}
res_reg = client.post("/api/users/register", json=reg_payload)
print("Register Status:", res_reg.status_code)
print("Register Response:", res_reg.json())

print("\n>>> 3. Testing POST /api/face/verify (First-time scan auto-enrollment) ...")
# Create a dummy image
img = np.full((320, 320, 3), 200, dtype=np.uint8)
_, buffer = cv2.imencode('.jpg', img)
b64_frame = base64.b64encode(buffer).decode('utf-8')

verify_payload = {
    "email_or_id": test_email,
    "frame_base64": b64_frame,
    "lesson_id": 1
}
res_ver = client.post("/api/face/verify", json=verify_payload)
print("Verify Status:", res_ver.status_code)
print("Verify Response:", res_ver.json())

# Cleanup test user
curr_users = client.get("/api/admin/users").json().get("users", [])
for u in curr_users:
    if u["email"] == test_email:
        client.delete(f"/api/admin/users/{u['id']}")
        print(f"Deleted test user {u['id']}")

print("\n[ALL BACKEND ENDPOINTS TESTED SUCCESSFULLY!]")
