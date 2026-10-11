// SmartAttend — SOS Modal (updated for new theme)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/theme.dart';
import '../constants/i18n.dart';

class SOSModal extends StatefulWidget {
  final String studentName;
  final Function(String type, String message) onSendSOS;
  final VoidCallback onClose;
  final String lang;

  const SOSModal({
    super.key,
    required this.studentName,
    required this.onSendSOS,
    required this.onClose,
    required this.lang,
  });

  @override
  State<SOSModal> createState() => _SOSModalState();
}

class _SOSModalState extends State<SOSModal> with SingleTickerProviderStateMixin {
  String _selectedType = 'MEDICAL';
  final _messageController = TextEditingController();
  bool _sent = false;
  late AnimationController _pulseController;

  Map<String, String> get t => translations[widget.lang] ?? translations['kk']!;

  List<Map<String, dynamic>> get _sosTypes => [
    {'key': 'MEDICAL', 'icon': Icons.medical_services_outlined, 'label': t['sos_medical'] ?? '', 'color': AppColors.danger},
    {'key': 'SECURITY', 'icon': Icons.security_outlined, 'label': t['sos_security'] ?? '', 'color': AppColors.teacher},
    {'key': 'TECHNICAL', 'icon': Icons.build_outlined, 'label': t['sos_technical'] ?? '', 'color': AppColors.warning},
    {'key': 'OTHER', 'icon': Icons.help_outline, 'label': t['sos_other'] ?? '', 'color': AppColors.primary},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _sendSOS() {
    HapticFeedback.heavyImpact();
    widget.onSendSOS(
      _selectedType,
      _messageController.text.isNotEmpty ? _messageController.text : 'Шұғыл жәрдем!',
    );
    setState(() => _sent = true);
    Future.delayed(const Duration(seconds: 2), widget.onClose);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {},
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: AppShadows.card,
                ),
                child: _sent ? _buildSentState() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Pulsing icon
      AnimatedBuilder(
        animation: _pulseController,
        builder: (ctx, _) => Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1 + _pulseController.value * 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 34),
        ),
      ),
      const SizedBox(height: 12),
      Text(t['sos_title'] ?? '', style: AppTextStyles.title3.copyWith(color: AppColors.danger)),
      Text(t['sos_subtitle'] ?? '', style: AppTextStyles.footnote, textAlign: TextAlign.center),
      const SizedBox(height: 20),

      // Type grid
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.8,
        children: _sosTypes.map((type) {
          final isSelected = _selectedType == type['key'];
          final color = type['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type['key'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.1) : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? color : AppColors.separator,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(type['icon'] as IconData,
                    color: isSelected ? color : AppColors.textSecondary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(type['label'] as String,
                      style: TextStyle(
                        fontFamily: AppTextStyles.font,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? color : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 14),

      // Message
      TextField(
        controller: _messageController,
        maxLines: 3,
        style: AppTextStyles.callout,
        decoration: InputDecoration(hintText: t['sos_describe'] ?? '',
            hintStyle: AppTextStyles.subheadline),
      ),
      const SizedBox(height: 16),

      // Buttons
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onClose,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.separator),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
            child: Text(t['cancel'] ?? '', style: AppTextStyles.callout),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _sendSOS,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
            child: Text(t['sos_send'] ?? '', style: const TextStyle(
              fontFamily: AppTextStyles.font, color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.w600,
            )),
          ),
        ),
      ]),
    ]);
  }

  Widget _buildSentState() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 60),
      const SizedBox(height: 12),
      Text(t['sos_sent'] ?? '', style: AppTextStyles.title3.copyWith(color: AppColors.success)),
      const SizedBox(height: 6),
      Text(t['sos_subtitle'] ?? '', style: AppTextStyles.subheadline, textAlign: TextAlign.center),
    ]);
  }
}
