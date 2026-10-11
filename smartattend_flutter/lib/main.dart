// SmartAttend — Main App (3-language support: KK / RU / EN)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/theme.dart';
import 'constants/i18n.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'services/app_session.dart';
import 'screens/auth_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/dean_dashboard.dart';
import 'screens/director_dashboard.dart';
import 'widgets/qr_scanner_modal.dart';
import 'widgets/qr_display_modal.dart';
import 'widgets/sos_modal.dart';
import 'widgets/face_verify_modal.dart';
import 'widgets/notification_modal.dart';
import 'widgets/toast_widget.dart';
import 'services/notification_service.dart';
import 'services/page_loader_service.dart';
import 'widgets/page_transition_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  runApp(const SmartAttendApp());
}

class SmartAttendApp extends StatelessWidget {
  const SmartAttendApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SmartAttend',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainScreen(),
      );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // ── 3-Language cycling: kk → ru → en → kk ───────────────
  final _langs = ['kk', 'ru', 'en'];
  int _langIndex = 0;
  String get _lang => _langs[_langIndex];

  void _cycleLang() {
    final nextLang = _langs[(_langIndex + 1) % _langs.length];
    PageLoaderService().show(lang: nextLang);
    setState(() => _langIndex = (_langIndex + 1) % _langs.length);
    Future.delayed(const Duration(milliseconds: 260), () {
      PageLoaderService().hide();
    });
  }

  Map<String, String> get t => translations[_lang] ?? translations['kk']!;

  // ── App State ─────────────────────────────────────────────
  UserModel? _user;
  bool _isOnline = false;
  List<LessonModel> _lessons = [];
  LessonModel? _selectedLesson;
  final Set<int> _attendedLessons = {};

  // ── Modals ────────────────────────────────────────────────
  bool _showQRScanner = false;
  bool _showQRDisplay = false;
  bool _showSOS = false;
  bool _showFaceVerify = false;
  bool _showNotificationCenter = false;
  Map<String, dynamic>? _pendingScanData;

  // ── 2FA Face ID on Login ──────────────────────────────────
  UserModel? _pendingLoginUser;
  bool _showLoginFaceVerify = false;

  // ── Toast ─────────────────────────────────────────────────
  ToastData? _toast;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final online = await ApiService.checkBackendHealth();
    final lessons = await ApiService.getActiveLessons();
    if (mounted) {
      setState(() {
        _isOnline = online;
        _lessons = lessons;
        if (lessons.isNotEmpty) _selectedLesson = lessons.first;
      });
    }
  }

  void _toast_(String type, String title, String msg) {
    setState(() => _toast = ToastData(type: type, title: title, message: msg));
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _handleLogin(UserModel user) {
    // 2-Factor Biometric authentication upon login
    setState(() {
      _pendingLoginUser = user;
      _showLoginFaceVerify = true;
    });
  }

  void _handleLoginFaceSuccess() {
    if (_pendingLoginUser != null) {
      final u = _pendingLoginUser!;
      PageLoaderService().show(lang: _lang);
      setState(() {
        _user = u;
        _pendingLoginUser = null;
        _showLoginFaceVerify = false;
      });
      Future.delayed(const Duration(milliseconds: 320), () {
        PageLoaderService().hide();
      });
      NotificationService().sendNotification(
        title: '🔐 Сәтті кіру',
        body: '${u.name}, SmartAttend жүйесіне қош келдіңіз!',
        type: 'ATTENDANCE',
      );
      _toast_('success', '${t['welcome']}!', u.name);
    }
  }

  void _handleLogout() {
    PageLoaderService().show(lang: _lang);
    AppSession.clear();
    setState(() { _user = null; _attendedLessons.clear(); });
    Future.delayed(const Duration(milliseconds: 260), () {
      PageLoaderService().hide();
    });
  }

  void _handleQRScanned(Map<String, dynamic> data) {
    setState(() { _showQRScanner = false; _pendingScanData = data; });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showFaceVerify = true);
    });
  }

  Future<void> _handleFaceVerified() async {
    setState(() => _showFaceVerify = false);
    final lessonId = _pendingScanData?['lessonId'] as int? ?? _selectedLesson?.id ?? 1;
    await ApiService.checkInStudent(
      lessonId: lessonId,
      studentEmail: _user?.email ?? '',
      qrToken: _pendingScanData?['token'] as String? ?? 'SA-TOKEN',
      faceVerified: true,
    );
    setState(() => _attendedLessons.add(lessonId));
    NotificationService().sendNotification(
      title: '✅ Face ID расталды!',
      body: '${_selectedLesson?.subject ?? 'Информатика'} сабағына қатысуыңыз 100% тіркелді.',
      type: 'ATTENDANCE',
    );
    _toast_('success', t['face_recognized'] ?? '', t['confirm_attendance'] ?? '');
  }

  void _handleSOS(String type, String msg) {
    ApiService.sendSOSAlert(alertType: type, message: msg, senderName: _user?.name ?? '');
    _toast_('danger', t['sos_sent'] ?? '', t['sos_subtitle'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        // ── Main content ──────────────────────────────────
        _user == null
            ? AuthScreen(
                onLogin: _handleLogin,
                isOnline: _isOnline,
                lang: _lang,
                onCycleLang: _cycleLang,
              )
            : _buildLoggedInView(),

        // ── Modals ────────────────────────────────────────
        if (_showQRScanner)
          QRScannerModal(
            lesson: _selectedLesson,
            onQRScanned: _handleQRScanned,
            onClose: () => setState(() => _showQRScanner = false),
            lang: _lang,
          ),
        if (_showQRDisplay)
          QRDisplayModal(
            lesson: _selectedLesson,
            onClose: () => setState(() => _showQRDisplay = false),
            lang: _lang,
          ),
        if (_showSOS)
          SOSModal(
            studentName: _user?.name ?? '',
            onSendSOS: _handleSOS,
            onClose: () => setState(() => _showSOS = false),
            lang: _lang,
          ),
        if (_showFaceVerify)
          FaceVerifyModal(
            lesson: _selectedLesson,
            student: _user,
            onSuccess: _handleFaceVerified,
            onClose: () => setState(() => _showFaceVerify = false),
            lang: _lang,
          ),
        if (_showLoginFaceVerify && _pendingLoginUser != null)
          FaceVerifyModal(
            student: _pendingLoginUser,
            isLoginVerification: true,
            onSuccess: () async => _handleLoginFaceSuccess(),
            onClose: () => setState(() {
              _showLoginFaceVerify = false;
              _pendingLoginUser = null;
            }),
            lang: _lang,
          ),
        if (_showNotificationCenter)
          NotificationCenterModal(
            onClose: () => setState(() => _showNotificationCenter = false),
            lang: _lang,
          ),

        // ── Global Page Transition Loader (Frosted Glass & Handwriting Stylus) ──
        const PageTransitionLoader(),

        // ── Toast ─────────────────────────────────────────
        if (_toast != null) ToastWidget(data: _toast!),
      ]),
    );
  }

  Widget _buildLoggedInView() {
    final user = _user!;
    switch (user.role) {
      case 'STUDENT':
        return StudentDashboard(
          user: user,
          lessons: _lessons,
          attendedLessons: _attendedLessons,
          onOpenScanner: () => setState(() => _showQRScanner = true),
          onOpenFaceVerify: () => setState(() => _showFaceVerify = true),
          onOpenSOS: () => setState(() => _showSOS = true),
          onOpenExcuse: () => _toast_('info', t['medical_excuse'] ?? '', ''),
          onOpenNotifications: () => setState(() => _showNotificationCenter = true),
          onLogout: _handleLogout,
          lang: _lang,
        );
      case 'TEACHER':
        return TeacherDashboard(
          user: user,
          lessons: _lessons,
          selectedLesson: _selectedLesson,
          onSelectLesson: (l) => setState(() => _selectedLesson = l),
          onOpenQRDisplay: () => setState(() => _showQRDisplay = true),
          onLogout: _handleLogout,
          onCycleLang: _cycleLang,
          lang: _lang,
        );
      case 'DEAN':
        return DeanDashboard(
          user: user,
          onLogout: _handleLogout,
          onCycleLang: _cycleLang,
          lang: _lang,
        );
      case 'DIRECTOR':
        return DirectorDashboard(
          user: user,
          onLogout: _handleLogout,
          onCycleLang: _cycleLang,
          lang: _lang,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
