import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/core/models/action_card_web.dart';

void main() {
  testWidgets('ActionCardWeb displays title, icon, color and reacts to tap', (tester) async {
    const testTitle = 'Action Title';
    const testIcon = Icons.add;
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionCardWeb(
            title: testTitle,
            icon: testIcon,
            onTap: () {
              tapped = true;
            },
            color: Colors.green,
          ),
        ),
      ),
    );

    expect(find.text(testTitle), findsOneWidget);
    expect(find.byIcon(testIcon), findsOneWidget);

    final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    final buttonStyle = elevatedButton.style;
    expect(buttonStyle?.backgroundColor?.resolve({}), Colors.green);

    final mouseRegion = tester.widget<MouseRegion>(find.byType(MouseRegion));
    expect(mouseRegion.cursor, SystemMouseCursors.click);

    await tester.tap(find.byType(ElevatedButton));
    expect(tapped, isTrue);
  });
}
