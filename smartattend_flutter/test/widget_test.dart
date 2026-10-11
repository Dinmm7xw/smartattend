import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend_flutter/main.dart';

void main() {
  testWidgets('SmartAttend app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAttendApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
