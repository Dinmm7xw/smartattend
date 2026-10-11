"""
SmartAttend Enterprise — Real Biometric Face Recognition Engine
Architecture: YuNet (Face Detection & Landmarks) + SFace (Deep Feature Extractor 128-D) via ONNXRuntime
Designed for Astana IT University / College Smart Campus
"""

import os
import io
import base64
import cv2
import numpy as np
import onnxruntime as ort

MODELS_DIR = os.path.dirname(__file__)
YUNET_PATH = os.path.join(MODELS_DIR, "face_detection_yunet_2023mar.onnx")
SFACE_PATH = os.path.join(MODELS_DIR, "face_recognition_sface_2021dec.onnx")

class FaceEngine:
    def __init__(self):
        self.detector = None
        self.session = None
        self.recognizer = None
        self._init_models()

    def _init_models(self):
        try:
            if os.path.exists(YUNET_PATH):
                self.detector = cv2.FaceDetectorYN.create(
                    model=YUNET_PATH,
                    config="",
                    input_size=(320, 320),
                    score_threshold=0.6,
                    nms_threshold=0.3,
                    top_k=5000
                )
            if os.path.exists(SFACE_PATH):
                # OpenCV FaceRecognizerSF: landmark-based alignCrop + SFace feature
                self.recognizer = cv2.FaceRecognizerSF.create(SFACE_PATH, "")
                self.session = self.recognizer
        except Exception as e:
            print(f"[FaceEngine] Initialization error: {e}")

    def decode_image(self, img_input):
        """Accepts base64 data URL, raw base64 string, or bytes, returns BGR numpy array"""
        try:
            if isinstance(img_input, str):
                if "base64," in img_input:
                    img_input = img_input.split("base64,")[1]
                img_bytes = base64.b64decode(img_input)
            elif isinstance(img_input, bytes):
                img_bytes = img_input
            else:
                return None

            nparr = np.frombuffer(img_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            return img
        except Exception as e:
            print(f"[FaceEngine] Decode image error: {e}")
            return None

    def extract_face(self, img):
        """
        Detects face, crops/aligns to 112x112, and runs SFace ONNX.
        Returns:
            embedding: list of 128 floats (L2 normalized)
            bbox: dict of {x, y, w, h, confidence}
            msg: status string
        """
        if img is None:
            return None, None, "Сурет оқылмады"

        if self.detector is None or self.session is None:
            self._init_models()

        if self.detector is None or self.session is None:
            return None, None, "Нейрожелі модельдері дайын емес"

        h, w, _ = img.shape
        # Set dynamic input size for YuNet
        self.detector.setInputSize((w, h))
        faces = self.detector.detect(img)

        if faces[1] is None or len(faces[1]) == 0:
            return None, None, "Кадрда бет-әлпет табылмады. Камераға қараңыз."

        # Select face with highest confidence
        best_face = faces[1][0]
        confidence = float(best_face[-1])
        if confidence < 0.50:
            return None, None, "Бет анық көрінбейді. Жарық жерге тұрыңыз."

        fx, fy, fw, fh = int(best_face[0]), int(best_face[1]), int(best_face[2]), int(best_face[3])
        bbox = {
            "x": max(0, fx),
            "y": max(0, fy),
            "w": min(w - fx, fw),
            "h": min(h - fy, fh),
            "confidence": round(confidence * 100, 1)
        }

        # Align face by 5 landmarks (eyes, nose, mouth corners) to 112x112, then extract SFace feature
        aligned = self.recognizer.alignCrop(img, best_face)
        raw_feature = self.recognizer.feature(aligned).flatten()

        # L2 Normalize
        norm = np.linalg.norm(raw_feature)
        if norm > 0:
            norm_feature = raw_feature / norm
        else:
            norm_feature = raw_feature

        return norm_feature.tolist(), bbox, "OK"

    def compare(self, embedding1, embedding2, threshold=0.36):
        """
        Cosine similarity between two 128-D normalized vectors.
        SFace official cosine threshold is ~0.363.
        Returns:
            is_match: bool
            similarity_percent: float (0.0 to 100.0)
            score: raw cosine similarity float
        """
        if not embedding1 or not embedding2:
            return False, 0.0, 0.0

        v1 = np.array(embedding1, dtype=np.float32)
        v2 = np.array(embedding2, dtype=np.float32)

        norm1 = np.linalg.norm(v1)
        norm2 = np.linalg.norm(v2)
        if norm1 == 0 or norm2 == 0:
            return False, 0.0, 0.0

        cos_sim = float(np.dot(v1, v2) / (norm1 * norm2))

        # Scale cosine similarity (-1.0 to 1.0, typically 0.1 to 0.8) to human 0-100%
        # >= 0.36 is a genuine match (e.g. 80% to 100%)
        # < 0.25 is different person (e.g. 10% to 40%)
        if cos_sim >= threshold:
            pct = 80.0 + min(20.0, ((cos_sim - threshold) / (1.0 - threshold)) * 20.0)
        else:
            pct = max(5.0, (cos_sim / threshold) * 75.0)

        is_match = cos_sim >= threshold
        return is_match, round(pct, 1), round(cos_sim, 4)

# Singleton instance
face_engine = FaceEngine()
