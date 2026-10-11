// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// SmartAttend — Director Executive Dashboard (AITU Management Console)
// Features:
// 1. College KPIs & Strategic Attendance Overview
// 2. Broadcast & Targeted Personal Notifications (Барлығына немесе Жеке тұлғаға)
// 3. HR Staff Requests (Увольнение, отпуск, командировки - утвердить/отклонить)
// 4. Grant-Loss Risk Monitoring (Гранттан айырылу қаупі)
// 5. Ministry of Education (ҰОБД / МОН РК) Official Export
// 6. NO SOS Panel (as explicitly requested by user)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/page_loader_service.dart';
import '../utils/platform_helper.dart';
import 'campus_map_screen.dart';

class DirectorDashboard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;
  final VoidCallback onCycleLang;
  final String lang;

  const DirectorDashboard({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onCycleLang,
    required this.lang,
  });

  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _StaffRequest {
  final String id;
  final String employeeName;
  final String role;
  final String department;
  final String type; // 'resignation' | 'vacation' | 'business_trip'
  final String title;
  final String details;
  final String date;
  String status; // 'pending' | 'approved' | 'rejected' | 'interview'

  _StaffRequest({
    required this.id,
    required this.employeeName,
    required this.role,
    required this.department,
    required this.type,
    required this.title,
    required this.details,
    required this.date,
    this.status = 'pending',
  });
}

class _SentNotification {
  final String id;
  final String targetType; // 'all' | 'teachers' | 'students' | 'personal'
  final String recipientName;
  final String title;
  final String message;
  final String priority; // 'normal' | 'important' | 'urgent'
  final String timestamp;

  _SentNotification({
    required this.id,
    required this.targetType,
    required this.recipientName,
    required this.title,
    required this.message,
    required this.priority,
    required this.timestamp,
  });
}

