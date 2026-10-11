"""
SmartAttend — Face ID live test from the laptop webcam.

Run:  python test_face_live.py
  SPACE — enroll the face currently in front of the camera
  Q     — quit
After enrolling, every frame shows the cosine score against the enrolled face.
Threshold: 0.363 (official SFace value). Ask another person to sit in front of
the camera: the result should switch to "БАСҚА АДАМ".
"""
import sys
import cv2
from face_engine import face_engine

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

cap = cv2.VideoCapture(0)
if not cap.isOpened():
    print("Камера ашылмады")
    sys.exit(1)

enrolled = None
print("SPACE — бетті тіркеу, Q — шығу")

while True:
    ok, frame = cap.read()
    if not ok:
        break

    emb, bbox, msg = face_engine.extract_face(frame)
    label, color = msg, (0, 200, 255)

    if emb and bbox:
        x, y, w, h = bbox["x"], bbox["y"], bbox["w"], bbox["h"]
        if enrolled is None:
            label, color = "Бет табылды - SPACE басыңыз", (0, 200, 255)
        else:
            match, pct, score = face_engine.compare(enrolled, emb)
            label = f"{'СОЛ АДАМ' if match else 'БАСҚА АДАМ'}  cos={score:.3f}"
            color = (0, 200, 0) if match else (0, 0, 255)
        cv2.rectangle(frame, (x, y), (x + w, y + h), color, 2)

    # cv2.putText does not render Cyrillic; print the label to console as well
    cv2.putText(frame, label.encode("ascii", "ignore").decode() or "see console",
                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)
    cv2.imshow("SmartAttend Face ID test", frame)

    key = cv2.waitKey(1) & 0xFF
    if key == ord(" ") and emb:
        enrolled = emb
        print("Бет тіркелді. Енді камераға қараңыз / басқа адамды отырғызыңыз.")
    elif key == ord(" "):
        print("Кадрда бет жоқ, тіркелмеді")
    elif key == ord("q"):
        break
    elif enrolled is not None and emb:
        match, pct, score = face_engine.compare(enrolled, emb)
        print(f"\r{'СОЛ АДАМ  ' if match else 'БАСҚА АДАМ'} cos={score:.3f}", end="")

cap.release()
cv2.destroyAllWindows()
