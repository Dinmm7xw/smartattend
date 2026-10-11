import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';
import '../services/app_session.dart';

/// Circular avatar: shows the user's photo (data URL / server path) or initials.
/// Rebuilds automatically when the profile photo changes.
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.color = AppColors.primary,
    this.onTap,
    this.showEditBadge = false,
  });

  static ImageProvider? providerFor(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      if (url.startsWith('data:image')) {
        return MemoryImage(base64Decode(url.substring(url.indexOf(',') + 1)));
      }
      if (url.startsWith('http')) return NetworkImage(url);
      if (url.startsWith('/')) return NetworkImage('${ApiService.baseUrl}$url');
      return MemoryImage(base64Decode(url));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0].toUpperCase()).join();
    return ValueListenableBuilder<String?>(
      valueListenable: AppSession.avatarUrl,
      builder: (_, url, __) {
        final img = providerFor(url);
        final circle = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: img == null
                ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                : null,
            image: img != null ? DecorationImage(image: img, fit: BoxFit.cover) : null,
            border: Border.all(color: Colors.white, width: size > 60 ? 3 : 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          alignment: Alignment.center,
          child: img == null
              ? Text(initials,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.36))
              : null,
        );
        final content = showEditBadge
            ? Stack(clipBehavior: Clip.none, children: [
                circle,
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ])
            : circle;
        return GestureDetector(onTap: onTap, child: content);
      },
    );
  }
}
