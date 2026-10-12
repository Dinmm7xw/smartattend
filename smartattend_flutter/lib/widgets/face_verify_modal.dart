// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// SmartAttend — Real Live WebCam Biometric Face Verification Modal

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../constants/i18n.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/camera_bridge.dart';

class FaceVerifyModal extends StatefulWidget {
  final LessonModel? lesson;
  final UserModel? student;
  final Future<void> Function() onSuccess;
  final VoidCallback onClose;
  final String lang;
  final bool isLoginVerification;

  const FaceVerifyModal({
    super.key,
    this.lesson,
    required this.student,
    required this.onSuccess,
    required this.onClose,
    required this.lang,
    this.isLoginVerification = false,
  });

  @override
  State<FaceVerifyModal> createState() => _FaceVerifyModalState();
}

class _FaceVerifyModalState extends State<FaceVerifyModal>
    with SingleTickerProviderStateMixin {
  late final String _viewType;

  bool _cameraInitialized = false;
  bool _cameraError = false;
  String _cameraErrorMsg = '';

  bool _isProcessing = false;
  bool _isVerified = false;
  bool _notEnrolled = false;
  String _statusMsg = '';
  double _similarity = 0.0;

  late AnimationController _scanAnimController;
  late Animation<double> _scanAnimation;

  Map<String, String> get t => translations[widget.lang] ?? translations['kk']!;

  @override
  void initState() {
    super.initState();
    _viewType = 'smartattend-face-cam-${DateTime.now().microsecondsSinceEpoch}';

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  void _initCamera() async {
    setState(() {
      _cameraError = false;
      _cameraErrorMsg = '';
      _statusMsg = 'Камера қосылуда...';
    });

    if (kIsWeb) {
      final success = await WebCameraBridge.initCamera(_viewType);
      if (!mounted) return;
      if (success) {
        setState(() {
          _cameraInitialized = true;
          _cameraError = false;
          _statusMsg = 'Камера белсенді. Бетіңізді ортаға бағыттаңыз.';
        });
      } else {
        setState(() {
          _cameraError = true;
          _cameraInitialized = false;
          _cameraErrorMsg = 'Камера қосылмады немесе рұқсат берілмеді.';
        });
      }
    } else {
      // Mobile fallback: mark camera as initialized for simulation / testing
      setState(() {
        _cameraInitialized = true;
        _cameraError = false;
        _statusMsg = 'Мобильді режимде дайын. Бетіңізді ортаға бағыттаңыз.';
      });
    }
  }

  void _stopCamera() {
    WebCameraBridge.stopCamera();
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _stopCamera();
    super.dispose();
  }

  String? _captureFrameBase64() {
    if (kIsWeb) {
      return WebCameraBridge.captureFrameBase64();
    }
    // Mobile fallback demo frame
    return 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP...';
  }

  Future<void> _verifyFromPhotoBase64(String photoB64) async {
    setState(() {
      _isProcessing = true;
      _notEnrolled = false;
      _statusMsg = 'Биометриялық векторды салыстыру жүруде...';
    });

    final targetEmail = widget.student?.email ?? 'dinmuhammed@smartattend.kz';
    try {
      final res = await ApiService.verifyFace(
        emailOrId: targetEmail,
        frameBase64: photoB64,
        lessonId: widget.lesson?.id,
      );

      if (!mounted) return;

      final bool verified = res['verified'] == true;
      final double sim = (res['similarity'] as num?)?.toDouble() ?? 0.0;
      final String msg = res['message'] ?? '';
      final bool enrolled = res['enrolled'] != false;

      if (!enrolled) {
        setState(() {
          _isProcessing = false;
          _notEnrolled = true;
          _isVerified = false;
          _statusMsg = msg.isNotEmpty ? msg : 'Face ID базада тіркелмеген. Бетіңізді тіркеңіз.';
        });
        return;
      }

      if (verified) {
        setState(() {
          _isProcessing = false;
          _isVerified = true;
          _similarity = sim;
          _statusMsg = 'Сәйкестендірілді! Сәйкестік: ${sim.toStringAsFixed(1)}% ✅';
        });
        // Save attendance record
        try {
          final Uint8List photoBytes = base64Decode(photoB64.split(',').last);
          await ApiService.saveAttendance(
            studentId: widget.student?.studentId ?? '',
            teacherId: widget.lesson?.teacher ?? '',
            scanTimestamp: DateTime.now().toIso8601String(),
            verificationTimestamp: DateTime.now().toIso8601String(),
            photoBytes: photoBytes,
          );
        } catch (e) {
          // ignore errors, but you could handle them
        }
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          _stopCamera();
          await widget.onSuccess();
        }
      } else {
        setState(() {
          _isProcessing = false;
          _isVerified = false;
          _similarity = sim;
          _statusMsg = msg.isNotEmpty
              ? msg
              : 'Тұлға сәйкес келмеді (${sim.toStringAsFixed(1)}%). Қайта көріңіз.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isVerified = false;
        _statusMsg = 'Сервермен байланыс қатесі: $e';
      });
    }
  }

  Future<void> _enrollFaceFromBase64(String photoB64) async {
    setState(() {
      _isProcessing = true;
      _statusMsg = 'Бетті базаға сақтау жүруде (YuNet + SFace)...';
    });

    final targetEmail = widget.student?.email ?? 'dinmuhammed@smartattend.kz';
    try {
      final res = await ApiService.enrollFace(
        emailOrId: targetEmail,
        photoBase64: photoB64,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _isProcessing = false;
          _notEnrolled = false;
          _statusMsg = 'Face ID сәтті тіркелді! Енді «Сканерлеу» арқылы тексеріңіз.';
        });
      } else {
        setState(() {
          _isProcessing = false;
          _statusMsg = res['message'] ?? 'Бетті тіркеуде қате орын алды.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMsg = 'Тіркеу қатесі: $e';
      });
    }
  }

  Future<void> _performRealScan() async {
    if (_isProcessing) return;

    if (!_cameraInitialized) {
      _initCamera();
      return;
    }

    final frameB64 = _captureFrameBase64();
    if (frameB64 == null || frameB64.isEmpty) {
      setState(() {
        _statusMsg = 'Камерадан кадр алынбады. Камераға тура қараңыз.';
      });
      return;
    }

    await _verifyFromPhotoBase64(frameB64);
  }

  Future<void> _enrollCurrentFace() async {
    if (_isProcessing) return;

    if (!_cameraInitialized) {
      _initCamera();
      return;
    }

    final frameB64 = _captureFrameBase64();
    if (frameB64 == null || frameB64.isEmpty) {
      setState(() {
        _statusMsg = 'Камерадан кадр алынбады. Камераға тура қараңыз.';
      });
      return;
    }

    await _enrollFaceFromBase64(frameB64);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 440,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.document_scanner_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isLoginVerification
                                    ? 'Face ID — Кіруді растау'
                                    : (t['scan_face'] ?? 'Face ID Сканерлеу'),
                                style: AppTextStyles.headline.copyWith(fontSize: 18),
                              ),
                              Text(
                                widget.isLoginVerification
                                    ? '2-Factor Biometric Security (AI)'
                                    : 'AITU Biometric Verification Engine',
                                style: AppTextStyles.caption2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Student Info Strip ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.separator),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            (widget.student?.name.isNotEmpty == true)
                                ? widget.student!.name[0]
                                : 'S',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.student?.name ?? 'Пайдаланушы',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.student?.role == 'DIRECTOR'
                                    ? 'Колледж басшылығы (Директор)'
                                    : widget.student?.role == 'TEACHER'
                                        ? 'Оқытушы · ${widget.student?.department ?? 'IT'}'
                                        : widget.student?.role == 'DEAN'
                                            ? 'Декан · ${widget.student?.department ?? 'IT'}'
                                            : '${widget.student?.group ?? 'БҚ2405'} · ${widget.student?.studentId ?? 'STU-2405-03'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isVerified
                                ? AppColors.successLight
                                : (_cameraInitialized ? Colors.green.shade50 : Colors.amber.shade50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isVerified
                                      ? AppColors.success
                                      : (_cameraInitialized ? Colors.green : Colors.amber),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isVerified
                                    ? 'Расталды'
                                    : (_cameraInitialized ? 'LIVE' : 'Дайындалуда'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _isVerified
                                      ? AppColors.success
                                      : (_cameraInitialized ? Colors.green.shade800 : Colors.amber.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Real Camera Preview Window ──
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(
                        color: _isVerified
                            ? AppColors.success
                            : (_cameraError
                                ? AppColors.danger
                                : AppColors.primary),
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isVerified ? AppColors.success : AppColors.primary)
                              .withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_cameraInitialized)
                            (kIsWeb
                                ? WebCameraBridge.buildView(_viewType)
                                : Container(
                                    color: const Color(0xFF0F172A),
                                    child: const Center(
                                      child: Icon(Icons.person_outline_rounded,
                                          color: Colors.white70, size: 90),
                                    ),
                                  ))
                          else
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _cameraError ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                                    color: _cameraError ? Colors.red.shade400 : AppColors.primary,
                                    size: 44,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _cameraError ? 'Камера қосылмады' : 'Камера қосылуда...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (_cameraErrorMsg.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      _cameraErrorMsg,
                                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _isProcessing ? null : _initCamera,
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text(
                                      'Камераны іске қосу',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Biometric scanner laser animation
                          if (_cameraInitialized && !_isVerified)
                            AnimatedBuilder(
                              animation: _scanAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scanAnimation.value * 280,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          AppColors.primary.withValues(alpha: 0.8),
                                          Colors.white,
                                          AppColors.primary.withValues(alpha: 0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.7),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Biometric target guide overlay
                          if (_cameraInitialized && !_isVerified)
                            IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                          // Verified checkmark badge
                          if (_isVerified)
                            Container(
                              color: Colors.black45,
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 90,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Status Message Box ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isVerified
                          ? AppColors.successLight
                          : (_notEnrolled
                              ? Colors.amber.shade50
                              : (_similarity > 0 && !_isVerified
                                  ? AppColors.dangerLight
                                  : AppColors.background)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _statusMsg.isNotEmpty
                              ? _statusMsg
                              : 'Камераға қарап «Сканерлеу» батырмасын басыңыз',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isVerified
                                ? AppColors.success
                                : (_notEnrolled
                                    ? Colors.amber.shade900
                                    : (_similarity > 0 && !_isVerified
                                        ? AppColors.danger
                                        : AppColors.textSecondary)),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_similarity > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Биометриялық ұқсастық: ${_similarity.toStringAsFixed(1)}% (SFace ONNX)',
                            style: TextStyle(
                              fontSize: 11,
                              color: _isVerified ? AppColors.success : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Action Buttons ──
                  if (_notEnrolled) ...[
                    // Button to enroll face right now
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _enrollCurrentFace,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_a_photo_rounded, size: 20),
                        label: const Text(
                          'Бетті базаға тіркеу (Face ID орнату)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : (_cameraInitialized ? _performRealScan : _initCamera),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cameraInitialized ? AppColors.primary : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _cameraInitialized
                                  ? Icons.camera_alt_rounded
                                  : Icons.videocam_rounded,
                              size: 20,
                            ),
                      label: Text(
                        _isProcessing
                            ? 'Тексерілуде...'
                            : (_cameraInitialized
                                ? (t['scan_face'] ?? 'Сканерлеу (Тексеру)')
                                : '🎥 Камераны қосу'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  if (widget.isLoginVerification) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                _stopCamera();
                                await widget.onSuccess();
                              },
                        icon: const Icon(Icons.lock_open_rounded, size: 14, color: AppColors.textSecondary),
                        label: const Text(
                          'Face ID-сыз тікелей кіру (Өткізіп жіберу)',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
