import cv2
import numpy as np
import torch

print("cv2 version:", cv2.__version__)
print("CUDA available in torch:", torch.cuda.is_available())

# Test Haar Cascade (always built into cv2)
cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
cascade = cv2.CascadeClassifier(cascade_path)
print("Haar Cascade loaded:", not cascade.empty())

# Check if FaceDetectorYN or FaceRecognizerSF exist
has_yunet = hasattr(cv2, 'FaceDetectorYN')
has_sface = hasattr(cv2, 'FaceRecognizerSF')
print("Has YuNet:", has_yunet, "Has SFace:", has_sface)
