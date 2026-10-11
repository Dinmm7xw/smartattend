// SmartAttend — Dean Dashboard (clean iOS redesign, 3-lang)

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/theme.dart';
import '../constants/i18n.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'campus_map_screen.dart';
import '../widgets/smart_ai_dialog.dart';
import '../widgets/user_avatar.dart';
import 'profile_screen.dart';

class DeanDashboard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;
  final VoidCallback onCycleLang;
  final String lang;

  const DeanDashboard({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onCycleLang,
    required this.lang,
  });

  @override
  State<DeanDashboard> createState() => _DeanDashboardState();
}

class _DeanDashboardState extends State<DeanDashboard> {
  DeanStats? _stats;
  bool _loading = true;

  Map<String, String> get t => translations[widget.lang] ?? translations['kk']!;

  @override
  void initState() { super.initState(); _loadStats(); }

  Future<void> _loadStats() async {
    final stats = await ApiService.getDeanStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  Future<void> _exportCSV() async {
    final url = Uri.parse(ApiService.getExportCsvUrl());
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: CircularProgressIndicator(color: AppColors.dean),
                ))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  _buildWelcomeCard(),
                  const SizedBox(height: 14),
                  _buildCampusMapBanner(),
                  const SizedBox(height: 14),
                  _buildAIScheduleBanner(),
                  const SizedBox(height: 14),
                  if (_stats != null) ...[
                    _buildStatsGrid(_stats!),
                    const SizedBox(height: 14),
                    _buildDepartmentCard(_stats!),
                    const SizedBox(height: 14),
                    if (_stats!.sosPending > 0) _buildSOSBanner(_stats!),
                    if (_stats!.sosPending > 0) const SizedBox(height: 14),
                    _buildExportBtn(),
                  ],
                  const SizedBox(height: 80),
                ]),
        )),
      ])),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dean_ai_fab',
        onPressed: () {
          SmartAIDialog.show(
            context,
            userRole: widget.user.role,
            userName: widget.user.name,
            lang: widget.lang,
          );
        },
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        label: Text(
          widget.lang == 'ru' ? 'AI Ассистент' : 'AI Көмекші',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        UserAvatar(
          name: widget.user.name,
          size: 40,
          color: AppColors.dean,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProfileScreen(user: widget.user, lang: widget.lang, onLogout: widget.onLogout),
          )),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SmartAttend', style: TextStyle(fontFamily: AppTextStyles.font, fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(widget.user.department ?? '', style: AppTextStyles.caption1),
        ])),
        // Campus Map Icon Button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CampusMapScreen(lang: widget.lang, initialFloor: 2),
              ),
            );
          },
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.deanLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: const Icon(Icons.map_outlined, color: AppColors.dean, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: widget.onCycleLang,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.deanLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(
              supportedLanguages.firstWhere((l) => l['code'] == widget.lang)['label'] ?? '',
              style: const TextStyle(fontFamily: AppTextStyles.font, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.dean),
            ),
          ),
        ),
        const SizedBox(width: 8),
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

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dean,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [BoxShadow(color: AppColors.dean.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
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
            child: const Text('DEAN OFFICE', style: TextStyle(fontFamily: AppTextStyles.font, color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ])),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: const Icon(Icons.business_rounded, color: Colors.white, size: 26),
        ),
      ]),
    );
  }

  Widget _buildCampusMapBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.map_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lang == 'kk'
                          ? 'Интерактивті кампус картасы'
                          : (widget.lang == 'en' ? 'Interactive Campus Map' : 'Интерактивная карта кампуса'),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.font,
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.lang == 'kk'
                          ? 'Кабинеттер мониторингі: сабақ, оқытушы, қатысу'
                          : (widget.lang == 'en'
                              ? 'Live room inspection: lesson, teacher, attendance'
                              : 'Мониторинг аудиторий: урок, препод, посещаемость'),
                      style: TextStyle(
                        fontFamily: AppTextStyles.font,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CampusMapScreen(
                      lang: widget.lang,
                      initialFloor: 2,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.apartment_rounded, size: 18),
              label: Text(
                widget.lang == 'kk'
                    ? 'Кабинеттерді тексеру (1-3 қабаттар)'
                    : (widget.lang == 'en'
                        ? 'Inspect Classrooms (Floors 1-3)'
                        : 'Инспекция аудиторий (1-3 этажи)'),
                style: const TextStyle(
                  fontFamily: AppTextStyles.font,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF312E81),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIScheduleBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.lang == 'kk'
                              ? 'ИИ-Кесте енгізу'
                              : (widget.lang == 'en' ? 'AI Schedule OCR' : 'ИИ-Ввод расписания'),
                          style: const TextStyle(
                            fontFamily: AppTextStyles.font,
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Vision AI',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.lang == 'kk'
                          ? 'Кесте фотосын жүктеңіз — Gemini сабақтарды автоматты базаға қосады'
                          : (widget.lang == 'en'
                              ? 'Upload schedule photo — Gemini parses and saves lessons to DB'
                              : 'Загрузите фото расписания — Gemini распознает и сохранит в базу'),
                      style: TextStyle(
                        fontFamily: AppTextStyles.font,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                SmartAIDialog.show(
                  context,
                  userRole: widget.user.role,
                  userName: widget.user.name,
                  lang: widget.lang,
                );
              },
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: Text(
                widget.lang == 'kk'
                    ? '📸 Кесте фотосын тану және қосу'
                    : (widget.lang == 'en'
                        ? '📸 Scan Schedule Photo with AI'
                        : '📸 Распознать фото расписания через ИИ'),
                style: const TextStyle(
                  fontFamily: AppTextStyles.font,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DeanStats stats) {
    final items = [
      _SI(label: t['total_students'] ?? '', value: stats.totalStudents.toString(), icon: Icons.people_outline_rounded, color: AppColors.primary, bg: AppColors.primaryLight),
      _SI(label: t['avg_attendance'] ?? '', value: '${stats.avgAttendance.toStringAsFixed(1)}%', icon: Icons.trending_up_rounded, color: AppColors.success, bg: AppColors.successLight),
      _SI(label: t['lessons_today'] ?? '', value: stats.totalLessonsToday.toString(), icon: Icons.calendar_today_rounded, color: AppColors.teacher, bg: AppColors.teacherLight),
      _SI(label: t['sos_pending'] ?? '', value: stats.sosPending.toString(), icon: Icons.warning_amber_rounded, color: AppColors.danger, bg: AppColors.dangerLight),
    ];
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.65,
      children: items.map(_buildStatCard).toList(),
    );
  }

  Widget _buildStatCard(_SI item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: item.bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(item.icon, color: item.color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(item.value, style: TextStyle(fontFamily: AppTextStyles.font, fontSize: 20, fontWeight: FontWeight.w700, color: item.color)),
          Text(item.label, style: AppTextStyles.caption2, maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _buildDepartmentCard(DeanStats stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t['by_department'] ?? '', style: AppTextStyles.headline),
        const SizedBox(height: 14),
        ...stats.departmentStats.map((dept) {
          final name = dept['name']?.toString() ?? dept['group']?.toString() ?? 'Топ';
          final num? rawAttendance = dept['attendance'] as num?;
          final int total = (dept['total_students'] as num?)?.toInt() ?? (dept['total'] as num?)?.toInt() ?? 0;
          final int attended = (dept['attended'] as num?)?.toInt() ?? 0;
          final double rate = rawAttendance?.toDouble() ?? (total > 0 ? (attended / total) * 100 : 0.0);
          final color = rate >= 90 ? AppColors.success : rate >= 80 ? AppColors.primary : AppColors.warning;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(name, style: AppTextStyles.footnote.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                Text('${rate.toStringAsFixed(1)}%', style: TextStyle(fontFamily: AppTextStyles.font, fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: rate / 100,
                  backgroundColor: AppColors.separator,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 7,
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildSOSBanner(DeanStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 26),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${stats.sosPending} ${t['sos_pending'] ?? ''}!',
              style: const TextStyle(fontFamily: AppTextStyles.font, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger)),
          Text(t['sos_subtitle'] ?? '', style: AppTextStyles.caption1),
        ])),
      ]),
    );
  }

  Widget _buildExportBtn() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _exportCSV,
        icon: const Icon(Icons.download_rounded, size: 20),
        label: Text(t['export_csv'] ?? ''),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
      ),
    );
  }
}

class _SI {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _SI({required this.label, required this.value, required this.icon, required this.color, required this.bg});
}
