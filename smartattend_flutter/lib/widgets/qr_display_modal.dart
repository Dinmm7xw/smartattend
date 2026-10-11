// SmartAttend — QR Display Modal (updated theme)

import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/theme.dart';
import '../constants/i18n.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class QRDisplayModal extends StatefulWidget {
  final LessonModel? lesson;
  final VoidCallback onClose;
  final String lang;

  const QRDisplayModal({
    super.key,
    required this.lesson,
    required this.onClose,
    required this.lang,
  });

  @override
  State<QRDisplayModal> createState() => _QRDisplayModalState();
}

class _QRDisplayModalState extends State<QRDisplayModal> {
  String? _token;
  int _secondsLeft = 15;
  Timer? _timer;
  bool _loading = true;

  Map<String, String> get t => translations[widget.lang] ?? translations['kk']!;

  @override
  void initState() {
    super.initState();
    _generateToken();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generateToken() async {
    setState(() => _loading = true);
    final data = await ApiService.generateQRToken(widget.lesson?.id ?? 1);
    if (!mounted) return;
    setState(() {
      _token = data['token'] as String?;
      _secondsLeft = (data['expires_in'] as int?) ?? 15;
      _loading = false;
    });
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _generateToken();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {},
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: AppShadows.card,
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Header
                  Row(children: [
                    const Icon(Icons.qr_code_2_rounded, color: AppColors.teacher, size: 22),
                    const SizedBox(width: 8),
                    Text(t['generate_qr'] ?? '', style: AppTextStyles.headline),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Lesson
                  if (widget.lesson != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(children: [
                        const Icon(Icons.book_outlined, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.lesson!.subject,
                            style: AppTextStyles.subheadline.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ))),
                      ]),
                    ),
                  const SizedBox(height: 16),

                  // QR box
                  _loading
                      ? const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator(color: AppColors.teacher)),
                        )
                      : Container(
                          width: 180, height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.separator, width: 1.5),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 110, color: AppColors.textPrimary),
                              Text(_token ?? '', style: AppTextStyles.caption2, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                  const SizedBox(height: 14),

                  // Countdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _secondsLeft <= 5 ? AppColors.dangerLight : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.timer_outlined,
                          color: _secondsLeft <= 5 ? AppColors.danger : AppColors.primary,
                          size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${t['qr_expires'] ?? ''}: $_secondsLeft ${t['sec'] ?? ''}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.font,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _secondsLeft <= 5 ? AppColors.danger : AppColors.primary,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // Refresh
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _generateToken,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(t['refresh'] ?? ''),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.teacher,
                        side: const BorderSide(color: AppColors.teacher),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
