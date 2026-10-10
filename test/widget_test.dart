import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/main.dart';

void main() {
  testWidgets('Splash shows name and tagline, then moves to login', (tester) async {
    await tester.pumpWidget(const MilbeKiApp());

    expect(find.text('MilbeKi'), findsOneWidget);
    expect(find.text('এইমাসেও হিসাব মিলবে না'), findsOneWidget);

    // Let the 2-second splash timer finish, then wait for the transition.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });
}