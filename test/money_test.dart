import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/core/widgets/money_text.dart';

void main() {
  group('Money formatting', () {
    test('uses Bangladeshi digit grouping', () {
      expect(Money.taka(14600).format(), '৳14,600');
      expect(Money.taka(100000).format(), '৳1,00,000');
      expect(Money.taka(1234567).format(), '৳12,34,567');
      expect(Money.taka(999).format(), '৳999');
    });

    test('shows decimals only when there are paisa', () {
      expect(Money.parse('125.5').format(), '৳125.50');
      expect(Money.parse('125000.5').format(), '৳1,25,000.50');
      expect(Money.taka(125).format(alwaysShowDecimals: true), '৳125.00');
    });

    test('formats negative amounts and zero', () {
      expect(Money.taka(-1200).format(), '-৳1,200');
      expect(Money.zero.format(), '৳0');
    });
  });

  group('Money parsing and arithmetic', () {
    test('parses text amounts into paisa', () {
      expect(Money.parse('125').paisa, 12500);
      expect(Money.parse('125.5').paisa, 12550);
      expect(Money.parse('-40.25').paisa, -4025);
    });

    test('rejects invalid text', () {
      expect(() => Money.parse('abc'), throwsFormatException);
      expect(() => Money.parse('1.234'), throwsFormatException);
      expect(() => Money.parse(''), throwsFormatException);
    });

    test('addition is exact, unlike double', () {
      expect(Money.parse('0.10') + Money.parse('0.20'), Money.parse('0.30'));
    });

    test('Phase 1 worked example: total money held is ৳14,600', () {
      final cash = Money.taka(2000) -
          Money.taka(500) +
          Money.taka(1000) +
          Money.taka(500) -
          Money.taka(200) -
          Money.taka(300) +
          Money.taka(100);
      final bkash = Money.taka(3000) + Money.taka(10000) - Money.taka(1000);

      expect(cash, Money.taka(2600));
      expect(bkash, Money.taka(12000));
      expect(cash + bkash, Money.taka(14600));
    });
  });

  testWidgets('MoneyText displays a formatted amount', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MoneyText(Money.taka(14600)))),
    );

    expect(find.text('৳14,600'), findsOneWidget);
  });
}