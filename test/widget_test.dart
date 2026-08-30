import 'package:ecommerce_app/screens/calculator/calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> openCalculator(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: CalculatorScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('saves answers once and updates saved total', (tester) async {
    await openCalculator(tester);
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('+').last);
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('9').last);
    await tester.tap(find.text('=').last);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Answer saved'), findsOneWidget);

    await tester.tap(find.byTooltip('Saved Results'));
    await tester.pumpAndSettle();
    expect(find.text('Total of Saved Answers'), findsOneWidget);
    expect(find.text('20'), findsWidgets);
    expect(find.text('1 saved record'), findsOneWidget);
  });

  testWidgets(
    'base converter rejects invalid digits and converts BigInt values',
    (tester) async {
      await openCalculator(tester);
      await tester.tap(find.byTooltip('Base Converter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Decimal — Base 10'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        '123456789012345678901234567890',
      );
      await tester.pumpAndSettle();
      expect(find.text('123456789012345678901234567890'), findsWidgets);
    },
  );
}
