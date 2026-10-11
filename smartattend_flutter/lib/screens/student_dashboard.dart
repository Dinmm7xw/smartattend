// SmartAttend — Student Scanner Screen (redesigned to match screenshot)
// Layout: Header → Camera/Face Scanner → Recognition Result → Lesson Info → Confirm Button

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../constants/theme.dart';
import '../constants/i18n.dart';
import '../models/models.dart';
import '../widgets/real_map_web.dart';
import '../services/notification_service.dart';
import '../services/page_loader_service.dart';
import '../widgets/smart_ai_dialog.dart';
import '../widgets/user_avatar.dart';
import 'profile_screen.dart';

class StudentDashboard extends StatefulWidget {
  final UserModel user;
  final List<LessonModel> lessons;
  final Set<int> attendedLessons;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenSOS;
  final VoidCallback onOpenExcuse;
  final VoidCallback? onOpenFaceVerify;
  final VoidCallback? onOpenNotifications;
  final VoidCallback onLogout;
  final String lang;

  const StudentDashboard({
    super.key,
    required this.user,
    required this.lessons,
    required this.attendedLessons,
    required this.onOpenScanner,
    required this.onOpenSOS,
    required this.onOpenExcuse,
    this.onOpenFaceVerify,
    this.onOpenNotifications,
    required this.lang,
    required this.onLogout,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  int _currentTab = 0; // 0=scanner, 1=lessons, 2=map, 3=profile
  int _scanStep = 0; // 0=idle, 1=scanning, 2=recognized
  double _accuracy = 0;
  int _timerSec = 0;
  Timer? _scanTimer;
  Timer? _countTimer;
  late AnimationController _scanLineController;
  late AnimationController _pulseController;

  void _switchTab(int index) {
    if (_currentTab == index) return;
    PageLoaderService().show(lang: widget.lang);
    setState(() => _currentTab = index);
    Future.delayed(const Duration(milliseconds: 260), () {
      PageLoaderService().hide();
    });
  }

  Map<String, String> get t => translations[widget.lang] ?? translations['kk']!;

  LessonModel? get activeLesson =>
      widget.lessons.isNotEmpty ? widget.lessons.first : null;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _countTimer?.cancel();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() { _scanStep = 1; _accuracy = 0; _timerSec = 0; });
    _scanTimer?.cancel();
    _countTimer?.cancel();

    // Simulate face recognition
    _scanTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _scanStep = 2;
        _accuracy = 97.0 + Random().nextDouble() * 2.9;
      });
    });

    // Count up timer
    _countTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timerSec++);
    });
  }

  void _confirmAttendance() {
    if (widget.onOpenFaceVerify != null) {
      widget.onOpenFaceVerify!();
    } else {
      widget.onOpenScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _currentTab == 0
                  ? _buildScannerTab()
                  : _currentTab == 1
                      ? _buildLessonsTab()
                      : _currentTab == 2
                          ? _buildMapTab()
                          : _buildProfileTab(),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'student_ai_fab',
        onPressed: () {
          SmartAIDialog.show(
            context,
            userRole: widget.user.role,
            userName: widget.user.name,
            lang: widget.lang,
            onNavigateToFloor: (floor, room) {
              _switchTab(2); // Open map tab
            },
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        label: Text(
          widget.lang == 'ru' ? 'AI Гид' : 'AI Навигатор',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Avatar
          UserAvatar(
            name: widget.user.name,
            size: 40,
            color: AppColors.primary,
            onTap: () => _switchTab(3),
          ),
          const SizedBox(width: 10),
          // Title block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SmartAttend',
                    style: TextStyle(
                      fontFamily: AppTextStyles.font,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                Text(
                  '${widget.user.group ?? ''} • ${activeLesson?.room ?? ''}',
                  style: AppTextStyles.caption1,
                ),
              ],
            ),
          ),
          // Status pill & Map shortcut
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppColors.primary, size: 22),
            tooltip: t['tab_map'] ?? 'Карта',
            onPressed: () => _switchTab(2),
          ),
          // Notification Bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 23),
                tooltip: 'Хабарламалар',
                onPressed: widget.onOpenNotifications,
              ),
              ValueListenableBuilder<List<AppNotification>>(
                valueListenable: NotificationService().notificationsNotifier,
                builder: (context, notifs, _) {
                  final unread = notifs.where((n) => !n.isRead).length;
                  if (unread == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (activeLesson != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    t['on_time'] ?? '',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.font,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Scanner Tab ───────────────────────────────────────────
  Widget _buildScannerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildCameraCard(),
          const SizedBox(height: 14),
          if (_scanStep == 2) _buildRecognitionResult(),
          if (_scanStep == 2) const SizedBox(height: 14),
          if (activeLesson != null) _buildCurrentLessonCard(),
          const SizedBox(height: 20),
          _buildConfirmButton(),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildCameraCard() {
    return GestureDetector(
      onTap: _confirmAttendance,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Camera indicator
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Веб-камера Face ID (Тікелей сканерлеу үшін басыңыз)',
                  style: AppTextStyles.caption1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),

          // Face scanner frame
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Face oval guide
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.separator,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _scanStep == 2
                      ? null
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                        color: AppColors.textTertiary,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 36),
                                Container(width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                        color: AppColors.textTertiary,
                                        shape: BoxShape.circle)),
                              ],
                            ),
                          ],
                        ),
                ),

                // Scanning dashed line
                if (_scanStep == 1)
                  AnimatedBuilder(
                    animation: _scanLineController,
                    builder: (ctx, _) => Positioned(
                      top: 20 + (_scanLineController.value * 180),
                      child: _buildDashedLine(),
                    ),
                  ),

                // Success checkmark
                if (_scanStep == 2)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 70,
                    ),
                  ),

                // Corner brackets
                ..._buildCornerBrackets(
                    _scanStep == 2 ? AppColors.success : AppColors.scanFrame),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Status text
          Text(
            'Бетті сканерлеу үшін түртіңіз (YuNet + SFace)',
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildDashedLine() {
    return SizedBox(
      width: 180,
      child: Row(
        children: List.generate(12, (i) => Expanded(
          child: Container(
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: i.isEven ? AppColors.scanLine : Colors.transparent,
          ),
        )),
      ),
    );
  }

  List<Widget> _buildCornerBrackets(Color color) {
    const size = 22.0;
    const stroke = 2.5;
    const pos = 0.0;

    return [
      Positioned(top: pos, left: pos, child: _corner(color, size, stroke, true, true)),
      Positioned(top: pos, right: pos, child: _corner(color, size, stroke, true, false)),
      Positioned(bottom: pos, left: pos, child: _corner(color, size, stroke, false, true)),
      Positioned(bottom: pos, right: pos, child: _corner(color, size, stroke, false, false)),
    ];
  }

  Widget _corner(Color c, double s, double w, bool top, bool left) {
    return SizedBox(
      width: s, height: s,
      child: CustomPaint(painter: _CornerPainter(c, w, top, left)),
    );
  }

  Widget _buildRecognitionResult() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['face_recognized'] ?? '',
                    style: AppTextStyles.headline),
                Text('${t['accuracy'] ?? ''} ${_accuracy.toStringAsFixed(1)}%',
                    style: AppTextStyles.footnote),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$_timerSec ${t['sec'] ?? ''}',
              style: TextStyle(
                fontFamily: AppTextStyles.font,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLessonCard() {
    final lesson = activeLesson!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t['current_lesson'] ?? '', style: AppTextStyles.caption1),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(lesson.subject,
                    style: AppTextStyles.headline),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(t['on_time'] ?? '',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.font,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${t['teacher_label'] ?? ''}: ${lesson.teacher}',
            style: AppTextStyles.footnote,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _confirmAttendance,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.button,
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.face_retouching_natural, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Face ID арқылы қатысуды растау',
                style: TextStyle(
                  fontFamily: AppTextStyles.font,
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickActionBtn(
            icon: Icons.warning_amber_rounded,
            label: t['sos_signal'] ?? '',
            color: AppColors.danger,
            bg: AppColors.dangerLight,
            onTap: widget.onOpenSOS,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickActionBtn(
            icon: Icons.medical_services_outlined,
            label: t['medical_excuse'] ?? '',
            color: AppColors.warning,
            bg: AppColors.warningLight,
            onTap: widget.onOpenExcuse,
          ),
        ),
      ],
    );
  }

  Widget _quickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontFamily: AppTextStyles.font,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Lessons Tab ───────────────────────────────────────────
  Widget _buildLessonsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Stats row
          Row(
            children: [
              Expanded(child: _statCard(
                label: t['attendance_rate'] ?? '',
                value: '${widget.lessons.isEmpty ? 0 : (widget.attendedLessons.length / widget.lessons.length * 100).toStringAsFixed(0)}%',
                color: AppColors.primary,
              )),
              const SizedBox(width: 12),
              Expanded(child: _statCard(
                label: t['attended'] ?? '',
                value: '${widget.attendedLessons.length}/${widget.lessons.length}',
                color: AppColors.success,
              )),
            ],
          ),
          const SizedBox(height: 20),
          Text(t['today_lessons'] ?? '', style: AppTextStyles.headline),
          const SizedBox(height: 12),
          if (widget.lessons.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(t['no_lessons'] ?? '', style: AppTextStyles.subheadline),
              ),
            )
          else
            ...widget.lessons.map((l) => _lessonCard(l)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _statCard({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                fontFamily: AppTextStyles.font,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption1),
        ],
      ),
    );
  }

  Widget _lessonCard(LessonModel lesson) {
    final isAttended = widget.attendedLessons.contains(lesson.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: lesson.isActive ? AppColors.primaryLight : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            Icons.book_outlined,
            color: lesson.isActive ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          ),
        ),
        title: Text(lesson.subject, style: AppTextStyles.headline.copyWith(fontSize: 15)),
        subtitle: Text('${lesson.room} • ${lesson.time}', style: AppTextStyles.caption1),
        trailing: isAttended
            ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
            : lesson.isActive
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('LIVE',
                        style: TextStyle(
                          fontFamily: AppTextStyles.font,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        )),
                  )
                : null,
      ),
    );
  }

  // ── Campus Map Tab ───────────────────────────────────────


  Widget _buildMapTab() {
    return const RealCollegeMapView();
  }

  // ── Profile Tab ───────────────────────────────────────────
  Widget _buildProfileTab() {
    final studentId = widget.user.studentId ?? 'STU-2405-03';
    final groupName = widget.user.group ?? 'БҚ2405';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. DIGITAL STUDENT ID CARD (APPLE WALLET STYLE) ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A192F), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: College & Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'AITU COLLEGE • ҚАЗАҚСТАН',
                          style: TextStyle(
                            fontFamily: AppTextStyles.font,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Color(0xFF93C5FD),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Студенттік Билет',
                          style: TextStyle(
                            fontFamily: AppTextStyles.font,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Middle: Avatar + Student Info
                Row(
                  children: [
                    Stack(
                      children: [
                        UserAvatar(
                          name: widget.user.name,
                          size: 58,
                          color: AppColors.primary,
                          onTap: () => pickAndUploadAvatar(context, widget.lang),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.font,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Топ: $groupName • 2-курс',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.font,
                              fontSize: 12,
                              color: Color(0xFFBFDBFE),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Meta row: ID & IIN
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ID / БИЛЕТ №',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            studentId,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'МАМАНДЫҚ',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ақпараттық қауіпсіздік',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Turnstile QR button
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Турникет динамикалық QR коды жаңартылды ✅'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.qr_code_2, size: 20, color: AppColors.textPrimary),
                        SizedBox(width: 8),
                        Text(
                          'Турникет және Кітапхана QR (Басу)',
                          style: TextStyle(
                            fontFamily: AppTextStyles.font,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. ATTENDANCE KPI & GAUGE ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Қатысу көрсеткіші',
                          style: TextStyle(
                            fontFamily: AppTextStyles.font,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Үздік нәтиже',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    // Percentage Circle
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 6),
                      ),
                      child: const Center(
                        child: Text(
                          '94.5%',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Metric Tiles
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _metricBox('Жалпы пар', '148', AppColors.textPrimary),
                              const SizedBox(width: 8),
                              _metricBox('Қатысқан', '140', AppColors.success),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _metricBox('Кешіккен', '4 рет', AppColors.warning),
                              const SizedBox(width: 8),
                              _metricBox('Себепсіз НБ', '0 пар', AppColors.textPrimary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // AI Risk Banner
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.psychology_outlined, color: Color(0xFF16A34A), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ИИ-Қауіп болжамы (Random Forest): 8% Төмен (Қалыпты)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 3. BIOMETRICS & SECURITY ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Қауіпсіздік және Face ID',
                  style: TextStyle(
                    fontFamily: AppTextStyles.font,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _securityRow(
                  Icons.face_retouching_natural,
                  'Face ID биометриясы',
                  'Белсенді және расталған (128-вектор)',
                  'Қайта тапсыру',
                  () => (widget.onOpenFaceVerify != null) ? widget.onOpenFaceVerify!() : _startScan(),
                ),
                const Divider(height: 16),
                _securityRow(
                  Icons.photo_camera_outlined,
                  widget.lang == 'ru' ? 'Фото профиля' : widget.lang == 'en' ? 'Profile photo' : 'Профиль фотосы',
                  widget.lang == 'ru' ? 'Загрузить новое фото' : widget.lang == 'en' ? 'Upload a new photo' : 'Жаңа фото жүктеу',
                  widget.lang == 'ru' ? 'Изменить' : widget.lang == 'en' ? 'Change' : 'Өзгерту',
                  () => pickAndUploadAvatar(context, widget.lang),
                ),
                const Divider(height: 16),
                _securityRow(
                  Icons.lock_outline,
                  'Жеке құпия сөз',
                  widget.lang == 'ru' ? 'Изменить пароль' : widget.lang == 'en' ? 'Change password' : 'Құпия сөзді өзгерту',
                  'Өзгерту',
                  () => showChangePasswordSheet(context, widget.lang),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 4. PARENT LINK (S-ATA-ANA) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ата-ана байланысы (S-Ata-Ana)',
                      style: TextStyle(
                        fontFamily: AppTextStyles.font,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ЭЦП Байланысқан',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Байтоморова Гүлнар Қасымқызы (Анасы)',
                  style: TextStyle(
                    fontFamily: AppTextStyles.font,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '📄 Соңғы расписка: 28.09 сағат 14:00 дәрігерлік қабылдау (Үйден 7.4 км, ЭЦП RSA-256 расталған) ✅',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => confirmLogout(context, widget.lang, widget.onLogout),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                widget.lang == 'ru' ? 'Выйти' : widget.lang == 'en' ? 'Log out' : 'Шығу',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerLight,
                foregroundColor: AppColors.danger,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _metricBox(String title, String val, Color valColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: valColor)),
          ],
        ),
      ),
    );
  }

  Widget _securityRow(IconData icon, String title, String sub, String btnText, VoidCallback onTap) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(sub, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(btnText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────
  Widget _buildBottomNav() {
    final tabs = [
      {'icon': Icons.qr_code_scanner, 'label': t['tab_scanner'] ?? ''},
      {'icon': Icons.calendar_today_outlined, 'label': t['tab_lessons'] ?? ''},
      {'icon': Icons.map_outlined, 'label': t['tab_map'] ?? 'Карта'},
      {'icon': Icons.person_outline, 'label': t['tab_profile'] ?? ''},
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.tabBar,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 10,
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _currentTab == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _switchTab(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[i]['icon'] as IconData,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tabs[i]['label'] as String,
                      style: TextStyle(
                        fontFamily: AppTextStyles.font,
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Corner Bracket Painter ────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isTop, isLeft;

  _CornerPainter(this.color, this.strokeWidth, this.isTop, this.isLeft);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final s = size.width;
    if (isTop && isLeft) {
      canvas.drawLine(Offset(0, s), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(s, 0), paint);
    } else if (isTop && !isLeft) {
      canvas.drawLine(Offset(s, s), Offset(s, 0), paint);
      canvas.drawLine(Offset(s, 0), const Offset(0, 0), paint);
    } else if (!isTop && isLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(0, s), paint);
      canvas.drawLine(Offset(0, s), Offset(s, s), paint);
    } else {
      canvas.drawLine(Offset(s, 0), Offset(s, s), paint);
      canvas.drawLine(Offset(s, s), Offset(0, s), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => oldDelegate.color != color;
}


