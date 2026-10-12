import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/page_loader_service.dart';

/// SmartAttend — Page Transition Loader Widget
/// 1. Semi-transparent frosted glass dark overlay with backdrop blur (6px)
/// 2. Centered SmartAttend logo ('S' with pin below and green checkmark above)
/// 3. SVG stylus handwriting typewriter animation
/// 4. 100ms fade-in, 150ms fade-out
class PageTransitionLoader extends StatefulWidget {
  const PageTransitionLoader({super.key});

  @override
  State<PageTransitionLoader> createState() => _PageTransitionLoaderState();
}

class _PageTransitionLoaderState extends State<PageTransitionLoader>
    with TickerProviderStateMixin {
  final PageLoaderService _service = PageLoaderService();

  late AnimationController _pulseController;
  late AnimationController _penController;

  Timer? _typewriterTimer;
  String _displayedText = '';
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _penController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _service.isVisible.addListener(_onVisibilityChanged);
  }

  void _onVisibilityChanged() {
    if (_service.isVisible.value) {
      _startTypewriter();
    } else {
      _stopTypewriter();
    }
  }

  void _startTypewriter() {
    _stopTypewriter();
    _charIndex = 0;
    _displayedText = '';

    final fullText = _service.currentMessage.value;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 110), (timer) {
      if (!mounted) return;
      if (_charIndex < fullText.length) {
        setState(() {
          _charIndex++;
          _displayedText = fullText.substring(0, _charIndex);
        });
      } else {
        // Pause and repeat if still visible
        _charIndex = 0;
        setState(() {
          _displayedText = '';
        });
      }
    });
  }

  void _stopTypewriter() {
    _typewriterTimer?.cancel();
    _typewriterTimer = null;
  }

  @override
  void dispose() {
    _service.isVisible.removeListener(_onVisibilityChanged);
    _typewriterTimer?.cancel();
    _pulseController.dispose();
    _penController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _service.isVisible,
      builder: (context, visible, child) {
        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: Duration(milliseconds: visible ? 100 : 150),
            curve: visible ? Curves.easeOut : Curves.easeIn,
            child: visible
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Frosted Backdrop Blur (sigma: 6px) & Dark Glass Tint
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                        child: Container(
                          color: const Color(0xB30B132B), // semi-transparent dark navy
                        ),
                      ),

                      // 2. Seamless Floating Elements (No Inner Box Background)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── SmartAttend Logo ──
                              _buildLogo(),
                              const SizedBox(height: 16),

                              // ── Typewriter Text & Handwriting Stylus ──
                              _buildHandwritingRow(),
                              const SizedBox(height: 12),

                              // ── Glowing Ink Underline ──
                              Container(
                                width: 140,
                                height: 2,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFF0062FF),
                                      Color(0xFF10B981),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 0.96 + (_pulseController.value * 0.08);
        final glowOpacity = 0.3 + (_pulseController.value * 0.4);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Soft glow aura
            Container(
              width: 76 * scale,
              height: 76 * scale,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0062FF).withValues(alpha: glowOpacity),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: glowOpacity * 0.6),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
            // Logo Image (Transparent floating)
            Image.asset(
              'assets/logo.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const _LogoFallbackPainterWidget(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHandwritingRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Typewriter Text
        Text(
          _displayedText.isEmpty ? ' ' : _displayedText,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),

        // Animated Handwriting Stylus
        AnimatedBuilder(
          animation: _penController,
          builder: (context, child) {
            final angle = -0.25 + (_penController.value * 0.15); // swaying
            final dy = -2.0 * _penController.value;

            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(
                angle: angle,
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF60A5FA),
                  size: 18,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Vector Painter fallback if asset hasn't finished loading
class _LogoFallbackPainterWidget extends StatelessWidget {
  const _LogoFallbackPainterWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blue downward pin pointer
          Positioned(
            bottom: 6,
            child: Container(
              width: 14,
              height: 22,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF38BDF8), Color(0xFF1D4ED8)],
                ),
              ),
            ),
          ),
          // White bold 'S'
          const Text(
            'S',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          // Green Checkmark
          const Positioned(
            top: 10,
            right: 12,
            child: Icon(
              Icons.check,
              size: 22,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}