class _DirectorDashboardState extends State<DirectorDashboard> {
  int _activeNav = 0; // 0=Overview & HR, 1=Notifications, 2=Grant Risks, 3=User Management
  List<Map<String, dynamic>> _dbUsers = [];
  List<Map<String, dynamic>> _dbApplications = [];
  bool _isLoadingUsers = false;
  bool _isLoadingApps = false;
  int _dbSubTab = 0; // 0: Топтық өтініштер (Бекіту), 1: Базадағы қолданушылар

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _isLoadingApps = true;
    });
    final list = await ApiService.getUsersList();
    final apps = await ApiService.getGroupApplications();
    if (mounted) {
      setState(() {
        _dbUsers = list;
        _dbApplications = apps;
        _isLoadingUsers = false;
        _isLoadingApps = false;
      });
    }
  }

  // ── Notification Form State ───────────────────────────────
  String _targetMode = 'all'; // 'all' | 'teachers' | 'students' | 'personal'
  String _selectedRecipient = 'Калниязов А.А. (Оқытушы)';
  String _selectedPriority = 'normal';
  final TextEditingController _notifTitleCtrl = TextEditingController();
  final TextEditingController _notifMsgCtrl = TextEditingController();

  final List<String> _availableRecipients = const [
    'Калниязов А.А. (Оқытушы, IT зертханасы)',
    'Билал Д.Д. (Оқытушы, Серверлік жүйелер)',
    'Ахметова Е.З. (Оқытушы, Cisco Академиясы)',
    'Талдаубек Арай (Бас куратор)',
    'Байтомор Дінмұхаммед (Студент, БҚ2405)',
    'Әлиев Санжар (Студент, БҚ2405)',
    'Нұрланқызы Амина (Студент, ПО2501)',
  ];

  // ── HR Requests State ─────────────────────────────────────
  final List<_StaffRequest> _hrRequests = [
    _StaffRequest(
      id: 'HR-101',
      employeeName: 'Калниязов А.А.',
      role: 'Аға оқытушы, Мобильді әзірлеу зертханасы',
      department: 'Компьютерлік инженерия кафедрасы',
      type: 'resignation',
      title: 'Жұмыстан өз еркімен босату туралы өтініш (Заявление на увольнение)',
      details:
          'Халықаралық IT стартап жобасына жетекшілік етуіме байланысты ағымдағы айдың 25-і күнінен бастап қызметімнен босатуыңызды сұраймын.',
      date: '09.10.2026',
      status: 'pending',
    ),
    _StaffRequest(
      id: 'HR-102',
      employeeName: 'Ахметова Е.З.',
      role: 'Оқытушы, Cisco Желілік Академиясы',
      department: 'Киберқауіпсіздік кафедрасы',
      type: 'vacation',
      title: 'Жылдық еңбек демалысын беру туралы өтініш',
      details:
          '2026 жылғы 15 қазаннан 28 қазанға дейін 14 күнтізбелік күнге кезекті ақылы еңбек демалысын беруіңізді сұраймын.',
      date: '08.10.2026',
      status: 'pending',
    ),
    _StaffRequest(
      id: 'HR-103',
      employeeName: 'Билал Д.Д.',
      role: 'Оқытушы, Серверлік архитектуралар',
      department: 'Ақпараттық жүйелер кафедрасы',
      type: 'business_trip',
      title: 'Ғылыми іссапарға жіберу туралы өтініш (Алматы, IT Forum)',
      details:
          'Digital Bridge 2026 форумына AITU атынан қатысу үшін 3 күндік ғылыми іссапарды ресімдеуіңізді сұраймын.',
      date: '07.10.2026',
      status: 'approved',
    ),
  ];

  // ── Sent Notifications History ────────────────────────────
  final List<_SentNotification> _sentNotifications = [
    _SentNotification(
      id: 'NOTIF-01',
      targetType: 'all',
      recipientName: 'Барлық студенттер мен оқытушыларға',
      title: 'Аралық бақылау (Midterm) кестесі бекітілді',
      message: 'Барлық топтар сабақ кестесі бойынша SmartAttend жүйесінде толық тіркелуі тиіс.',
      priority: 'important',
      timestamp: 'Бүгін, 09:30',
    ),
    _SentNotification(
      id: 'NOTIF-02',
      targetType: 'personal',
      recipientName: 'Калниязов А.А.',
      title: 'Оқу әдістемелік кеңес жиналысы',
      message: 'Бүгін сағат 16:00-де 210 аудиторияда директорат кабинетіне шақырыласыз.',
      priority: 'urgent',
      timestamp: 'Кеше, 15:45',
    ),
  ];

  @override
  void dispose() {
    _notifTitleCtrl.dispose();
    _notifMsgCtrl.dispose();
    super.dispose();
  }

  void _sendNotification() {
    final title = _notifTitleCtrl.text.trim();
    final msg = _notifMsgCtrl.text.trim();
    if (title.isEmpty || msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Хабарлама тақырыбы мен мәтінін толтырыңыз!'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    String recipient;
    if (_targetMode == 'all') {
      recipient = 'Барлық студенттер мен оқытушыларға';
    } else if (_targetMode == 'teachers') {
      recipient = 'Барлық оқытушылар құрамына (86 оқытушы)';
    } else if (_targetMode == 'students') {
      recipient = 'Барлық студенттерге (1,420 студент)';
    } else {
      recipient = _selectedRecipient;
    }

    setState(() {
      _sentNotifications.insert(
        0,
        _SentNotification(
          id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          targetType: _targetMode,
          recipientName: recipient,
          title: title,
          message: msg,
          priority: _selectedPriority,
          timestamp: 'Қазір ғана',
        ),
      );
      _notifTitleCtrl.clear();
      _notifMsgCtrl.clear();
    });

    NotificationService().sendNotification(
      title: '📢 $title',
      body: msg,
      type: _selectedPriority == 'urgent' ? 'URGENT' : 'DIRECTOR',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _targetMode == 'personal'
                    ? 'Жеке хабарлама жіберілді: $recipient'
                    : 'Жалпы хабарлама сәтті таратылды!',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleStaffAction(_StaffRequest req, String action) {
    setState(() {
      req.status = action;
    });

    String actionMsg;
    if (action == 'approved') {
      actionMsg = '${req.employeeName} өтініші дирекция тарапынан БЕКІТІЛДІ (қол қойылды).';
    } else if (action == 'rejected') {
      actionMsg = '${req.employeeName} өтінішіне рұқсат берілмеді (ҚАБЫЛДАНБАДЫ).';
    } else {
      actionMsg = '${req.employeeName} директордың жеке сұхбатына шақырылды.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(actionMsg),
        backgroundColor: action == 'approved'
            ? const Color(0xFF10B981)
            : (action == 'rejected' ? const Color(0xFFEF4444) : const Color(0xFF0062FF)),
      ),
    );
  }

  void _exportMinistryReport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_outlined, color: Color(0xFF0062FF), size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'ҰОБД / МОН РК Ресми Экспорт',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Қазақстан Республикасы Оқу-ағарту министрлігі ҰОБД талаптарына сәйкес толық колледж қатысу ведомосы дайын:',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Академиялық кезең:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('2026 Күзгі семестр', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Студенттер саны:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('1,420 студент', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Орташа қатысу:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('94.2% (Жоғары)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Цифрлық қолтаңба:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('ЭЦП AITU RSA-2048', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0062FF))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Жабу', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ҰОБД мемлекеттік форматында (AITU_Attendance_2026.xlsx) жүктелді!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Excel / PDF Жүктеу'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0062FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildExecutiveHeader(),
            _buildTopTabs(),
            Expanded(
              child: _activeNav == 0
                  ? _buildOverviewAndHrTab()
                  : _activeNav == 1
                      ? _buildNotificationsTab()
                      : _activeNav == 2
                          ? _buildGrantRiskTab()
                          : _buildUserManagementTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Executive Header ──────────────────────────────────────
  Widget _buildExecutiveHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Director Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A192F), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0A192F),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.account_balance_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Director Title & Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Text(
                        'ДИРЕКТОР',
                        style: TextStyle(
                          color: Color(0xFF0062FF),
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'AITU Колледж Басқармасы • Жоғары басшылық',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Interactive Map Shortcut
          IconButton(
            tooltip: 'Кампус картасы',
            icon: const Icon(Icons.map_outlined, color: Color(0xFF0062FF), size: 22),
            onPressed: () {
              PageLoaderService().show(lang: widget.lang);
              Future.delayed(const Duration(milliseconds: 220), () {
                PageLoaderService().hide();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CampusMapScreen(lang: widget.lang, initialFloor: 2),
                  ),
                );
              });
            },
          ),
          // Language Switcher
          GestureDetector(
            onTap: widget.onCycleLang,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                widget.lang.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF0062FF),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Logout Button
          IconButton(
            tooltip: 'Шығу',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 20),
            onPressed: widget.onLogout,
          ),
        ],
      ),
    );
  }

  // ── Top Navigation Tabs ────────────────────────────────────
  Widget _buildTopTabs() {
    final pendingCount = _hrRequests.where((r) => r.status == 'pending').length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          _navTab(
            index: 0,
            label: 'Бақылау & HR',
            icon: Icons.dashboard_customize_rounded,
            badge: pendingCount > 0 ? '$pendingCount' : null,
          ),
          const SizedBox(width: 8),
          _navTab(
            index: 1,
            label: 'Хабарламалар',
            icon: Icons.campaign_rounded,
          ),
          const SizedBox(width: 8),
          _navTab(
            index: 2,
            label: 'Грант қаупі',
            icon: Icons.warning_amber_rounded,
            badge: '4',
            badgeColor: const Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          _navTab(
            index: 3,
            label: 'Базаға қосу',
            icon: Icons.person_add_alt_1_rounded,
            badge: _dbUsers.isNotEmpty ? '${_dbUsers.length}' : null,
            badgeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _navTab({
    required int index,
    required String label,
    required IconData icon,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = _activeNav == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_activeNav == index) return;
          PageLoaderService().show(lang: widget.lang);
          setState(() => _activeNav = index);
          Future.delayed(const Duration(milliseconds: 260), () {
            PageLoaderService().hide();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0062FF) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeColor ?? (isSelected ? Colors.white : const Color(0xFFEF4444)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: isSelected && badgeColor == null ? const Color(0xFF0062FF) : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 0: Overview & HR Staff Requests ────────────────────
  Widget _buildOverviewAndHrTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── College KPI Summary Cards ──
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  title: 'Қатысу дәрежесі',
                  value: '94.2%',
                  subtext: '+1.4% осы аптада',
                  color: const Color(0xFF10B981),
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  title: 'Контингент',
                  value: '1,420',
                  subtext: '86 оқытушы құрамы',
                  color: const Color(0xFF0062FF),
                  icon: Icons.groups_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  title: 'Оқытушылар пунктуалдығы',
                  value: '98.6%',
                  subtext: 'Уақытында басталды',
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.verified_user_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  title: 'Аудиториялар',
                  value: '28 / 32',
                  subtext: 'Қазір сабақ өтуде',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.meeting_room_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Official Ministry Export Banner ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x180F172A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0062FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.cloud_download_rounded, color: Color(0xFF60A5FA), size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ҰОБД / МОН РК Ресми Есебі',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Министрлік стандарты бойынша дайын есепті жүктеу',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _exportMinistryReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0062FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Жүктеу', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── HR Staff Requests Section Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Кадрлық өтініштер (HR)',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Оқытушылардың босату, демалыс және іссапар сұраныстары',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_hrRequests.length} өтініш',
                  style: const TextStyle(
                    color: Color(0xFF0062FF),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // HR Request Cards
          ..._hrRequests.map((req) => _buildHrRequestCard(req)),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtext, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildHrRequestCard(_StaffRequest req) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    if (req.type == 'resignation') {
      typeColor = const Color(0xFFEF4444);
      typeIcon = Icons.person_remove_rounded;
      typeLabel = 'Жұмыстан босату туралы (Увольнение)';
    } else if (req.type == 'vacation') {
      typeColor = const Color(0xFFF59E0B);
      typeIcon = Icons.beach_access_rounded;
      typeLabel = 'Еңбек демалысы (Отпуск)';
    } else {
      typeColor = const Color(0xFF0062FF);
      typeIcon = Icons.flight_takeoff_rounded;
      typeLabel = 'Ғылыми іссапар (Командировка)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: req.status == 'pending' ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
          width: req.status == 'pending' ? 1.4 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with employee info & status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          req.employeeName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: req.status == 'approved'
                                ? const Color(0xFFDCFCE7)
                                : (req.status == 'rejected'
                                    ? const Color(0xFFFEE2E2)
                                    : (req.status == 'interview'
                                        ? const Color(0xFFEFF6FF)
                                        : const Color(0xFFFEF3C7))),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status == 'approved'
                                ? 'БЕКІТІЛДІ ✓'
                                : (req.status == 'rejected'
                                    ? 'ҚАБЫЛДАНБАДЫ ✕'
                                    : (req.status == 'interview'
                                        ? 'СҰХБАТҚА ШАҚЫРЫЛДЫ'
                                        : 'ҚАРАЛУДА ⏳')),
                            style: TextStyle(
                              color: req.status == 'approved'
                                  ? const Color(0xFF16A34A)
                                  : (req.status == 'rejected'
                                      ? const Color(0xFFDC2626)
                                      : (req.status == 'interview'
                                          ? const Color(0xFF0062FF)
                                          : const Color(0xFFD97706))),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      req.role,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Request Title & Type tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),

          // Request Statement Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              req.details,
              style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5, height: 1.4),
            ),
          ),
          const SizedBox(height: 8),

          // Timestamp
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                'Күні: ${req.date} • Өтініш №${req.id}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Director Action Buttons
          if (req.status == 'pending') ...[
            Row(
              children: [
                // Approve Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleStaffAction(req, 'approved'),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Бекіту (Қол қою)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Interview Button (especially for resignation)
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleStaffAction(req, 'interview'),
                    icon: const Icon(Icons.record_voice_over_rounded, size: 16),
                    label: const Text('Сұхбатқа шақыру', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0062FF),
                      side: const BorderSide(color: Color(0xFF0062FF)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Reject Button
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => _handleStaffAction(req, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Қабылдамау', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'Шешім қабылданды: ${req.status == 'approved' ? 'Бекітілді' : (req.status == 'rejected' ? 'Қабылданбады' : 'Сұхбат белгіленді')}',
                style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 1: Targeted & Broadcast Notifications ─────────────
  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.send_rounded, color: Color(0xFF0062FF), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Жаңа хабарлама жолдау',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Барлық ұжымға жалпы хабарландыру немесе жеке тұлғаға (мұғалімге/студентке) дербес ескерту жіберіңіз',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 14),

                // ── Mode Switcher Pills ──
                const Text('Қабылдаушы аудиториясы:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _audiencePill('all', 'Барлығына', Icons.public_rounded),
                      const SizedBox(width: 6),
                      _audiencePill('teachers', 'Оқытушыларға', Icons.school_rounded),
                      const SizedBox(width: 6),
                      _audiencePill('students', 'Студенттерге', Icons.groups_rounded),
                      const SizedBox(width: 6),
                      _audiencePill('personal', 'Жеке тұлғаға', Icons.person_rounded),
                    ],
                  ),
                ),

                // ── Individual Recipient Dropdown (if personal) ──
                if (_targetMode == 'personal') ...[
                  const SizedBox(height: 12),
                  const Text('Нақты адамды таңдаңыз:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRecipient,
                        isExpanded: true,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12.5, fontWeight: FontWeight.w700),
                        items: _availableRecipients.map((String r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRecipient = val);
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Priority Selector
                const Text('Маңыздылық деңгейі:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _priorityChip('normal', 'Қалыпты', const Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    _priorityChip('important', 'Маңызды', const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _priorityChip('urgent', 'Шұғыл', const Color(0xFFEF4444)),
                  ],
                ),

                const SizedBox(height: 12),

                // Title Input
                TextField(
                  controller: _notifTitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Хабарлама тақырыбы',
                    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),

                // Message Body Input
                TextField(
                  controller: _notifMsgCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Хабарлама мәтіні...',
                    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendNotification,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _targetMode == 'personal' ? 'Жеке хабарламаны жолдау' : 'Хабарламаны жариялау',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Sent History
          const Text(
            'Жіберілген хабарламалар тарихы',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          ..._sentNotifications.map((n) => _buildSentNotificationCard(n)),
        ],
      ),
    );
  }

  Widget _audiencePill(String mode, String label, IconData icon) {
    final isSelected = _targetMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _targetMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0062FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priorityChip(String priority, String label, Color color) {
    final isSelected = _selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSentNotificationCard(_SentNotification n) {
    Color priorityColor;
    if (n.priority == 'urgent') {
      priorityColor = const Color(0xFFEF4444);
    } else if (n.priority == 'important') {
      priorityColor = const Color(0xFFF59E0B);
    } else {
      priorityColor = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  n.priority.toUpperCase(),
                  style: TextStyle(color: priorityColor, fontWeight: FontWeight.w900, fontSize: 9),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  n.recipientName,
                  style: const TextStyle(
                    color: Color(0xFF0062FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                n.timestamp,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            n.title,
            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 3),
          Text(
            n.message,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Grant Loss Risk Monitor ────────────────────────
  Widget _buildGrantRiskTab() {
    final atRiskStudents = [
      {
        'name': 'Сапарбаев Нұржан',
        'group': 'БҚ2405',
        'attendance': '61.4%',
        'missedHours': '38 сағат',
        'grantType': 'Мемлекеттік білім гранты',
        'curator': 'Талдаубек Арай',
      },
      {
        'name': 'Жұмағалиев Асқар',
        'group': 'ПО2501',
        'attendance': '64.8%',
        'missedHours': '34 сағат',
        'grantType': 'Аким гранты',
        'curator': 'Талдаубек Арай',
      },
      {
        'name': 'Кенжебек Диас',
        'group': 'ИС2505',
        'attendance': '67.2%',
        'missedHours': '30 сағат',
        'grantType': 'Мемлекеттік білім гранты',
        'curator': 'Қалиева Б.С.',
      },
      {
        'name': 'Төлегенова Аружан',
        'group': 'ВТ2511',
        'attendance': '68.5%',
        'missedHours': '28 сағат',
        'grantType': 'Колледж гранты',
        'curator': 'Ерғалиев С.Ж.',
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.gpp_maybe_rounded, color: Color(0xFFEF4444), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Қызыл аймақ: Гранттан айырылу қаупі',
                        style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ҚР МОН ережесі бойынша 70%-дан төмен қатысу грантты қайтарып алуға негіз болады.',
                        style: TextStyle(color: Color(0xFFB91C1C), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          ...atRiskStudents.map((st) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        st['name']!,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          st['attendance']!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Топ: ${st['group']} • ${st['grantType']} • Өткізілгені: ${st['missedHours']}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Куратор: ${st['curator']}',
                        style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Кураторға (${st['curator']}) шұғыл ескерту жолданды!'),
                              backgroundColor: const Color(0xFF0062FF),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0062FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: const Text('Кураторға ескерту', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 4. БАЗАНЫ БАСҚАРУ & ПАЙДАЛАНУШЫ ҚОСУ (FACE ID & КУРАТОРЛЫҚ БЕКІТУ) ──
  Widget _buildUserManagementTab() {
    final students = _dbUsers.where((u) => u['role'] == 'STUDENT').toList();
    final withFaceId = _dbUsers.where((u) => u['has_face_id'] == true).toList();
    final pendingApps = _dbApplications.where((a) => a['status'] == 'PENDING').toList();

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A192F), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330062FF),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'БАЗАНЫ БАСҚАРУ • КУРАТОРЛЫҚ БЕКІТУ & FACE ID',
                      style: TextStyle(
                        color: Color(0xFF93C5FD),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      tooltip: 'Жаңарту',
                      onPressed: _loadUsers,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Топтық тізімдер мен биометриялық база',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Куратор топтық тізімді Face ID-мен жібереді • Директор растайды • Жүйе бір реттік пароль береді',
                  style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Metrics row
                Row(
                  children: [
                    _dbStatBadge('Базада', '${_dbUsers.length} адам', const Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    _dbStatBadge('Студенттер', '${students.length}', const Color(0xFF4ADE80)),
                    const SizedBox(width: 8),
                    _dbStatBadge('Face ID', '${withFaceId.length} ✅', const Color(0xFFEC4899)),
                    const SizedBox(width: 8),
                    _dbStatBadge('Өтініштер', '${pendingApps.length} ⏳', const Color(0xFFFBBF24)),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons (Кураторлық топтық жіберу + Жеке қосу + Excel Қызметкерлер)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showCuratorGroupSubmitDialog,
                      icon: const Icon(Icons.group_add_rounded, size: 16),
                      label: const Text(
                        'Топтық өтініш (Куратор & Face ID)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0062FF),
                        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showAddUserDialog,
                      icon: const Icon(Icons.person_add_alt, size: 15, color: Colors.white),
                      label: const Text(
                        '+ Жеке тіркеу',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showBulkStaffDialog,
                      icon: const Icon(Icons.table_chart_rounded, size: 15, color: Color(0xFF93C5FD)),
                      label: const Text(
                        '📊 Excel (Қызметкерлер)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF93C5FD)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF60A5FA), width: 1.2),
                        backgroundColor: const Color(0x221E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Sub-Tab Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _dbSubTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _dbSubTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _dbSubTab == 0 ? const [BoxShadow(color: Color(0x10000000), blurRadius: 4)] : null,
                      ),
                      child: Center(
                        child: Text(
                          'Кураторлық өтініштер (${pendingApps.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: _dbSubTab == 0 ? const Color(0xFF0062FF) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _dbSubTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _dbSubTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _dbSubTab == 1 ? const [BoxShadow(color: Color(0x10000000), blurRadius: 4)] : null,
                      ),
                      child: Center(
                        child: Text(
                          'Базадағы барлық адамдар (${_dbUsers.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: _dbSubTab == 1 ? const Color(0xFF0062FF) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── TAB 0: КУРАТОРЛЫҚ ТОПТЫҚ ӨТІНІШТЕР ───────────────────
          if (_dbSubTab == 0) ...[
            if (_dbApplications.isEmpty && !_isLoadingApps)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined, color: Color(0xFF94A3B8), size: 48),
                    SizedBox(height: 10),
                    Text('Әзірге өтініштер жоқ', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Жоғарыдағы «Топтық өтініш (Куратор)» арқылы жаңа тізім жіберіңіз', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              )
            else
              ..._dbApplications.map((app) {
                final isPending = app['status'] == 'PENDING';
                final isApproved = app['status'] == 'APPROVED';
                final studentsCount = app['students_count'] ?? 0;
                final studentsList = (app['students_summary'] as List?) ?? [];
                final appId = app['id'] as int? ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                      width: isPending ? 1.5 : 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${app['group_name']} ТОБЫ',
                                  style: const TextStyle(
                                    color: Color(0xFF0062FF),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$studentsCount студент',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPending ? 'КҮТІЛУДЕ ⏳' : 'БЕКІТІЛДІ ✅',
                              style: TextStyle(
                                color: isPending ? const Color(0xFF92400E) : const Color(0xFF166534),
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Куратор: ${app['curator_name']} • ${app['faculty'] ?? ''}',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),

                      // Студенттер тізімі превьюі
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Топ құрамы (Face ID дайын):',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            ...studentsList.take(4).map((s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      s['full_name'] ?? '',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Face ID ✅', style: TextStyle(color: Color(0xFF166534), fontSize: 9.5, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                            )),
                            if (studentsList.length > 4)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '... және тағы ${studentsList.length - 4} студент',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Actions
                      if (isPending)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approveApplication(appId, app['group_name'] ?? ''),
                                icon: const Icon(Icons.verified, size: 16),
                                label: const Text('Топты бекіту және базаға енгізу', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () async {
                                await ApiService.rejectGroupApplication(appId);
                                _loadUsers();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Қайтару', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ],
                        )
                      else if (isApproved && (app['credentials'] as List?)?.isNotEmpty == true)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showCredentialsDialog(app['credentials'], app['group_name'] ?? ''),
                            icon: const Icon(Icons.vpn_key_rounded, size: 16, color: Color(0xFF0062FF)),
                            label: const Text('Берілген бір реттік парольдер мен ID қарау (Талон)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0062FF))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ],

          // ── TAB 1: БАЗАДАҒЫ ПАЙДАЛАНУШЫЛАР ТІЗІМІ ────────────────
          if (_dbSubTab == 1) ...[
            if (_dbUsers.isEmpty && !_isLoadingUsers)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline, color: Color(0xFF94A3B8), size: 48),
                    const SizedBox(height: 10),
                    const Text('База әлі бос немесе сервер жүктелуде', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadUsers,
                      child: const Text('Қайта тексеру'),
                    ),
                  ],
                ),
              )
            else
              ..._dbUsers.map((u) {
                final isStudent = u['role'] == 'STUDENT';
                final hasFace = u['has_face_id'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x080F172A),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isStudent ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
                        child: Text(
                          (u['full_name'] as String? ?? 'U').isNotEmpty
                              ? (u['full_name'] as String).substring(0, 1).toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: isStudent ? const Color(0xFF0062FF) : const Color(0xFFDB2777),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    u['full_name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isStudent ? const Color(0xFFEFF6FF) : const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isStudent ? 'СТУДЕНТ' : (u['role'] == 'TEACHER' ? 'ОҚЫТУШЫ' : (u['role'] == 'DEAN' ? 'ДЕКАН' : (u['role'] ?? ''))),
                                    style: TextStyle(
                                      color: isStudent ? const Color(0xFF0062FF) : const Color(0xFF7E22CE),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                                if (u['curator_group'] != null && u['curator_group'].toString().isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'КУРАТОР (${u['curator_group']})',
                                      style: const TextStyle(
                                        color: Color(0xFF92400E),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${u['email']} • ${u['group_name'] ?? u['department'] ?? 'AITU'}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (u['student_id'] != null)
                                  Text(
                                    'ID: ${u['student_id']}',
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: hasFace ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    hasFace ? 'Face ID: Бар ✅' : 'Face ID: Жоқ ⚠️',
                                    style: TextStyle(
                                      color: hasFace ? const Color(0xFF166534) : const Color(0xFF92400E),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── ӨТІНІШТІ БЕКІТУ ЖӘНЕ ПАРОЛЬДЕР ТАЛОНЫН КӨРСЕТУ ─────────
  Future<void> _approveApplication(int appId, String groupName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final res = await ApiService.approveGroupApplication(appId);
    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    if (res['success'] == true) {
      await _loadUsers();
      final creds = (res['credentials'] as List?) ?? [];
      _showCredentialsDialog(creds, groupName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Қате орын алды')),
      );
    }
  }

  // ── БЕРІЛГЕН СТУДЕНТТІК ID ЖӘНЕ БІР РЕТТІК ПАРОЛЬДЕР ТАЛОНЫ ─
  void _showCredentialsDialog(List credentials, String groupName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎉 «$groupName» тобы сәтті бекітілді!',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Барлық ${credentials.length} студентке ID, бір реттік құпия сөз және Face ID берілді',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Credentials list
            Expanded(
              child: ListView.separated(
                itemCount: credentials.length,
                separatorBuilder: (context, index) => const Divider(height: 12),
                itemBuilder: (ctx, i) {
                  final c = credentials[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c['full_name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Face ID ✅', style: TextStyle(color: Color(0xFF166534), fontSize: 9.5, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('ID: ${c['student_id']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                children: [
                                  const Text('Пароль: ', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  Text(
                                    c['one_time_password'] ?? 'AITU-1234',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0062FF), fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Copy all button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final text = credentials.map((c) => "${c['full_name']} | ID: ${c['student_id']} | Пароль: ${c['one_time_password']}").join("\n");
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Барлық талондар алмасу буферіне көшірілді! 📋')),
                  );
                },
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text('Барлық талондарды көшіріп алу (Тарату үшін)', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0062FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Вебте фото таңдау көмекшісі ────────────────────────────
  void _pickWebImage(Function(String base64Data) onSelected) {
    WebPlatformHelper.pickWebImage(onSelected);
  }

  // ── Вебте CSV/Excel мәтіндік файл оқу көмекшісі ────────────
  void _pickWebTextFile(Function(String content) onContentRead) {
    WebPlatformHelper.pickWebTextFile(onContentRead);
  }

  // ── КУРАТОР РЕТІНДЕ ЖАҢА ТОПТЫҚ ӨТІНІШ ЖІБЕРУ ДИАЛОГЫ ───────
  void _showCuratorGroupSubmitDialog() {
    final groupCtrl = TextEditingController(text: 'ИТ2301');
    final curatorCtrl = TextEditingController(text: 'Талдаубек Арай (Оқытушы-Куратор)');
    final facultyCtrl = TextEditingController(text: 'Ақпараттық технологиялар бөлімі');

    List<Map<String, dynamic>> studentsInRoster = [
      {'full_name': 'Серікұлы Әлішер', 'iin': '040101501234', 'email': 'alisher.s@aitu.edu.kz', 'has_photo': false, 'photo_base64': null},
      {'full_name': 'Мұратқызы Динара', 'iin': '040202602345', 'email': 'dinara.m@aitu.edu.kz', 'has_photo': false, 'photo_base64': null},
      {'full_name': 'Нұрланұлы Бауыржан', 'iin': '040303503456', 'email': 'bauyrzhan.n@aitu.edu.kz', 'has_photo': false, 'photo_base64': null},
      {'full_name': 'Ерланқызы Аида', 'iin': '040404604567', 'email': 'aida.e@aitu.edu.kz', 'has_photo': false, 'photo_base64': null},
      {'full_name': 'Қайратұлы Тимур', 'iin': '040505505678', 'email': 'timur.k@aitu.edu.kz', 'has_photo': false, 'photo_base64': null},
    ];

    final newStudentCtrl = TextEditingController();
    final newStudentIinCtrl = TextEditingController();

    // Excel import modal opener
    void showExcelStudentPasteModal(StateSetter setSheetState) {
      final pasteCtrl = TextEditingController();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (pCtx) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(pCtx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '📊 Excel / CSV тізімін импорттау',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Excel кестесінен студенттерді көшіріп (Ctrl+V) осында қойыңыз:\nФормат: Аты-жөні, ЖСН, Email (немесе жай ғана аты-жөні)',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        pasteCtrl.text =
                            "Серікұлы Әлішер, 040101501234, alisher.s@aitu.edu.kz\n"
                            "Мұратқызы Динара, 040202602345, dinara.m@aitu.edu.kz\n"
                            "Нұрланұлы Бауыржан, 040303503456, bauyrzhan.n@aitu.edu.kz\n"
                            "Ерланқызы Аида, 040404604567, aida.e@aitu.edu.kz\n"
                            "Қайратұлы Тимур, 040505505678, timur.k@aitu.edu.kz";
                      },
                      icon: const Icon(Icons.flash_on, size: 14, color: Color(0xFF0062FF)),
                      label: const Text('Үлгі мәтінді қою', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {
                        _pickWebTextFile((content) {
                          pasteCtrl.text = content;
                        });
                      },
                      icon: const Icon(Icons.file_open_rounded, size: 14),
                      label: const Text('Файл таңдау (.csv)', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pasteCtrl,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: "Әр жолға 1 студенттен:\nСерікұлы Әлішер, 040101501234, alisher.s@aitu.edu.kz",
                    hintStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final raw = pasteCtrl.text.trim();
                      if (raw.isEmpty) return;
                      final lines = raw.split('\n');
                      int added = 0;
                      for (var line in lines) {
                        line = line.trim();
                        if (line.isEmpty || line.toLowerCase().startsWith('аты') || line.toLowerCase().startsWith('фио')) continue;
                        final parts = line.split(RegExp(r'[\t,;]')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
                        if (parts.isEmpty) continue;
                        final name = parts[0];
                        String? iin;
                        String? email;
                        for (int i = 1; i < parts.length; i++) {
                          final p = parts[i];
                          if (p.contains('@')) {
                            email = p;
                          } else if (RegExp(r'^\d{12}$').hasMatch(p)) {
                            iin = p;
                          } else if (iin == null && RegExp(r'^\d+$').hasMatch(p)) {
                            iin = p;
                          }
                        }
                        setSheetState(() {
                          studentsInRoster.add({
                            'full_name': name,
                            'iin': iin,
                            'email': email,
                            'has_photo': false,
                            'photo_base64': null,
                          });
                        });
                        added++;
                      }
                      Navigator.pop(pCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Excel тізімінен $added студент қосылды! Енді олардың Face ID фотоларын жүктеңіз.'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                    label: const Text('Тізімге қосу', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final photoCount = studentsInRoster.where((s) => s['photo_base64'] != null).length;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.90,
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Куратор: Топтық өтініш & Face ID базасы',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Тізімді Excel-ден импорттап, студенттердің Face ID суреттерін бекітіңіз',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),

                // Group & Curator Info
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: groupCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Топ атауы *',
                          hintText: 'ИТ2301',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: curatorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Оқытушы / Куратор аты-жөні *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Excel Import & Status bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Студенттер: ${studentsInRoster.length} | Face ID фотосы: $photoCount',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => showExcelStudentPasteModal(setSheetState),
                        icon: const Icon(Icons.table_view_rounded, size: 14),
                        label: const Text('📊 Excel / CSV тізім қою', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0062FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Add single student manual row
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: newStudentCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Аты-жөні (ФИО)...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: newStudentIinCtrl,
                        decoration: const InputDecoration(
                          hintText: 'ЖСН (12 сан)...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () {
                        if (newStudentCtrl.text.trim().isNotEmpty) {
                          setSheetState(() {
                            studentsInRoster.add({
                              'full_name': newStudentCtrl.text.trim(),
                              'iin': newStudentIinCtrl.text.trim().isNotEmpty ? newStudentIinCtrl.text.trim() : null,
                              'has_photo': false,
                              'photo_base64': null,
                            });
                            newStudentCtrl.clear();
                            newStudentIinCtrl.clear();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      child: const Text('+ Қосу', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Students roster list with photo uploaders
                Expanded(
                  child: studentsInRoster.isEmpty
                      ? const Center(
                          child: Text(
                            'Тізім бос. Жоғарыдағы «Excel / CSV тізім қою» түймесін басыңыз',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        )
                      : ListView.separated(
                          itemCount: studentsInRoster.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            final st = studentsInRoster[i];
                            final bool hasPhoto = st['photo_base64'] != null;

                            Widget avatarWidget;
                            if (hasPhoto) {
                              try {
                                final b64Str = (st['photo_base64'] as String).split(',').last;
                                avatarWidget = ClipOval(
                                  child: Image.memory(
                                    base64Decode(b64Str),
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFF0062FF)),
                                  ),
                                );
                              } catch (_) {
                                avatarWidget = const Icon(Icons.person, color: Color(0xFF0062FF));
                              }
                            } else {
                              avatarWidget = CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0062FF))),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: hasPhoto ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: hasPhoto ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  avatarWidget,
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          st['full_name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            if (st['iin'] != null && st['iin'].toString().isNotEmpty) 'ЖСН: ${st['iin']}',
                                            if (st['email'] != null && st['email'].toString().isNotEmpty) '${st['email']}',
                                          ].join(' • '),
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          hasPhoto ? 'Face ID фотосы жүктелді ✅ (Нейрожелі дайын)' : 'Фото жүктелмеген (Face ID үшін фото қосыңыз) ⚠️',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: hasPhoto ? const Color(0xFF166534) : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _pickWebImage((dataUrl) {
                                        setSheetState(() {
                                          st['photo_base64'] = dataUrl;
                                          st['has_photo'] = true;
                                        });
                                      });
                                    },
                                    icon: Icon(hasPhoto ? Icons.check_circle : Icons.add_a_photo_rounded, size: 14, color: hasPhoto ? const Color(0xFF166534) : const Color(0xFF0062FF)),
                                    label: Text(
                                      hasPhoto ? 'Ауыстыру' : '📸 Фото',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: hasPhoto ? const Color(0xFF166534) : const Color(0xFF0062FF)),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      side: BorderSide(color: hasPhoto ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE)),
                                      backgroundColor: hasPhoto ? const Color(0xFFDCFCE7) : Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                    onPressed: () {
                                      setSheetState(() {
                                        studentsInRoster.removeAt(i);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),

                // Submit to director button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (groupCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Топ атауын енгізіңіз!')));
                        return;
                      }
                      if (studentsInRoster.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Студенттер тізімі бос болмауы керек!')));
                        return;
                      }

                      Navigator.of(ctx).pop();
                      final res = await ApiService.submitGroupApplication(
                        groupName: groupCtrl.text.trim(),
                        curatorName: curatorCtrl.text.trim(),
                        faculty: facultyCtrl.text.trim(),
                        students: studentsInRoster,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Өтініш жіберілді!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                        setState(() => _dbSubTab = 0);
                        _loadUsers();
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      'Директорға бекітуге жіберу (${studentsInRoster.length} студент)',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Excel Қызметкерлерді (Оқытушылар/Декандар/Кураторлар) импорттау ─
  void _showBulkStaffDialog() {
    final pasteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        height: MediaQuery.of(bCtx).size.height * 0.85,
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(bCtx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '📊 Excel-ден Қызметкерлер тізімін енгізу',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Оқытушылар мен Декандарды кураторлық топтарымен бірге жаппай базаға қосу:\nФормат: ФИО, ЖСН, Рөлі (TEACHER/DEAN), Кафедра, Кураторлық тобы',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      pasteCtrl.text =
                          "Калниязов Аманжол, 750101300111, TEACHER, Ақпараттық жүйелер кафедрасы, ИТ2301\n"
                          "Билал Дархан, 820202300222, TEACHER, Бағдарламалық инженерия кафедрасы, БҚ2405\n"
                          "Садықов Берік, 680303300333, DEAN, Компьютерлік инженерия факультеті, \n"
                          "Талдаубек Арай, 890404400444, TEACHER, Киберқауіпсіздік кафедрасы, КҚ2201";
                    },
                    icon: const Icon(Icons.flash_on, size: 14, color: Color(0xFF0062FF)),
                    label: const Text('Үлгі қызметкерлер тізімі (4 адам)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      _pickWebTextFile((content) {
                        pasteCtrl.text = content;
                      });
                    },
                    icon: const Icon(Icons.file_open_rounded, size: 14),
                    label: const Text('Файл таңдау', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              TextField(
                controller: pasteCtrl,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "Әр жолға 1 қызметкерден:\nКалниязов Аманжол, 750101300111, TEACHER, Ақпараттық жүйелер, ИТ2301",
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final raw = pasteCtrl.text.trim();
                    if (raw.isEmpty) return;
                    final lines = raw.split('\n');
                    List<Map<String, dynamic>> staffList = [];
                    for (var line in lines) {
                      line = line.trim();
                      if (line.isEmpty || line.toLowerCase().startsWith('фио') || line.toLowerCase().startsWith('аты')) continue;
                      final parts = line.split(RegExp(r'[\t,;]')).map((p) => p.trim()).toList();
                      if (parts.isEmpty) continue;
                      final name = parts[0];
                      final iin = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
                      final role = parts.length > 2 && parts[2].isNotEmpty ? parts[2].toUpperCase() : 'TEACHER';
                      final dept = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : 'Ақпараттық технологиялар бөлімі';
                      final curatorGrp = parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null;

                      staffList.add({
                        'full_name': name,
                        'iin': iin,
                        'role': (role == 'DEAN' || role == 'ДЕКАН') ? 'DEAN' : 'TEACHER',
                        'department': dept,
                        'curator_group': curatorGrp,
                        'password': '12345',
                      });
                    }

                    if (staffList.isEmpty) return;
                    Navigator.pop(bCtx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Қызметкерлер базаға сақталуда...')));

                    final res = await ApiService.bulkImportStaff(staffList);
                    if (!mounted) return;
                    if (res['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] ?? 'Қызметкерлер базаға енгізілді!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                      setState(() => _dbSubTab = 1);
                      _loadUsers();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] ?? 'Қате орын алды'),
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('Қызметкерлерді базаға енгізу', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0062FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dbStatBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12.5)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Жаңа қолданушы қосу диалогы (Оқытушы / Декан / Студент) ─
  void _showAddUserDialog() {
    String selectedRole = 'TEACHER'; // Default to Teacher
    final nameCtrl = TextEditingController();
    final iinCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'Ақпараттық технологиялар бөлімі');
    final curatorGroupCtrl = TextEditingController(); // For teachers/deans who are curators
    final groupCtrl = TextEditingController(text: 'ИТ2301'); // For students
    final studentIdCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '12345');
    String? userPhotoBase64;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Базаға жаңа қызметкер немесе студент тіркеу',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Оқытушы немесе деканға кураторлық тобын бекітуге болады',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // 3 Role selector chips: Оқытушы, Декан, Студент
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedRole = 'TEACHER'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedRole == 'TEACHER' ? const Color(0xFF0062FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Оқытушы',
                              style: TextStyle(
                                color: selectedRole == 'TEACHER' ? Colors.white : const Color(0xFF475569),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedRole = 'DEAN'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedRole == 'DEAN' ? const Color(0xFF7E22CE) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Декан',
                              style: TextStyle(
                                color: selectedRole == 'DEAN' ? Colors.white : const Color(0xFF475569),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedRole = 'STUDENT'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedRole == 'STUDENT' ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Студент',
                              style: TextStyle(
                                color: selectedRole == 'STUDENT' ? Colors.white : const Color(0xFF475569),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Name input
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Толық аты-жөні (ФИО) *',
                    hintText: 'Калниязов Аманжол',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    if (emailCtrl.text.isEmpty && val.isNotEmpty) {
                      final slug = val.toLowerCase().replaceAll(' ', '.');
                      setSheetState(() {
                        emailCtrl.text = '$slug@aitu.edu.kz';
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                // IIN & Email Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: iinCtrl,
                        decoration: InputDecoration(
                          labelText: 'ЖСН / ИИН *',
                          hintText: '080524554184',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Email / Логин *',
                          hintText: 'teacher@aitu.edu.kz',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Conditional fields for Teacher / Dean vs Student
                if (selectedRole != 'STUDENT') ...[
                  TextField(
                    controller: deptCtrl,
                    decoration: InputDecoration(
                      labelText: 'Кафедра / Факультет',
                      hintText: 'Ақпараттық қауіпсіздік кафедрасы',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: curatorGroupCtrl,
                    decoration: InputDecoration(
                      labelText: 'Кураторлық тобы (егер куратор болса)',
                      hintText: 'ИТ2301 (бос қалдыруға болады)',
                      helperText: 'Оқытушы немесе декан қай топтың кураторы екенін көрсетеді',
                      filled: true,
                      fillColor: const Color(0xFFEFF6FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: groupCtrl,
                          decoration: InputDecoration(
                            labelText: 'Студент тобы *',
                            hintText: 'ИТ2301',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: studentIdCtrl,
                          decoration: InputDecoration(
                            labelText: 'Билет № (ID)',
                            hintText: 'STU-2405-21',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),

                // Password
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: 'Құпия сөз (Password)',
                    hintText: '12345',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Face ID Photo slot
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: userPhotoBase64 != null ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: userPhotoBase64 != null ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      if (userPhotoBase64 != null)
                        ClipOval(
                          child: Image.memory(
                            base64Decode(userPhotoBase64!.split(',').last),
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Icon(Icons.face_retouching_natural, color: Color(0xFF0062FF), size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userPhotoBase64 != null ? 'Face ID фотосы бекітілді ✅' : 'Face ID фотосын жүктеу',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                            ),
                            Text(
                              userPhotoBase64 != null ? 'YuNet + SFace нейрожелісі бойынша тануға дайын' : 'Камерадан немесе файлдан суретті таңдаңыз',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _pickWebImage((dataUrl) {
                            setSheetState(() => userPhotoBase64 = dataUrl);
                          });
                        },
                        icon: const Icon(Icons.upload_file_rounded, size: 14),
                        label: Text(userPhotoBase64 != null ? 'Ауыстыру' : '📸 Фото'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ФИО мен Email толтыру міндетті!')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Базаға сақталуда...')),
                      );

                      final res = await ApiService.registerUser(
                        email: emailCtrl.text.trim(),
                        fullName: nameCtrl.text.trim(),
                        role: selectedRole,
                        iin: iinCtrl.text.trim().isNotEmpty ? iinCtrl.text.trim() : null,
                        phone: iinCtrl.text.trim().isNotEmpty ? iinCtrl.text.trim() : null,
                        curatorGroup: curatorGroupCtrl.text.trim().isNotEmpty ? curatorGroupCtrl.text.trim() : null,
                        department: deptCtrl.text.trim().isNotEmpty ? deptCtrl.text.trim() : null,
                        groupName: selectedRole == 'STUDENT' ? groupCtrl.text.trim() : null,
                        studentId: studentIdCtrl.text.trim().isNotEmpty ? studentIdCtrl.text.trim() : null,
                        password: passCtrl.text.trim(),
                        photoBase64: userPhotoBase64,
                      );

                      if (!mounted) return;

                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Қолданушы сәтті тіркелді!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                        _loadUsers();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Қате орын алды'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Базаға сақтау және тіркеу',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
