import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/features/practice/expense_practice_screen.dart';

void main() {
  testWidgets('Adding an expense updates the total and the list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExpensePracticeScreen()));

    expect(find.text('৳0'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('amountField')), '120');
    await tester.enterText(find.byKey(const Key('noteField')), 'Lunch');
    await tester.tap(find.byKey(const Key('addButton')));
    await tester.pump(); // rebuild after setState

    // ৳120 appears twice: in the total card and in the list row.
    expect(find.text('৳120'), findsNWidgets(2));
    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets('An empty amount shows an error and adds nothing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExpensePracticeScreen()));

    await tester.tap(find.byKey(const Key('addButton')));
    await tester.pump();

    expect(find.text('Enter a whole amount greater than 0'), findsOneWidget);
    expect(find.text('৳0'), findsOneWidget);
  });
}