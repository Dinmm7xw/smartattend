// SmartAttend — Official Authentication Screen (Real Database Only)

import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../constants/i18n.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/face_recovery_modal.dart';

class AuthScreen extends StatefulWidget {
  final Function(UserModel) onLogin;
  final bool isOnline;
  final String lang;
  final VoidCallback onCycleLang;

  const AuthScreen({
    super.key,
    required this.onLogin,
    required this.isOnline,
    required this.lang,
    required this.onCycleLang,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  Map<String, String> get t => translations[widget.lang] ?? translations['kk']!;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _handleRealLogin() async {
    final ident = _emailCtrl.text.trim();
    final pwd = _passCtrl.text.trim();

    if (ident.isEmpty) {
      setState(() => _errorMessage = 'ИИН немесе Студенттік ID енгізіңіз');
      return;
    }
    if (pwd.isEmpty) {
      setState(() => _errorMessage = 'Құпия сөзді енгізіңіз');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.login(identifier: ident, password: pwd);
    if (!mounted) return;

    if (res['success'] == true) {
      widget.onLogin(res['user'] as UserModel);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res['message'] ?? 'Қате логин немесе құпия сөз! Бұл қолданушы колледж базасында жоқ.';
      });
    }
  }

  void _openFaceRecovery() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FaceRecoveryModal(
        lang: widget.lang,
        onSuccess: (ident, newPass) {
          Navigator.pop(context);
          setState(() {
            _emailCtrl.text = ident;
            _passCtrl.text = newPass;
            _errorMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.lang == 'ru'
                    ? 'Пароль успешно обновлён через Face ID! Нажмите «Войти»'
                    : widget.lang == 'en'
                        ? 'Password updated via Face ID! Click "Sign in"'
                        : 'Құпия сөз Face ID арқылы жаңартылды! «Кіру» түймесін басыңыз',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  _buildLogo(),
                  const SizedBox(height: 36),
                  _buildCard(),
                  const SizedBox(height: 32),
                  _buildFooterNotice(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Lang switcher top right
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: widget.onCycleLang,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    supportedLanguages.firstWhere((l) => l['code'] == widget.lang)['label'] ?? '',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.font,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Logo
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: AppTextStyles.font,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
            children: [
              TextSpan(text: 'Smart', style: TextStyle(color: AppColors.textPrimary)),
              TextSpan(text: 'Attend', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(t['app_subtitle'] ?? 'Ақылды қатысу жүйесі', style: AppTextStyles.subheadline),
        const SizedBox(height: 12),
        // Online pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.isOnline ? AppColors.success : AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.isOnline ? (t['online'] ?? 'Желіде') : (t['offline'] ?? 'Офлайн'),
                style: AppTextStyles.caption1.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['sign_in'] ?? 'Жүйеге кіру',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.font,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Ресми деректер қорымен растау',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Identifier field
          const Text(
            'Логин (ИИН, Студенттік ID немесе Email)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            style: AppTextStyles.callout,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.textSecondary),
              hintText: 'Мысалы: 080524554184 немесе STU-...',
              hintStyle: AppTextStyles.subheadline,
            ),
          ),
          const SizedBox(height: 16),

          // Password field
          Text(
            t['password'] ?? 'Құпия сөз',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            style: AppTextStyles.callout,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
              hintText: 'Құпия сөзді енгізіңіз',
              hintStyle: AppTextStyles.subheadline,
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Forgot password / Face ID Recovery
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: _openFaceRecovery,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.face_retouching_natural_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      widget.lang == 'ru'
                          ? 'Забыли пароль? Face ID'
                          : widget.lang == 'en'
                              ? 'Forgot password? Face ID'
                              : 'Құпия сөзді ұмыттыңыз ба? Face ID',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Sign in button
          GestureDetector(
            onTap: _isLoading ? null : _handleRealLogin,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: AppShadows.button,
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        t['sign_in'] ?? 'Кіру',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.font,
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.separator),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Қауіпсіздік: Тек колледж деректер қорында (PostgreSQL) ресми тіркелген қолданушылар кіре алады.',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
