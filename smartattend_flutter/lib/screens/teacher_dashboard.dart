// SmartAttend — Teacher Dashboard (clean iOS redesign, 3-lang)

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../constants/theme.dart';
import '../constants/i18n.dart';
import '../models/models.dart';
import '../services/page_loader_service.dart';
import 'campus_map_screen.dart';
import 'profile_screen.dart';
import '../widgets/user_avatar.dart';

class TeacherDashboard extends StatefulWidget {
  final UserModel user;
  final List<LessonModel> lessons;
  final LessonModel? selectedLesson;
  final Function(LessonModel) onSelectLesson;
  final VoidCallback onOpenQRDisplay;
  final VoidCallback onLogout;
  final VoidCallback onCycleLang;
  final String lang;

  const TeacherDashboard({
    super.key,
    required this.user,
    required this.lessons,
    required this.selectedLesson,
    required this.onSelectLesson,
    required this.onOpenQRDisplay,
    required this.onLogout,
    required this.onCycleLang,
    required this.lang,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _attendedNow = 24;
  Timer? _timer;
  int _currentTab = 0;

  Map<String, String> get t => translations[widget.lang] ?? translations['kk']!;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _attendedNow = 18 + Random().nextInt(12));
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: _currentTab == 0 ? _buildDashTab() : _buildLessonsTab()),
        _buildBottomNav(),
      ])),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        // Avatar
        UserAvatar(
          name: widget.user.name,
          size: 40,
          color: AppColors.teacher,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProfileScreen(user: widget.user, lang: widget.lang, onLogout: widget.onLogout),
          )),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SmartAttend', style: TextStyle(fontFamily: AppTextStyles.font, fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(widget.user.department ?? '', style: AppTextStyles.caption1),
        ])),
        // Lang
        GestureDetector(
          onTap: widget.onCycleLang,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(
              supportedLanguages.firstWhere((l) => l['code'] == widget.lang)['label'] ?? '',
              style: const TextStyle(fontFamily: AppTextStyles.font, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Campus Map Button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CampusMapScreen(
                  lang: widget.lang,
                  initialPOI: widget.selectedLesson?.room,
                  initialFloor: 3,
                ),
              ),
            );
          },
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.teacherLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: const Icon(Icons.map_outlined, color: AppColors.teacher, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        // Logout
        GestureDetector(
          onTap: widget.onLogout,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 16),
          ),
        ),
      ]),
    );
  }

  Widget _buildDashTab() {
    final lesson = widget.selectedLesson;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        _buildWelcomeCard(),
        const SizedBox(height: 14),
        if (lesson != null) _buildActiveSessionCard(lesson),
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.teacher,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [BoxShadow(color: AppColors.teacher.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t['welcome'] ?? '', style: TextStyle(fontFamily: AppTextStyles.font, color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
          const SizedBox(height: 4),
          Text(widget.user.name, style: const TextStyle(fontFamily: AppTextStyles.font, color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text('TEACHER', style: const TextStyle(fontFamily: AppTextStyles.font, color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ])),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: const Icon(Icons.cast_for_education_rounded, color: Colors.white, size: 26),
        ),
      ]),
    );
  }

  Widget _buildActiveSessionCard(LessonModel lesson) {
    final total = lesson.totalStudents;
    final rate = (_attendedNow / total * 100).clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(t['active_lesson'] ?? '', style: const TextStyle(fontFamily: AppTextStyles.font, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
            ]),
          ),
          const Spacer(),
          Text(lesson.time, style: AppTextStyles.caption1),
        ]),
        const SizedBox(height: 10),
        Text(lesson.subject, style: AppTextStyles.headline),
        Text('${lesson.room} • ${lesson.group}', style: AppTextStyles.footnote),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$_attendedNow / $total ${t['students_present'] ?? ''}', style: AppTextStyles.footnote),
          Text('${rate.toStringAsFixed(0)}%', style: const TextStyle(fontFamily: AppTextStyles.font, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: AppColors.separator,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            minHeight: 7,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onOpenQRDisplay,
            icon: const Icon(Icons.qr_code_2_rounded, size: 20),
            label: Text(t['generate_qr'] ?? ''),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teacher,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CampusMapScreen(
                    lang: widget.lang,
                    initialPOI: lesson.room,
                    initialFloor: 3,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: Text(
              widget.lang == 'kk'
                  ? 'Кабинетті картадан көру (${lesson.room})'
                  : (widget.lang == 'en'
                      ? 'View room on Map (${lesson.room})'
                      : 'Показать аудиторию на карте (${lesson.room})'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.teacher,
              side: const BorderSide(color: AppColors.teacher, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildLessonsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text(t['today_lessons'] ?? '', style: AppTextStyles.headline),
        const SizedBox(height: 12),
        ...widget.lessons.map((l) => _buildLessonRow(l)),
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _buildLessonRow(LessonModel lesson) {
    final isSelected = widget.selectedLesson?.id == lesson.id;
    return GestureDetector(
      onTap: () => widget.onSelectLesson(lesson),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isSelected ? AppColors.teacher : AppColors.separator, width: isSelected ? 1.5 : 1),
          boxShadow: AppShadows.card,
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: lesson.isActive ? AppColors.successLight : AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.book_outlined, color: lesson.isActive ? AppColors.success : AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lesson.subject, style: AppTextStyles.subheadline.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${lesson.group} • ${lesson.time}', style: AppTextStyles.caption1),
          ])),
          if (lesson.isActive) const Icon(Icons.circle, color: AppColors.success, size: 8),
        ]),
      ),
    );
  }

  Widget _buildBottomNav() {
    final tabs = [
      {'icon': Icons.home_outlined, 'label': t['tab_dashboard'] ?? ''},
      {'icon': Icons.calendar_today_outlined, 'label': t['tab_lessons'] ?? ''},
    ];
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.tabBar),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 4, top: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(tabs.length, (i) {
        final isActive = _currentTab == i;
        return GestureDetector(
          onTap: () {
            if (_currentTab == i) return;
            PageLoaderService().show(lang: widget.lang);
            setState(() => _currentTab = i);
            Future.delayed(const Duration(milliseconds: 260), () {
              PageLoaderService().hide();
            });
          },
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(tabs[i]['icon'] as IconData, color: isActive ? AppColors.teacher : AppColors.textSecondary, size: 24),
            const SizedBox(height: 3),
            Text(tabs[i]['label'] as String,
              style: TextStyle(fontFamily: AppTextStyles.font, fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.teacher : AppColors.textSecondary)),
          ]),
        );
      })),
    );
  }
}
