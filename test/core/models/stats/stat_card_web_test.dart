import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/core/models/stats/stat_card_web.dart';

void main() {
  testWidgets('StatCardWeb displays title, count and correct colors with opacity', (tester) async {
    const testTitle = 'Test Title';
    const testCount = 123;
    const testColor = Colors.blue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatCardWeb(
            title: testTitle,
            count: testCount,
            color: testColor,
          ),
        ),
      ),
    );

    expect(find.text('$testCount'), findsOneWidget);
    expect(find.text(testTitle), findsOneWidget);

    final countText = tester.widget<Text>(find.text('$testCount'));
    expect(countText.style?.color, testColor);

    final titleText = tester.widget<Text>(find.text(testTitle));
    expect(titleText.style?.color, testColor.withOpacity(0.8));

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, testColor.withOpacity(0.1));

    final mouseRegion = tester.widget<MouseRegion>(find.byType(MouseRegion));
    expect(mouseRegion.cursor, SystemMouseCursors.click);
  });
}
