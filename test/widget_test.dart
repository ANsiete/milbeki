import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/main.dart';

void main() {
  testWidgets('Splash screen shows the app name and tagline', (tester) async {
    await tester.pumpWidget(const MilbeKiApp());

    expect(find.text('MilbeKi'), findsOneWidget);
    expect(find.text('এইমাসেও হিসাব মিলবে না'), findsOneWidget);
  });
}