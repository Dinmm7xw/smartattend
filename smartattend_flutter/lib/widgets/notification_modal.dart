import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/notification_service.dart';

class NotificationCenterModal extends StatefulWidget {
  final VoidCallback onClose;
  final String lang;

  const NotificationCenterModal({
    super.key,
    required this.onClose,
    required this.lang,
  });

  @override
  State<NotificationCenterModal> createState() =>
      _NotificationCenterModalState();
}

class _NotificationCenterModalState extends State<NotificationCenterModal> {
  final _service = NotificationService();
  String _selectedFilter = 'ALL'; // ALL | DIRECTOR | LESSON | ATTENDANCE

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'Жаңа ғана';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин бұрын';
    if (diff.inHours < 24) return '${diff.inHours} сағ бұрын';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'DIRECTOR':
        return const Color(0xFF6366F1); // Indigo
      case 'URGENT':
        return AppColors.danger;
      case 'LESSON':
        return Colors.orange.shade700;
      case 'ATTENDANCE':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'DIRECTOR':
        return Icons.campaign_rounded;
      case 'URGENT':
        return Icons.warning_amber_rounded;
      case 'LESSON':
        return Icons.school_rounded;
      case 'ATTENDANCE':
        return Icons.verified_user_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'DIRECTOR':
        return 'Директор';
      case 'URGENT':
        return 'Маңызды';
      case 'LESSON':
        return 'Сабақ';
      case 'ATTENDANCE':
        return 'Face ID / Қатысу';
      default:
        return 'Хабарлама';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPushGranted = _service.pushPermission == 'granted';

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: SafeArea(
        child: Center(
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxHeight: 620),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Modal Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Хабарламалар орталығы',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Push & In-App Notification Center',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ── OS Push Notification Banner ──
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPushGranted
                        ? Colors.green.shade50
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPushGranted
                          ? Colors.green.shade200
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPushGranted
                            ? Icons.check_circle_rounded
                            : Icons.phone_android_rounded,
                        color: isPushGranted
                            ? Colors.green.shade700
                            : const Color(0xFF2563EB),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPushGranted
                                  ? 'Телефон Push-хабарламасы белсенді'
                                  : 'Телефон экранына Push-ты қосу',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPushGranted
                                    ? Colors.green.shade900
                                    : const Color(0xFF1E3A8A),
                              ),
                            ),
                            Text(
                              isPushGranted
                                  ? 'Хабарламалар телефон шторкасына түседі'
                                  : 'Дыбыспен телефон панеліне шығуы үшін рұқсат беріңіз',
                              style: TextStyle(
                                fontSize: 10,
                                color: isPushGranted
                                    ? Colors.green.shade800
                                    : const Color(0xFF1E40AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (!isPushGranted)
                        ElevatedButton(
                          onPressed: () async {
                            final granted =
                                await _service.requestPushPermission();
                            if (mounted) setState(() {});
                            if (granted) {
                              await _service.sendNotification(
                                title: '🔔 SmartAttend Push белсенді!',
                                body:
                                    'Сіз телефоннан нақты уақыттағы Push-хабарламаларды сәтті қостыңыз.',
                                type: 'DIRECTOR',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Қосу',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else
                        TextButton.icon(
                          onPressed: () async {
                            await _service.sendNotification(
                              title: '🔔 Тест Push: SmartAttend',
                              body:
                                  'Телефон шторкасындағы хабарлама 100% сәтті жұмыс істеп тұр! ✅',
                              type: 'ATTENDANCE',
                            );
                            if (mounted) setState(() {});
                          },
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text('Тест Push', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green.shade800,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Filter Pills ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'Барлығы'),
                      const SizedBox(width: 6),
                      _buildFilterChip('DIRECTOR', 'Директордан'),
                      const SizedBox(width: 6),
                      _buildFilterChip('LESSON', 'Сабақтар'),
                      const SizedBox(width: 6),
                      _buildFilterChip('ATTENDANCE', 'Face ID'),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ── Notifications List ──
                Expanded(
                  child: ValueListenableBuilder<List<AppNotification>>(
                    valueListenable: _service.notificationsNotifier,
                    builder: (context, notifs, _) {
                      final filtered = _selectedFilter == 'ALL'
                          ? notifs
                          : notifs
                              .where((n) => n.type == _selectedFilter)
                              .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                                  size: 48),
                              const SizedBox(height: 10),
                              Text(
                                'Хабарламалар жоқ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final n = filtered[idx];
                          final typeColor = _getTypeColor(n.type);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? AppColors.background.withValues(alpha: 0.6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: n.isRead
                                    ? AppColors.separator
                                    : typeColor.withValues(alpha: 0.35),
                                width: n.isRead ? 1 : 1.5,
                              ),
                              boxShadow: n.isRead
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: typeColor.withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getTypeIcon(n.type),
                                    color: typeColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: typeColor
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getTypeLabel(n.type),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: typeColor,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatTime(n.time),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        n.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: n.isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        n.body,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                // ── Footer ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _service.markAllAsRead();
                          setState(() {});
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Барлығын оқылды деу',
                            style: TextStyle(fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _service.clearAll();
                          setState(() {});
                        },
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.danger),
                        label: const Text('Тазалау',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
