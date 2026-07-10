import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timepickerfield/timepickerfield.dart';

void main() {
  testWidgets('TimePickerField renders and opens the overlay panel',
      (tester) async {
    final controller = TextEditingController(text: '09:30');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: TimePickerField(controller: controller),
          ),
        ),
      ),
    );

    // Field shows the seeded value.
    expect(find.text('09:30'), findsOneWidget);

    // Tapping opens the overlay with HOURS / MINUTES columns.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.text('HOURS'), findsOneWidget);
    expect(find.text('MINUTES'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });
}
