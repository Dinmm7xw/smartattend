// SmartAttend — QR Scanner Modal

import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../constants/i18n.dart';
import '../models/models.dart';

class QRScannerModal extends StatefulWidget {
  final LessonModel? lesson;
  final Function(Map<String, dynamic>) onQRScanned;
  final VoidCallback onClose;
  final String lang;

  const QRScannerModal({
    super.key,
    required this.lesson,
    required this.onQRScanned,
    required this.onClose,
    required this.lang,
  });

  @override
  State<QRScannerModal> createState() => _QRScannerModalState();
}

class _QRScannerModalState extends State<QRScannerModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scanAnim;
  bool _scanned = false;

  Map<String, String> get t => translations[widget.lang] ?? translations['kk']!;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _simulateScan() {
    if (_scanned) return;
    setState(() => _scanned = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onQRScanned({
        'lessonId': widget.lesson?.id ?? 1,
        'token': 'SA-QR-${DateTime.now().millisecondsSinceEpoch}',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black87,
        child: SafeArea(
          child: GestureDetector(
            onTap: () {}, // prevent dismiss on modal tap
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(t['scan_qr'] ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),

                // Lesson info
                if (widget.lesson != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.book_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.lesson!.subject,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700)),
                              Text('${widget.lesson!.room} • ${widget.lesson!.time}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                                      fontFamily: 'Inter', fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // QR Scanner viewfinder
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dark overlay with cutout
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _scanned ? AppColors.success : AppColors.primary,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.3),
                            child: _scanned
                                ? const Icon(Icons.check_circle,
                                    color: AppColors.success, size: 80)
                                : const Icon(Icons.qr_code_scanner,
                                    color: Colors.white54, size: 80),
                          ),
                        ),
                      ),

                      // Scanning line animation
                      if (!_scanned)
                        AnimatedBuilder(
                          animation: _scanAnim,
                          builder: (context, child) {
                            return Positioned(
                              top: 20 + (_scanAnim.value * 220),
                              child: Container(
                                width: 240,
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.primary.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // Corner decorations
                      ...['tl', 'tr', 'bl', 'br'].map((pos) =>
                          _buildCorner(pos, _scanned ? AppColors.success : AppColors.primary)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Demo scan button (since we can't use real camera in all contexts)
                GestureDetector(
                  onTap: _simulateScan,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF1557B0)]),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          _scanned ? '✅ QR Сканерленді!' : 'QR Кодты Сканерлеу',
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorner(String pos, Color color) {
    final isTop = pos.startsWith('t');
    final isLeft = pos.endsWith('l');
    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? BorderSide(color: color, width: 3) : BorderSide.none,
            bottom: !isTop ? BorderSide(color: color, width: 3) : BorderSide.none,
            left: isLeft ? BorderSide(color: color, width: 3) : BorderSide.none,
            right: !isLeft ? BorderSide(color: color, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
