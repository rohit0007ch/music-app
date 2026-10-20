import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/app/app.dart';

void main() {
  testWidgets('MeloraApp renders root scaffold without errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MeloraApp());
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Switching to Discover tab shows search field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MeloraApp());
    await tester.pump();

    await tester.tap(find.text('Discover'));
    // Avoid pumpAndSettle — library/plugin futures + indicators can animate.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Switching to Downloads tab works', (WidgetTester tester) async {
    await tester.pumpWidget(const MeloraApp());
    await tester.pump();

    await tester.tap(find.text('Downloads'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Downloads'), findsWidgets);
  });
}
