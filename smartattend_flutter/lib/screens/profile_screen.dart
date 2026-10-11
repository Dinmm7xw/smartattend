import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/user_avatar.dart';

const _tr = {
  'profile': {'kk': 'Профиль', 'ru': 'Профиль', 'en': 'Profile'},
  'change_photo': {'kk': 'Фотоны өзгерту', 'ru': 'Изменить фото', 'en': 'Change photo'},
  'gallery': {'kk': 'Галереядан таңдау', 'ru': 'Выбрать из галереи', 'en': 'Choose from gallery'},
  'camera': {'kk': 'Камерамен түсіру', 'ru': 'Сделать снимок', 'en': 'Take a photo'},
  'photo_ok': {'kk': 'Фото жаңартылды', 'ru': 'Фото обновлено', 'en': 'Photo updated'},
  'change_pw': {'kk': 'Құпия сөзді өзгерту', 'ru': 'Изменить пароль', 'en': 'Change password'},
  'current_pw': {'kk': 'Қазіргі құпия сөз', 'ru': 'Текущий пароль', 'en': 'Current password'},
  'new_pw': {'kk': 'Жаңа құпия сөз', 'ru': 'Новый пароль', 'en': 'New password'},
  'confirm_pw': {'kk': 'Жаңа құпия сөзді қайталаңыз', 'ru': 'Повторите новый пароль', 'en': 'Repeat new password'},
  'save': {'kk': 'Сақтау', 'ru': 'Сохранить', 'en': 'Save'},
  'cancel': {'kk': 'Бас тарту', 'ru': 'Отмена', 'en': 'Cancel'},
  'pw_short': {'kk': 'Кемінде 6 таңба', 'ru': 'Минимум 6 символов', 'en': 'At least 6 characters'},
  'pw_mismatch': {'kk': 'Құпия сөздер сәйкес емес', 'ru': 'Пароли не совпадают', 'en': 'Passwords do not match'},
  'pw_ok': {'kk': 'Құпия сөз өзгертілді', 'ru': 'Пароль изменён', 'en': 'Password changed'},
  'logout': {'kk': 'Шығу', 'ru': 'Выйти', 'en': 'Log out'},
  'logout_q': {'kk': 'Аккаунттан шыққыңыз келе ме?', 'ru': 'Выйти из аккаунта?', 'en': 'Log out of your account?'},
  'security': {'kk': 'Қауіпсіздік', 'ru': 'Безопасность', 'en': 'Security'},
  'email': {'kk': 'Email', 'ru': 'Email', 'en': 'Email'},
  'id': {'kk': 'Студенттік ID', 'ru': 'ID студента', 'en': 'Student ID'},
  'group': {'kk': 'Топ', 'ru': 'Группа', 'en': 'Group'},
  'dept': {'kk': 'Бөлім', 'ru': 'Отделение', 'en': 'Department'},
  'STUDENT': {'kk': 'Студент', 'ru': 'Студент', 'en': 'Student'},
  'TEACHER': {'kk': 'Оқытушы', 'ru': 'Преподаватель', 'en': 'Teacher'},
  'DEAN': {'kk': 'Деканат', 'ru': 'Деканат', 'en': 'Dean'},
  'DIRECTOR': {'kk': 'Директор', 'ru': 'Директор', 'en': 'Director'},
};

String _t(String lang, String key) => _tr[key]?[lang] ?? _tr[key]?['ru'] ?? key;

Color _roleColor(String role) {
  switch (role) {
    case 'TEACHER':
      return AppColors.teacher;
    case 'DEAN':
      return AppColors.dean;
    case 'DIRECTOR':
      return const Color(0xFF1E3A8A);
    default:
      return AppColors.primary;
  }
}

void _snack(BuildContext c, String msg, {bool error = false}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? AppColors.danger : AppColors.success,
    behavior: SnackBarBehavior.floating,
  ));
}

