import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/core/models/stats/stat_card.dart';

void main() {
  testWidgets('StatCard displays title, count and has correct background color', (tester) async {
    const testTitle = 'Test Title';
    const testCount = 42;
    const testColor = Colors.red;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatCard(
            title: testTitle,
            count: testCount,
            color: testColor,
          ),
        ),
      ),
    );

    expect(find.text('$testCount'), findsOneWidget);
    expect(find.text(testTitle), findsOneWidget);

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, testColor);
  });
}
