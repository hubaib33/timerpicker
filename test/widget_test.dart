// Basic smoke test for the time picker field demo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timepickerfield/main.dart';

void main() {
  testWidgets('Time picker field renders with initial value',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // The demo seeds the field with 09:30.
    expect(find.text('Selected: 09:30'), findsOneWidget);
    expect(find.byIcon(Icons.access_time), findsOneWidget);
  });
}