/// Pick a photo (gallery / camera) and upload it as the user's avatar.
Future<void> pickAndUploadAvatar(BuildContext context, String lang) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
            title: Text(_t(lang, 'gallery')),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
            title: Text(_t(lang, 'camera')),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    ),
  );
  if (source == null || !context.mounted) return;
  try {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final res = await ApiService.uploadAvatar(bytes);
    if (!context.mounted) return;
    if (res['success'] == true) {
      _snack(context, _t(lang, 'photo_ok'));
    } else {
      _snack(context, res['message'].toString(), error: true);
    }
  } catch (e) {
    if (context.mounted) _snack(context, '$e', error: true);
  }
}

/// Bottom sheet for changing the password.
Future<void> showChangePasswordSheet(BuildContext context, String lang) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ChangePasswordSheet(lang: lang),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  final String lang;
  const _ChangePasswordSheet({required this.lang});
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _conf = TextEditingController();
  bool _show = false;
  bool _loading = false;
  String? _error;

  String _l(String k) => _t(widget.lang, k);

  Future<void> _submit() async {
    if (_cur.text.isEmpty) {
      setState(() => _error = _l('current_pw'));
      return;
    }
    if (_new.text.length < 6) {
      setState(() => _error = _l('pw_short'));
      return;
    }
    if (_new.text != _conf.text) {
      setState(() => _error = _l('pw_mismatch'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.changePassword(currentPassword: _cur.text, newPassword: _new.text);
    if (!mounted) return;
    if (res['success'] == true) {
      final nav = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      nav.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(_l('pw_ok')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      setState(() {
        _loading = false;
        _error = res['message'].toString();
      });
    }
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          obscureText: !_show,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 16),
              Text(_l('change_pw'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _field(_cur, _l('current_pw')),
              _field(_new, _l('new_pw')),
              _field(_conf, _l('confirm_pw')),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _show = !_show),
                  icon: Icon(_show ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                  label: Text(_show ? 'Hide' : 'Show'),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                ),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text(_l('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_l('save')),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Confirm dialog, then run [onLogout]. Pops any pushed routes first so the
/// login screen is shown.
Future<void> confirmLogout(BuildContext context, String lang, VoidCallback onLogout) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_t(lang, 'logout')),
      content: Text(_t(lang, 'logout_q')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(lang, 'cancel'))),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(_t(lang, 'logout'), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  Navigator.of(context).popUntil((r) => r.isFirst);
  onLogout();
}

/// Universal profile screen for all roles.
class ProfileScreen extends StatelessWidget {
  final UserModel user;
  final String lang;
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.user, required this.lang, required this.onLogout});

  Widget _info(IconData icon, String label, String? value, Color color) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  Widget _action(IconData icon, String title, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.role);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withValues(alpha: 0.75)]),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(children: [
              Row(children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
                Text(_t(lang, 'profile'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              UserAvatar(
                name: user.name,
                size: 104,
                color: color,
                showEditBadge: true,
                onTap: () => pickAndUploadAvatar(context, lang),
              ),
              const SizedBox(height: 14),
              Text(user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(_t(lang, user.role),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => pickAndUploadAvatar(context, lang),
                icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                label: Text(_t(lang, 'change_photo'), style: const TextStyle(color: Colors.white)),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: AppShadows.card),
                child: Column(children: [
                  _info(Icons.email_rounded, _t(lang, 'email'), user.email, color),
                  _info(Icons.badge_rounded, _t(lang, 'id'), user.studentId, color),
                  _info(Icons.groups_rounded, _t(lang, 'group'), user.group, color),
                  _info(Icons.apartment_rounded, _t(lang, 'dept'), user.department, color),
                ]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: AppShadows.card),
                child: Column(children: [
                  _action(Icons.photo_camera_rounded, _t(lang, 'change_photo'), color, () => pickAndUploadAvatar(context, lang)),
                  const Divider(height: 1),
                  _action(Icons.lock_rounded, _t(lang, 'change_pw'), color, () => showChangePasswordSheet(context, lang)),
                ]),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => confirmLogout(context, lang, onLogout),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(_t(lang, 'logout'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dangerLight,
                    foregroundColor: AppColors.danger,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }
}
