// SmartAttend — Toast Notification Widget

import 'package:flutter/material.dart';
import '../constants/theme.dart';

class ToastData {
  final String type; // success | danger | info | warning
  final String title;
  final String message;
  const ToastData({required this.type, required this.title, required this.message});
}

class ToastWidget extends StatelessWidget {
  final ToastData data;
  const ToastWidget({super.key, required this.data});

  Color get _bgColor {
    switch (data.type) {
      case 'success': return AppColors.success;
      case 'danger': return AppColors.danger;
      case 'warning': return AppColors.warning;
      default: return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (data.type) {
      case 'success': return Icons.check_circle;
      case 'danger': return Icons.warning_rounded;
      case 'warning': return Icons.info_outline;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: _bgColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(_icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(data.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        )),
                    Text(data.message,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: 'Inter',
                          fontSize: 11,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
