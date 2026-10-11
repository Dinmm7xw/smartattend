// SmartAttend — Official AITU Real 3D Vector College Map Screen (Block C1)
// Replaces previous box schematic with the genuine vector architectural blueprints

import 'package:flutter/material.dart';
import '../widgets/real_map_web.dart';

class CampusMapScreen extends StatelessWidget {
  final String lang;
  final String? initialPOI;
  final int initialFloor;
  final bool isEmbeddedTab;
  final Function(String lang)? onLangChanged;

  const CampusMapScreen({
    super.key,
    this.lang = 'kk',
    this.initialPOI,
    this.initialFloor = 2,
    this.isEmbeddedTab = false,
    this.onLangChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmbeddedTab) {
      return const RealCollegeMapView();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'AITU Кампус Картасы (C1 Блогы)',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SafeArea(
        child: RealCollegeMapView(),
      ),
    );
  }
}
