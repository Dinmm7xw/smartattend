import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/platform_helper.dart';

/// SmartAttend — Global Page Transition Loader Controller
/// Provides global showLoader / hideLoader methods accessible anywhere in the app.
class PageLoaderService {
  static final PageLoaderService _instance = PageLoaderService._internal();
  factory PageLoaderService() => _instance;
  PageLoaderService._internal();

  final ValueNotifier<bool> isVisible = ValueNotifier<bool>(false);
  final ValueNotifier<String> currentMessage = ValueNotifier<String>('Жүктелуде...');
  final ValueNotifier<String> currentLang = ValueNotifier<String>('kk');

  Timer? _autoHideTimer;

  static const Map<String, String> localizedTexts = {
    'kk': 'Жүктелуде...',
    'kz': 'Жүктелуде...',
    'ru': 'Загрузка...',
    'en': 'Loading...',
  };

  /// Show the page transition loader
  void show({String? lang, String? message}) {
    final selectedLang = lang ?? currentLang.value;
    final text = message ?? localizedTexts[selectedLang] ?? 'Жүктелуде...';

    currentLang.value = selectedLang;
    currentMessage.value = text;
    isVisible.value = true;

    // Web DOM bridge call if running in browser
    if (kIsWeb) {
      WebPlatformHelper.showWebLoader(selectedLang, text);
    }

    // Safety timeout: auto-hide after 5 seconds to prevent permanent lock
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 5), () {
      if (isVisible.value) hide();
    });
  }

  /// Hide the page transition loader
  void hide() {
    _autoHideTimer?.cancel();
    isVisible.value = false;

    // Web DOM bridge call
    if (kIsWeb) {
      WebPlatformHelper.hideWebLoader();
    }
  }

  /// Run an asynchronous task or page switch with smooth transition
  Future<T> runWithLoader<T>(
    Future<T> Function() action, {
    String? lang,
    String? message,
    Duration minDuration = const Duration(milliseconds: 320),
  }) async {
    show(lang: lang, message: message);
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      final elapsed = stopwatch.elapsed;
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
      return result;
    } finally {
      hide();
    }
  }
}
