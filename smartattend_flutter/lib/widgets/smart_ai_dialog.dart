// SmartAttend — Smart AI College Navigator & Dean Assistant (Gemini Flash)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/api_service.dart';
import '../utils/platform_helper.dart';

class SmartAIMessage {
  final String text;
  final bool isUser;
  final Map<String, dynamic>? action;
  final DateTime time;

  SmartAIMessage({
    required this.text,
    required this.isUser,
    this.action,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class SmartAIDialog extends StatefulWidget {
  final String userRole;
  final String userName;
  final String lang;
  final Function(int floor, String? roomCode)? onNavigateToFloor;

  const SmartAIDialog({
    super.key,
    required this.userRole,
    required this.userName,
    this.lang = 'kk',
    this.onNavigateToFloor,
  });

  static Future<void> show(
    BuildContext context, {
    required String userRole,
    required String userName,
    String lang = 'kk',
    Function(int floor, String? roomCode)? onNavigateToFloor,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SmartAIDialog(
        userRole: userRole,
        userName: userName,
        lang: lang,
        onNavigateToFloor: onNavigateToFloor,
      ),
    );
  }

  @override
  State<SmartAIDialog> createState() => _SmartAIDialogState();
}

class _SmartAIDialogState extends State<SmartAIDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<SmartAIMessage> _messages = [];
  bool _loading = false;
  bool _scanningSchedule = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      SmartAIMessage(
        text: widget.lang == 'ru'
            ? 'Привет! Я ИИ-ассистент колледжа SmartAttend. Спросите меня о расположении кабинетов (например, "где 221 кабинет?"), расписании или правилах.'
            : 'Сәлем! Мен SmartAttend колледжінің ИИ-көмекшісімін. Менен аудиториялардың орналасқан жерін (мысалы, "221 кабинет қайда?"), кесте мен ережелерді сұрай аласыз.',
        isUser: false,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _loading) return;

    _controller.clear();
    setState(() {
      _messages.add(SmartAIMessage(text: prompt, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    final res = await ApiService.askAI(
      prompt: prompt,
      role: widget.userRole,
      userName: widget.userName,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        _messages.add(
          SmartAIMessage(
            text: res['reply'] ?? (widget.lang == 'ru' ? 'Ошибка ответа ИИ' : 'ИИ жауап беруде қате кетті'),
            isUser: false,
            action: res['action'],
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _handleScanSchedule() {
    if (kIsWeb) {
      WebPlatformHelper.pickWebImage((base64Data) async {
        setState(() => _scanningSchedule = true);
        try {
          final cleanBase64 = base64Data.contains(',')
              ? base64Data.split(',')[1]
              : base64Data;
          final bytes = base64Decode(cleanBase64);

          final res = await ApiService.scanScheduleAI(imageBytes: bytes);
          if (mounted) {
            setState(() => _scanningSchedule = false);
            if (res['success'] == true) {
              final count = res['saved_count'] ?? 0;
              setState(() {
                _messages.add(
                  SmartAIMessage(
                    text: widget.lang == 'ru'
                        ? '✅ Фото расписания успешно распознано ИИ Gemini!\nСохранено в базу: $count занятий.'
                        : '✅ Сабақ кестесінің фотосы Gemini ИИ арқылы танылды!\nБазаға қосылды: $count сабақ.',
                    isUser: false,
                  ),
                );
              });
              _scrollToBottom();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message'] ?? 'Қате орын алды')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() => _scanningSchedule = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Қате: $e')),
            );
          }
        }
      });
    } else {
      // Mobile demo fallback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фото таңдау терезесі ашылуда...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDeanOrDirector = widget.userRole == 'DEAN' || widget.userRole == 'DIRECTOR';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            spreadRadius: 2,
            offset: Offset(0, -4),
          )
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Smart AI Navigator',
                            style: TextStyle(
                              fontFamily: AppTextStyles.font,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Gemini 3.5',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.lang == 'ru'
                            ? 'Навигация по кампусу и умный поиск'
                            : 'Кампус навигаторы және ақылды кеңесші',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_loading || _scanningSchedule)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _scanningSchedule
                        ? (widget.lang == 'ru' ? 'ИИ Gemini распознает расписание...' : 'Gemini ИИ кестені оқуда...')
                        : (widget.lang == 'ru' ? 'ИИ думает...' : 'ИИ ойлануда...'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

          // Suggestion Chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _buildQuickChip('📍 221 кабинет қайда?', '221 аудитория қайда орналасқан?'),
                _buildQuickChip('🏛️ Деканат қайда?', 'Деканат қай қабатта орналасқан?'),
                _buildQuickChip('🍽️ Асхана қайда?', 'Асхана мен спортзал қайда?'),
                _buildQuickChip('🎯 241 IT лабораториясы', '241 кабинетке қалай барамын?'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Dean OCR Action Bar
          if (isDeanOrDirector) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: InkWell(
                onTap: _scanningSchedule ? null : _handleScanSchedule,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.document_scanner_rounded, size: 18, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 8),
                      Text(
                        widget.lang == 'ru'
                            ? '📸 ИИ-сканирование фото расписания в базу'
                            : '📸 ИИ-арқылы кесте фотосын базаға қосу',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.lang == 'ru'
                          ? 'Спросите (например: "где 221 кабинет?")...'
                          : 'Сұраңыз (мысалы: "221 кабинет қайда?")...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendMessage(_controller.text),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => _sendMessage(prompt),
      ),
    );
  }

  Widget _buildMessageBubble(SmartAIMessage msg) {
    final isUser = msg.isUser;
    final targetFloor = msg.action?['target_floor'] as int?;
    final roomCode = msg.action?['room_code'] as String?;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: isUser ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (targetFloor != null) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onNavigateToFloor != null) {
                    widget.onNavigateToFloor!(targetFloor, roomCode);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.lang == 'ru'
                            ? '📍 Открыть на карте ($targetFloor этаж)'
                            : '📍 Картадан көру ($targetFloor-қабат)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
