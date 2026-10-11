// SmartAttend — Unified Light Mode Native Campus Map
// Fully native, zero-lag architectural indoor blueprint for AITU Block C1
// Responsive layout that scales to any screen size (Light Mode: #FFFFFF, #F8FAFC, #0062FF)

import 'package:flutter/material.dart';
import '../services/page_loader_service.dart';

class CampusMapScreen extends StatefulWidget {
  final String lang; // 'kk', 'ru', 'en'
  final String? initialPOI;
  final int initialFloor;
  final bool isEmbeddedTab;
  final Function(String lang)? onLangChanged;

  const CampusMapScreen({
    super.key,
    this.lang = 'kk',
    this.initialPOI,
    this.initialFloor = 3,
    this.isEmbeddedTab = false,
    this.onLangChanged,
  });

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class RoomModel {
  final String code;
  final String titleKk;
  final String titleRu;
  final String titleEn;
  final int floor;
  final String teacher;
  final String group;
  final int present;
  final int late;
  // Normalized coordinates (0.0 to 1.0) relative to blueprint canvas
  final double normLeft;
  final double normTop;
  final double normWidth;
  final double normHeight;
  final bool isLive;
  final IconData icon;

  const RoomModel({
    required this.code,
    required this.titleKk,
    required this.titleRu,
    required this.titleEn,
    required this.floor,
    required this.teacher,
    required this.group,
    this.present = 18,
    this.late = 2,
    required this.normLeft,
    required this.normTop,
    required this.normWidth,
    required this.normHeight,
    this.isLive = false,
    this.icon = Icons.meeting_room_outlined,
  });

  String getTitle(String lang) {
    if (lang == 'ru') return titleRu;
    if (lang == 'en') return titleEn;
    return titleKk;
  }
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  late String _currentLang;
  late int _currentFloor;
  RoomModel? _selectedRoom;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // All university rooms by floor with normalized coordinates
  final List<RoomModel> _allRooms = const [
    // ── 3-FLOOR (Main IT Faculty & БҚ2405) ──
    RoomModel(
      code: 'C1.3.241',
      titleKk: 'Мобильді қосымшалар әзірлеу зертханасы',
      titleRu: 'Лаборатория мобильной разработки',
      titleEn: 'Mobile App Development Lab',
      floor: 3,
      teacher: 'Калниязов А.А.',
      group: 'БҚ2405 (20 студент)',
      present: 18,
      late: 2,
      normLeft: 0.22,
      normTop: 0.10,
      normWidth: 0.23,
      normHeight: 0.30,
      isLive: true,
      icon: Icons.developer_mode_rounded,
    ),
    RoomModel(
      code: 'C1.3.240',
      titleKk: 'Серверлік жүйелер зертханасы',
      titleRu: 'Лаборатория серверных систем',
      titleEn: 'Server Systems Lab',
      floor: 3,
      teacher: 'Билал Д.Д.',
      group: 'ПО2501',
      present: 19,
      late: 1,
      normLeft: 0.48,
      normTop: 0.10,
      normWidth: 0.22,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.dns_outlined,
    ),
    RoomModel(
      code: 'C1.3.238',
      titleKk: 'Компьютерлік желілер дәрісханасы',
      titleRu: 'Аудитория компьютерных сетей',
      titleEn: 'Computer Networks Lecture Hall',
      floor: 3,
      teacher: 'Ахметова Е.З.',
      group: 'БҚ2503',
      present: 20,
      late: 0,
      normLeft: 0.73,
      normTop: 0.10,
      normWidth: 0.22,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.lan_outlined,
    ),
    RoomModel(
      code: 'C1.3.220',
      titleKk: 'Оқу бөлмесі 220',
      titleRu: 'Учебная аудитория 220',
      titleEn: 'Study Room 220',
      floor: 3,
      teacher: 'Еркін оқу залы',
      group: 'Студенттер',
      present: 10,
      late: 0,
      normLeft: 0.05,
      normTop: 0.58,
      normWidth: 0.16,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.menu_book_outlined,
    ),
    RoomModel(
      code: 'C1.3.228',
      titleKk: 'Алгоритмдер және деректер құрылымы',
      titleRu: 'Алгоритмы и структуры данных',
      titleEn: 'Algorithms & Data Structures',
      floor: 3,
      teacher: 'Жұмағанбетова А.К.',
      group: 'ПО2502',
      present: 17,
      late: 3,
      normLeft: 0.24,
      normTop: 0.58,
      normWidth: 0.17,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.code_rounded,
    ),
    RoomModel(
      code: 'C1.3.229',
      titleKk: 'Деректер қоры зертханасы',
      titleRu: 'Лаборатория баз данных',
      titleEn: 'Database Systems Lab',
      floor: 3,
      teacher: 'Акубаева Б.А.',
      group: 'ВТ2510',
      present: 16,
      late: 4,
      normLeft: 0.44,
      normTop: 0.58,
      normWidth: 0.16,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.storage_rounded,
    ),
    RoomModel(
      code: 'C1.3.230',
      titleKk: 'Web-технологиялар аудиториясы',
      titleRu: 'Аудитория Web-технологий',
      titleEn: 'Web Technologies Classroom',
      floor: 3,
      teacher: 'Мұғалімдер құрамы',
      group: 'ПО2506',
      present: 19,
      late: 0,
      normLeft: 0.63,
      normTop: 0.58,
      normWidth: 0.15,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.web_rounded,
    ),
    RoomModel(
      code: 'C1.3.237',
      titleKk: 'Жасанды интеллект орталығы',
      titleRu: 'Центр искусственного интеллекта',
      titleEn: 'AI Research Center',
      floor: 3,
      teacher: 'AI Faculty',
      group: 'ПО2508',
      present: 15,
      late: 2,
      normLeft: 0.81,
      normTop: 0.58,
      normWidth: 0.15,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.psychology_outlined,
    ),

    // ── 2-FLOOR (Deanery, Faculty & Classrooms) ──
    RoomModel(
      code: 'ДЕКАНАТ',
      titleKk: 'IT-Факультеті Деканаты (Мониторинг)',
      titleRu: 'Деканат IT-факультета (Мониторинг)',
      titleEn: 'Deanery Office (Live Monitoring)',
      floor: 2,
      teacher: 'Декан: Ахметов С.Б.',
      group: 'Колледж әкімшілігі',
      present: 20,
      late: 0,
      normLeft: 0.20,
      normTop: 0.10,
      normWidth: 0.32,
      normHeight: 0.30,
      isLive: true,
      icon: Icons.apartment_rounded,
    ),
    RoomModel(
      code: 'ОҚЫТУШЫЛАР',
      titleKk: 'Оқытушылар бөлмесі (Кафедра)',
      titleRu: 'Преподавательская (Кафедра)',
      titleEn: 'Faculty & Teachers Room',
      floor: 2,
      teacher: 'Талдаубек Арай (Куратор)',
      group: 'Оқытушылар құрамы',
      present: 12,
      late: 0,
      normLeft: 0.56,
      normTop: 0.10,
      normWidth: 0.32,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.badge_outlined,
    ),
    RoomModel(
      code: 'C1.2.215',
      titleKk: 'Аудитория 215 (Киберқауіпсіздік)',
      titleRu: 'Аудитория 215 (Кибербезопасность)',
      titleEn: 'Classroom 215 (Cybersecurity)',
      floor: 2,
      teacher: 'Оқытушы',
      group: 'ПО2507',
      present: 18,
      late: 1,
      normLeft: 0.15,
      normTop: 0.58,
      normWidth: 0.24,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.shield_outlined,
    ),
    RoomModel(
      code: 'C1.2.218',
      titleKk: 'Аудитория 218',
      titleRu: 'Аудитория 218',
      titleEn: 'Classroom 218',
      floor: 2,
      teacher: 'Оқытушы',
      group: 'БҚ2504',
      present: 17,
      late: 2,
      normLeft: 0.42,
      normTop: 0.58,
      normWidth: 0.24,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.meeting_room_outlined,
    ),
    RoomModel(
      code: 'C1.2.222',
      titleKk: 'Аудитория 222',
      titleRu: 'Аудитория 222',
      titleEn: 'Classroom 222',
      floor: 2,
      teacher: 'Оқытушы',
      group: 'ВТ2511',
      present: 19,
      late: 0,
      normLeft: 0.69,
      normTop: 0.58,
      normWidth: 0.24,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.meeting_room_outlined,
    ),

    // ── 1-FLOOR (Public Services) ──
    RoomModel(
      code: 'АКТ ЗАЛЫ',
      titleKk: 'Акт залы (Assembly Hall)',
      titleRu: 'Актовый зал (Assembly Hall)',
      titleEn: 'Assembly Hall (Grand Auditorium)',
      floor: 1,
      teacher: 'Бас конференц-орталық',
      group: 'Жалпы жиындар',
      present: 120,
      late: 0,
      normLeft: 0.12,
      normTop: 0.10,
      normWidth: 0.36,
      normHeight: 0.30,
      isLive: true,
      icon: Icons.stadium_outlined,
    ),
    RoomModel(
      code: 'АСХАНА',
      titleKk: 'Асхана / Столовая (Food Court)',
      titleRu: 'Столовая / Food Court',
      titleEn: 'Dining Hall / Cafeteria',
      floor: 1,
      teacher: 'AITU Food Service',
      group: 'Барлық студенттер',
      present: 85,
      late: 0,
      normLeft: 0.52,
      normTop: 0.10,
      normWidth: 0.36,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.restaurant_outlined,
    ),
    RoomModel(
      code: 'СПОРТЗАЛ',
      titleKk: 'Спортзал (Fitness & Gym)',
      titleRu: 'Спорткомплекс / Gym',
      titleEn: 'Sports Complex & Gym',
      floor: 1,
      teacher: 'Дене шынықтыру кафедрасы',
      group: 'Барлық топтар',
      present: 40,
      late: 0,
      normLeft: 0.10,
      normTop: 0.58,
      normWidth: 0.26,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.fitness_center_outlined,
    ),
    RoomModel(
      code: 'КІТАПХАНА',
      titleKk: 'Ғылыми кітапхана және коворкинг',
      titleRu: 'Научная библиотека и коворкинг',
      titleEn: 'Science Library & Coworking',
      floor: 1,
      teacher: 'Кітапхана әкімшілігі',
      group: 'Оқу залы',
      present: 35,
      late: 0,
      normLeft: 0.40,
      normTop: 0.58,
      normWidth: 0.28,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.local_library_outlined,
    ),
    RoomModel(
      code: 'МЕДПУНКТ 143',
      titleKk: 'Медпункт (143 аудитория)',
      titleRu: 'Медпункт (Кабинет 143)',
      titleEn: 'Medical Center (Room 143)',
      floor: 1,
      teacher: 'Дәрігер / Медициналық көмек',
      group: 'Денсаулық қызметі',
      present: 2,
      late: 0,
      normLeft: 0.72,
      normTop: 0.58,
      normWidth: 0.22,
      normHeight: 0.30,
      isLive: false,
      icon: Icons.local_hospital_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;
    _currentFloor = widget.initialFloor;

    // Default active classroom: C1.3.241 (user's classroom)
    final initial = _allRooms.firstWhere(
      (r) => r.code == (widget.initialPOI ?? 'C1.3.241'),
      orElse: () => _allRooms.first,
    );
    _selectedRoom = initial;
    _currentFloor = initial.floor;
  }

  void _onRoomTapped(RoomModel room) {
    PageLoaderService().show(lang: _currentLang);
    setState(() {
      _selectedRoom = room;
      if (_currentFloor != room.floor) {
        _currentFloor = room.floor;
      }
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      PageLoaderService().hide();
    });
  }

  void _onFloorChanged(int floor) {
    if (_currentFloor == floor) return;
    PageLoaderService().show(lang: _currentLang);
    setState(() {
      _currentFloor = floor;
      if (_selectedRoom?.floor != floor) {
        _selectedRoom = _allRooms.firstWhere((r) => r.floor == floor, orElse: () => _allRooms.first);
      }
    });
    Future.delayed(const Duration(milliseconds: 220), () {
      PageLoaderService().hide();
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      if (_searchQuery.isNotEmpty) {
        final match = _allRooms.firstWhere(
          (r) =>
              r.code.toLowerCase().contains(_searchQuery) ||
              r.titleKk.toLowerCase().contains(_searchQuery) ||
              r.titleRu.toLowerCase().contains(_searchQuery) ||
              r.titleEn.toLowerCase().contains(_searchQuery) ||
              r.teacher.toLowerCase().contains(_searchQuery) ||
              r.group.toLowerCase().contains(_searchQuery),
          orElse: () => _selectedRoom ?? _allRooms.first,
        );
        _selectedRoom = match;
        _currentFloor = match.floor;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentFloorRooms = _allRooms.where((r) => r.floor == _currentFloor).toList();
    debugPrint(">>> CAMPUS MAP BUILD: floor=$_currentFloor, count=${currentFloorRooms.length}, room=${_selectedRoom?.code}");

    Widget body = Column(
      children: [
        // ── SEARCH BAR & QUICK FILTERS ──────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            children: [
              // Clean Vector Search Bar
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: _currentLang == 'kk'
                              ? 'Кабинет, мұғалім немесе топ іздеу...'
                              : (_currentLang == 'en' ? 'Find classroom, teacher or group...' : 'Поиск кабинета, преподавателя, группы...'),
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                        child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Floor Switcher Pills (1, 2, 3)
              Row(
                children: [
                  _floorTab(1, _currentLang == 'kk' ? '1-қабат' : (_currentLang == 'en' ? '1st floor' : '1 этаж')),
                  const SizedBox(width: 8),
                  _floorTab(2, _currentLang == 'kk' ? '2-қабат' : (_currentLang == 'en' ? '2nd floor' : '2 этаж')),
                  const SizedBox(width: 8),
                  _floorTab(3, _currentLang == 'kk' ? '3-қабат' : (_currentLang == 'en' ? '3rd floor' : '3 этаж')),
                ],
              ),
            ],
          ),
        ),

        // ── RESPONSIVE BLUEPRINT CANVAS ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double canvasWidth = constraints.maxWidth;
              const double canvasHeight = 310.0;

              return Container(
                width: canvasWidth,
                height: canvasHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Blueprint Hallway & Watermark
                    CustomPaint(
                      painter: _CampusBlueprintPainter(
                        floor: _currentFloor,
                      ),
                    ),
                    // Interactive Room Boxes
                    ...currentFloorRooms.map((room) {
                      final isSelected = _selectedRoom?.code == room.code;
                      final left = room.normLeft * canvasWidth;
                      final top = room.normTop * canvasHeight;
                      final width = room.normWidth * canvasWidth;
                      final height = room.normHeight * canvasHeight;

                      return Positioned(
                        left: left,
                        top: top,
                        width: width,
                        height: height,
                        child: GestureDetector(
                          onTap: () => _onRoomTapped(room),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : (room.isLive ? const Color(0xFFF0FDF4) : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0062FF)
                                    : (room.isLive ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
                                width: isSelected ? 2.2 : 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0062FF).withValues(alpha: 0.18),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        room.code,
                                        style: TextStyle(
                                          color: isSelected ? const Color(0xFF0062FF) : const Color(0xFF0F172A),
                                          fontWeight: FontWeight.w900,
                                          fontSize: canvasWidth < 380 ? 10.5 : 11.5,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (room.isLive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Color(0xFF16A34A),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 7.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      room.icon,
                                      color: isSelected ? const Color(0xFF0062FF) : const Color(0xFF64748B),
                                      size: canvasWidth < 380 ? 13 : 15,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        room.group,
                                        style: TextStyle(
                                          color: isSelected ? const Color(0xFF0062FF) : const Color(0xFF64748B),
                                          fontSize: canvasWidth < 380 ? 8 : 8.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),

        // ── BOTTOM AUDITORIUM INSPECTOR CARD ─────────────────────────
        if (_selectedRoom != null) _buildAuditoriumInspectorCard(_selectedRoom!),
        const SizedBox(height: 16),
      ],
    );

    final scrollableBody = SingleChildScrollView(
      child: body,
    );

    if (widget.isEmbeddedTab) {
      return Container(
        color: const Color(0xFFF8FAFC),
        child: scrollableBody,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0062FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AITU',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentLang == 'kk' ? 'SmartAttend Картасы' : (_currentLang == 'en' ? 'SmartAttend Map' : 'Карта SmartAttend'),
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _currentLang == 'kk' ? 'C1 Блогы (1–3 қабаттар)' : (_currentLang == 'en' ? 'Block C1 (Floors 1–3)' : 'Блок C1 (1–3 этажи)'),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Language Pill
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _langChip('kk', 'KZ'),
                        _langChip('ru', 'RU'),
                        _langChip('en', 'EN'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      body: scrollableBody,
    );
  }

  Widget _floorTab(int floor, String label) {
    final isSelected = _currentFloor == floor;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onFloorChanged(floor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0062FF) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _langChip(String code, String label) {
    final isSelected = _currentLang == code;
    return GestureDetector(
      onTap: () {
        setState(() => _currentLang = code);
        widget.onLangChanged?.call(code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0062FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildAuditoriumInspectorCard(RoomModel room) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: SafeArea(
        top: false,
        bottom: !widget.isEmbeddedTab,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Center(
                    child: Icon(room.icon, color: const Color(0xFF0062FF), size: 22),
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
                            '${room.code} • ${room.floor}-${_currentLang == 'kk' ? 'қабат' : (_currentLang == 'en' ? 'floor' : 'этаж')}',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(),
                          if (room.isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _currentLang == 'kk' ? 'Сабақ жүруде' : (_currentLang == 'en' ? 'Live Lecture' : 'Идёт занятие'),
                                style: const TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        room.getTitle(_currentLang),
                        style: const TextStyle(
                          color: Color(0xFF0062FF),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Details grid (Teacher, Group)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentLang == 'kk' ? 'Оқытушы' : (_currentLang == 'en' ? 'Teacher' : 'Преподаватель'),
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          room.teacher,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentLang == 'kk' ? 'Топ' : (_currentLang == 'en' ? 'Group' : 'Группа'),
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          room.group,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Live Attendance Tag & Navigate Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '${room.present} ${_currentLang == 'kk' ? 'Қатысты' : (_currentLang == 'en' ? 'Present' : 'Присутствуют')} • ${room.late} ${_currentLang == 'kk' ? 'Кешікті' : (_currentLang == 'en' ? 'Late' : 'Опоздали')}',
                        style: const TextStyle(
                          color: Color(0xFF047857),
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _currentLang == 'kk'
                              ? 'Маршрут құрылды: ${room.code} (${room.floor}-қабат)'
                              : 'Маршрут построен: ${room.code} (${room.floor} этаж)',
                        ),
                        backgroundColor: const Color(0xFF0062FF),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.near_me_rounded, size: 14),
                  label: Text(
                    _currentLang == 'kk' ? 'Маршрут' : (_currentLang == 'en' ? 'Navigate' : 'Маршрут'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0062FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── CUSTOM PAINTER FOR ARCHITECTURAL BLUEPRINT ────────────────
class _CampusBlueprintPainter extends CustomPainter {
  final int floor;

  _CampusBlueprintPainter({
    required this.floor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final corridorPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    final wallPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw main central hallway / corridor
    final corridorRect = Rect.fromLTWH(
      size.width * 0.04,
      size.height * 0.44,
      size.width * 0.92,
      size.height * 0.10,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(corridorRect, const Radius.circular(6)),
      corridorPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(corridorRect, const Radius.circular(6)),
      wallPaint,
    );

    // Floor label watermark
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'AITU BLOCK C1 • FLOOR $floor',
        style: TextStyle(
          color: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
          fontSize: size.width < 380 ? 12 : 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        corridorRect.top + (corridorRect.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _CampusBlueprintPainter oldDelegate) {
    return oldDelegate.floor != floor;
  }
}
